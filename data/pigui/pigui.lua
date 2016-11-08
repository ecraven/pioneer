-- Copyright © 2008-2016 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Format = import('Format')
local Game = import('Game')
local Space = import('Space')
local Engine = import('Engine')
local Event = import("Event")
local ShipDef = import("ShipDef")
local Vector = import("Vector")
local Color = import("Color")
local Lang = import("Lang")

local lui = Lang.GetResource("ui-core");
local lc = Lang.GetResource("core");
local lec = Lang.GetResource("equipment-core");

local utils = import("utils")
local pigui = Engine.pigui

local pi = 3.14159264
local pi_2 = pi / 2
local pi_4 = pi / 4
local two_pi = pi * 2
local standard_gravity = 9.80665

local ui = { }

ui.icons_texture = pigui:LoadTextureFromSVG(pigui.DataDirPath({"icons", "icons.svg"}), 16 * 64, 16 * 64)

function ui.window(name, params, fun)
	pigui.Begin(name, params)
	fun()
	pigui.End()
end

function ui.group(fun)
	pigui.BeginGroup()
	fun()
	pigui.EndGroup()
end

function ui.withFont(name, size, fun)
	pigui.PushFont(name, size)
	fun()
	pigui.PopFont()
end

function ui.withStyleColors(styles, fun)
	for k,v in pairs(styles) do
		pigui.PushStyleColor(k, v)
	end
	fun()
	pigui.PopStyleColor(utils.count(styles))
end

pigui.handlers.INIT = function(progress)
	if pigui.handlers and pigui.handlers.init then
		pigui.handlers.init(progress)
	end
end

pigui.handlers.GAME = function(deltat)
	if pigui.handlers and pigui.handlers.game then
		pigui.handlers.game(deltat)
	end
end

pigui.handlers.MAINMENU = function(deltat)
	if pigui.handlers and pigui.handlers.mainMenu then
		pigui.handlers.mainMenu(deltat)
	end
end

ui.registerHandler = function(name, fun)
	pigui.handlers[name] = fun
end

ui.circleSegments = function(radius)
	if radius < 5 then
		return 8
	elseif radius < 20 then
		return 16
	elseif radius < 50 then
		return 32
	elseif radius < 100 then
		return 64
	else
		return 128
	end
end

ui.Format = {
	Duration = function(duration, elements)
		-- shown elements items (2 -> wd or dh, 3 -> dhm or hms)
		local seconds = math.floor(duration % 60)
		local minutes = math.floor(duration / 60 % 60)
		local hours = math.floor(duration / 60 / 60 % 24)
		local days = math.floor(duration / 60 / 60 / 24 % 7)
		local weeks = math.floor(duration / 60 / 60 / 24 / 7)
		local i = elements or 5
		local count = false
		local result = ""
		if i > 0 then
			if weeks ~= 0 then
				result = result .. weeks .. "w"
				count = true
			end
			if count then
				i = i - 1
			end
		end
		if i > 0 then
			if days ~= 0 then
				result = result .. days .. "d"
				count = true
			end
			if count then
				i = i - 1
			end
		end
		if i > 0 then
			if hours ~= 0 then
				result = result .. hours .. "h"
				count = true
			end
			if count then
				i = i - 1
			end
		end
		if i > 0 then
			if minutes ~= 0 then
				result = result .. minutes .. "m"
				count = true
			end
			if count then
				i = i - 1
			end
		end
		if i > 0 then
			if seconds ~= 0 then
				result = result .. seconds .. "s"
				count = true
			end
			if count then
				i = i - 1
			end
		end
		return result
	end,
	Distance = function(distance)
		local d = math.abs(distance)
		if d < 1000 then
			return math.floor(distance), lc.UNIT_METERS
		end
		if d < 1000*1000 then
			return string.format("%0.2f", distance / 1000), lc.UNIT_KILOMETERS
		end
		if d < 1000*1000*1000 then
			return string.format("%0.2f", distance / 1000 / 1000), lc.UNIT_MILLION_METERS
		end
		return string.format("%0.2f", distance / 1.4960e11), lc.UNIT_AU
	end,
	Speed = function(distance)
		local d = math.abs(distance)
		if d < 1000 then
			return math.floor(distance), lc.UNIT_METERS_PER_SECOND
		end
		if d < 1000*1000 then
			return string.format("%0.2f", distance / 1000), lc.UNIT_KILOMETERS_PER_SECOND
		end
		return string.format("%0.2f", distance / 1000 / 1000), lc.UNIT_MILLION_METERS_PER_SECOND
		-- no need for au/s
	end,
}

