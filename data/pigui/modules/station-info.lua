-- Copyright © 2008-2018 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Engine = import('Engine')
local Game = import('Game')
local Equipment = import("Equipment")
local Character = import("Character")
local SpaceStation = import("SpaceStation")
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

local show_item = function (label,value)
	ui.text(label); ui.nextColumn()
	ui.text(value); ui.nextColumn()
end

local large_text = function(text)
	ui.withFont(ui.fonts.pionillium.large, function()
								ui.text(text)
	end)
end

local showLobby = function ()
	large_text(l.LOBBY)
end

local showBBS = function ()
	large_text(l.BULLETIN_BOARD)
	local station = Game.player:GetDockedWith()
	if not station then return end
	local adverts = SpaceStation.adverts[station]
	if not adverts then return end
	local iconsize = Vector(16,16)
	for ref,ad in pairs(adverts) do
		local icon = ad.icon or 'default'
		local label = ad.description
		local enabled = type(ad.isEnabled) == "function" and ad.isEnabled(ref)
		local color = enabled and colors.white or colors.grey
		ui.icon(icons['mission_' .. icon], iconsize, color); ui.sameLine()
		ui.withStyleColors({ ["Text"] = color }, function()
				if enabled then
					ui.selectable(label)
				else
					ui.text(label)
				end
		end)
	end
end

local showCommodityMarket = function ()
	large_text(l.COMMODITY_MARKET)
	local station = player:GetDockedWith()
	if not station then return end
	local items = {}
	for k,e in pairs(Equipment.cargo) do
		-- if its purchasable, a cargo type equipment and a legal commodity in this system then we can list it in the commodity market
		if e.purchasable and e:IsValidSlot("cargo") and Game.system:IsCommodityLegal(e) then
			-- its ok, put it in the list
			table.insert(items, { name = e:GetName(),
														description = e:GetDescription(),
														price = station:GetEquipmentPrice(e),
														stock = station:GetEquipmentStock(e),
														cargo = player:CountEquip(e) })
		end
	end

	table.sort(items, function(e1,e2)
							 return e1.name < e2.name        -- cargo sorted on translated name
	end)
	ui.columns(4,"foo",true)
	for k,e in pairs(items) do
		ui.text(e.name)
		ui.nextColumn()
		ui.text(ui.Format.Money(e.price, true))
		ui.nextColumn()
		ui.text(e.stock)
		ui.nextColumn()
		if(e.cargo > 0) then
			ui.text(e.cargo)
		end
		ui.nextColumn()
	end
end
local sort_by = "name"
local asc = true
local showShipMarket = function ()
	local header = function(name, key)
		if ui.selectable(name, sort_by == key, {}) then
			if sort_by == key then
				asc = not asc
			else
				sort_by = key
				asc = true
			end
		end
	end
	large_text(l.SHIP_MARKET)
	local station = Game.player:GetDockedWith()
	if not station then return end
	local shipsOnSale = station:GetShipsOnSale()
	local iconsize = Vector(24,24)
	ui.columns(3, "ships", true)
	header("Name","name")
	ui.nextColumn()
	header("Price", "price")
	ui.nextColumn()
	header("Capacity", "capacity")
	ui.nextColumn()
	ui.separator()
	local ships = {}
	for i = 1,#shipsOnSale do
		local sos = shipsOnSale[i]
		local def = sos.def
		table.insert(ships, { icon = icons[def.shipClass] or icons.ship, name = def.name, price = def.basePrice, capacity = def.capacity } )
	end
	table.sort(ships, function(a,b)
							 if asc then
								 return a[sort_by] < b[sort_by]
							 else
								 return a[sort_by] > b[sort_by]
							 end
	end)
	for k,ship in pairs(ships) do
		ui.icon(ship.icon, iconsize, colors.white); ui.sameLine()
		if ui.selectable(ship.name, false, { "SpanAllColumns" }) then
			print("clicked on " .. ship.name)
		end
		ui.nextColumn()
		ui.text(ui.Format.Money(ship.price, false))
		ui.nextColumn()
		ui.text(ui.Format.Capacity(ship.capacity))
		ui.nextColumn()
	end
end

local hasTech = function (e)
	local station = Game.player:GetDockedWith()
	local equip_tech_level = e.tech_level or 1 -- default to 1

	if type(equip_tech_level) == "string" then
		if equip_tech_level == "MILITARY" then
			return station.techLevel == 11
		else
			error("Unknown tech level:\t"..equip_tech_level)
		end
	end

	assert(type(equip_tech_level) == "number")
	return station.techLevel >= equip_tech_level
