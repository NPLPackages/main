--[[
Title: Style
Author(s): wxa
Date: 2020/6/30
Desc: 布局类
use the lib:
-------------------------------------------------------
local Layout = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Layout/Layout.lua");
-------------------------------------------------------
]]

local BaseLayout = NPL.load("./BaseLayout.lua", IsDevEnv);
local Flex = NPL.load("./Flex.lua", IsDevEnv);

local Layout = commonlib.inherit(BaseLayout, NPL.export());

local LayoutDebug = GGS.Debug.GetModuleDebug("LayoutDebug").Disable(); --Enable  Disable

-- 初始化
function Layout:Init(element)
	Layout._super.Init(self, element);
	return self;
end

-- 处理布局准备工作, 单位数字化
function Layout:PrepareLayout()
	Layout._super.PrepareLayout(self);
	
	-- 获取父元素布局
    local parentLayout = self:GetParentLayout();
	
	-- 窗口元素 直接设置宽高
	if (not parentLayout and self:GetElement():IsWindow()) then
		local x, y, w, h = self:GetWindowPosition();
		self:SetPos(x or 0, y or 0);
		self:SetWidthHeight(w or 0, h or 0);
		self:SetFixedSize(true);
		return ;
	end
	
	-- 获取父元素宽高
	local parentWidth, parentHeight = nil, nil;
	if (parentLayout) then
		-- 百分比统一使用内容宽高
		if (self:IsPositionElement()) then
			parentWidth, parentHeight = parentLayout:GetWidthHeight();
		else
			parentWidth, parentHeight = parentLayout:GetContentWidthHeight();
		end

		if (not parentLayout:IsFixedSize()) then
			parentWidth = parentLayout:IsFixedWidth() and parentWidth or nil;
			parentHeight = parentLayout:IsFixedHeight() and parentHeight or nil;
		end
	end

    -- 获取元素样式
	local style = self:GetStyle();
   	-- 数字最大最小宽高
	local minWidth, minHeight, maxWidth, maxHeight = style["min-width"], style["min-height"], style["max-width"], style["max-height"];
	minWidth = self:PercentageToNumber(minWidth, parentWidth);
	maxWidth = self:PercentageToNumber(maxWidth, parentWidth);
	minHeight = self:PercentageToNumber(minHeight, parentHeight);
    maxHeight = self:PercentageToNumber(maxHeight, parentHeight);
    self:SetMinWidthHeight(minWidth, minHeight);
    self:SetMaxWidthHeight(maxWidth, maxHeight);

    -- 数字化边距
	local marginTop, marginRight, marginBottom, marginLeft = style["margin-top"], style["margin-right"], style["margin-bottom"], style["margin-left"];
	marginRight = self:PercentageToNumber(marginRight, parentWidth) or 0;
	marginTop = self:PercentageToNumber(marginTop, parentWidth) or 0;
	marginBottom = self:PercentageToNumber(marginBottom, parentWidth) or 0;
	marginLeft = self:PercentageToNumber(marginLeft, parentWidth) or 0;
    self:SetMargin(marginTop, marginRight, marginBottom, marginLeft);
    
    -- 数字化边框
	local borderTop, borderRight, borderBottom, borderLeft = style["border-top-width"], style["border-right-width"], style["border-bottom-width"], style["border-left-width"];
	borderRight = self:PercentageToNumber(borderRight, parentWidth) or 0;
	borderTop = self:PercentageToNumber(borderTop, parentWidth) or 0;
    borderBottom = self:PercentageToNumber(borderBottom, parentWidth) or 0;
	borderLeft = self:PercentageToNumber(borderLeft, parentWidth) or 0;
    self:SetBorder(borderTop, borderRight, borderBottom, borderLeft);

	-- 数字化填充
	local paddingTop, paddingRight, paddingBottom, paddingLeft = style["padding-top"], style["padding-right"], style["padding-bottom"], style["padding-left"];
	paddingRight = self:PercentageToNumber(paddingRight, parentWidth) or 0;
	paddingTop = self:PercentageToNumber(paddingTop, parentWidth) or 0;
    paddingBottom = self:PercentageToNumber(paddingBottom, parentWidth) or 0;
	paddingLeft = self:PercentageToNumber(paddingLeft, parentWidth) or 0;
    self:SetPadding(paddingTop, paddingRight, paddingBottom, paddingLeft);
    
	-- 数字化宽高
	local width, height = style.width, style.height;     
	                                                                                                   -- 支持百分比, px
	-- 块元素默认为父元素宽
	if (self:IsBlockElement() and not self:IsPositionElement() and not width and parentLayout and not parentLayout:IsFlexElement()) then width = parentWidth end  
	width = self:PercentageToNumber(width, parentWidth);
    height = self:PercentageToNumber(height, parentHeight);
	if (style["box-sizing"] == "content-box" and style.width) then
		self:SetWidthHeight(width and (width + paddingLeft + paddingRight + borderLeft + borderRight), height and (height + paddingTop + paddingBottom + borderTop + borderBottom));
	else
		self:SetWidthHeight(width, height);
	end

	if (width and height) then self:SetFixedSize(true) end
	if (width) then self:SetFixedWidth(true) end
	if (height) then self:SetFixedHeight(true) end

	-- 最大最小宽高
	minWidth, minHeight = style["min-width"], style["min-height"];
	minWidth = self:PercentageToNumber(minWidth, parentWidth);
	minHeight = self:PercentageToNumber(minHeight, parentHeight);
	self:SetMinWidthHeight(minWidth, minHeight);
	maxWidth, maxHeight = style["max-width"], style["max-height"];
	maxWidth = self:PercentageToNumber(maxWidth, parentWidth);
	maxHeight = self:PercentageToNumber(maxHeight, parentHeight);
	self:SetMaxWidthHeight(maxWidth, maxHeight);

	-- 数字化位置
	local left, top, right, bottom = style.left, style.top, style.right, style.bottom;
	left = self:PercentageToNumber(left, parentWidth);
	right = self:PercentageToNumber(right, parentWidth);
	top = self:PercentageToNumber(top, parentHeight);
	bottom = self:PercentageToNumber(bottom, parentHeight);
	self:SetPosition(top, right, bottom, left);

	-- 父元素是固定大小
	if (parentWidth and parentHeight and self:IsPositionElement()) then
		self:ApplyPositionStyle();
		local width, height = self:GetWidthHeight();
		if (width and height) then self:SetFixedSize(true) end
		if (width) then self:SetFixedWidth(true) end
		if (height) then self:SetFixedHeight(true) end
	end
	
    LayoutDebug.If(
		self:GetElement():GetAttrValue("id") == "debug",
        "PrepareLayout TagName = " .. self:GetTagName() ..  " ElementName = " .. self:GetName(), 
        string.format("Element nid = %s, width = %s, height = %s", self.nid, width, height),
        parentLayout and string.format("ParentElement nid = %s, width = %s, height = %s", parentLayout.nid, parentWidth, parentHeight)
    );
