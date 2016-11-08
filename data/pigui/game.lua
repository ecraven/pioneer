local Engine = import('Engine')
local Game = import('Game')
local ui = import('pigui')
local Vector = import('Vector')
local Color = import('Color')
local Lang = import("Lang")
local lc = Lang.GetResource("core");
local lui = Lang.GetResource("ui-core");
local utils = import("utils")

local base = Color(0,1,33)
local highlight = Color(0,63,112)

local reticuleCircleRadius = math.min(ui.screenWidth, ui.screenHeight) / 13
local reticuleCircleThickness = 2.0

local showNavigationalNumbers = false
local colors = {
	reticuleCircle = Color(200, 200, 200),
	transparent = Color(0, 0, 0, 0),
	navTarget = Color(0, 255, 0),
	frame = Color(200, 200, 200),
	navigationalElements = Color(200, 200, 200),
	deltaVCurrent = Color(150, 150, 150),
	deltaVManeuver = Color(168, 168, 255),
	deltaVRemaining = Color(250, 250, 250),
	deltaVTotal = Color(100, 100, 100, 200),
}

local function displayReticulePitch(center, pitch_degrees)
	local function pitchline(hrs, length, color, thickness)
		local a = ui.pointOnClock(center, reticuleCircleRadius - 1 - length, hrs)
		local b = ui.pointOnClock(center, reticuleCircleRadius - 1, hrs)
		ui.addLine(a, b, color, thickness)
	end
	local size = 2
	pitchline(3, size * 2, colors.reticuleCircle, 1)
	pitchline(2.25, size, colors.reticuleCircle, 1)
	pitchline(3.75, size, colors.reticuleCircle, 1)
	pitchline(1.5, size * 2, colors.reticuleCircle, 1)
	pitchline(4.5, size * 2, colors.reticuleCircle, 1)
	local xpitch = (pitch_degrees + 90) / 180
	local xpitch_h = 4.5 - xpitch * 3
	pitchline(xpitch_h, size * 3, colors.navigationalElements, 2)
end

local function displayReticuleHorizon(center, roll_degrees)
	local offset = 30
	local width = 10
	local height_hrs = 0.1
	local hrs = roll_degrees / 360 * 12 + 3
	-- left hook
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs),
						 ui.pointOnClock(center, reticuleCircleRadius - offset - width, hrs),
						 colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs),
						 ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + height_hrs),
						 colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, -3),
						 ui.pointOnClock(center, reticuleCircleRadius - offset + width/2, -3),
						 colors.navigationalElements, 1)
	-- right hook
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + 6),
						 ui.pointOnClock(center, reticuleCircleRadius - offset - width, hrs + 6),
						 colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + 6),
						 ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + 6 - height_hrs),
						 colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, 3),
						 ui.pointOnClock(center, reticuleCircleRadius - offset + width/2, 3),
						 colors.navigationalElements, 1)



end

local function displayReticuleCompass(center, heading)
	local relevant = {}
	local directions = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW" }
	local function cl(x)
		if x < 0 then
			return cl(x + 360)
		elseif x >= 360 then
			return cl(x - 360)
		else
			return x
		end
	end
	local left = math.floor(heading - 45)
	local right = left + 90
	local d = left

	local function stroke(d, p, n, height, thickness)
		if d % n == 0 then
			local a = ui.pointOnClock(center, reticuleCircleRadius, 2.8 * p - 1.4)
			local b = ui.pointOnClock(center, reticuleCircleRadius + height, 2.8 * p - 1.4)
			ui.addLine(a, b, colors.reticuleCircle, thickness)
		end
	end

	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius, 0),
						 ui.pointOnClock(center, reticuleCircleRadius - 3, 0),
						 colors.reticuleCircle, 1)

	while true do
		if d > right then
			break
		end
		local p = (d - left) / 90
		stroke(d, p, 15, 3, 1)
		stroke(d, p, 45, 4, 1)
		stroke(d, p, 90, 4, 2)
		for k,v in pairs(directions) do
			if cl(k) == cl(d) then
				local a = ui.pointOnClock(center, reticuleCircleRadius + 8, 3 * p - 1.5)
				ui.addStyledText(a, v, colors.navigationalElements, ui.fonts.pionillium.small, ui.anchor.center, ui.anchor.bottom, "")
			end
		end
		d = d + 1
	end
end

