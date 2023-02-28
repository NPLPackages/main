--[[
Title: Element
Author(s): wxa
Date: 2020/6/30
Desc: 元素类
use the lib:
-------------------------------------------------------
local Element = NPL.load("script/ide/System/UI/Window/Element.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local Rect = commonlib.gettable("mathlib.Rect");
local Point = commonlib.gettable("mathlib.Point");

local Style = NPL.load("./Style/Style.lua", IsDevEnv);
local Layout = NPL.load("./Layout/Layout.lua", IsDevEnv);
local ElementUI = NPL.load("./ElementUI.lua", IsDevEnv);
local Element = commonlib.inherit(ElementUI, NPL.export());

local ElementDebug = GGS.Debug.GetModuleDebug("ElementDebug").Enable();   --Enable  Disable
local ElementHoverDebug = GGS.Debug.GetModuleDebug("ElementHoverDebug").Enable();
local ElementFocusDebug = GGS.Debug.GetModuleDebug("ElementFocusDebug").Disable();

Element:Property("Window");                               -- 元素所在窗口
Element:Property("Attr", {});                             -- 元素属性
Element:Property("XmlNode");                              -- 元素XmlNode
Element:Property("ParentElement");                        -- 父元素
Element:Property("Layout");                               -- 元素布局
Element:Property("Style");                                -- 样式
Element:Property("AttrStyle");                            -- 属性样式表
Element:Property("StyleSheet");                           -- 元素样式表
Element:Property("ScopedStyleSheet");                     -- 局部元素样式表
Element:Property("BaseStyle");                            -- 默认样式, 基本样式
Element:Property("Selector");                             -- 选择器集
Element:Property("Rect");                                 -- 元素几何区域矩形
Element:Property("Name", "Element");                      -- 元素名
Element:Property("TagName", "");                          -- 标签名
Element:Property("ScrollBarStyle");                       -- 滚动条样式


-- 构造函数
function Element:ctor()
    self.childrens = {};                    -- 子元素列表
    self.ElementClassMap = {};              -- 元素类
    -- 设置布局
    self:SetLayout(Layout:new():Init(self));
    self:SetRect(Rect:new():init(0,0,0,0));
    self:SetSelector({});
    self:SetStyle(Style:new());
    self:SetAttrStyle({});
    self:SetScrollBarStyle({["scrollbar"] = {}, ["scrollbar-thumb"] = {}});
end

-- 转化为普通对象
function Element:ToPlainObject()
    return {
        Name = self:GetName(),
        TagName = self:GetTagName(),
        Rect = self:GetRect(),
        Attr = self:GetAttr(),
    }
end

-- 是否有效
function Element:IsValid()
    local window = self:GetWindow();
    -- 判断窗口是否有效
    if (not window or not window:GetNativeWindow()) then return false end   

    return self.attached;
    -- -- 判断元素是否有效
    -- local root = self;
    -- while (root:GetParentElement()) do root = root:GetParentElement() end
    -- return root == window;  -- 根元素为窗口元素则为有效
end

-- 是否是元素
function Element:IsElement()
    return true;
end

-- 是否是组件
function Element:IsComponent()
    return false;
end

-- 是否是窗口
function Element:IsWindow()
    return false;
end

-- 获取元素
function Element:GetElementByTagName(tagname)
    if (self.ElementClassMap[tagname]) then return self.ElementClassMap[tagname] end
    local parentElement = self:GetParentElement();
    if (parentElement) then return parentElement:GetElementByTagName(tagname) end
    return self:GetWindow():GetElementManager():GetElementByTagName(tagname);
end

-- 创建元素
function Element:CreateFromXmlNode(xmlNode, window, parent)
    if (type(xmlNode) == "string") then return self:GetWindow():GetElementManager():GetTextElement():new():Init(xmlNode, window, parent) end
    return self:GetElementByTagName(string.lower(xmlNode.name)):new():Init(xmlNode, window, parent);
end

-- 复制元素
function Element:Clone()
    local clone = self:new();
    clone.ElementClassMap = self.ElementClassMap;
    return clone:Init(commonlib.deepcopy(self:GetXmlNode()), self:GetWindow(), self:GetParentElement());
end

-- 元素初始化
function Element:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:InitChildElement(xmlNode, window);
    return self;
end

-- 初始化基本属性
function Element:InitElement(xmlNode, window, parent)
    -- 设置窗口
    self:SetWindow(window);
    -- 设置父元素
    self:SetParentElement(parent);
    -- 先清除子元素
    self:ClearChildElement();

    -- 设置元素属性
    self:SetAttr({});
    if (type(xmlNode) ~= "table") then 
        self:SetTagName("");
        self:SetXmlNode(xmlNode);
    else 
        self:SetTagName(xmlNode.name);
        self:SetXmlNode(xmlNode);
        if (type(xmlNode.attr) == "table") then
            for key, val in pairs(xmlNode.attr) do self:GetAttr()[key] = val end
        end
    end

    if (parent) then parent.ElementClassMap[self:GetTagName()] = self:class() end 

    self:SetAttrStyle(Style.ParseString(self:GetAttrStringValue("style")));
    -- if (self:GetAttrStringValue("id") == "test") then echo(self:GetAttrStyle()) end

    -- 初始化样式表
    if (not self:GetStyleSheet()) then
        self:SetStyleSheet(self:GetWindow():GetStyleManager():NewStyleSheet());
    end
    self:GetStyleSheet():SetInheritStyleSheet(parent and parent:GetStyleSheet());

    return self;
end

-- 初始化子元素
function Element:InitChildElement(xmlNode, window)
    if (not xmlNode) then return end
    -- 创建子元素
    for i, childXmlNode in ipairs(xmlNode) do
        local childElement = self:CreateFromXmlNode(childXmlNode, window, self);
        if (childElement) then 
            -- ElementDebug.FormatIf(self:GetTagName() == "Title" ,"InitChildElement Child Element Name = %s, TagName = %s", childElement:GetName(), childElement:GetTagName());
        else 
            ElementDebug("元素不存在", xmlNode);
        end
        -- self:InsertChildElement(childElement);
        table.insert(self.childrens, childElement);
        childElement:SetParentElement(self);
    end
end

-- 元素加载
function Element:LoadElement()
    self:OnLoadElementBeforeChild();

    self:OnLoadElement();
    for child in self:ChildElementIterator() do
        child:LoadElement();
    end

    self:OnLoadElementAfterChild();
end

function Element:OnLoadElementBeforeChild()
end

function Element:OnLoadElement()
end

function Element:OnLoadElementAfterChild()
end


-- 上一个兄弟元素
function Element:GetPrevSiblingElement()
    local parentElement = self:GetParentElement();
    if (not parentElement) then return end
    local prevSiblingElement = nil;
    for i, child in ipairs(parentElement.childrens) do
        if (child == self) then return prevSiblingElement end
        prevSiblingElement = if_else(child:IsExist(), child, prevSiblingElement);
    end
end

-- 下一个兄弟元素
function Element:GetNextSiblingElement()
    local parentElement = self:GetParentElement();
    if (not parentElement) then return end
    local nextSiblingElement = nil;
    for i = #self.childrens, 1, -1 do
        child = self.childrens[i];
        if (child == self) then return nextSiblingElement end
        nextSiblingElement = if_else(child:IsExist(), child, nextSiblingElement);
    end
end

-- 获取元素位置
function Element:GetChildElementIndex(childElement)    
    local index = 0;
    for _, child in ipairs(self.childrens) do 
        if (child:IsExist()) then index = index + 1 end
        if (child == childElement) then return index end 
    end
    return 0;
end

-- 获取元素位置
function Element:GetIndexInParentElement()
    local parentElement = self:GetParentElement();
    if (not parentElement) then return 0 end
    return parentElement:GetChildElementIndex(self);
end

-- 添加子元素
function Element:InsertChildElement(pos, childElement)
    local element = childElement or pos;
    -- 验证元素的有效性
    if (type(element) ~= "table" or not element.IsElement or not element:IsElement()) then return end
    -- 添加子元素
    if (childElement) then
        table.insert(self.childrens, pos, element);
    else 
        table.insert(self.childrens, element);
    end
    -- 设置子元素的父元素
    element:SetParentElement(self);

    -- 更新元素布局
    element:Attach();
end

-- 移除子元素
function Element:RemoveChildElement(pos)
    if (type(pos) == "table" and pos.IsElement and pos:IsElement()) then
        for i = 1, #self.childrens do
            if (self.childrens[i] == pos) then 
                table.remove(self.childrens, i);
                pos:SetParentElement(nil);
                pos:OnDetach();
                return;
            end
        end
    end
    pos = pos or self:GetChildElementCount();
    if (type(pos) ~= "number" or pos < 1 or pos > self:GetChildElementCount()) then return end
    local element = self.childrens[pos];
    table.remove(self.childrens, pos);
    if (element) then 
        element:Detach();
        element:SetParentElement(nil);
    end
end

-- 替换子元素
function Element:ReplaceChildElement(oldElement, newElement)
    local pos = self:GetChildElementIndex(oldElement);
    if (pos == 0) then return end
    oldElement:Detach();
    oldElement:SetParentElement(nil);
    self.childrens[pos] = newElement;
    newElement:Attach();
    newElement:SetParentElement(self);
end

-- 清除子元素
function Element:ClearChildElement()
    for _, child in ipairs(self.childrens) do
        child:Detach();
        child:SetParentElement(nil);
    end

    self.childrens = {};
end

-- 获取子元素数量
function Element:GetChildElementCount()
    return #self.childrens;
end

-- 获取子元素列表
function Element:GetChildElementList()
    return self.childrens;
end

-- 遍历 默认渲染序  false 事件序
function Element:ChildElementIterator(isRender, filter)
    local list = {};
    for _, child in ipairs(self.childrens) do
        if (child:IsExist()) then
            table.insert(list, child);
        end
    end

    isRender = isRender == nil or isRender;
    local function comp(child1, child2)
        local style1, style2 = child1:GetStyle() or {}, child2:GetStyle() or {};
        local zindex1, zindex2 = style1["z-index"] or 0, style2["z-index"] or 0;
        -- 函数返回true, 表两个元素需要交换位置
        local sort = zindex1 > zindex2;
        sort = sort or (style1.float ~= nil and style2.float == nil);
        sort = sort or (child1:GetLayout():IsPositionElement() and not child2:GetLayout():IsPositionElement());
        return if_else(isRender, sort, not sort);
    end
    -- table.sort(list, comp);
    -- 自行排序 table.sort 不稳定报错
    for i = 1, #list do
        for j = i + 1, #list do 
            if (comp(list[i], list[j])) then
                list[i], list[j] = list[j], list[i];
            end
        end
    end
    
    if (self.horizontalScrollBar) then table.insert(list, isRender and (#list + 1) or 1, self.horizontalScrollBar) end
    if (self.verticalScrollBar) then table.insert(list, isRender and (#list + 1) or 1, self.verticalScrollBar) end

    local i, size = 0, #list;
    local function iterator() 
        i = i + 1;
        
        if (i > size) then return end
        
        if (type(filter) == "function" and not filter(list[i])) then return iterator() end

        return list[i], i, size;
    end

    return iterator;
end

-- 元素添加至文档树
function Element:Attach()
    self:OnBeforeChildAttach();
	-- for child in self:ChildElementIterator() do
    for _, child in ipairs(self.childrens) do
        child:Attach();
    end
    -- 滚动条
    if (self.horizontalScrollBar) then self.horizontalScrollBar:Attach() end
    if (self.verticalScrollBar) then self.verticalScrollBar:Attach() end

    self:OnAttach();
    self:OnAfterChildAttach();
end


function Element:OnBeforeChildAttach()
    self:ApplyElementStyle();
end

-- 添加DOM树中
function Element:OnAttach()
    self.attached = true;
end

function Element:OnAfterChildAttach()
end

-- 元素脱离文档树
function Element:Detach()
    self:OnBeforeChildDetach();
    for _, child in ipairs(self.childrens) do
        child:Detach();
    end
    -- 滚动条
    if (self.horizontalScrollBar) then self.horizontalScrollBar:Detach() end
    if (self.verticalScrollBar) then self.verticalScrollBar:Detach() end

    self:OnDetach();
    self:OnAfterChildDetach();
end

function Element:OnBeforeChildDetach()
end

-- 从DOM树中移除
function Element:OnDetach()
    self.attached = false;
end

function Element:OnAfterChildDetach()
end

-- 获取局部样式表
function Element:GetElementScopedStyleSheet(element)
    return self:GetParentElement() and self:GetParentElement():GetElementScopedStyleSheet(element or self);
end

-- 创建样式
function Element:ApplyElementStyle()
    local parent = self:GetParentElement();
    local style = self:GetStyle();

    -- 设置继承样式
    style:Init(self:GetBaseStyle(), parent and parent:GetStyle());

    -- 全局样式表
    self:GetWindow():GetStyleManager():ApplyElementStyle(self, style);

    -- 元素样式表
    self:GetStyleSheet():ApplyElementStyle(self, style);
    -- ElementDebug.If(self:GetName() == "Text", "class", style);
    -- 局部样式表
    local scopedStyleSheet = self:GetElementScopedStyleSheet();
    if (scopedStyleSheet) then scopedStyleSheet:ApplyElementStyle(self, style) end 

    -- 内联样式
    style:AddNormalStyle(self:GetAttrStyle());

    -- 选择合适样式
    self:SelectStyle();

    -- 为元素添加动画
    self:GetWindow():GetStyleManager():ApplyElementAnimationStyle(self, style);
    self:GetStyleSheet():ApplyElementAnimationStyle(self, style);
    if (scopedStyleSheet) then scopedStyleSheet:ApplyElementAnimationStyle(self, style) end 
    self:GetAnimation():ApplyAnimationStyle();

    return;
end

-- 元素布局更新前回调
function Element:OnBeforeUpdateLayout()
end
-- 子元素布局更新前回调
function Element:OnBeforeUpdateChildLayout()
end
-- 子元素布局更新后回调
function Element:OnAfterUpdateChildLayout()
end
-- 元素布局更新回调
function Element:OnUpdateLayout()
end

-- 元素布局更新后回调
function Element:OnAfterUpdateLayout()
end

-- 更新布局, 先进行子元素布局, 再布局当前元素
function Element:UpdateLayout(bApplyElementStyle)
    -- 是否正在更新布局
    if (self.isUpdateLayout) then return end
    self.isUpdateLayout = true;
    
    -- ElementDebug.If(self:GetAttrValue("id") == "debug", "Update Layout", bApplyElementStyle);
    -- 生成元素样式
    if (bApplyElementStyle) then self:ApplyElementStyle() end

    -- 选择合适样式
    self:SelectStyle();

    -- 布局更新前回调
    if (self:OnBeforeUpdateLayout()) then 
        self.isUpdateLayout = false;
        return; 
    end

    -- 准备布局
    local layout = self:GetLayout();
    layout:PrepareLayout();

    -- 是否布局
    if (not layout:IsLayout()) then 
        self.isUpdateLayout = false;
        return; 
    end

    -- 子元素布局更新前回调
    local isUpdatedChildLayout = self:OnBeforeUpdateChildLayout();

    -- 执行子元素布局  子元素布局未更新则进行更新
    if (not isUpdatedChildLayout) then
        for childElement in self:ChildElementIterator() do
            -- ElementDebug.If(self:GetAttrValue("id") == "debug", "Child Update Layout", childElement:GetTagName(), childElement:GetName());
			childElement:UpdateLayout(bApplyElementStyle);
		end
    end
    
	-- 执行子元素布局后回调
    self:OnAfterUpdateChildLayout();

    -- 更新元素布局
    self:OnUpdateLayout();

    -- 调整布局
    local topLayout = self:GetLayout():Update();

    -- 元素布局更新后回调
    self:OnAfterUpdateLayout();
    
    -- 强制更新一次元素窗口坐标
    local parentElement = self:GetParentElement();
    -- 父元素不存在或父元素已布局完成
    if (not parentElement or not parentElement.isUpdateLayout) then 
        topLayout:GetElement():UpdateWindowPos(true);
        -- self:GetWindow():UpdateWindowPos(true); 
    end

    self.isUpdateLayout = false;
    return;
end

-- 真实内容大小更改
function Element:OnRealContentSizeChange()
    if (not self:GetWindow()) then return end
    local layout = self:GetLayout();
    if (not layout:IsEnableScroll()) then return end 

    -- 构建滚动条 这里只能使用Style 此时Layout不一定初始化
    local ScrollBar = self:GetWindow():GetElementManager().ScrollBar;
    if (layout:IsEnableScrollX()) then self.horizontalScrollBar = self.horizontalScrollBar or ScrollBar:new():Init({name = "ScrollBar", attr = {direction = "horizontal"}}, self:GetWindow(), self) end
    if (layout:IsEnableScrollY()) then self.verticalScrollBar = self.verticalScrollBar or ScrollBar:new():Init({name = "ScrollBar", attr = {direction = "vertical"}}, self:GetWindow(), self) end

    local width, height = layout:GetWidthHeight();
    local contentWidth, contentHeight = layout:GetContentWidthHeight();
    local realContentWidth, realContentHeight = layout:GetRealContentWidthHeight();

    if (self.horizontalScrollBar) then
        self.horizontalScrollBar:SetVisible(layout:IsCanScrollX());
        if (self.horizontalScrollBar:IsVisible()) then
            self.horizontalScrollBar:SetScrollWidthHeight(width, height, contentWidth, contentHeight, realContentWidth, realContentHeight);
        else 
            self.horizontalScrollBar:ScrollTo(0);
        end
    end

    if (self.verticalScrollBar) then
        self.verticalScrollBar:SetVisible(layout:IsCanScrollY());
        if (self.verticalScrollBar:IsVisible()) then
            self.verticalScrollBar:SetScrollWidthHeight(width, height, contentWidth, contentHeight, realContentWidth, realContentHeight);
        else 
            self.verticalScrollBar:ScrollTo(0);
        end
    end
end

function Element:GetHorizontalScrollBar()
    return self.horizontalScrollBar;
end

function Element:GetVerticalScrollBar()
    return self.verticalScrollBar;
end

function Element:OnScroll(scrollEl)
    self:UpdateWindowPos(true);

    self:CallAttrFunction("onscroll", nil, scrollEl);
end

-- 获取属性值
function Element:GetAttrValue(attrName, defaultValue)
    local attr = self:GetAttr();
    if (not attr) then return defaultValue end
    if (attr[attrName] == nil) then return defaultValue end
    return attr[attrName];
end

-- 获取数字属性值
function Element:GetAttrNumberValue(attrName, defaultValue)
    return tonumber(self:GetAttrValue(attrName)) or defaultValue;
end

-- 获取字符属性值
function Element:GetAttrStringValue(attrName, defaultValue)
    local value = self:GetAttrValue(attrName, defaultValue)
    return value ~= nil and tostring(value) or nil;
end

-- 获取布尔属性值
function Element:GetAttrBoolValue(attrName, defaultValue)
    local value = self:GetAttrValue(attrName);
    if (type(value) == "boolean") then return value end
    if (type(value) ~= "string") then return defaultValue end
    return value == "true";
end

-- 获取函数属性
function Element:GetAttrFunctionValue(attrName, defaultValue)
    local value = self:GetAttrValue(attrName, defaultValue);
    if (type(value) == "string") then
        local code_func, errmsg = loadstring(value);
        if (code_func) then
            setfenv(code_func, self:GetWindow():GetG());
            value = code_func;
        end
    end

    return type(value) == "function" and value or nil;
end

-- 调用事件函数
function Element:CallAttrFunction(attrName, defaultValue, ...)
    local func = self:GetAttrFunctionValue(attrName, defaultValue);
    if (not func) then return nil end
    return self:GetWindow():GetG().Call(func, ...);
end

-- 样式属性值改变
function Element:OnAttrStyleValueChange(attrValue, oldAttrValue)
    if (attrValue == nil) then return end
    oldAttrValue = self:GetAttrStyle();
    -- ElementDebug(attrValue, oldAttrValue, tostring(attrValue), tostring(oldAttrValue), commonlib.compare(attrValue, oldAttrValue));
    if (commonlib.compare(attrValue, oldAttrValue)) then return end
    local style = type(attrValue) == "string" and Style.ParseString(attrValue) or commonlib.copy(attrValue);
    self:SetAttrStyle(style);
    self:ApplyElementStyle();
    self:UpdateLayout(false);
end

-- 样式类属性值改变
function Element:OnAttrClassValueChange(attrValue, oldAttrValue)
    if (attrValue == nil) then return end
    if (commonlib.compare(attrValue, oldAttrValue)) then return end
    self:UpdateLayout(true);
end

-- 元素属性值更新
function Element:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    if (attrName == "style") then self:OnAttrStyleValueChange(attrValue, oldAttrValue) end
    if (attrName == "class") then self:OnAttrClassValueChange(attrValue, oldAttrValue) end
end

-- 设置属性值
function Element:SetAttrValue(attrName, attrValue)
    local attr = self:GetAttr();
    local oldAttrValue = attr[attrName];
    attr[attrName] = attrValue;
    if (type(attrValue) ~= "table" and oldAttrValue == attrValue) then return end
    self:OnAttrValueChange(attrName, attrValue, oldAttrValue);
end

-- 设置样式值
function Element:SetStyleValue(styleKey, styleValue)
    local style = self:GetStyle();
    local value = Style.GetStyleValue(styleKey, styleValue);
    style[styleKey] = value;
    style:GetNormalStyle()[styleKey] = value;
    self:GetAttrStyle()[styleKey] = value;
    return ;
end

-- 获取元素计算样式
function Element:GetComputedStyle()
    local curStyle = self:GetStyle();
    local layout = self:GetLayout();
    local style = {};
    for key, val in pairs(curStyle) do
        if (type(val) ~= "table" and type(val) ~= "function") then
            style[key] = val;
        end
    end
    style["min-width"], style["min-height"] = layout:GetMinWidthHeight();
	style["max-width"], style["max-height"] = layout:GetMaxWidthHeight();
    style["margin-top"], style["margin-right"], style["margin-bottom"], style["margin-left"] = layout:GetMargin();
    style["padding-top"], style["padding-right"], style["padding-bottom"], style["padding-left"] = layout:GetPadding();
    style.top, style.right, style.bottom, style.left = layout:GetPosition();
    style.left, style.top, style.width, style.height = self:GetGeometry();
    style.display = style.display or "block";
    -- echo(style, true);
    return style;
end

-- 获取内联文本
function Element:GetInnerText()
    local function GetInnerText(xmlNode)
        if (not xmlNode) then return "" end
        if (type(xmlNode) == "string") then return xmlNode end
        -- if (type(xmlNode) == "table" and type(xmlNode.value) == "string") then return xmlNode.value end
        local text = "";
        for _, childXmlNode in ipairs(xmlNode) do
            text = text .. GetInnerText(childXmlNode);
        end 
        return text;
    end
    return GetInnerText(self:GetXmlNode());
end

-- 遍历每个元素
function Element:ForEach(callback)
    local function forEach(element)
        local bExit = callback(element);
        if (bExit ~= nil) then return bExit end
        for child in element:ChildElementIterator() do
            bExit = forEach(child);
            if (bExit ~= nil) then return bExit end
        end
    end
    return forEach(self);
end

function Element:GetElements(attrName, attrValue)
    local list = {};

    self:ForEach(function(element)
        if (element:GetAttrValue(attrName) == attrValue) then
            table.insert(list, element);
        end
    end);

    return list;
end

-- 获取元素通过名称
function Element:GetElementsByName(name)
    return self:GetElements("name", name);
end

-- 获取元素通过Id
function Element:GetElementsById(id)
    return self:GetElements("id", id);
end

-- 获取元素通过Id
function Element:GetElementById(id)
    return self:GetElementsById(id)[1];
end

-- 获取定位元素
function Element:GetPositionElements()
    local list = {};
    local function GetPositionElements(element)
        if (element:GetLayout():IsPositionElement()) then
            table.insert(list, element);
        end
        for childElement in element:ChildElementIterator(false) do
            GetPositionElements(childElement);
        end
    end
    GetPositionElements(self);
    return list;
end

-- 当前元素是否是指定元素的祖先
function ElementUI:IsAncestorOf(element)
    while (element and element ~= self) do
        element = element:GetParentElement();
    end
    return element == self;
end