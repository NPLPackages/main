--[[
Title: BaseLayout
Author(s): wxa
Date: 2020/6/30
Desc: 弹性布局类
use the lib:
-------------------------------------------------------
local BaseLayout = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Layout/BaseLayout.lua");
-------------------------------------------------------
]]

local BaseLayout = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local BaseLayoutDebug = GGS.Debug.GetModuleDebug("BaseLayoutDebug").Disable(); --Enable  Disable

local nid = 0;

-- 属性定义
BaseLayout:Property("Element");                                        -- 元素
BaseLayout:Property("BorderBox", false, "IsBorderBox");                -- 区域盒子
BaseLayout:Property("LayoutFinish", false, "IsLayoutFinish");          -- 是否布局完成
BaseLayout:Property("FixedSize", false, "IsFixedSize");                -- 是否是固定宽高
BaseLayout:Property("FixedWidth", false, "IsFixedWidth");              -- 是否是固定宽
BaseLayout:Property("FixedHeight", false, "IsFixedHeight");            -- 是否是固定高
BaseLayout:Property("UseSpace", true, "IsUseSpace");                   -- 是否使用空间

BaseLayout:Property("Layout", true, "IsLayout");                                     -- 是否布局
BaseLayout:Property("Visible", true, "IsVisible");                                   -- 是否可见
BaseLayout:Property("BlockElement", false, "IsBlockElement");                        -- 是否块元素
BaseLayout:Property("FlexElement", false, "IsFlexElement");                          -- 是否弹性元素
BaseLayout:Property("PositionElement", false, "IsPositionElement");                  -- 是否是定位元素

BaseLayout:Property("PositionStyle");
BaseLayout:Property("DisplayStyle");

-- 构造函数
function BaseLayout:ctor()
    nid = nid + 1;
	self.nid = nid;
end

-- 重置布局
function BaseLayout:Reset()
	-- 相对于父元素的位置
	self.top, self.right, self.bottom, self.left = 0, 0, 0, 0;
	-- 元素宽高 
	self.x, self.y, self.width, self.height = 0, 0, nil, nil;
	-- 真实内容宽高
	self.realContentWidth, self.realContentHeight = nil, nil;
	-- 内容宽高
	self.contentWidth, self.contentHeight = 0, 0;  
	-- 空间大小
	self.spaceWidth, self.spaceHeight = 0, 0;
	-- 边框
	self.borderTop, self.borderRight, self.borderBottom, self.borderLeft = 0, 0, 0, 0;
	-- 填充
	self.paddingTop, self.paddingRight, self.paddingBottom, self.paddingLeft = 0, 0, 0, 0;
	-- 边距
    self.marginTop, self.marginRight, self.marginBottom, self.marginLeft = 0, 0, 0, 0;
    
	-- 窗口坐标
	-- self.windowX, self.windowY = 0, 0;

	-- 是否固定内容大小
	self:SetFixedSize(false);
	self:SetLayoutFinish(false);
    self:SetUseSpace(true);

    self:SetBlockElement(false);
    self:SetFlexElement(false);
    self:SetPositionElement(false);
end

-- 初始化
function BaseLayout:Init(element)
	self:Reset();
    self:SetElement(element);
	return self;
end

function BaseLayout:GetTagNameAndName()
	return self:GetTagName() .. "-" .. self:GetName();
end

-- 获取元素名
function BaseLayout:GetName()
	return self:GetElement():GetName();
end

-- 获取元素名
function BaseLayout:GetTagName()
    return self:GetElement():GetTagName();
end

-- 获取窗口
function BaseLayout:GetWindow()
    return self:GetElement():GetWindow();
end

-- 获取窗口位置 x, y, w, h    (w, h 为宽高, 非坐标)
function BaseLayout:GetWindowPosition()
	return self:GetWindow():GetWindowPosition();
end

-- 获取页面元素的样式
function BaseLayout:GetStyle()
	return self:GetElement():GetStyle();
end

-- 获取父布局
function BaseLayout:GetParentLayout()
    local parent = self:GetElement():GetParentElement();
    return parent and parent:GetLayout();
end

-- 获取根布局
function BaseLayout:GetRootLayout()
    return self:GetWindow() and self:GetWindow():GetLayout();
end

-- 设置空间大小
function BaseLayout:SetSpaceWidthHeight(width, height)
	self.spaceWidth, self.spaceHeight = width, height;
end

-- 获取空间大小 margin border padding content
function BaseLayout:GetSpaceWidthHeight(width, height)
	return self.spaceWidth, self.spaceHeight;
end

