--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/ShadowData.lua");
local ShadowData = commonlib.gettable("System.Windows.mcml.style.ShadowData");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");

local ShadowData = commonlib.gettable("System.Windows.mcml.style.ShadowData");
ShadowData.__index = ShadowData;

function ShadowData:new(x, y, blur, color)
	local o = {};

	o.x = x or 0;
	o.y = y or 0;
	o.blur = blur or 0;
	o.color = color or Color:new();
	o.next = nil;

	setmetatable(o, self);
	return o;
end

function ShadowData:clone()
	return ShadowData:new(self.x, self.y, self.blur, self.color:clone());
end

function ShadowData.__eq(a, b)
	return a.x == b.x and a.y == b.y and a.blur == b.blur and a.color == b.color;
end

function ShadowData:X()
	return self.x;
end

function ShadowData:Y()
	return self.y;
end

function ShadowData:Blur()
	return self.blur;
end

function ShadowData:Color()
	return self.color;
end

function ShadowData:ToString()
	return string.format("%dpx %dpx %dpx %s", self.x, self.y, self.blur, self.color:ToString());
end

--@param css: css text-shadow string, as "5px 5px 1px red"
function ShadowData.CreateFromCssTextShadow(value)
	local x, y, blur, color = string.match(value,"(%d+)px (%d+)px ([^%s]+)%s?([^%s]*)");
	if(blur == "" and color == "") then
		blur = 0;
		color = "#00000088";
	elseif(color == "") then
		color = blur;
		blur = 0;
	else
		blur = string.match(blur,"(%d+)px");
	end
	color = Color.CreateFromCssColor(color);
	return ShadowData:new(x, y, blur, color);
end