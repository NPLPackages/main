--[[
Title: 
Author(s): LiPeng
Date: 2018/2/8
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/Font.lua");
local Font = commonlib.gettable("System.Windows.mcml.style.Font");
local FontMetrics = commonlib.gettable("System.Windows.mcml.style.Font.FontMetrics");
-------------------------------------------------------
]]


local FontMetrics = commonlib.gettable("System.Windows.mcml.style.Font.FontMetrics");
FontMetrics.__index = FontMetrics;

function FontMetrics:new(size)
	local o = {};

--	o.m_ascent = size*0.8;
--	o.m_descent = size*0.2;
--	o.m_lineGap = size*0.3;
	o.m_ascent = size*0.86;
	o.m_descent = size*0.14;
	o.m_lineGap = size*0.3;
	o.m_lineSpacing = o.m_ascent + o.m_descent + o.m_lineGap;
	
	setmetatable(o, self);
	return o;
end

function FontMetrics:init(size)
	self.m_ascent = size*0.86;
	self.m_descent = size*0.14;
	self.m_lineGap = size*0.3;
	self.m_lineSpacing = self.m_ascent + self.m_descent + self.m_lineGap;

	return self;
end

function FontMetrics:setAscent(ascent)
	self.m_ascent = ascent;
end

function FontMetrics:setDescent(descent)
	self.m_descent = descent;
end

function FontMetrics:setLineGap(lineGap)
	self.m_lineGap = lineGap;
end

function FontMetrics:setLineSpacing(lineSpacing)
	self.m_lineSpacing = lineSpacing;
end

local function lroundf(value)
	return math.floor(value+0.5);
end

function FontMetrics:ascent(baselineType)
	baselineType = baselineType or "AlphabeticBaseline"
	if (baselineType == "AlphabeticBaseline") then
		return lroundf(self.m_ascent);
	end
	return self:height() - self:height() / 2;
end

function FontMetrics:descent(baselineType)
	baselineType = baselineType or "AlphabeticBaseline"
	if (baselineType == "AlphabeticBaseline") then
		return lroundf(self.m_descent);
	end
	return self:height() / 2;
end

function FontMetrics:lineGap() 
	return lroundf(self.m_lineGap); 
end

function FontMetrics:lineSpacing() 
	return lroundf(self.m_lineSpacing); 
end

function FontMetrics:height(baselineType)
	baselineType = baselineType or "AlphabeticBaseline"
	return self:ascent(baselineType) + self:descent(baselineType);
end

--bool hasIdenticalAscentDescentAndLineGap(const FontMetrics& other) const
function FontMetrics:hasIdenticalAscentDescentAndLineGap(other)
    return self:ascent() == other:ascent() and self:descent() == other:descent() and self:lineGap() == other:lineGap();
end

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

	o.m_fontMetrics = FontMetrics:new(o.size);

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

function Font:FontMetrics()
	return self.m_fontMetrics;
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
	self.m_fontMetrics:init(v);
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

function Font.__eq(a, b)
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