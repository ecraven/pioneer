-- Copyright © 2008-2018 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Engine = import('Engine')
local Game = import('Game')
local Space = import('Space')
local Vector = import('Vector')
local ui = import('pigui/pigui.lua')
local utils = import('utils')
local Lang = import("Lang")
local lui = Lang.GetResource("ui-core");

local colors = ui.theme.colors
local icons = ui.theme.icons

local width_fraction = 5
local height_fraction = 5
local function showOrbitInfoWindow()
	ui.setNextWindowSize(Vector(ui.screenWidth / width_fraction, ui.screenHeight / height_fraction) , "Always")
	ui.setNextWindowPos(Vector(ui.screenWidth - (ui.screenWidth / width_fraction) - 10 , 10) , "Always")
	ui.window("OrbitInfo", {"NoTitleBar", "NoResize", "NoFocusOnAppearing", "NoBringToFrontOnFocus"},
						function()
							local orbit = Game.player:GetOrbit()
							local frame = Game.player.frameBody
							if orbit then
								local radius = frame:GetPhysicalRadius()
								local apoapsis = orbit.apoapsis:magnitude()
								local periapsis = orbit.periapsis:magnitude()
								local aa = orbit.apoapsis
								local pa = orbit.periapsis
								local xa = aa - pa
								ui.text("Relative to " .. frame.label)
								if apoapsis > 0 then
									local raa = apoapsis - radius
									local color = raa < 0 and colors.red or colors.white
									ui.textColored(color, "Apo " .. ui.Format.Distance(apoapsis, true) .. "(" .. ui.Format.Distance(raa, true) .. ")")
									color = orbit.apoapsisTime < orbit.periapsisTime and colors.green or colors.red
									ui.textColored(color, "ApT " .. ui.Format.Duration(orbit.apoapsisTime))
								end
								local rpa = periapsis - radius
								local color = rpa < 0 and colors.red or colors.white
								ui.textColored(color, "Per " .. ui.Format.Distance(periapsis, true) .. "(" .. ui.Format.Distance(periapsis - radius, true) .. ")")
								color = (orbit.periapsisTime < 0 or orbit.periapsisTime > orbit.apoapsisTime) and colors.red or colors.green
								ui.textColored(color, "PeT " .. ui.Format.Duration(orbit.periapsisTime))
								ui.text("Ecc " .. string.format("%.3f", orbit.eccentricity))
							else
								ui.text("Not orbiting anything.")
							end
	end)
end

ui.registerModule("game", showOrbitInfoWindow)

return {}