end


-- 应用CSS的定位样式
function Layout:ApplyPositionStyle()
	local style = self:GetStyle();
	local width, height = self:GetWidthHeight();
	local marginTop, marginRight, marginBottom, marginLeft = self:GetMargin();
	local WindowX, WindowY, WindowWidth, WindowHeight = self:GetWindowPosition();
	local top, right, bottom, left = self:GetPosition()
	local float, position  = style.float, style.position;
	-- 浮动与定位不共存
	if (float or not position or position == "static") then return end
	-- 相对定位
	if (position == "relative") then return end  -- self:OffsetPos(left or 0, top or 0)
	
	-- 计算定位
	local relLayout = self:GetParentLayout();
	
	if (position == "absolute") then
		-- 绝对定位 取已定位的父元素
		-- while (relLayout and relLayout:GetParentLayout()) do
		-- 	local relStyle = relLayout:GetStyle();
		-- 	if (relStyle.position and (relStyle.position == "relative" or relStyle.position == "absolute" or relStyle.position == "fixed")) then break end
		-- 	relLayout = relLayout:GetParentLayout();
		-- end
	elseif (position == "fixed") then
		-- 固定定位 取根元素
		relLayout = self:GetRootLayout();
	end

	local relWidth, relHeight = nil, nil;
	if (relLayout) then relWidth, relHeight = relLayout:GetWidthHeight() end
	relWidth, relHeight = relWidth or 0, relHeight or 0;
	if (right and width and not left) then left = relWidth - right - width end
	if (bottom and height and not top) then top = relHeight - bottom - height end
	if (not width and left and right) then width = relWidth - left - right end 
	if (not height and top and bottom) then height = relHeight - top - bottom end 
	if (width and left) then right = relWidth - left - width end
	if (height and top) then bottom = relHeight - top - height end
	
	left, top = left or 0, top or 0;
	right, bottom = right or 0, bottom or 0;
	self:SetPos(left + marginLeft, top + marginTop);
	self:SetPosition(top, right, bottom, left);
	-- LayoutDebug.FormatIf(self:GetElement():GetAttrValue("id") == "debug", 
	-- 	"ApplyPositionStyle, name = %s, left = %s, top = %s, right = %s, bottom = %s, width = %s, height = %s, relWidth = %s, relHeight = %s, parentLayoutId = %s", 
	-- 	self:GetTagNameAndName(), left, top, right, bottom, width, height, relWidth, relHeight, self:GetParentLayout().nid);
	self:SetWidthHeight(width and math.max(width, 0), height and math.max(height, 0));
