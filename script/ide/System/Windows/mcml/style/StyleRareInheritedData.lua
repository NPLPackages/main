--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleRareInheritedData.lua");
local StyleRareInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleRareInheritedData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ShadowData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ShadowData.lua");
local ShadowData = commonlib.gettable("System.Windows.mcml.style.ShadowData");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local ShadowData = commonlib.gettable("System.Windows.mcml.style.ShadowData");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleRareInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleRareInheritedData");
StyleRareInheritedData.__index = StyleRareInheritedData;

function StyleRareInheritedData:new()
	local o = {};

	o.indent = ComputedStyle.initialTextIndent();
	o.effectiveZoom = ComputedStyle.initialZoom();

	-- Paged media properties.
	o.widows = ComputedStyle.initialWidows();
	o.orphans = ComputedStyle.initialOrphans();

	o.textSecurity = ComputedStyle.initialTextSecurity(); -- ETextSecurity
	o.userModify = ComputedStyleConstants.UserModifyEnum.READ_ONLY; -- EUserModify (editing)
	o.wordBreak = ComputedStyle.initialWordBreak(); -- EWordBreak
	o.wordWrap = ComputedStyle.initialWordWrap(); -- EWordWrap 
	o.nbspMode = ComputedStyleConstants.NBSPModeEnum.NBNORMAL; -- ENBSPMode
	o.khtmlLineBreak = ComputedStyleConstants.KHTMLLineBreakEnum.LBNORMAL; -- EKHTMLLineBreak
	o.textSizeAdjust = ComputedStyle.initialTextSizeAdjust(); -- An Apple extension.
	o.resize = ComputedStyle.initialResize(); -- EResize
	o.userSelect = ComputedStyle.initialUserSelect();  -- EUserSelect
	--o.colorSpace = nil; -- ColorSpace
	o.speak = ComputedStyleConstants.SpeakEnum.SpeakNormal; -- ESpeak
	o.hyphens = ComputedStyleConstants.HyphensEnum.HyphensManual; -- Hyphens
	o.textEmphasisFill = ComputedStyleConstants.TextEmphasisFillEnum.TextEmphasisFillFilled; -- TextEmphasisFill
	o.textEmphasisMark = ComputedStyleConstants.TextEmphasisMarkEnum.TextEmphasisMarkNone; -- TextEmphasisMark
	o.textEmphasisPosition = ComputedStyleConstants.TextEmphasisPositionEnum.TextEmphasisPositionOver; -- TextEmphasisPosition
	o.m_lineBoxContain = ComputedStyle.initialLineBoxContain(); -- LineBoxContain
--	-- CSS Image Values Level 3
--	o.imageRendering = nil; -- EImageRendering

	o.textShadow = nil;

	o.caretColor = ComputedStyle.initialColor();

	setmetatable(o, self);
	return o;
end

function StyleRareInheritedData:clone()
	local o = StyleRareInheritedData:new();

	o.indent = self.indent;
	o.effectiveZoom = self.effectiveZoom;

	-- Paged media properties.
	o.widows = self.widows;
	o.orphans = self.orphans;

	o.textSecurity = self.textSecurity;
	o.userModify = self.userModify;
	o.wordBreak = self.wordBreak;
	o.wordWrap = self.wordWrap;
	o.nbspMode = self.nbspMode;
	o.khtmlLineBreak = self.khtmlLineBreak;
	o.textSizeAdjust = self.textSizeAdjust;
	o.resize = self.resize;
	o.userSelect = self.userSelect;
	--o.colorSpace = nil;
	o.speak = self.speak;
	o.hyphens = self.hyphens;
	o.textEmphasisFill = self.textEmphasisFill;
	o.textEmphasisMark = self.textEmphasisMark;
	o.textEmphasisPosition = self.textEmphasisPosition;
	o.lineBoxContain = self.lineBoxContain;

	if(self.textShadow) then
		o.textShadow = self.textShadow:clone();
	else
		o.textShadow = nil;
	end

	o.caretColor = self.caretColor:clone();

	return o;
end

function StyleRareInheritedData.__eq(a, b)
	return a.indent == b.indent 
		and a.effectiveZoom == b.effectiveZoom 
		and a.widows == b.widows 
		and a.orphans == b.orphans 
		and a.textSecurity == b.textSecurity 
		and a.userModify == b.userModify 
		and a.wordBreak == b.wordBreak 
		and a.wordWrap == b.wordWrap 
		and a.nbspMode == b.nbspMode 
		and a.khtmlLineBreak == b.khtmlLineBreak 
		and a.textSizeAdjust == b.textSizeAdjust 
		and a.resize == b.resize 
		and a.userSelect == b.userSelect 
		and a.speak == b.speak 
		and a.hyphens == b.hyphens 
		and a.textEmphasisFill == b.textEmphasisFill 
		and a.textEmphasisMark == b.textEmphasisMark 
		and a.lineBoxContain == b.lineBoxContain
		and a.textShadow == b.textShadow
		and a.caretColor == b.caretColor
		and a.textEmphasisPosition == b.textEmphasisPosition;
end

function StyleRareInheritedData.Create()
	return StyleRareInheritedData:new();
end

function StyleRareInheritedData:copy()
	return self:clone();
end

function StyleRareInheritedData:ShadowDataEquivalent(other)
	if((self.textShadow == nil and other.textShadow ~= nil) or (self.textShadow ~= nil and other.textShadow == nil)) then
		return false;
	end
	if(self.textShadow ~= nil and other.textShadow ~= nil and self.textShadow ~= other.textShadow) then
		return false;
	end
	return true;
end