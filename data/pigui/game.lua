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


local function displayReticulePitch(center, pitch_degrees)
	local function pitchline(hrs, length, color, thickness)
		local a = ui.pointOnClock(center, reticuleCircleRadius - 1 - length, hrs)
		local b = ui.pointOnClock(center, reticuleCircleRadius - 1, hrs)
		ui.addLine(a, b, color, thickness)
	end
	local size = 2
	pitchline(3, size * 2, ui.theme.colors.reticuleCircle, 1)
	pitchline(2.25, size, ui.theme.colors.reticuleCircle, 1)
	pitchline(3.75, size, ui.theme.colors.reticuleCircle, 1)
	pitchline(1.5, size * 2, ui.theme.colors.reticuleCircle, 1)
	pitchline(4.5, size * 2, ui.theme.colors.reticuleCircle, 1)
	local xpitch = (pitch_degrees + 90) / 180
	local xpitch_h = 4.5 - xpitch * 3
	pitchline(xpitch_h, size * 3, ui.theme.colors.navigationalElements, 2)
end

local function displayReticuleHorizon(center, roll_degrees)
	local offset = 30
	local width = 10
	local height_hrs = 0.1
	local hrs = roll_degrees / 360 * 12 + 3
	-- left hook
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs),
						 ui.pointOnClock(center, reticuleCircleRadius - offset - width, hrs),
						 ui.theme.colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs),
						 ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + height_hrs),
						 ui.theme.colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, -3),
						 ui.pointOnClock(center, reticuleCircleRadius - offset + width/2, -3),
						 ui.theme.colors.navigationalElements, 1)
	-- right hook
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + 6),
						 ui.pointOnClock(center, reticuleCircleRadius - offset - width, hrs + 6),
						 ui.theme.colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + 6),
						 ui.pointOnClock(center, reticuleCircleRadius - offset, hrs + 6 - height_hrs),
						 ui.theme.colors.navigationalElements, 1)
	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius - offset, 3),
						 ui.pointOnClock(center, reticuleCircleRadius - offset + width/2, 3),
						 ui.theme.colors.navigationalElements, 1)



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
			ui.addLine(a, b, ui.theme.colors.reticuleCircle, thickness)
		end
	end

	ui.addLine(ui.pointOnClock(center, reticuleCircleRadius, 0),
						 ui.pointOnClock(center, reticuleCircleRadius - 3, 0),
						 ui.theme.colors.reticuleCircle, 1)

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
				ui.addStyledText(a, v, ui.theme.colors.navigationalElements, ui.fonts.pionillium.tiny, ui.anchor.center, ui.anchor.bottom, "")
			end
		end
		d = d + 1
	end
end

local function displayReticuleDeltaV(center)
	-- ratio is 1.0 for full, 0.0 for empty
	local function gauge(ratio, center, radius, color, thickness)
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

	gauge(1.0, center, reticuleCircleRadius + offset, ui.theme.colors.deltaVTotal, thickness)
	if dvr > 0 then
	  gauge(dvr, center, reticuleCircleRadius + offset, ui.theme.colors.deltaVRemaining, thickness)
	end
	if dvm > 0 then
	  gauge(dvm, center, reticuleCircleRadius + offset + thickness / 4, ui.theme.colors.deltaVManeuver, thickness / 2)
	end
	if dvc > 0 then
	  gauge(dvc, center, reticuleCircleRadius + offset + thickness, ui.theme.colors.deltaVCurrent, thickness)
	end

end

local brakeNowRatio = 0.90

local function displayReticuleBrakeGauge(center, ratio)
	local function gauge(ratio, center, radius, color, thickness)
		if ratio < 0 then
			ratio = 0
		end
		if ratio > 0 and ratio < 0.001 then
			ratio = 0.001
		end
		if ratio > 1 then
			ratio = 1
		end
		ui.pathArcTo(center, radius + thickness / 2, ui.pi_4, - ui.pi_4 + ui.pi_2 * (1 - ratio), 64)
		ui.pathStroke(color, false, thickness)
	end
	local thickness = 5
	local offset = 3

	if ratio <= 1 then
		gauge(1, center, reticuleCircleRadius + offset, ui.theme.colors.brakeBackground, thickness)
		local color
		if ratio > brakeNowRatio then
			color = ui.theme.colors.brakeNow
		else
			color = ui.theme.colors.brakeLight
		end
		gauge(ratio, center, reticuleCircleRadius + offset, color, thickness)
	else
		gauge(1, center, reticuleCircleRadius + offset, ui.theme.colors.brakeOvershoot, thickness)
		gauge(2 - math.min(ratio, 2), center, reticuleCircleRadius + offset, ui.theme.colors.brakeLight, thickness)
	end