end

-- 更新布局  返回向上传递的终止布局对象
function Layout:Update(isUpdateWidthHeight)
	local width, height = self:GetWidthHeight();
	local maxWidth, maxHeight = self:GetMaxWidthHeight();
	local minWidth, minHeight = self:GetMinWidthHeight();
    local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
    local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();

	-- 更新真实内容大小 由所有子元素决定
	self:UpdateRealContentWidthHeight();
	local realContentWidth, realContentHeight = self:GetRealContentWidthHeight();

	if (isUpdateWidthHeight) then
		width = if_else(self:IsFixedWidth(), width, realContentWidth + paddingLeft + paddingRight + borderLeft + borderRight);
		height = if_else(self:IsFixedHeight(), height, realContentHeight + paddingTop + paddingBottom + borderTop + borderBottom);
	else
		width = width or (realContentWidth + paddingLeft + paddingRight + borderLeft + borderRight);
		height = height or (realContentHeight + paddingTop + paddingBottom + borderTop + borderBottom);
	end

	width, height = math.min(width, maxWidth or width), math.min(height, maxHeight or height);
	width, height = math.max(width, minWidth or width), math.max(height, minHeight or height);
	self:SetWidthHeight(width, height);

	-- 应用定位方式获取宽高
	self:ApplyPositionStyle();

	LayoutDebug.FormatIf(self:GetElement():GetAttrValue("id") == "debug", 
		"Layout Update Name = %s, width = %s, height = %s, IsFixedSize = %s, realContentWidth = %s, realContentHeight = %s",
		self:GetTagNameAndName(), width, height, self:IsFixedSize(), realContentWidth, realContentHeight);
	-- 再次回调
	self:GetElement():OnRealContentSizeChange();
	
	-- 设置布局完成
	self:SetLayoutFinish(true);
	
	-- 返回终止布局
	if (not self:IsUseSpace()) then return self end

	-- 子元素更新完成, 当父元素存在,非固定宽高时, 需要更新父布局使其有正确的宽高 
	local parentLayout = self:GetParentLayout();
	-- 父布局存在且在布局中则直接跳出
	if (parentLayout and not parentLayout:IsLayoutFinish()) then return self end
	-- 父布局存在且不为固定宽高则需更新父布局重新计算宽高 
	if (parentLayout and not parentLayout:IsFixedSize()) then return parentLayout:Update(true) end
	-- 父布局存在且为固定宽高则直接更新父布局的真实宽高即可
	if (parentLayout and parentLayout:IsFixedSize()) then return parentLayout:UpdateRealContentWidthHeight() end

	return self;
end

function Layout:UpdateRealContentWidthHeight()
	local display = self:GetStyle().display;
	if (display == "flex" or display == "inline-flex") then
		return self:UpdateFlexLayoutRealContentWidthHeight();
	else
		return self:UpdateBoxLayoutRealContentWidthHeight();
	end
end

function Layout:UpdateFlexLayoutRealContentWidthHeight()
	return Flex.Update(self);
end

