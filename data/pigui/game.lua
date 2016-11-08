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

local colors = {
	reticuleCircle = Color(200, 200, 200),
	transparent = Color(0, 0, 0, 0),
	navTarget = Color(0, 255, 0),
	frame = Color(200, 200, 200),
}

ui.registerHandler(
	'game',
	function(delta_t)
		local player = Game.player
		ui.setNextWindowPos(Vector(0, 0), "Always")
		ui.setNextWindowSize(Vector(ui.screenWidth, ui.screenHeight), "Always")
		ui.withStyleColors({ ["WindowBg"] = colors.transparent }, function()
				ui.window("HUD", {"NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings", "NoFocusOnAppearing", "NoBringToFrontOnFocus"}, function()
										local center = Vector(ui.screenWidth / 2, ui.screenHeight / 2)
										-- reticule circle
										ui.addCircle(center, reticuleCircleRadius, colors.reticuleCircle, ui.circleSegments(reticuleCircleRadius), reticuleCircleThickness)
										-- nav target
										local navTarget = player:GetNavTarget()
										if navTarget then
											local uiPos = ui.pointOnClock(center, reticuleCircleRadius, 1.35)
											local velocity = player:GetVelocityRelTo(navTarget)
											local position = player:GetPositionRelTo(navTarget)

											-- label of target
											ui.addStyledText(uiPos, navTarget.label, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The current navigational target")

											-- current relative speed
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 2)
											local speed,unit = ui.Format.Speed(velocity:magnitude())
											ui.addStyledText(uiPos, speed .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The relative speed of the navigational target")

											-- current distance
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 2.5)
                      local distance,unit = ui.Format.Distance(player:DistanceTo(navTarget))
											ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The distance to the navigational target")

											-- current brake distance
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 3)
                      local distance,unit = ui.Format.Distance(player:GetDistanceToZeroV(velocity:magnitude(),"forward"))
											ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The braking distance using the forward thrusters.")

											-- current speed of approach
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 4)
											local proj = position:dot(velocity) / position:magnitude()
											local speed,unit = ui.Format.Speed(proj)
											ui.addStyledText(uiPos, speed .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.top, "The speed of approach of the navigational target")

											-- current altitude
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 4.5)
											local altitude = player:GetAltitudeRelTo(navTarget)
											if altitude then
												local distance,unit = ui.Format.Distance(altitude)
												ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.top, "The current altitude above the navigational target")
											end
										end
										-- pitch
										do
											local function pitchline(hrs, length, color, thickness)
												local a = ui.pointOnClock(center, reticuleCircleRadius - 1 - length, hrs)
												local b = ui.pointOnClock(center, reticuleCircleRadius - 1, hrs)
												ui.addLine(a, b, color, thickness)
											end
											local size = 3
											pitchline(3, size * 2, colors.reticuleCircle, 1)
											pitchline(2.25, size, colors.reticuleCircle, 1)
											pitchline(3.75, size, colors.reticuleCircle, 1)
											pitchline(1.5, size * 2, colors.reticuleCircle, 1)
											pitchline(4.5, size * 2, colors.reticuleCircle, 1)
											local heading, pitch = player:GetHeadingPitch("planet")
											local xpitch = ((pitch / ui.twoPi * 360) + 90) / 180
											local xpitch_h = 4.5 - xpitch * 3
											pitchline(xpitch_h, size * 2, colors.reticuleCircle, 2)

											local uiPos = ui.pointOnClock(center, reticuleCircleRadius - size * 2, 3)
											ui.addStyledText(uiPos, pitch .. "°", colors.reticuleCircle, ui.fonts.pionillium.small, ui.anchor.right, ui.anchor.center, "Current pitch")
										end
				end)
		end)
end)
