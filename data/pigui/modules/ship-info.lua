-- Copyright © 2008-2018 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Engine = import('Engine')
local Game = import('Game')
local Equipment = import("Equipment")
local Character = import("Character")
local ui = import('pigui/pigui.lua')
local Vector = import('Vector')
local Color = import('Color')
local Lang = import("Lang")
local lc = Lang.GetResource("core");
local lui = Lang.GetResource("ui-core");
local utils = import("utils")
local Event = import("Event")

local player = nil
local colors = ui.theme.colors
local icons = ui.theme.icons


local ShipDef = import("ShipDef")
local l = Lang.GetResource("ui-core");

local yes_no = function (binary)
	if binary == 1 then
		return l.YES
	elseif binary == 0 then
		return l.NO
	else error("argument to yes_no not 0 or 1")
	end
end

local show_item = function (label,value)
	ui.text(label); ui.nextColumn()
	ui.text(value); ui.nextColumn()
end
local large_text = function(text)
		ui.withFont(ui.fonts.pionillium.large, function()
								ui.text(text)
	end)
end
local showShipInfo = function()
	local shipDef     =    ShipDef[player.shipId]
	local shipLabel   =    player:GetLabel()
	local hyperdrive  =    table.unpack(player:GetEquip("engine"))
	local frontWeapon =    table.unpack(player:GetEquip("laser_front"))
	local rearWeapon  =    table.unpack(player:GetEquip("laser_rear"))

	hyperdrive =  hyperdrive  or nil
	frontWeapon = frontWeapon or nil
	rearWeapon =  rearWeapon  or nil

	-- local shipNameEntry = ui:TextEntry(player.shipName):SetFont("HEADING_SMALL")
	-- shipNameEntry.onChange:Connect(function (newName)
	-- 	player:SetShipName(newName)
	-- end )

	local mass_with_fuel = player.staticMass + player.fuelMassLeft
	local mass_with_fuel_kg = 1000 * mass_with_fuel

	-- ship stats mass is in tonnes; scale by 1000 to convert to kg
	local fwd_acc = -shipDef.linearThrust.FORWARD / mass_with_fuel_kg
	local bwd_acc = shipDef.linearThrust.REVERSE / mass_with_fuel_kg
	local up_acc = shipDef.linearThrust.UP / mass_with_fuel_kg

	-- delta-v calculation according to http://en.wikipedia.org/wiki/Tsiolkovsky_rocket_equation
	local deltav = shipDef.effectiveExhaustVelocity * math.log((player.staticMass + player.fuelMassLeft) / player.staticMass)

	local equipItems = {}
	local equips = {Equipment.cargo, Equipment.misc, Equipment.hyperspace, Equipment.laser}
	for _,t in pairs(equips) do
		for k,et in pairs(t) do
			local slot = et:GetDefaultSlot(player)
			if (slot ~= "cargo" and slot ~= "missile" and slot ~= "engine" and slot ~= "laser_front" and slot ~= "laser_rear") then
				local count = player:CountEquip(et)
				if count > 0 then
					if count > 1 then
						if et == Equipment.misc.shield_generator then
							table.insert(equipItems,
													 string.interp(l.N_SHIELD_GENERATORS, { quantity = string.format("%d", count) }))
						elseif et == Equipment.misc.cabin_occupied then
							table.insert(equipItems,
													 string.interp(l.N_OCCUPIED_PASSENGER_CABINS, { quantity = string.format("%d", count) }))
						elseif et == Equipment.misc.cabin then
							table.insert(equipItems,
													 string.interp(l.N_UNOCCUPIED_PASSENGER_CABINS, { quantity = string.format("%d", count) }))
						else
							table.insert(equipItems, et:GetName())
						end
					else
						table.insert(equipItems, et:GetName())
					end
				end
			end
		end
	end

	ui.columns(2, "shipInfoColumns", true)
	show_item(l.REGISTRATION_NUMBER, shipLabel)
	show_item(l.HYPERDRIVE, hyperdrive and hyperdrive:GetName() or l.NONE)
	local range = string.interp(
		l.N_LIGHT_YEARS_N_MAX, {
			range    = string.format("%.1f",player.hyperspaceRange),
			maxRange = string.format("%.1f",player.maxHyperspaceRange)
													 }
	);
	show_item(l.HYPERSPACE_RANGE, range)
	ui.separator()
	show_item(l.WEIGHT_EMPTY, string.format("%dt", player.staticMass - player.usedCapacity))
	show_item(l.CAPACITY_USED, string.format("%dt (%dt "..l.FREE..")", player.usedCapacity,  player.freeCapacity))
	show_item(l.CARGO_SPACE, string.format("%dt (%dt "..l.MAX..")", player.totalCargo, shipDef.equipSlotCapacity.cargo))
	show_item(l.CARGO_SPACE_USED, string.format("%dt (%dt "..l.FREE..")", player.usedCargo, player.totalCargo - player.usedCargo))
	show_item(l.FUEL_WEIGHT,   string.format("%dt (%dt "..l.MAX..")", player.fuelMassLeft, shipDef.fuelTankMass ))
	show_item(l.ALL_UP_WEIGHT, string.format("%dt", mass_with_fuel ))
	ui.separator()
	show_item(l.FRONT_WEAPON, frontWeapon and frontWeapon:GetName() or l.NONE)
	show_item(l.REAR_WEAPON,  rearWeapon and rearWeapon:GetName() or l.NONE)
	show_item(l.FUEL,         string.format("%d%%", player.fuel))
	show_item(l.DELTA_V,      string.format("%d km/s", deltav / 1000))
	ui.separator()
	show_item(l.FORWARD_ACCEL,  string.format("%.2f m/s² (%.1f G)", fwd_acc, fwd_acc / 9.81))
	show_item(l.BACKWARD_ACCEL, string.format("%.2f m/s² (%.1f G)", bwd_acc, bwd_acc / 9.81))
	show_item(l.UP_ACCEL,       string.format("%.2f m/s² (%.1f G)", up_acc, up_acc / 9.81))
	ui.separator()
	show_item(l.MINIMUM_CREW, shipDef.minCrew)
	show_item(l.CREW_CABINS,  shipDef.maxCrew)
	ui.separator()
	show_item(l.MISSILE_MOUNTS,            shipDef.equipSlotCapacity.missile)
	show_item(l.ATMOSPHERIC_SHIELDING,     yes_no(shipDef.equipSlotCapacity.atmo_shield))
	show_item(l.SCOOP_MOUNTS,              shipDef.equipSlotCapacity.scoop)
	ui.separator()
	ui.columns(1, "foo", false)
	large_text(l.EQUIPMENT)
	for k,e in pairs(equipItems) do
		ui.text(e)
	end