local function displayReticuleDeltaV(center)
	-- ratio is 1.0 for full, 0.0 for empty
	local function deltav_gauge(ratio, center, radius, color, thickness)
		if ratio < 0 then
			ratio = 0
		end
		if ratio > 0 and ratio < 0.001 then
			ratio = 0.001
		end
		if ratio > 1 then
			ratio = 1
		end
		ui.pathArcTo(center, radius + thickness / 2, ui.pi_2 + ui.pi_4, ui.pi_2 + ui.pi_4 + ui.pi_2 * ratio, 64)
		ui.pathStroke(color, false, thickness)
	end

	local player = Game.player
	local offset = 3
	local thickness = 5
	
	local deltav_max = player:GetMaxDeltaV()
	local deltav_remaining = player:GetRemainingDeltaV()
	local dvr = deltav_remaining / deltav_max
	local deltav_maneuver = player:GetManeuverSpeed() or 0
	local dvm = deltav_maneuver / deltav_max
	local deltav_current = player:GetCurrentDeltaV()
	local dvc = deltav_current / deltav_max

	deltav_gauge(1.0, center, reticuleCircleRadius + offset, colors.deltaVTotal, thickness)
	if dvr > 0 then
	  deltav_gauge(dvr, center, reticuleCircleRadius + offset, colors.deltaVRemaining, thickness)
	end
	if dvm > 0 then
	  deltav_gauge(dvm, center, reticuleCircleRadius + offset + thickness / 4, colors.deltaVManeuver, thickness / 2)
	end
	if dvc > 0 then
	  deltav_gauge(dvc, center, reticuleCircleRadius + offset + thickness, colors.deltaVCurrent, thickness)
	end

end

local function displayReticule(center)
	local player = Game.player
	-- reticule circle
	ui.addCircle(center, reticuleCircleRadius, colors.reticuleCircle, ui.circleSegments(reticuleCircleRadius), reticuleCircleThickness)
	-- nav target
	local navTarget = player:GetNavTarget()
	if navTarget then
		local radius = reticuleCircleRadius + 10
		local uiPos = ui.pointOnClock(center, radius, 2)
		local velocity = player:GetVelocityRelTo(navTarget)
		local position = player:GetPositionRelTo(navTarget)

		-- label of target
		ui.addStyledText(uiPos, navTarget.label, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The current navigational target")

		-- current relative speed
		uiPos = ui.pointOnClock(center, radius, 2.5)
		local speed,unit = ui.Format.Speed(velocity:magnitude())
		ui.addStyledText(uiPos, speed .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The relative speed of the navigational target")

		-- current distance
		uiPos = ui.pointOnClock(center, radius, 3)
		local distance,unit = ui.Format.Distance(player:DistanceTo(navTarget))
		ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The distance to the navigational target")

		-- current brake distance
		uiPos = ui.pointOnClock(center, radius, 3.5)
		local distance,unit = ui.Format.Distance(player:GetDistanceToZeroV(velocity:magnitude(),"forward"))
		ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The braking distance using the forward thrusters.")

		-- current speed of approach
		uiPos = ui.pointOnClock(center, radius, 4)
		local proj = position:dot(velocity) / position:magnitude()
		local speed,unit = ui.Format.Speed(proj)
		ui.addStyledText(uiPos, speed .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.top, "The speed of approach of the navigational target")

		-- current altitude
		uiPos = ui.pointOnClock(center, radius, 4.5)
		local altitude = player:GetAltitudeRelTo(navTarget)
		if altitude then
			local distance,unit = ui.Format.Distance(altitude)
			ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.top, "The current altitude above the navigational target")
		end
	end
	-- heading, pitch and roll
	do
		if showNavigationalNumbers then
			local uiPos = ui.pointOnClock(center, reticuleCircleRadius - size * 2, 3)
			ui.addStyledText(uiPos, math.floor(pitch_degrees + 0.5) .. "°", colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.right, ui.anchor.center, "Current pitch")

			local uiPos = ui.pointOnClock(center, reticuleCircleRadius - size * 2, 0)
			ui.addStyledText(uiPos, math.floor(heading_degrees + 0.5) .. "°", colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.center, ui.anchor.top, "Current heading")

			local uiPos = ui.pointOnClock(center, reticuleCircleRadius, 6)
			ui.addStyledText(uiPos, math.floor(roll_degrees + 0.5) .. "°", colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.center, ui.anchor.top, "Current roll")
		end

		local heading, pitch, roll = player:GetHeadingPitchRoll("planet")
		local pitch_degrees = (pitch / ui.twoPi * 360)
		local heading_degrees = (heading / ui.twoPi * 360)
		local roll_degrees = (roll / ui.twoPi * 360);

		displayReticulePitch(center, pitch_degrees)
		displayReticuleHorizon(center, roll_degrees)
		displayReticuleCompass(center, heading_degrees)
		displayReticuleDeltaV(center)
	end
end

local function displayHyperspace()
	-- TODO implement :)
end

ui.registerHandler(
	'game',
	function(delta_t)
		ui.setNextWindowPos(Vector(0, 0), "Always")
		ui.setNextWindowSize(Vector(ui.screenWidth, ui.screenHeight), "Always")
		ui.withStyleColors({ ["WindowBg"] = colors.transparent }, function()
				ui.window("HUD", {"NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings", "NoFocusOnAppearing", "NoBringToFrontOnFocus"}, function()
										local center = Vector(ui.screenWidth / 2, ui.screenHeight / 2)
										if Game.CurrentView() == "world" then
											if Game.InHyperspace() then
												displayHyperspace()
											else
												displayReticule(center)
											end
										end
				end)
		end)
end)
