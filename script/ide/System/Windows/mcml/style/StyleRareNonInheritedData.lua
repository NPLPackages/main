--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleRareNonInheritedData.lua");
local StyleRareNonInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleRareNonInheritedData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Util/EnumCreater.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleMarqueeData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleMultiColData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleDeprecatedFlexibleBoxData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleFlexibleBoxData.lua");
local StyleFlexibleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleFlexibleBoxData");
local StyleDeprecatedFlexibleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleDeprecatedFlexibleBoxData");
local StyleMultiColData = commonlib.gettable("System.Windows.mcml.style.StyleMultiColData");
local StyleMarqueeData = commonlib.gettable("System.Windows.mcml.style.StyleMarqueeData");
local EnumCreater = commonlib.gettable("System.Util.EnumCreater");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LengthSize = commonlib.gettable("System.Windows.mcml.platform.LengthSize");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleRareNonInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleRareNonInheritedData");
StyleRareNonInheritedData.__index = StyleRareNonInheritedData;


local PageSizeTypeEnum = ComputedStyleConstants.PageSizeTypeEnum;

function StyleRareNonInheritedData:new()
	local o = {};

	-- value type
	o.m_regionOverflow = ComputedStyle.initialRegionOverflow(); -- RegionOverflow
	o.m_regionBreakAfter = ComputedStyle.initialPageBreak(); -- EPageBreak
	o.m_regionBreakBefore = ComputedStyle.initialPageBreak(); -- EPageBreak
	o.m_regionBreakInside = ComputedStyle.initialPageBreak(); -- EPageBreak
	o.m_pageSizeType = PageSizeTypeEnum.PAGE_SIZE_AUTO; -- PageSizeType
	o.m_transformStyle3D = ComputedStyle.initialTransformStyle3D(); -- ETransformStyle3D
	o.m_backfaceVisibility = ComputedStyle.initialBackfaceVisibility(); -- EBackfaceVisibility
	o.userDrag = ComputedStyle.initialUserDrag(); -- EUserDrag
	o.textOverflow = ComputedStyle.initialTextOverflow(); -- Whether or not lines that spill out should be truncated with "..."
	o.marginBeforeCollapse = ComputedStyleConstants.MarginCollapseEnum.MCOLLAPSE; -- EMarginCollapse
	o.marginAfterCollapse = ComputedStyleConstants.MarginCollapseEnum.MCOLLAPSE; -- EMarginCollapse
	o.matchNearestMailBlockquoteColor = ComputedStyle.initialMatchNearestMailBlockquoteColor(); -- EMatchNearestMailBlockquoteColor, FIXME: This property needs to be eliminated. It should never have been added.
	o.m_appearance = ComputedStyle.initialAppearance(); -- EAppearance
	o.m_borderFit = ComputedStyle.initialBorderFit(); -- EBorderFit
	o.m_textCombine = ComputedStyle.initialTextCombine(); -- CSS3 text-combine properties


	o.m_flowThread = ComputedStyle.initialFlowThread();

	o.m_boxShadow = nil;

	-- class type
	o.opacity = ComputedStyle.initialOpacity();
	o.m_pageSize = LengthSize:new();

	-- pointer class type
	o.m_marquee = StyleMarqueeData:new();
	o.m_multiCol = StyleMultiColData:new();
	o.m_deprecatedFlexibleBox = StyleDeprecatedFlexibleBoxData:new();
	o.m_flexibleBox = StyleFlexibleBoxData:new();

	o.alignContent = ComputedStyle.initialContentAlignment();
    o.alignItems = ComputedStyle.initialDefaultAlignment();
    o.alignSelf = ComputedStyle.initialSelfAlignment();
    o.justifyContent = ComputedStyle.initialContentAlignment();
    o.justifyItems = ComputedStyle.initialSelfAlignment();
    o.justifySelf = ComputedStyle.initialSelfAlignment();

	--o.m_runningAcceleratedAnimation = false;

	setmetatable(o, self);
	return o;
end

