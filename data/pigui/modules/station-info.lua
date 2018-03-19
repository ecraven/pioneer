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
end

local showCommodityMarket = function ()
	large_text(l.COMMODITY_MARKET)
end

local showShipMarket = function ()
	large_text(l.SHIP_MARKET)
end

local showEquipmentMarket = function ()
	large_text(l.EQUIPMENT_MARKET)
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
												ui.setNextWindowSize(Vector(ui.screenWidth / 5, ui.screenHeight / 1.5) , "Always")
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