end
local showPersonalInfo = function ()
	local player = Character.persistent.player
	large_text(l.COMBAT)
	ui.columns(2, "COL1", true)
	show_item(l.RATING, l[player:GetCombatRating()])
	show_item(l.KILLS, string.format('%d',player.killcount))
	ui.columns(1, "", false)
	large_text(l.REPUTATION)
	ui.columns(2, "COL2", true)
	show_item(l.STATUS, l[player:GetReputationRating()])
	ui.columns(1, "", false)
	large_text(l.MILITARY)
	ui.columns(2, "COL3", true)
	show_item(l.ALLEGIANCE, l.NONE) -- TODO
	show_item(l.RANK, l.NONE) -- TODO
end
local buttonSize = Vector(32,32)
local framePadding = 3
local show_tab = "shipinfo"
local displayInfoWindow = function ()
	local font = ui.fonts.pionillium.medium;
	player = Game.player
	ui.withFont(font.name, font.size, function()
								ui.withStyleColors({ ["WindowBg"] = colors.commsWindowBackground }, function()
										ui.withStyleVars({ ["WindowRounding"] = 0.0 }, function()
												ui.setNextWindowSize(Vector(ui.screenWidth / 5, ui.screenHeight / 1.5) , "Always")
												ui.window("ShipInfo", {"NoCollapse","NoTitleBar"},
																	function()
																		if(ui.coloredSelectedIconButton(icons.info, buttonSize, show_tab == 'shipinfo', framePadding, colors.buttonBlue, colors.white, "Ship Info")) then
																			show_tab='shipinfo'
																		end
																		ui.sameLine()
																		if(ui.coloredSelectedIconButton(icons.personal_info, buttonSize, show_tab == 'personalinfo', framePadding, colors.buttonBlue, colors.white, "Personal Info")) then
																			show_tab='personalinfo'
																		end
																		if(show_tab == 'shipinfo') then
																			showShipInfo()
																		end
																		if(show_tab == 'personalinfo') then
																			showPersonalInfo()
																		end

												end)
										end)
								end)
	end)
end

ui.registerModule("game", displayInfoWindow)

return {}
