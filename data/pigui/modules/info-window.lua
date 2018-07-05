-- Copyright © 2008-2018 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Engine = import('Engine')
local Game = import('Game')
local Vector = import('Vector')
local Format = import('Format')
local ui = import('pigui/pigui.lua')
local utils = import('utils')

local colors = ui.theme.colors

local function showInfoWindow()
	ui.setNextWindowSize(Vector(ui.screenWidth / 4, ui.screenHeight / 4) , "Always")
	ui.setNextWindowPos(Vector(ui.screenWidth - (ui.screenWidth / 4) - 10 , 10) , "Always")
	ui.withStyleColors({ ["WindowBg"] = colors.commsWindowBackground }, function()
			ui.withStyleVars({ ["WindowRounding"] = 0.0 }, function()
					ui.window("TargetInfoWindow", {"NoResize", "NoFocusOnAppearing", "NoBringToFrontOnFocus"},
						function()
							local target = Game.player:GetNavTarget()
							if target then
								local sb = target:GetSystemBody()
								local parent = nil
								local psb = nil
								if sb then
									parent = sb.parent
								end
								ui.text(target.label)
								if target:IsMoon() or target:IsPlanet() or target:IsSpaceStation() then
									ui.text("Orbiting")
									ui.sameLine()
									ui.textColored(colors.navTarget, parent.name)
									if ui.isItemClicked(0) then
										Game.player:SetNavTarget(parent.body)
									end
									ui.sameLine()
									ui.text("at a mean distance of " .. Format.Distance((sb.periapsis + sb.apoapsis) / 2 - parent.radius))
								elseif target:IsGroundStation() then
									ui.text("On the surface of")
									ui.sameLine()
									ui.textColored(colors.navTarget, parent.name)
									if ui.isItemClicked(0) then
										Game.player:SetNavTarget(parent.body)
									end
								end
								local children = sb.children
								local on_surface = {}
								local in_orbit = {}
								for _,csb in pairs(children) do
									if csb.body:IsSpaceStation() or csb.body:IsPlanet() or csb.body:IsMoon() then
										table.insert(in_orbit, csb)
									end
									if csb.body:IsGroundStation() then
										table.insert(on_surface, csb)
									end
								end

								if in_orbit and next(in_orbit) ~= nil then
									ui.text(target.label .. " is orbited by")
									for _,csb in pairs(in_orbit) do
										ui.text(" -")
										ui.sameLine()
										ui.textColored(colors.navTarget, csb.name)
										if ui.isItemClicked(0) then
											Game.player:SetNavTarget(csb.body)
										end
									end
								else
									if not target:IsStation() then
										ui.text("Nothing orbits this.")
									end
								end
								if on_surface and next(on_surface) ~= nil then
									ui.text("On " .. target.label .. "'s surface")
									for _,csb in pairs(on_surface) do
										ui.text(" -")
										ui.sameLine()
										ui.textColored(colors.navTarget, csb.name)
										if ui.isItemClicked(0) then
											Game.player:SetNavTarget(csb.body)
										end
									end
								else
									if not target:IsStation() then
										ui.text("The surface is empty.")
									end
								end
							end
					end)
			end)
	end)
end

ui.registerModule("game", showInfoWindow)

return {}