ui.pointOnClock = function(center, radius, hours)
	-- 0 hours is top, going rightwards, negative goes leftwards
	local a = math.fmod(hours / 12 * two_pi, two_pi)
	local p = Vector(0, -radius)
	return Vector(center.x, center.y) + Vector(p.x * math.cos(a) - p.y * math.sin(a), p.y * math.cos(a) + p.x * math.sin(a))
end

ui.fonts = {
	-- dummy font, actually renders icons
	pionicons = {
		small = { name = "icons", size = 16, offset = 14 },
		large = { name = "icons", size = 22, offset = 28 }
	},
	pionillium = {
		large = { name = "pionillium", size = 30, offset = 24 },
		medium = { name = "pionillium", size = 18, offset = 14 },
		-- 		medsmall = { name = "pionillium", size = 15, offset = 12 },
		small = { name = "pionillium", size = 12, offset = 10 }
	}
}

ui.anchor = { left = 1, right = 2, center = 3, top = 4, bottom = 5, baseline = 6 }

ui.calcTextAlignment = function(pos, size, anchor_horizontal, anchor_vertical)
	local position = Vector(pos.x, pos.y)
	if anchor_horizontal == ui.anchor.left or anchor_horizontal == nil then
	  position.x = position.x -- do nothing
	elseif anchor_horizontal == ui.anchor.right then
	  position.x = position.x - size.x
	elseif anchor_horizontal == ui.anchor.center then
	  position.x = position.x - size.x/2
	else
	  error("show_text: incorrect horizontal anchor " .. anchor_horizontal)
	end
	if anchor_vertical == ui.anchor.top or anchor_vertical == nil then
	  position.y = position.y -- do nothing
	elseif anchor_vertical == ui.anchor.center then
	  position.y = position.y - size.y/2
	elseif anchor_vertical == ui.anchor.bottom then
	  position.y = position.y - size.y
	else
	  error("show_text: incorrect vertical anchor " .. anchor_vertical)
	end
	return position
end

ui.addStyledText = function(position, text, color, font, anchor_horizontal, anchor_vertical, tooltip)
	-- addStyledText aligns to upper left
	local size
	ui.withFont(font.name, font.size, function()
								size = pigui.CalcTextSize(text)
								local vert
								if anchor_vertical == ui.anchor.baseline then
									vert = nil
								else
									vert = anchor_vertical
								end
								position = ui.calcTextAlignment(position, size, anchor_horizontal, vert) -- ignore vertical if baseline
								if anchor_vertical == ui.anchor.baseline then
									position.y = position.y - font.offset
								end
								pigui.AddText(position, color, text)
								-- pigui.AddQuad(position, position + Vector(size.x, 0), position + Vector(size.x, size.y), position + Vector(0, size.y), colors.red, 1.0)
	end)
	if tooltip and not pigui.IsMouseHoveringAnyWindow() and tooltip ~= "" then
	  if pigui.IsMouseHoveringRect(position, position + size, true) then
			pigui.SetTooltip(tooltip)
	  end
	end
	return Vector(size.x, size.y)
end

-- Forward selected functions
ui.screenWidth = pigui.screen_width
ui.screenHeight = pigui.screen_height
ui.setNextWindowPos = pigui.SetNextWindowPos
ui.setNextWindowSize = pigui.SetNextWindowSize
ui.dummy = pigui.Dummy
ui.sameLine = pigui.SameLine
ui.text = pigui.Text
ui.progressBar = pigui.ProgressBar
ui.calcTextSize = pigui.CalcTextSize
ui.addCircle = pigui.AddCircle
ui.addLine = pigui.AddLine
ui.pathArcTo = pigui.PathArcTo
ui.pathStroke = pigui.PathStroke
ui.twoPi = two_pi
ui.pi_2 = pi_2
ui.pi_4 = pi_4
ui.pi = pi
return ui
