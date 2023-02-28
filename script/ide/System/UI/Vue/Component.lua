--[[
Title: Component
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
local Component = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Vue/Component.lua");
-------------------------------------------------------
]]
local Element = NPL.load("../Window/Element.lua");
local Helper = NPL.load("./Helper.lua");
local Scope = NPL.load("./Scope.lua");
local ComponentScope = NPL.load("./ComponentScope.lua");
local Compile = NPL.load("./Compile.lua");

local Component = commonlib.inherit(Element, NPL.export());
local ComponentDebug = GGS.Debug.GetModuleDebug("Component");

Component:Property("Components");             -- 组件依赖组件集
Component:Property("ParentComponent");        -- 父组件
Component:Property("Scope");                  -- 组件Scope 
Component:Property("Compiled", false, "IsCompiled");              -- 是否编译

-- 全局组件
local GlobalComponentClassMap = {};
local XmlFileCache = {};

local function FormatXmlTemplate(template)
    -- 移除xml注释
    template = string.gsub(template, "<!%-%-.-%-%->", "");
    -- 维持脚本原本格式
    template = string.gsub(template, "[\r\n]<script(.-)>(.-)[\r\n]</script>", "<script%1>\n<![CDATA[\n%2\n]]>\n</script>");

    return template;
end

local function LoadXmlFile(filename)
    -- if (XmlFileCache[filename]) then return XmlFileCache[filename] end

    local template = Helper.ReadFile(filename) or "";
    template = FormatXmlTemplate(template);
    -- 缓存
    -- XmlFileCache[filename] = template;
    
    return template;
end

-- 是否是组件
function Component:IsComponent()
    return true;
end

-- 通过标签名获取组件元素类
function Component:GetElementByTagName(tagname)
    local ComponentClassMap = self:GetComponents();
    if (ComponentClassMap[tagname]) then return ComponentClassMap[tagname] end
    return Component._super.GetElementByTagName(self, tagname);
end

-- 组件构造函数
function Component:ctor()
    self:SetName("Component");

    self:SetComponents({});             -- 依赖组件集
    self.refs = {};
    self.slotXmlNodes = {};
    self.attrs = {};                    -- 组件属性
end

-- 初始化
function Component:Init(xmlNode, window, parent)
    self:SetWindow(window);
    self:SetParentElement(parent);
    self:SetXmlNode(xmlNode);
    self:LoadComponent(false);
    return self;
end

function Component:LoadComponent(isReload)
    local xmlNode, window, parent = self:GetXmlNode(), self:GetWindow(), self:GetParentElement();
    local htmlNode, scriptNodes, styleNodes, xmlRoot = self:LoadXmlNode(xmlNode, isReload);
    -- 清楚所有子元素
    self:ClearChildElement();
    -- 加载组件样式
    self:InitByStyleNode(styleNodes);
    -- 合并XmlNode
    self:InitByXmlNode(xmlNode, htmlNode);
    -- 初始化元素
    self:InitElement(xmlNode, window, parent);
    -- 初始化组件
    self:InitComponent(xmlNode);
    -- 解析script
    self:InitByScriptNode(scriptNodes);
    -- 初始化子元素  需要重写创建子元素逻辑
    self:InitChildElement(htmlNode, window);
    -- 初始化插槽
    self:InitSlotXmlNode(xmlNode);

    -- 如果是重新加载
    if (isReload) then
        self:SetCompiled(false);
        self:Attach();
        self:UpdateLayout(true);
    end
end

-- 初始化Slot
function Component:InitSlotXmlNode(xmlNode)
    -- slot attr 
    local slotXmlNodes = self.slotXmlNodes;
    local defaultSlot = {name = "template"};
    for _, childXmlNode in ipairs(xmlNode) do
        local slot = type(childXmlNode) == "table" and childXmlNode.attr and childXmlNode.attr.slot;
        if (slot) then
            slotXmlNodes[string.lower(slot)] = childXmlNode;
        else
            table.insert(defaultSlot, childXmlNode);
        end
    end
    slotXmlNodes.default = slotXmlNodes.default or defaultSlot;

    -- 设置Slot元素所属组件
    local function Slot(xmlNode)
        if (type(xmlNode) ~= "table") then return end
        if (string.lower(xmlNode.name) == "slot") then
            xmlNode.component = self;
        end
        for _, childXmlNode in ipairs(xmlNode) do
            Slot(childXmlNode);
        end
    end 
    Slot(xmlNode);
end

