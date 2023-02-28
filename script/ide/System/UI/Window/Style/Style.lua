--[[
Title: Style
Author(s): wxa
Date: 2020/6/30
Desc: 样式类
use the lib:
-------------------------------------------------------
local Style = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Style.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/LocalCache.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local LocalCache = commonlib.gettable("System.Windows.mcml.LocalCache");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local type = type;
local tonumber = tonumber;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local string_find = string.find;

local Style = commonlib.inherit(nil, NPL.export());

local pseudo_class_fields = {
	["RawStyle"] = true,
	["NormalStyle"] = true,
	["ActiveStyle"] = true,
	["HoverStyle"] = true,
}
-- 拷贝样式
local function CopyStyle(dst, src)
	if (type(src) ~= "table" or type(dst) ~= "table") then return dst end
	for key, value in pairs(src) do
		if (not pseudo_class_fields[key]) then
			Style.AddStyleItem(dst, key, value);
		end
	end
	return dst;
end

Style.CopyStyle = CopyStyle;

-- 布局字段
local layout_fields = {
	["width"] = true,
	["height"] = true,
	["max-width"] = true,
	["max-height"] = true,
	["min-width"] = true,
	["min-height"] = true,
	["margin"] = true,
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,
	["padding"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,
	["border-size"] = true,
	["border-left-size"] = true,
	["border-right-size"] = true,
	["border-top-size"] = true,
	["border-bottom-size"] = true,
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,

	["float"] = true,
	["position"] = true,
	["box-sizing"] = true,
}

-- 是否需要重新布局
local function IsRefreshLayout(style)
	if (type(style) ~= "table") then return false end
	for key, val in pairs(style) do
		if (layout_fields[key]) then
			return true;
		end
	end
	return false;
end

-- 构造函数
function Style:ctor()
	self.RawStyle = {};             -- 原始样式
	self.NormalStyle = {};          -- 普通样式
	self.InheritStyle = nil;        -- 继承样式
	-- 伪类样式
	self.ActiveStyle = {};          -- 激活样式
	self.HoverStyle = {};           -- 鼠标悬浮样式
	self.FocusStyle = {};           -- 聚焦样式
end

-- 初始化函数
function Style:Init(style, inheritStyle)
	self:Clear();

	self.InheritStyle = inheritStyle;
    self:Merge(style);
	
	return self;
end

local ClearCacheTable = {};
local function ClearStyle(self)
	if (type(self) ~= "table") then return end

	for key, val in pairs(self) do
		if (rawget(self, key) ~= nil and type(val) ~= "function" and type(val) ~= "table") then
			ClearCacheTable[key] = true;
		end
	end

	for key, val in pairs(ClearCacheTable) do
		if (val) then
			self[key] = nil;
			ClearCacheTable[key] = false;
		end
	end
end

-- 清空样式
function Style:Clear()
	ClearStyle(self);
	ClearStyle(self.RawStyle);
	ClearStyle(self.NormalStyle);
	ClearStyle(self.ActiveStyle);
	ClearStyle(self.HoverStyle);
	ClearStyle(self.FocusStyle);

	self.InheritStyle = nil;        -- 继承样式
	self.RawStyle = {};             -- 原始样式
	self.NormalStyle = {};          -- 普通样式
	-- 伪类样式
	self.ActiveStyle = {};          -- 激活样式
	self.HoverStyle = {};           -- 鼠标悬浮样式
	self.FocusStyle = {};           -- 聚焦样式
end

-- 设置继承样式
function Style:SetInheritStyle(inheritStyle)
	self.InheritStyle = inheritStyle;
end

-- 是否需要刷新布局
function Style:IsNeedRefreshLayout(style)
	return IsRefreshLayout(style);
end

-- 选择样式
function Style:SelectStyle(style)
	for key, val in pairs(style) do
		self[key] = val;
	end
	return self;
end

-- 当前样式
function Style:GetCurStyle()
	local style = {};
	for key, val in pairs(self) do
		if (type(val) ~= "table" or key == "transform") then
			style[key] = val;
		end
	end
	return style;
end

-- 选择默认样式
function Style:SelectNormalStyle()
	return self:SelectStyle(self.NormalStyle);
end

-- 选择激活样式
function Style:SelectActiveStyle()
	return self:SelectStyle(self.ActiveStyle);
end

-- 选择悬浮样式
function Style:SelectHoverStyle()
	return self:SelectStyle(self.HoverStyle);
end

-- 选择聚焦样式
function Style:SelectFocusStyle()
	return self:SelectStyle(self.FocusStyle);
end

-- 取消选择
function Style:UnselectStyle()
	ClearStyle(self);
end

-- 选择默认样式
function Style:GetNormalStyle()
	return self.NormalStyle;
end

-- 选择激活样式
function Style:GetActiveStyle()
	return self.ActiveStyle;
end

-- 选择悬浮样式
function Style:GetHoverStyle()
	return self.HoverStyle;
end

-- 选择聚焦样式
function Style:GetFocusStyle()
	return self.FocusStyle;
end

-- 合并样式
function Style:Merge(style)			
    if(type(style) ~= "table") then return end 

	CopyStyle(self, style);                              -- 计算样式
	CopyStyle(self.RawStyle, style.RawStyle);
	CopyStyle(self.NormalStyle, style.NormalStyle);
	CopyStyle(self.ActiveStyle, style.ActiveStyle);
	CopyStyle(self.HoverStyle, style.HoverStyle);
	
    return self;
end


-- 继承字段
local inheritable_fields = {
	["color"] = true,
	["font-family"] = true,
	["font-size"] = true,
	["font-weight"] = true,
	["text-shadow"] = true,
	["shadow-color"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
	["text-align"] = true,
	["line-height"] = true,
	["caret-color"] = true,
	["text-singleline"] = true,
	["base-font-size"] = true,
	["white-space"] = true,
};


local dimension_fields = {
	["height"] = true, ["min-height"] = true, ["max-height"] = true,
	["width"] = true, ["min-width"] = true, ["max-width"] = true,
	["left"] = true, ["top"] = true, ["right"] = true, ["bottom"] = true,
	["padding"] = true, ["padding-top"] = true, ["padding-right"] = true, ["padding-bottom"] = true, ["padding-left"] = true, 
	["margin"] = true, ["margin-top"] = true, ["margin-right"] = true, ["margin-bottom"] = true, ["margin-left"] = true, 
	["border-width"] = true, ["border-top-wdith"] = true, ["border-right-wdith"] = true, ["border-bottom-wdith"] = true, ["border-left-wdith"] = true, 
	-- ["border-radius"] = true,

	["spacing"] = true,
	["shadow-quality"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
}

local number_fields = {
	["border-top-width"] = true, ["border-right-width"] = true, ["border-bottom-width"] = true, ["border-left-width"] = true, ["border-width"] = true,
	["outline-width"] = true, 

	["font-size"] = true, ["base-font-size"] = true,
	["z-index"] = true,
	["scale"] = true,
	["flex-grow"] = true,
	["flex-shrink"] = true,

	["border-radius"] = true,

	["animation-iteration-count"] = true,
	["rotate"] = true,
	["translateX"] = true,
	["translateY"] = true,
};

local color_fields = {
	["color"] = true, 
	["border-color"] = true,
	["border-top-color"] = true, ["border-right-color"] = true, ["border-bottom-color"] = true, ["border-left-color"] = true,
	["outline-color"] = true,
	["background-color"] = true,
	["outer-background-color"] = true,
	["shadow-color"] = true,
	["caret-color"] = true,
};

local image_fields = {
	["background"] = true,
	["background-image"] = true,
}

local time_fields = {
	["animation-duration"] = true,
	["animation-delay"] = true,
}

local transform_fields = {
	["transform"] = true,
	["transform-origin"] = true,
};

function Style.IsPx(value)
	return string.match(value or "", "^[%+%-]?%d+px$");
end

function Style.GetPxValue(value)
	if (type(value) ~= "string") then return value end
	return tonumber(string.match(value, "[%+%-]?%d+"));
end

function Style.IsNumber(value)
	return string.match(value or "", "[%+%-]?%d+%.?%d*$");
end

function Style.GetNumberValue(value)
	return tonumber(value);
end

function  Style.FilterImage(filename)
	if (filename:match("^http[s]:")) then return filename end 
	return CommonLib.GetFullPath(filename, {});
	-- if(filename:match("^@")) then
	-- 	filename = string.sub(filename, 2);
	-- 	local filename_, params = filename:match("^([^;#:]+)(.*)$");
	-- 	if(filename_) then
	-- 		local filepath = Files.GetFilePath(filename_);
	-- 		if(filepath) then
	-- 			 if(filepath~=filename_) then
	-- 				filename = filepath..(params or "");
	-- 			 end
	-- 		else
	-- 			-- file not exist, return nil
	-- 			LOG.std(nil, "warn", "Style", "image file not exist %s", filename);
	-- 			return;
	-- 		end
	-- 	end
	-- end
	-- return filename;
end

function Style.GetTransformStyleValue(value)
	local transform = {};
	value = string.gsub(value, "^%s*", "");
	while(string.len(value) > 0) do
		if (string.find(value, "rotate", 1, true) == 1) then
			local str = string.match(value, "^(rotate%([^%)]*%))");
			value = string.sub(value, string.len(str) + 1);
			value = string.gsub(value, "^%s*", "");
			local degree =  string.match(str, "([%+%-]?%d+)");
			table.insert(transform, {action = "rotate", rotate = tonumber(degree)});
		end

		if (string.find(value, "translate", 1, true) == 1) then
			local str = string.match(value, "^(translate%([^%)]*%))");
			value = string.sub(value, string.len(str) + 1);
			value = string.gsub(value, "^%s*", "");
			local splitIndex = string.find(str, ",", 1, true);
			local x =  string.match(string.sub(str, 1, splitIndex), "([%+%-]?%d+)");
			local y =  string.match(string.sub(str, splitIndex or 1), "([%+%-]?%d+)");
			table.insert(transform, {action = "translate", translateX = tonumber(x), translateY = tonumber(y)});
		end

		if (string.find(value, "scale", 1, true) == 1) then
			local str = string.match(value, "^(scale%([^%)]*%))");
			value = string.sub(value, string.len(str) + 1);
			value = string.gsub(value, "^%s*", "");
			local splitIndex = string.find(str, ",", 1, true) or 1;
			local x =  string.match(string.sub(str, 1, splitIndex), "([%+%-]?%d+)");
			local y =  string.match(string.sub(str, splitIndex or 1), "([%+%-]?%d+)");
			table.insert(transform, {action = "scale", scaleX = tonumber(x), scaleY = tonumber(y)});
		end
	end
	-- echo(transform, true)
	return transform;
end

function Style.GetStyleValue(name, value)
	if (type(name) ~= "string" or type(value) ~= "string") then return value end
	
    if(dimension_fields[name]) then
		if (string.match(value, "^[%+%-]?%d+px$")) then   -- 像素值
			value = tonumber(string.match(value, "^([%+%-]?%d+)px$"));
		elseif (string.match(value, "^[%+%-]?%d+%%$")) then  -- 百分比
			value = value;
		else
			-- value = tonumber(value);
		end
	elseif (number_fields[name]) then
		value = tonumber(string.match(value, "[%+%-]?%d+"));
	elseif(color_fields[name]) then
		value = StyleColor.ConvertTo16(string.lower(value));
	elseif(transform_fields[name]) then
		if(name == "transform") then
			value = Style.GetTransformStyleValue(value);
		elseif(name == "transform-origin") then
			local values = {}
			for v in value:gmatch("%-?%d+") do
				values[#values+1] = tonumber(v);
			end
			if(values[1]) then
				values[2] = values[2] or 0;
				value = values;
			else
				value = nil;
			end
		end
	elseif(image_fields[name]) then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
		value = Style.FilterImage(value);
		value = value ~= "" and value or nil;
	elseif (time_fields[name]) then
		value = string.match(value, "%d+");
		value = value and tonumber(value);
	end
	return value;
end

-- 缩写字段
local complex_fields = {
	["border"] = "border-width border-style border-color",
	["border-top"] = "border-top-width border-top-style border-top-color",
	["border-right"] = "border-right-width border-right-style border-right-color",
	["border-bottom"] = "border-bottom-width border-bottom-style border-bottom-color",
	["border-left"] = "border-left-width border-left-style border-left-color",
	["border-width"] = "border-top-width border-right-width border-bottom-width border-left-width",
    ["padding"] = "padding-top padding-right padding-bottom padding-left",
	["margin"] = "margin-top margin-right margin-bottom margin-left ",
	["overflow"] = "overflow-x overflow-y",
	["flex"] = "flex-grow flex-shrink flex-basis",
	["animation"] = "animation-name animation-duration animation-timing-function animation-delay animation-iteration-count animation-direction animation-fill-mode animation-play-state",
};


local function AddSingleStyleItem(style, name, value)
	value = Style.GetStyleValue(name, value);
	if (not value) then return end
	style[name] = value;
end

local function AddComplexStyleItem(style, name, value)
	local names = commonlib.split(complex_fields[name], "%s");
    local values = commonlib.split(tostring(value), "%s");
	
	-- 保留简写值
	AddSingleStyleItem(style, name, value);

	-- 解析符合样式值
	if (name == "padding" or name == "margin" or name == "border-width") then
		values[1] = values[1] or 0;
		values[4] = values[4] or values[2] or values[1];
        values[3] = values[3] or values[1];
		values[2] = values[2] or values[1];
	elseif (name == "border" or name == "border-top" or name == "border-right" or name == "border-bottom" or name == "border-left") then
		values[1] = values[1] or 0;
		values[2] = values[2] or "solid";
		values[3] = values[3] or "#000000";
		values[1] = values[1] == "none" and 0 or values[1];
	elseif (name == "overflow") then
		values[1] = values[1] or "hidden";
		values[2] = values[2] or values[1];
	elseif (name == "flex") then
		values[1] = values[1] or 1;
		values[2] = values[2] or 1;
		values[3] = values[3] or "auto";
	elseif (name == "animation") then
		values[1], values[2], values[3], values[4], values[5], values[6], values[7], values[8] = values[1], values[2] or "0s", values[3] or "linear", values[4] or "0s", values[5] or 1, values[6] or "normal", values[7], values[8];
    end
	
	for i = 1, #names do
		if (complex_fields[names[i]]) then
			AddComplexStyleItem(style, names[i], values[i]);
		else
			AddSingleStyleItem(style, names[i], values[i]);
		end
	end
	
end

function Style.AddStyleItem(style, name, value)
	name = string_lower(name);
	if (type(value) == "string") then value = string_gsub(value, "%s*$", "") end

	if(complex_fields[name]) then
		AddComplexStyleItem(style, name, value);
	else
		AddSingleStyleItem(style, name, value);
	end
end

function Style.ParseString(style_code)
	local style = {};
	for name, value in string.gfind(style_code or "", "([%w%-]+)%s*:%s*([^;]*)[;]?") do
		Style.AddStyleItem(style, name, value);		
	end
	return style;
end


function Style:AddStyle(dst_style, src_style)
	if (type(src_style) == "string") then
		local style = Style.ParseString(src_style);
		for key, val in pairs(style) do
			dst_style[key] = val;
		end
	elseif (type(src_style) == "table") then
		for key, val in pairs(src_style) do
			Style.AddStyleItem(dst_style, key, val);
		end
	end
end

-- 添加样式代码: mcml style attribute string like "background:url();margin:10px;"
function Style:AddNormalStyle(style)
	self:AddStyle(self.NormalStyle, style);
end

-- 获取样式值
function Style:GetValue(key, defaultValue)
	local value, style = self[key], self.InheritStyle;
	if (value or not inheritable_fields[key]) then return value or defaultValue end
	while (style and not value) do
		value = style[key];
		style = style.InheritStyle;
	end
	return value or defaultValue;
end

function Style:GetTextAlign(defaultValue)
	return self:GetValue("text-align", defaultValue);
end

-- 获取字体  System;14;norm
function Style:GetFont()
	return string.format("%s;%d;%s", self:GetFontFamily("System"), self:GetFontSize(14), self:GetFontWeight("norm"));
end

function Style:GetFontFamily(defaultValue)
	return self:GetValue("font-family", defaultValue);
end

function Style:GetFontWeight(defaultValue)
	return self:GetValue("font-weight", defaultValue);
end

function Style:GetFontSize(defaultValue)
	return self:GetValue("font-size", defaultValue or 14);
end

function Style:GetScale(defaultValue)
	return self.scale or (self["font-size"] and self["base-font-size"] and self["font-size"] / self["base-font-size"]) or defaultValue;
end

function Style:GetColor(defaultValue)
	return self:GetValue("color", defaultValue);
end

function Style:GetBackgroundColor(defaultValue)
	return self:GetValue("background-color", defaultValue);
end

function Style:GetBackground(defaultValue)
	return self:GetValue("background", defaultValue);
end

function Style:GetLineHeight(defaultValue)
	local lineHeight = self:GetValue("line-height", defaultValue);
	if (type(lineHeight) == "number") then return lineHeight end
	local fontSize = self:GetFontSize(14);
	if (self.IsPx(lineHeight)) then 
		lineHeight = self.GetPxValue(lineHeight);
	elseif (self.IsNumber(lineHeight)) then 
		lineHeight = math.floor(self.GetNumberValue(lineHeight) * fontSize);
	else
		lineHeight = defaultValue or math.floor(1.4 * fontSize);
	end
	return lineHeight; 
end

function Style:GetOutlineWidth(defaultValue)
	return self:GetValue("outline-width", defaultValue);
end

function Style:GetOutlineColor(defaultValue)
	return self:GetValue("outline-color", defaultValue);
end

function Style:GetWhiteSpace()
	return self:GetValue("white-space", "normal");
end

function Style:GetAnimationName()
	return self["animation-name"];
end

-- function Style:GetRotate()
-- 	return self.rotate;
-- end

-- function Style:GetTranslate()

-- end