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

											-- current speed of approach
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 2.5)
											local proj = position:dot(velocity) / position:magnitude()
											local speed,unit = ui.Format.Speed(proj)
											ui.addStyledText(uiPos, speed .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The speed of approach of the navigational target")
											
											-- current distance
											uiPos = ui.pointOnClock(center, reticuleCircleRadius, 3)
                      local distance,unit = ui.Format.Distance(player:DistanceTo(navTarget))
											ui.addStyledText(uiPos, distance .. "" .. unit, colors.navTarget, ui.fonts.pionillium.medium, ui.anchor.left, ui.anchor.bottom, "The distance to the navigational target")

											
										end
				end)
		end)
end)