-- 初始化组件
function Component:InitComponent(xmlNode)
    -- 设置父组件
    local parentComponent = self:GetParentElement();
    while (parentComponent and not parentComponent:isa(Component)) do parentComponent = parentComponent:GetParentElement() end
    self:SetParentComponent(parentComponent);
    -- 初始化组件Scope
    local scope = ComponentScope.New(self);
    self:SetScope(scope);
end

-- 加载文件
function Component:LoadXmlNode(xmlNode, isReload)
    if (self.xmlRoot and not isReload) then return self.htmlNode, self.scriptNodes, self.styleNodes, self.xmlRoot end

    local filename, template = self.filename, self.template;
    if (self:class() == Component) then
        filename = self:GetAttrStringValue("src") or (xmlNode.attr and xmlNode.attr.src);
        template = self:GetAttrStringValue("template") or (xmlNode.attr and xmlNode.attr.template);
        self.filename, self.template = filename, template;
    end
    
    -- 从字符串加载
    local xmlRoot = nil;
    if (template and template ~= "") then
        template = FormatXmlTemplate(template);
        xmlRoot = type(template) == "table" and template or ParaXML.LuaXML_ParseString(template);
    elseif (filename and filename ~= "") then
        local template = LoadXmlFile(filename);
        xmlRoot = ParaXML.LuaXML_ParseString(template);
    end

    local htmlNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//template");
    local scriptNodes = xmlRoot and commonlib.XPath.selectNodes(xmlRoot, "//script");
    local styleNodes = xmlRoot and commonlib.XPath.selectNodes(xmlRoot, "//style");

    self.htmlNode, self.scriptNodes, self.styleNodes, self.xmlRoot = htmlNode, scriptNodes, styleNodes, xmlRoot;
    return htmlNode, scriptNodes, styleNodes, xmlRoot;
end

-- 获取局部样式表
function Component:GetElementScopedStyleSheet(element)
    return self:GetScopedStyleSheet();
end

-- 加载组件样式
function Component:InitByStyleNode(styleNodes)
    if (not styleNodes) then return end
    local styleText, scopedStyleText = "", "";
    for _, styleNode in ipairs(styleNodes) do
        local filename = styleNode.attr and styleNode.attr.src;
        local text = styleNode[1] or "";
        local filetext = Helper.ReadFile(filename) or "";
        text = text .. "\n" .. filetext;
        if (styleNode.attr and styleNode.attr.scoped == "true") then
            scopedStyleText = scopedStyleText .. text .. "\n";
        else 
            styleText = styleText .. text .. "\n";
        end
    end
    -- 强制使用css样式
    self:SetStyleSheet(self:GetWindow():GetStyleManager():GetStyleSheetByString(styleText));
    if (scopedStyleText ~= "") then self:SetScopedStyleSheet(self:GetWindow():GetStyleManager():GetStyleSheetByString(scopedStyleText)) end
    -- ComponentDebug.If(self:GetTagName() == "GoodsTooltip", "==============",scopedStyleText, styleText);
end

-- 合并XmlNode
function Component:InitByXmlNode(elementXmlNode, componentXmlNode)
    if (not elementXmlNode or not componentXmlNode) then return end
    local componentAttr = componentXmlNode.attr or {};
    local elementAttr = elementXmlNode.attr or {};
    self.attrs.style = self.attrs.style == nil and elementAttr.style or "";
    self.attrs.class = self.attrs.class == nil and elementAttr.class or "";
    commonlib.mincopy(elementAttr, componentAttr);
    elementAttr.style = (componentAttr.style or "") .. ";" .. self.attrs.style;
    elementAttr.class = (componentAttr.class or "") .. " " .. self.attrs.class;
    elementAttr.draggable = if_else(elementAttr.draggable == nil, componentAttr.draggable, elementAttr.draggable);
    elementXmlNode.attr = elementAttr;

    if (componentAttr.ref) then self:SetRef(componentAttr.ref, self) end

    return elementXmlNode;
end

-- 解析脚本节点
function Component:InitByScriptNode(scriptNodes)
    if (not scriptNodes) then return end
    local filename = nil;
    for _, scriptNode in ipairs(scriptNodes) do
        local scriptFile = scriptNode.attr and scriptNode.attr.src;
        local scriptText = scriptNode[1] or "";
        filename = Helper.FormatFilename(self.filename);
        scriptText = string.gsub(scriptText, "^%s*", "");
        if (scriptText ~= "") then
            scriptText = "-- " .. filename .. "\n" .. scriptText;        -- 第一行作为文件名 方便日志输出
            self:ExecCode(scriptText, filename);
        end
    
        local fileScriptText = Helper.ReadFile(scriptFile) or "";
        filename = Helper.FormatFilename(scriptFile);
        fileScriptText = string.gsub(fileScriptText, "^%s*", "");
        if (fileScriptText ~= "") then
            fileScriptText = "-- " .. filename .. "\n" .. fileScriptText;   -- 第一行作为文件名 方便日志输出
            self:ExecCode(fileScriptText, filename);
       end
    end