function StyleRareNonInheritedData:clone()
	local o = StyleRareNonInheritedData:new();

	o.opacity = self.opacity;
	o.m_pageSize = self.m_pageSize:clone();

	o.m_regionOverflow = self.m_regionOverflow; 
	o.m_regionBreakAfter = self.m_regionBreakAfter; 
	o.m_regionBreakBefore = self.m_regionBreakBefore; 
	o.m_regionBreakInside = self.m_regionBreakInside; 
	o.m_pageSizeType = self.m_pageSizeType; 
	o.m_transformStyle3D = self.m_transformStyle3D; 
	o.m_backfaceVisibility = self.m_backfaceVisibility; 
	o.userDrag = self.userDrag; 
	o.textOverflow = self.textOverflow; 
	o.marginBeforeCollapse = self.marginBeforeCollapse; 
	o.marginAfterCollapse = self.marginAfterCollapse; 
	o.matchNearestMailBlockquoteColor = self.matchNearestMailBlockquoteColor; 
	o.m_appearance = self.m_appearance; 
	o.m_borderFit = self.m_borderFit; 
	o.m_textCombine = self.m_textCombine; 
	o.m_flowThread = self.m_flowThread;
	o.m_marquee = self.m_marquee:clone();
	o.m_multiCol = self.m_multiCol:clone();
	o.m_deprecatedFlexibleBox = self.m_deprecatedFlexibleBox:clone();
	o.m_flexibleBox = self.m_flexibleBox:clone();

	o.alignContent = self.alignContent:clone();
	o.alignItems = self.alignItems:clone(); 
	o.alignSelf = self.alignSelf:clone(); 
	o.justifyContent = self.justifyContent:clone();
	o.justifyItems = self.justifyItems:clone();
	o.justifySelf = self.justifySelf:clone(); 

	--o.m_runningAcceleratedAnimation = self.m_runningAcceleratedAnimation;

	return o;
end

function StyleRareNonInheritedData.__eq(a, b)
	    return a.opacity == b.opacity 
			and a.m_pageSize == b.m_pageSize
			and a.m_regionOverflow == b.m_regionOverflow 
			and a.m_regionBreakAfter == b.m_regionBreakAfter 
			and a.m_regionBreakBefore == b.m_regionBreakBefore 
			and a.m_regionBreakInside == b.m_regionBreakInside 
			and a.m_pageSizeType == b.m_pageSizeType 
			and a.m_transformStyle3D == b.m_transformStyle3D 
			and a.m_backfaceVisibility == b.m_backfaceVisibility 
			and a.userDrag == b.userDrag 
			and a.textOverflow == b.textOverflow 
			and a.marginBeforeCollapse == b.marginBeforeCollapse 
			and a.marginAfterCollapse == b.marginAfterCollapse 
			and a.matchNearestMailBlockquoteColor == b.matchNearestMailBlockquoteColor 
			and a.m_appearance == b.m_appearance 
			and a.m_borderFit == b.m_borderFit 
			and a.m_textCombine == b.m_textCombine
			and a.m_flowThread == b.m_flowThread
			and a.m_marquee == b.m_marquee
			and a.m_multiCol == b.m_multiCol
			and a.m_deprecatedFlexibleBox == b.m_deprecatedFlexibleBox
			and a.m_flexibleBox == b.m_flexibleBox
			and a.alignContent == b.alignContent
			and a.alignItems == b.alignItems 
			and a.alignSelf == b.alignSelf 
			and a.justifyContent == b.justifyContent
			and a.justifyItems == b.justifyItems
			and a.justifySelf == b.justifySelf;
end

function StyleRareNonInheritedData.Create()
	return StyleRareNonInheritedData:new();
end

function StyleRareNonInheritedData:copy()
	return self:clone();
end

function StyleRareNonInheritedData:ContentDataEquivalent(other)
	return true;
end

function StyleRareNonInheritedData:CounterDataEquivalent(other)
	return true;
end

function StyleRareNonInheritedData:ShadowDataEquivalent(other)
	return true;
end

function StyleRareNonInheritedData:ReflectionDataEquivalent(other)
	return true;
end

function StyleRareNonInheritedData:AnimationDataEquivalent(other)
	return true;
end

function StyleRareNonInheritedData:TransitionDataEquivalent(other)
	return true;
end