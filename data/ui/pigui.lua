local Engine = import('Engine')
local pigui = Engine.pigui

local Vector = {}
do
	 local meta = {
			_metatable = "Private metatable",
			_DESCRIPTION = "Vectors in 2D"
	 }

	 meta.__index = meta

	 function meta:__add( v )
			if(type(v) == "number") then
				 return Vector(self.x + v, self.y + v)
			else
				 return Vector(self.x + v.x, self.y + v.y)
			end
	 end

	 function meta:__sub( v )
			if(type(v) == "number") then
				 return Vector(self.x - v, self.y - v)
			else
				 return Vector(self.x - v.x, self.y - v.y)
			end
	 end

	 function meta:__mul( v )
			if(type(v) == "number") then
				 return Vector(self.x * v, self.y * v)
			else
				 return Vector(self.x * v.x, self.y * v.y)
			end
	 end

	 function meta:__div( v )
			if(type(v) == "number") then
				 return Vector(self.x / v, self.y / v)
			else
				 return Vector(self.x / v.x, self.y / v.y)
			end
	 end

	 function meta:__tostring()
			return ("<%g, %g>"):format(self.x, self.y)
	 end

	 function meta:magnitude()
			return math.sqrt( self.x * self.x + self.y * self.y )
	 end

	 function meta:normalized()
			return Vector(self / math.abs(self.magnitude()))
	 end

	 function meta:left()
			return Vector(-self.y, self.x)
	 end

	 function meta:right()
			return Vector(self.y, -self.x)
	 end

	 setmetatable( Vector, {
										__call = function( V, x ,y ) return setmetatable( {x = x, y = y}, meta ) end
	 } )
end

Vector.__index = Vector

function map(func, array)
	 local new_array = {}
	 for i,v in ipairs(array) do
			new_array[i] = func(v)
	 end
	 return new_array
end

function print_r ( t )
   local print_r_cache={}
   local function sub_print_r(t,indent)
      if (print_r_cache[tostring(t)]) then
         print(indent.."*"..tostring(t))
      else
         print_r_cache[tostring(t)]=true
         if (type(t)=="table") then
            for pos,val in pairs(t) do
               if (type(val)=="table") then
                  print(indent.."["..pos.."] => "..tostring(t).." {")
                  sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                  print(indent..string.rep(" ",string.len(pos)+6).."}")
               elseif (type(val)=="string") then
                  print(indent.."["..pos..'] => "'..val..'"')
               else
                  print(indent.."["..pos.."] => "..tostring(val))
               end
            end
         else
            print(indent..tostring(t))
         end
      end
   end
   if (type(t)=="table") then
      print(tostring(t).." {")
      sub_print_r(t,"  ")
      print("}")
   else
      sub_print_r(t,"  ")
   end
   print()
end
print("****************************** PIGUI *******************************")
local center = Vector(1920/2, 1200/2)
local radius = 80
local function markerPos(name, distance)
	 local side, dir, pos = pigui.GetHUDMarker(name)
	 local point = center + Vector(dir.x, dir.y) * distance
	 if side == "hidden" then
			return nil
	 end
	 if Vector(pos.x, pos.y):magnitude() < distance / 1920 * 800 then
			return nil
	 else
			return point,Vector(dir.x, dir.y)
	 end
end

local selected

pigui.handlers.HUD = function(delta)
	 -- transparent full-size window, no inputs
	 pigui.SetNextWindowPos(Vector(0, 0), "Always")
	 pigui.SetNextWindowSize(Vector(1920, 1200), "Always")
	 pigui.PushStyleColor("WindowBg", {r=0,g=0,b=0,a=0})
	 pigui.Begin("HUD", {"NoTitleBar","NoInputs","NoMove","NoResize","NoSavedSettings","NoFocusOnAppearing","NoBringToFrontOnFocus"})
	 -- reticule
	 pigui.AddCircle(center, radius, {r=200, g=200, b=200}, 128, 2.0)
	 pigui.AddLine(center - Vector(5,0), center + Vector(5,0), {r=200,g=200,b=200}, 4.0)
	 pigui.AddLine(center - Vector(0,5), center + Vector(0,5), {r=200,g=200,b=200}, 4.0)
	 -- various markers
	 local pos,dir = markerPos("prograde", radius - 10)
	 if pos then
			local size = 4
			local left = pos + Vector(-1,0) * size
			local right = pos + Vector(1,0) * size
			local top = pos + Vector(0,1) * size
			local bottom = pos + Vector(0,-1) * size
			pigui.AddQuad(left, top, right, bottom, {r=200,g=200,b=200}, 1.0)
	 end
	 local pos,dir = markerPos("frame", radius + 5)
	 if pos then
			local left = dir:left() * 4 + pos
			local right = dir:right() * 4 + pos
			local top = dir * 8 + pos
			pigui.AddTriangle(left, right, top, {r=200,g=200,b=200}, 2.0)
	 end
	 local pos,dir = markerPos("nav_target", radius + 5)
	 if pos then
			local left = dir:left() * 7 + pos
			local right = dir:right() * 7 + pos
			local top = dir * 14 + pos
			pigui.AddTriangleFilled(left, right, top, {r=200,g=200,b=200})
	 end

	 pigui.End()
	 pigui.PopStyleColor(1);


	 -- nav window
	 pigui.Begin("Navigation", {})
	 pigui.Columns(2, "navcolumns", false)
	 local Game = import('Game')
	 local Format = import('Format')
	 local Space = import('Space')
	 local system = Game.system
	 local player = Game.player
	 local body_paths = system:GetBodyPaths()
	 -- create intermediate structure
	 local data = map(function(system_path)
				 local system_body = system_path:GetSystemBody()
				 local body = Space.GetBody(system_body.index)
				 local distance = player:DistanceTo(body)
				 return { systemBody = system_body, body = body, distance = distance, name = system_body.name }
										end,
			body_paths)
	 -- sort by distance
	 table.sort(data, function(a,b) return a.distance < b.distance end)
	 -- display
	 for key,data in pairs(data) do
			if(pigui.Selectable(data.name, selected == data.body, {"SpanAllColumns"})) then
				 selected = data.body
				 player:SetNavTarget(data.body)
			end
			pigui.NextColumn()
			pigui.Text(Format.Distance(data.distance))
			pigui.NextColumn()
	 end
	 pigui.End()
end