end

-- 元素加载到DOM之前
function Component:OnAfterChildAttach()
    Component._super.OnAfterChildAttach(self);
    
    -- 根组件直接编译
    local parentComponent = self:GetParentComponent();
    if (not parentComponent or parentComponent:IsCompiled()) then 
        self:Compile();
    end
end

-- 编译组件
function Component:Compile()
    if (self:IsCompiled()) then return end
    self:OnBeforeCompile();
    self:OnCompile();
    self:SetCompiled(true);
    local function CompileChildComponent(element) 
        for _, child in ipairs(element.childrens) do
            if (child:isa(Component)) then
                child:Compile();
            elseif (child.childrens) then
                CompileChildComponent(child);
            end
        end
    end
    CompileChildComponent(self);
    self:OnAfterCompile();
end

-- 编译回调
function Component:OnCompile()
    Compile(self);
end

-- 编译前回调
function Component:OnBeforeCompile()
end

-- 编译后回调
function Component:OnAfterCompile()
    local OnReady = self:GetScope():__get_data__()["OnReady"];
    if (type(OnReady) == "function") then
        self:ExecCode([[OnReady()]]);
    end
end

-- 刷新
function Component:Refresh()
    local OnRefresh = self:GetScope():__get_data__()["OnRefresh"];
    if (type(OnRefresh) == "function") then
        self:ExecCode([[OnRefresh()]]);
    end
    Component._super.Refresh(self);
end

-- 设置引用元素
function Component:SetRef(ref, element)
    self.refs[ref] = element;
end
-- 获取引用元素
function Component:GetRef(ref)
    return self.refs[ref];
end

-- 执行代码
function Component:ExecCode(code, filename) 
    if (type(code) ~= "string" or code == "") then return end
    local func, errmsg = loadstring(code, "loadstring:" .. (filename or ""));
    if (not func) then return ComponentDebug("===============================Exec Code Error=================================", errmsg, code) end

    setfenv(func, self:GetScope());
    -- return func();
    xpcall(function()
        func();
    end, function(errinfo) 
        print("ERROR:", errinfo)
        DebugStack();
    end);
end

-- 属性值更新
function Component:OnAttrValueChange(attrName, attrValue)
    if (self:class() == Component and (attrName == "template" or attrName == "src")) then
        self:LoadComponent(true);
        return;
    end

    Component._super.OnAttrValueChange(self, attrName, attrValue);
    local OnAttrValueChange = self:GetScope():__get_data__()["OnAttrValueChange"];
    if (type(OnAttrValueChange) == "function") then
        self:ExecCode(string.format([[OnAttrValueChange("%s", GetAttrValue("%s"))]], attrName, attrName));
    end
end

-- 全局注册组件
function Component:Register(tagname, tagclass)
    -- 验证组件类
    tagclass = Component.Extend(tagclass);

    -- 注册
    local Register = function (tagname, tagclass)
        tagname = string.lower(tagname);
        local ComponentClassMap = self:GetComponents();
        if (not tagclass) then
            return ComponentClassMap[tagname] or self:GetElementByTagName(tagname);
        end
        -- ComponentDebug.Format("注册组件: %s", tagname);
        ComponentClassMap[tagname] = tagclass;
        return tagclass;
    end

    if (type(tagname) == "string") then
        tagclass = Register(tagname, tagclass) or tagclass;
    elseif (type(tagname) == "table") then
        for i, tag in ipairs(tagname) do
            tagclass = Register(tag, tagclass) or tagclass;
        end
    else
        LOG:warn("无效组件:" .. tostring(tagname));
    end

    return tagclass
end

-- 定义组件
function Component.Extend(opts, bTemplate)
    -- 为字符串则默认为文件名
    if (type(opts) == "string") then 
        if (bTemplate) then
            opts = {template = opts} 
        else
            opts = {filename = opts} 
        end
    end
    
    -- 只接受table
    if (type(opts) ~= "table") then return end
    -- 已经是组件直接返回
    if (opts.isa and opts:isa(Component)) then return opts end
    -- 继承Component构造新组件
    local ComponentExtend = commonlib.inherit(Component, opts);
    -- 返回新组件
    return ComponentExtend;
end