end

local canTrade = function(e)
	return e.purchasable and hasTech(e) and not e:IsValidSlot("cargo", Game.player)
end

local showEquipmentMarket = function ()
	large_text(l.EQUIPMENT_MARKET)
	local station = Game.player:GetDockedWith()
	if not station then return end
	local stationEquipment = {}
	local shipEquipment = {}
	local sellPriceReduction = 0.8
	for _,t in pairs({Equipment.cargo, Equipment.misc, Equipment.laser, Equipment.hyperspace}) do
		for k,e in pairs(t) do
			if canTrade(e) then
				local basePrice = station:GetEquipmentPrice(e)
				table.insert(stationEquipment, { stock = station:GetEquipmentStock(e),
																	buy_price = basePrice,
																	sell_price = basePrice * (basePrice > 0 and sellPriceReduction or 1.0/sellPriceReduction),
																	name = e:GetName(),
																	mass = e.capabilities.mass
				})
			end
		end
	end
	for _,t in pairs({Equipment.cargo, Equipment.misc, Equipment.laser, Equipment.hyperspace}) do
		for k,e in pairs(t) do
			if player:CountEquip(e) > 0 and canTrade(e) then
				local basePrice = station:GetEquipmentPrice(e)
				table.insert(shipEquipment, { stock = station:GetEquipmentStock(e),
																	sell_price = basePrice * (basePrice > 0 and sellPriceReduction or 1.0/sellPriceReduction),
																	name = e:GetName(),
																	mass = e.capabilities.mass,
																	total_mass = e.capabilities.mass * Game.player:CountEquip(e)
				})
			end
		end
	end
	ui.columns(5, "foo", true)
	for k,e in pairs(stationEquipment) do
		ui.text(e.name)
		ui.nextColumn()
		ui.text(ui.Format.Money(e.buy_price, true))
		ui.nextColumn()
		ui.text(ui.Format.Money(e.sell_price, true))
		ui.nextColumn()
		ui.text(e.stock)
		ui.nextColumn()
		ui.text(ui.Format.Mass(e.mass))
		ui.nextColumn()
	end
	ui.columns(4, "bar", true)
	for k,e in pairs(shipEquipment) do
		ui.text(e.name)
		ui.nextColumn()
		ui.text(e.sell_price and ui.Format.Money(e.sell_price, true) or "--")
		ui.nextColumn()
		ui.text(ui.Format.Mass(e.mass))
		ui.nextColumn()
		ui.text(ui.Format.Mass(e.total_mass))
		ui.nextColumn()
	end
end

local showShipRepairs = function ()
	large_text(l.SHIP_REPAIRS)
end

local showPolice = function ()
	large_text(l.POLICE)
end

local buttonSize = Vector(32,32)
local framePadding = 3
local show_tab = 1

local displayInfoWindow = function ()
	local font = ui.fonts.pionillium.medium;
	player = Game.player
	ui.withFont(font.name, font.size, function()
								ui.withStyleColors({ ["WindowBg"] = colors.commsWindowBackground }, function()
										ui.withStyleVars({ ["WindowRounding"] = 0.0 }, function()
												ui.setNextWindowSize(Vector(ui.screenWidth / 2, ui.screenHeight / 2) , "Always")
												ui.window("StationInfo", {"NoCollapse","NoTitleBar"},
																	function()
																		show_tab = ui.iconTabs(show_tab,
																													 {{ icon = icons.info, tooltip = l.LOBBY, fun = showLobby },
																														 { icon = icons.bbs, tooltip = l.BULLETIN_BOARD, fun = showBBS },
																														 { icon = icons.market, tooltip = l.COMMODITY_MARKET, fun = showCommodityMarket },
																														 { icon = icons.rocketship, tooltip = l.SHIP_MARKET, fun = showShipMarket },
																														 { icon = icons.equipment, tooltip = l.EQUIPMENT_MARKET, fun = showEquipmentMarket },
																														 { icon = icons.repairs, tooltip = l.SHIP_REPAIRS, fun = showShipRepairs },
																														 { icon = icons.shield_other, tooltip = l.POLICE, fun = showPolice },
																		})
												end)
										end)
								end)
	end)
end

ui.registerModule("game", displayInfoWindow)

return {}

-- icons.info
-- icons.bbs
-- icons.market
-- seems to be missing
-- icons.equipment
-- icons.repairs
-- icons.shield_other
