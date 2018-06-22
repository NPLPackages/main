--[[
Title: 
Author(s): LiPeng
Date: 2018/2/8
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/Font.lua");
local Font = commonlib.gettable("System.Windows.mcml.style.Font");
-------------------------------------------------------
]]
local Font = commonlib.gettable("System.Windows.mcml.style.Font");
Font.__index = Font;

-- {family="System", size=10, bold=true}
-- "System;14;bold"
function Font:new(family, size, bold)
	local o = {};

	o.family = family or "System";
	o.size = size or 12;
	o.bold = if_else(bold == nil, false, bold);
	o.m_letterSpacing = 0;
	o.m_wordSpacing = 0;

	setmetatable(o, self);
	return o;
end

function Font:ToTable()
	return {family = self.family, size = self.size, bold = self.bold};
end

function Font:ToString()
	return string.format("%s;%d;%s", self.family, self.size, if_else(self.bold, "bold", "norm"));
end

function Font:clone()
	return Font:new(self.family, self.size, self.bold);
end

function Font:Family()
	return self.family;
end

function Font:Size()
	return self.size;
end

function Font:Bold()
	return self.bold;
end

function Font:SetFamily(v)
	self.family = v;
end

function Font:SetSize(v)
	self.size = v;
end

function Font:SetBold(b)
	self.bold = b;
end

function Font:WordSpacing() 
	return self.m_wordSpacing; 
end

function Font:LetterSpacing() 
	return self.m_letterSpacing; 
end

function Font:SetWordSpacing(v) 
	self.m_wordSpacing = v; 
end

function Font:SetLetterSpacing(v) 
	self.m_letterSpacing = v; 
end

function Font._eq(a, b)
	return a.family == b.family and a.size == b.size and a.bold == b.bold;
end

function Font.CreateFromCssFont(family_str, size_str, bold_str)
	local family, size, bold;
	family = family_str;
	if(size_str) then
		size = string.match(size_str, "%d+");
	end

	if(bold_str and bold_str == "bold") then
		bold = true;
	end

	return Font:new(family, size, bold);
end