-- 获取固定内容宽高
function BaseLayout:GetFixedContentWidthHeight() 
	local width, height = self:GetContentWidthHeight();
	if (self:IsFixedSize()) then return width, height end
	if (not self:IsFixedWidth()) then width = nil end
	if (not self:IsFixedHeight()) then height = nil end
	return width, height;
end

-- 获取固定宽高
function BaseLayout:GetFixedWidthHeight()
	local width, height = self:GetWidthHeight();
	if (self:IsFixedSize()) then return width, height end
	if (not self:IsFixedWidth()) then width = nil end
	if (not self:IsFixedHeight()) then height = nil end
	return width, height;
end

-- 设置区域宽高 非坐标 包含 padding border content
function BaseLayout:SetWidthHeight(width, height)
	self.width, self.height = width, height;
	self:GetElement():SetSize(self.width or 0, self.height or 0);
	local marginTop, marginRight, marginBottom, marginLeft = self:GetMargin();
	local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
	local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();
	self.spaceWidth = width and (width + marginLeft + marginRight);
	self.spaceHeight = height and (height + marginTop + marginBottom);
	self.contentWidth = width and (width - borderLeft - borderRight - paddingLeft - paddingRight);
	self.contentHeight = height and (height - borderTop - borderBottom - paddingTop - paddingBottom);
	-- BaseLayoutDebug.FormatIf(
	-- 	self:GetElement():GetAttrValue("id") == "flex",
	-- 	"width = %s, height = %s",
	-- 	width, height
    -- );
end

-- 获取区域宽高 非坐标 包含 padding border style.width    style.width 可能是内容宽也可能是区域宽,  布局里的宽一定是区域宽
function BaseLayout:GetWidthHeight()
	return self.width, self.height;
end

-- 获取几何大小
function BaseLayout:GetGeometry()
    return self.left, self.top, self.width, self.height;
end

-- 获取内容几何大小
function BaseLayout:GetContentGeometry()
	local x, y = self:GetContentPos();
	local w, h = self:GetContentWidthHeight();
	return x, y, w, h;
end

-- 设置内容宽高
function BaseLayout:SetContentWidthHeight(width, height)
    self.contentWidth, self.contentHeight = width, height;
end

-- 获取内容宽高 
function BaseLayout:GetContentWidthHeight()
	return self.contentWidth, self.contentHeight;
end

-- 设置真实宽高
function BaseLayout:SetRealContentWidthHeight(width, height)
	-- BaseLayoutDebug.FormatIf(
	-- 	self:GetElement():GetAttrValue("id") == "flex",
	-- 	"realContentWidth = %s, realContentHeight = %s",
	-- 	width, height
    -- );
	local isRealContentWidthHeightChange = self.realContentWidth ~= width or self.realContentHeight ~= height;
    self.realContentWidth, self.realContentHeight = width, height;
	-- 真实内容发生改变
	if (isRealContentWidthHeightChange and self:IsLayoutFinish()) then self:GetElement():OnRealContentSizeChange() end
end
-- 获取真实宽高 
function BaseLayout:GetRealContentWidthHeight()
	return self.realContentWidth, self.realContentHeight;
end
-- 设置最小宽高 
function BaseLayout:SetMinWidthHeight(width, height)
	self.minWidth, self.minHeight = width, height;
end
-- 获取最小宽高
function BaseLayout:GetMinWidthHeight()
	return self.minWidth, self.minHeight;
end
-- 设置最大宽高 
function BaseLayout:SetMaxWidthHeight(width, height)
	self.maxWidth, self.maxHeight = width, height;
end
-- 获取最大宽高
function BaseLayout:GetMaxWidthHeight()
	return self.maxWidth, self.maxHeight;
end
-- 设置填充
function BaseLayout:SetBorder(top, right, bottom, left)
    self.borderTop, self.borderRight, self.borderBottom, self.borderLeft = top, right, bottom, left;
end
-- 获取填充 top right bottom left 
function BaseLayout:GetBorder()
	return self.borderTop, self.borderRight, self.borderBottom, self.borderLeft;
end
-- 设置填充
function BaseLayout:SetPadding(top, right, bottom, left)
    self.paddingTop, self.paddingRight, self.paddingBottom, self.paddingLeft = top, right, bottom, left;
end
-- 获取填充 top right bottom left 
function BaseLayout:GetPadding()
	return self.paddingTop, self.paddingRight, self.paddingBottom, self.paddingLeft;
end
-- 设置边距
function BaseLayout:SetMargin(top, right, bottom, left)
    self.marginTop, self.marginRight, self.marginBottom, self.marginLeft = top, right, bottom, left;
end
-- 获取填充 top right bottom left 
function BaseLayout:GetMargin()
	return self.marginTop, self.marginRight, self.marginBottom, self.marginLeft;