-- 更新盒子内容宽高
function Layout:UpdateBoxLayoutRealContentWidthHeight()
	local availableX, availableY, rightAvailableX, rightAvailableY, realContentWidth, realContentHeight = 0, 0, 0, 0, 0, 0;
	local width, height = self:GetWidthHeight();
	local element = self:GetElement();
	local isFalseWidth = false;

	if (not width) then
		width = 1000000; -- 虚拟出假宽度
		isFalseWidth = true;
	end

	-- 渲染序
	for child in element:ChildElementIterator(true) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle();
		local childLeft, childTop = 0, 0;
		local childMarginTop, childMarginRight, childMarginBottom, childMarginLeft = childLayout:GetMargin();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();
		local childWidth, childHeight = childLayout:GetWidthHeight();
		local isRightFloat = childStyle.float == "right";
		if (childLayout:IsLayout() and childLayout:IsUseSpace()) then
			LayoutDebug.If(
				true and element:GetAttrValue("id") == "debug",
				string.format("[%s] Layout Add ChildLayout Before ", self:GetTagNameAndName()),
				string.format("Layout availableX = %s, availableY = %s, realContentWidth = %s, realContentHeight = %s, width = %s, height = %s", availableX, availableY, realContentWidth, realContentHeight, width, height),
				-- string.format("child margin: %s, %s, %s, %s", childMarginTop, childMarginRight, childMarginBottom, childMarginLeft), childStyle,
				string.format("[%s] childLeft = %s, childTop = %s, childSpaceWidth = %s, childSpaceHeight = %s, childWidth = %s, childHeight = %s", childLayout:GetTagName(), childLeft, childTop, childSpaceWidth, childSpaceHeight, childWidth, childHeight)
			);
			if (not childLayout:IsBlockElement()) then
				-- 内联元素
				if ((width - availableX - rightAvailableX) < childSpaceWidth) then
					-- 新起一行
					if (isRightFloat) then
						childLeft, childTop = (width - childSpaceWidth + childMarginLeft), realContentHeight + childMarginTop;
						availableX, availableY = 0, realContentHeight;
						rightAvailableX, rightAvailableY = childSpaceWidth, realContentHeight;
					else
						childLeft, childTop = childMarginLeft, realContentHeight + childMarginTop;
						availableX, availableY = childSpaceWidth, realContentHeight;
						rightAvailableX, rightAvailableY = 0, realContentHeight;
					end
				else 
					-- 同行追加
					if (isRightFloat) then
						childLeft, childTop = (width - rightAvailableX - childSpaceWidth + childMarginLeft), rightAvailableY + childMarginTop;
						availableX, availableY = availableX, availableY;
						rightAvailableX, rightAvailableY = rightAvailableX + childSpaceWidth, rightAvailableY;
					else
						childLeft, childTop = availableX + childMarginLeft, availableY + childMarginTop;
						availableX, availableY = availableX + childSpaceWidth, availableY;
						rightAvailableX, rightAvailableY = rightAvailableX, rightAvailableY;
					end
				end
				realContentWidth = if_else(realContentWidth > (availableX + rightAvailableX), realContentWidth, availableX + rightAvailableX);
				local newHeight = availableY + childSpaceHeight;
				realContentHeight = if_else(newHeight > realContentHeight, newHeight, realContentHeight)
			else 
				-- 块元素 新起一行
				childLeft, childTop = childMarginLeft, realContentHeight + childMarginTop;
				availableX, availableY = 0, realContentHeight + childSpaceHeight;    -- 可用位置X坐标置0 取最大Y坐标
				rightAvailableX, rightAvailableY = availableX, availableY;
				realContentWidth = if_else(childSpaceWidth > realContentWidth, childSpaceWidth, realContentWidth);
				realContentHeight = availableY;
			end
			childLayout:SetPos(childLeft, childTop);
			LayoutDebug.If(
				true and element:GetAttrValue("id") == "debug",
				string.format("[%s] Layout Add ChildLayout After ", self:GetTagNameAndName()),
				string.format("Layout availableX = %s, availableY = %s, realContentWidth = %s, realContentHeight = %s, width = %s, height = %s", availableX, availableY, realContentWidth, realContentHeight, width, height),
				string.format("[%s] childLeft = %s, childTop = %s, childSpaceWidth = %s, childSpaceHeight = %s", childLayout:GetTagNameAndName(), childLeft, childTop, childSpaceWidth, childSpaceHeight)
			);
		end
	end
	local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
	local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();
	LayoutDebug.If(
		element:GetAttrValue("id") == "debug",
		string.format("children count = %s, TagName = %s", #element.childrens, self:GetTagNameAndName()),
		string.format("paddingTop = %s, paddingRight = %s, paddingBottom = %s, paddingLeft = %s, borderTop = %s, borderRight = %s, borderBottom = %s, borderLeft = %s", paddingTop, paddingRight, paddingBottom, paddingLeft, borderTop, borderRight, borderBottom, borderLeft)
	);
	-- 假宽度右浮动元素需要调整
	for child in element:ChildElementIterator(true) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle(); 
		local left, top = childLayout:GetPos();
		if (childStyle.float == "right") then
			if (isFalseWidth) then left = left - width + realContentWidth end
			left = left - paddingRight - borderRight;
		else
			left = left + paddingLeft + borderLeft;
		end
		top = top + paddingTop + borderTop;
		if (not childLayout:IsPositionElement()) then
			childLayout:SetPos(left, top);
		end
		LayoutDebug.If(
			element:GetAttrValue("id") == "debug",
			string.format("[%s] Adjust Pos Left = %s, Top = %s ", childLayout:GetTagNameAndName(), left, top)
		);
	end

	-- 设置内容宽高
	self:SetRealContentWidthHeight(realContentWidth, realContentHeight);

	return self;
end