end


local function displayDirectionalMarkers(center)
	local function displayDirectionalMarker(ship_space, icon, showDirection, angle)
		local screen = Engine.ShipSpaceToScreenSpace(ship_space)
		if screen.z <= 1 then
			ui.addIcon(screen, icon, ui.theme.colors.reticuleCircle, 32, ui.anchor.center, ui.anchor.center, nil, angle)
		end
		return showDirection and (screen - center):magnitude() > reticuleCircleRadius
	end
	local function angle(forward, adjust)
		if forward.z >= 1 then
			return forward:angle() + adjust - ui.pi
		else
			return forward:angle() + adjust
		end
  end
	local forward = Engine.ShipSpaceToScreenSpace(Vector(0,0,-1)) - center
	local showDirection = displayDirectionalMarker(Vector(0,0,-1), ui.theme.icons.forward, true)
	showDirection = displayDirectionalMarker(Vector(0,0,1), ui.theme.icons.backward, showDirection)
	showDirection = displayDirectionalMarker(Vector(0,1,0), ui.theme.icons.up, showDirection, angle(forward, ui.pi))
	showDirection = displayDirectionalMarker(Vector(0,-1,0), ui.theme.icons.down, showDirection, angle(forward, 0))
	showDirection = displayDirectionalMarker(Vector(1,0,0), ui.theme.icons.right, showDirection)
	showDirection = displayDirectionalMarker(Vector(-1,0,0), ui.theme.icons.left, showDirection)

	if showDirection then
		ui.addIcon(center, ui.theme.icons.direction_forward, ui.theme.colors.reticuleCircle, 32, ui.anchor.center, ui.anchor.center, nil, angle(forward, 0))
	end
	
end

local reticuleTarget = "frame"

local lastNavTarget = nil
local lastCombatTarget = nil