end
-- 设置位置
function BaseLayout:SetPosition(top, right, bottom, left)
	self.top, self.right, self.bottom, self.left = top, right, bottom, left;
end
-- 获取位置
function BaseLayout:GetPosition()
    return self.top, self.right, self.bottom, self.left;
end
-- 设置位置坐标
function BaseLayout:SetPos(x, y)
	self.x, self.y = x or 0, y or 0;
	self:GetElement():SetPosition(self.x, self.y);
end
-- 获取位置坐标
function BaseLayout:GetPos()
	return self.x or 0, self.y or 0; 
end
-- 获取内容偏移
function BaseLayout:GetContentOffset()
	return self.borderLeft + self.paddingLeft, self.borderTop + self.paddingTop;
end
-- 获取内容位置
function BaseLayout:GetContentPos()
	return self.x + self.borderLeft + self.paddingLeft, self.y + self.borderTop + self.paddingTop;
end

function BaseLayout:SetZIndex(zindex)
	self:GetElement():SetZIndex(string.format("%06d", zindex));
end

-- 百分比转数字
function BaseLayout:PercentageToNumber(percentage, size)
	if (type(percentage) == "number") then return percentage end;
	if (type(percentage) ~= "string") then return end
	local number = tonumber(string.match(percentage, "[%+%-]?%d+"));
	if (string.match(percentage, "%%$")) then
		number = size and math.floor(size * number /100);
	end
	return number;
end

-- 是否裁剪溢出
function BaseLayout:IsClipOverflow()
	return self.overflowX == "auto" or self.overflowX == "scroll" or self.overflowX == "hidden" or self.overflowY == "auto" or self.overflowY == "scroll" or self.overflowY == "hidden";
end

-- X方向是否允许滚动
function BaseLayout:IsEnableScrollX()
	return self.overflowX == "auto" or self.overflowX == "scroll";
end

-- Y方向是否允许滚动
function BaseLayout:IsEnableScrollY()
	return self.overflowY == "auto" or self.overflowY == "scroll";
end

-- 是否允许滚动
function BaseLayout:IsEnableScroll()
	return self:IsEnableScrollX() or self:IsEnableScrollY();
end

-- 是否溢出
function BaseLayout:IsOverflow()
	return self:IsOverflowX() or self:IsOverflowY();
end

-- X方向是否溢出
function BaseLayout:IsOverflowX()
	return self.contentWidth and self.realContentWidth and self.realContentWidth > self.contentWidth;
end

-- Y方向是否溢出
function BaseLayout:IsOverflowY()
	return self.contentHeight and self.realContentHeight and self.realContentHeight > self.contentHeight;
end

-- 是否可以滚动
function BaseLayout:IsCanScroll()
	return self:IsCanScrollX() or self:IsCanScrollY();
end

-- X方向是否可以滚动
function BaseLayout:IsCanScrollX()
	return self:IsEnableScrollX() and self:IsOverflowX();
end

-- Y方向是否可以滚动
function BaseLayout:IsCanScrollY()
	return self:IsEnableScrollY() and self:IsOverflowY();
end

-- 开始布局
function BaseLayout:PrepareLayout()
    self:Reset();

    local style = self:GetStyle();
    local display = style.display;
	local position = style.position or "static";
	local visibility = style.visibility;

	-- 显示样式
	self:SetDisplayStyle(display);

    -- 块元素
    if ((not display or display == "block" or display == "flex") and not style.float) then self:SetBlockElement(true) end
    
    -- 弹性元素
    if (display == "flex") then self:SetFlexElement(true) end

	-- 是否布局
	if (display == "none") then 
		self:SetLayout(false);
	else
		self:SetLayout(true);
	end

	-- 是否可见
    if (display == "none" or visibility == "hidden") then 
        self:SetVisible(false);
    else
        self:SetVisible(true);
    end

    -- 定位元素
	self:SetPositionStyle(position);

	if (position == "absolute" or position == "fixed") then 
		self:SetPositionElement(true);
		-- 不使用文档流
		self:SetUseSpace(false);
		style["z-index"] = style["z-index"] or 1;  -- 定位元素默认为1
	else
		self:SetUseSpace(true);
		self:SetPositionElement(false);
		style["z-index"] = style["z-index"] or 0;  -- 普通元素默认为0
	end
	self:SetZIndex(style["z-index"]);
	
    -- 溢出
    self.overflowX = style["overflow-x"] or "visible";
	self.overflowY = style["overflow-y"] or "visible";
	
	-- 设置盒子类型
    if (style["box-sizing"] == "border-box") then
        self:SetBorderBox(true);
    else  -- content-box
        self:SetBorderBox(false);
    end
end