local function displayReticule(center)
	local player = Game.player
	-- reticule circle
	ui.addCircle(center, reticuleCircleRadius, ui.theme.colors.reticuleCircle, ui.circleSegments(reticuleCircleRadius), reticuleCircleThickness)
	-- nav target
	local target, colorLight, colorDark, frameColor, navTargetColor, combatTargetColor
	local frame = player.frameBody
	local navTarget = player:GetNavTarget()
	local combatTarget = player:GetCombatTarget()

	if lastNavTarget ~= navTarget then
		reticuleTarget = "navTarget"
	end
	lastNavTarget = navTarget
	if lastCombatTarget ~= combatTarget then
		reticuleTarget = "combatTarget"
	end
	lastCombatTarget = combatTarget
	if reticuleTarget == "frame" then
		target = frame
		colorLight = ui.theme.colors.frame
		colorDark = ui.theme.colors.frameDark
		frameColor = ui.theme.colors.reticuleCircle
		navTargetColor = ui.theme.colors.reticuleCircleDark
		combatTargetColor = ui.theme.colors.reticuleCircleDark
	elseif reticuleTarget == "navTarget" then
		target = navTarget
		colorLight = ui.theme.colors.navTarget
		colorDark = ui.theme.colors.navTargetDark
		frameColor = ui.theme.colors.reticuleCircleDark
		navTargetColor = ui.theme.colors.reticuleCircle
		combatTargetColor = ui.theme.colors.reticuleCircleDark
	elseif reticuleTarget == "combatTarget" then
		target = player:GetCombatTarget()
		colorLight = ui.theme.colors.combatTarget
		colorDark = ui.theme.colors.combatTargetDark
		frameColor = ui.theme.colors.reticuleCircleDark
		navTargetColor = ui.theme.colors.reticuleCircleDark
		combatTargetColor = ui.theme.colors.reticuleCircle
	end

	local radius = reticuleCircleRadius * 1.2
	if reticuleTarget ~= "frame" and frame then
		local velocity = player:GetVelocityRelTo(frame)
		local position = player:GetPositionRelTo(frame)
		local altitude = player:GetAltitudeRelTo(frame)
		local altitude, altitude_unit = ui.Format.Distance(altitude)
		local approach_speed = position:dot(velocity) / position:magnitude()
		local speed, speed_unit = ui.Format.Speed(approach_speed)

		
		local uiPos = ui.pointOnClock(center, radius, -2)
		-- label of frame
		ui.addStyledText(uiPos, frame.label, ui.theme.colors.frame, ui.fonts.pionillium.medium, ui.anchor.right, ui.anchor.baseline, "The current frame")

		-- altitude above frame
		uiPos = ui.pointOnClock(center, radius, -3)
		ui.addFancyText(uiPos,
										{ altitude, altitude_unit },
										{ ui.theme.colors.frame, ui.theme.colors.frameDark },
										{ ui.fonts.pionillium.medium, ui.fonts.pionillium.small },
										ui.anchor.right, ui.anchor.baseline,
										{ "The altitude above the frame", "The altitude above the frame" })

		-- speed of approach of frame
		uiPos = ui.pointOnClock(center, radius, -2.5)
		ui.addFancyText(uiPos,
										{ speed, speed_unit },
										{ ui.theme.colors.frame, ui.theme.colors.frameDark },
										{ ui.fonts.pionillium.medium, ui.fonts.pionillium.small },
										ui.anchor.right, ui.anchor.baseline,
										{ "The speed of approach towards the frame", "The speed of approach towards the frame" })
	end
	if navTarget then
		local onscreen,position,direction = navTarget:GetProjectedScreenPosition()
		local dir = direction * reticuleCircleRadius * 0.90
		local indicator = center + dir
		if onscreen then
			ui.addIcon(position, ui.theme.icons.square, ui.theme.colors.navTarget, 48, ui.anchor.center, ui.anchor.center)
		end
		if (position - indicator):magnitude() > reticuleCircleRadius then
			ui.addIcon(indicator, ui.theme.icons.square, ui.theme.colors.navTarget, 12, ui.anchor.center, ui.anchor.center)
		end
	end
	if target then
		local velocity = player:GetVelocityRelTo(target)
		local position = player:GetPositionRelTo(target)

		local uiPos = ui.pointOnClock(center, radius, 2)
		-- label of target
		ui.addStyledText(uiPos, target.label, colorDark, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.baseline, "The current navigational target")

		-- current distance, relative speed
		uiPos = ui.pointOnClock(center, radius, 2.5)
		local distance, distance_unit = ui.Format.Distance(player:DistanceTo(target))
		local approach_speed = position:dot(velocity) / position:magnitude()
		local speed, speed_unit = ui.Format.Speed(approach_speed)

		ui.addFancyText(uiPos,
										{ speed, speed_unit }, -- distance, distance_unit, " " .. 
										{ colorLight, colorDark }, -- colorLight, colorDark, 
										{ ui.fonts.pionillium.medium, ui.fonts.pionillium.small }, -- ui.fonts.pionillium.medium, ui.fonts.pionillium.small, 
										ui.anchor.left, ui.anchor.baseline,
										{ "The speed relative to the navigational target", "The speed relative to the navigational target" }) -- "The distance to the navigational target", "The distance to the navigational target", 

		-- current brake distance
		local brake_distance = player:GetDistanceToZeroV(velocity:magnitude(),"forward")
		local altitude = player:GetAltitudeRelTo(target)
		local ratio = brake_distance / altitude
		local speed, speed_unit = ui.Format.Speed(velocity:magnitude())

		local ratio_text = math.floor(ratio * 100) .. "%"
		if ratio > 2 then
			ratio_text = ">200%"
		end
		-- speed
		uiPos = ui.pointOnClock(center, radius, 3.5)
		local distance,unit = ui.Format.Distance(brake_distance)
		ui.addFancyText(uiPos,
										{ "~" .. distance, unit, approach_speed < 0 and "  " .. ratio_text or "" },
										{ colorDark, colorDark, colorDark },
										{ ui.fonts.pionillium.medium, ui.fonts.pionillium.small, ui.fonts.pionillium.medium },
										ui.anchor.left, ui.anchor.baseline,
										{ "The braking distance using the main thrusters.", "The braking distance using the main thrusters.", "The percentage of brake distance vs. altitude." })
		-- current altitude
		uiPos = ui.pointOnClock(center, radius, 3)
		local altitude, altitude_unit = ui.Format.Distance(altitude)
		ui.addFancyText(uiPos,
										{ altitude, altitude_unit, " " .. speed, speed_unit },
										{ colorLight, colorDark, colorLight, colorDark },
										{ ui.fonts.pionillium.medium, ui.fonts.pionillium.small, ui.fonts.pionillium.medium, ui.fonts.pionillium.small },
										ui.anchor.left, ui.anchor.baseline,
										{ "The altitude above the navigational target", "The altitude above the navigational target", "The speed of approach of the navigational target", "The speed of approach of the navigational target" })
		-- current speed of approach
		if approach_speed < 0 then
			displayReticuleBrakeGauge(center, ratio)
		end

	end
	-- frame / target switch buttons
	local uiPos = ui.pointOnClock(center, radius, 4.2)
	local mouse_position = ui.getMousePos()
	local size = 24
	ui.addIcon(uiPos, ui.theme.icons.moon, frameColor, size, ui.anchor.left, ui.anchor.bottom, "Show frame")
	if ui.isMouseClicked(0) and (mouse_position - (uiPos + Vector(size/2, -size/2))):magnitude() < size/2 then
		reticuleTarget = "frame"
	end
	uiPos = uiPos + Vector(size,0)
	ui.addIcon(uiPos, ui.theme.icons.forward, navTargetColor, size, ui.anchor.left, ui.anchor.bottom, "Show nav target")
	if ui.isMouseClicked(0) and (mouse_position - (uiPos + Vector(size/2, -size/2))):magnitude() < size/2 then
		reticuleTarget = "navTarget"
	end
	uiPos = uiPos + Vector(size,0)
	ui.addIcon(uiPos, ui.theme.icons.ship, combatTargetColor, size, ui.anchor.left, ui.anchor.bottom, "Show combat target")
	if ui.isMouseClicked(0) and (mouse_position - (uiPos + Vector(size/2, -size/2))):magnitude() < size/2 then
		reticuleTarget = "combatTarget"
	end

	-- heading, pitch and roll
	do
		if showNavigationalNumbers then
			local uiPos = ui.pointOnClock(center, reticuleCircleRadius - size * 2, 3)
			ui.addStyledText(uiPos, math.floor(pitch_degrees + 0.5) .. "°", ui.theme.colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.right, ui.anchor.center, "Current pitch")

			local uiPos = ui.pointOnClock(center, reticuleCircleRadius - size * 2, 0)
			ui.addStyledText(uiPos, math.floor(heading_degrees + 0.5) .. "°", ui.theme.colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.center, ui.anchor.top, "Current heading")

			local uiPos = ui.pointOnClock(center, reticuleCircleRadius, 6)
			ui.addStyledText(uiPos, math.floor(roll_degrees + 0.5) .. "°", ui.theme.colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.center, ui.anchor.top, "Current roll")
		end

		local heading, pitch, roll = player:GetHeadingPitchRoll("planet")
		local pitch_degrees = (pitch / ui.twoPi * 360)
		local heading_degrees = (heading / ui.twoPi * 360)
		local roll_degrees = (roll / ui.twoPi * 360);

		displayReticulePitch(center, pitch_degrees)
		displayReticuleHorizon(center, roll_degrees)
		displayReticuleCompass(center, heading_degrees)
		displayReticuleDeltaV(center)

		displayDirectionalMarkers(center)
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
		ui.withStyleColors({ ["WindowBg"] = ui.theme.colors.transparent }, function()
				ui.window("HUD", {"NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings", "NoFocusOnAppearing", "NoBringToFrontOnFocus"}, function()
										local center = Vector(ui.screenWidth / 2, ui.screenHeight / 2)
										if Game.CurrentView() == "world" and ui.shouldDrawUI() then
											if Game.InHyperspace() then
												displayHyperspace()
											else
												displayReticule(center)
											end
										end
				end)
		end)
end)
