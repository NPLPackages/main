--[[
Title: Directive
Author(s): wxa
Date: 2020/6/30
Desc: 组件指令解析器
use the lib:
-------------------------------------------------------
local Compile = NPL.load("script/ide/System/UI/Vue/Compile.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
local Helper = NPL.load("./Helper.lua");
local Scope = NPL.load("./Scope.lua");
local Table = NPL.load("./Table.lua");
local Compile = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local CompileDebug = GGS.Debug.GetModuleDebug("CompileDebug").Enable();   --Enable  Disable

local BeginTime, EndTime = Helper.BeginTime, Helper.EndTime;
-- local EventNameMap = {["onclick"] = true, ["onmousedown"] = true, ["onmousemove"] = true, ["onmouseup"] = true};
local DependItems = {};
local AllDependItemWatch = {};
local DependItemUpdateQueue = {};
local DependItemUpdateMap  = {};
local IsActivedDependItemUpdate = false;

local CallBackFunctionListCache = {};
local ElementListCache = {};

local function ClearDependItemUpdateQueue()
    -- print("======================开始更新依赖项==============================");
    local BeginTime = ParaGlobal.timeGetTime();
    -- 获取更新依赖项
    local dependItemCount = 0;
    for dependItem in pairs(DependItemUpdateQueue) do 
        dependItemCount = dependItemCount + 1;
        DependItemUpdateMap[dependItemCount] = dependItem;
    end
    -- CompileDebug.Format("需要更新的依赖项数: %s", dependItemCount);
    if (dependItemCount == 0) then return end

    -- 清除无效元素监听
    for dependItem, elements in pairs(AllDependItemWatch) do
        local invalueElementCount = 0;
        for element, _ in pairs(elements) do
            if (not element:IsValid()) then
                invalueElementCount = invalueElementCount + 1;
                ElementListCache[invalueElementCount] = element;
                -- CompileDebug.Format("无效依赖元素:", element:GetAttr());
            end
        end
        for i = 1, invalueElementCount do
            elements[ElementListCache[i]] = nil;
            ElementListCache[i] = nil;
        end
    end
    local clearElementTime = ParaGlobal.timeGetTime() - BeginTime;
    -- CompileDebug(DependItemUpdateMap);
    -- 提取回调函数
    local callbackFunctionCount = 0;
    for i = 1, dependItemCount do
        local dependItem = DependItemUpdateMap[i];
        DependItemUpdateQueue[dependItem] = nil;   -- 清除更新
        DependItemUpdateMap[i] = nil;
        local elements = AllDependItemWatch[dependItem];
        -- CompileDebug.If(string.match(dependItem, "%[isAuthUser%]"), objects);
        for element, watchs in pairs(elements) do
            for code, watch in pairs(watchs) do
                callbackFunctionCount = callbackFunctionCount + 1;
                CallBackFunctionListCache[callbackFunctionCount] = watch;
                -- CompileDebug.Format("更新回调: %s, %s", code, callbackFunctionCount);
            end
        end
    end
    local getCallbackTime = ParaGlobal.timeGetTime() - BeginTime;
    -- 触发回调
    for i = 1, callbackFunctionCount do
        local func = CallBackFunctionListCache[i];
        CallBackFunctionListCache[i] = nil;
        func();
    end

    local EndTime = ParaGlobal.timeGetTime();
    -- print(string.format("响应更新耗时: %sms, 更新依赖项数: %s, 触发回调函数: %s, 清除无效元素耗时: %sms, 提取回调函数耗时: %sms", EndTime - BeginTime, dependItemCount, callbackFunctionCount, clearElementTime, getCallbackTime));
    -- print("======================结束更新依赖项==============================");
end

-- local ClearDependItemTimer = commonlib.Timer:new({callbackFunc = function() 
--     IsActivedDependItemUpdate = false;
--     ClearDependItemUpdateQueue();
-- end});

NPL.this(function()
    IsActivedDependItemUpdate = false;
    ClearDependItemUpdateQueue();
end, {filename = "script/ide/System/UI/Vue/Compile/DependItemUpdate"});

local function GenerateDependItem(obj, key)
    if (key == nil) then return tostring(obj) end
    return  tostring(obj) .. "[" .. tostring(key) .. "]";
end

Scope.__set_global_index__(function(obj, key)
    -- CompileDebug.Format("__Index key = %s, obj = %s", key, tostring(obj));
    DependItems[GenerateDependItem(obj, key)] = true;
end)

Scope.__set_global_newindex__(function(obj, key, newVal, oldVal)
    local dependItem = GenerateDependItem(obj, key);
    -- CompileDebug.Format("__NewIndex key = %s, dependItem = %s, newVal = %s, oldVal = %s", key, dependItem, newVal, oldVal);
    if (not AllDependItemWatch[dependItem]) then return end
    -- CompileDebug.Format("标记待更新: __NewIndex key = %s, dependItem = %s, newVal = %s, oldVal = %s", key, dependItem, newVal, oldVal);
    DependItemUpdateQueue[dependItem] = true;

    -- 是否已激活更新, 已经激活忽略
    if (IsActivedDependItemUpdate) then return end
    -- 激活更新
    IsActivedDependItemUpdate = true;
    -- CompileDebug.Format("开始清除依赖更新队列");
    -- ClearDependItemTimer:Change(20);
    NPL.activate("script/ide/System/UI/Vue/Compile/DependItemUpdate"); 
end)

local function ExecCode(code, func, element, watch)
    DependItems = {};                                                                                        -- 清空依赖集
    -- local oldVal = func();
    local oldVal = nil;
    local ok, errinfo = pcall(function()
        oldVal = func();
    end, function() 
        DebugStack();
    end);

    if (not ok) then
        GGS.ERROR("===============执行代码出错=============", errinfo, code);
        return nil;
    end

    local OldDependItems = {};
    local oldValLen = Table.len(oldVal);
    local oldValCache = nil;
    if (oldValLen > 0) then
        oldValCache = {};
        for i = 1, oldValLen do
            oldValCache[i] = oldVal[i];
        end
    end
    -- CompileDebug.If(code == "UserDetail", code, DependItems);
    if (element and type(watch) == "function") then
        for dependItem in pairs(DependItems) do
            OldDependItems[dependItem] = true;                                                               -- 备份依赖项 
            AllDependItemWatch[dependItem] = AllDependItemWatch[dependItem] or {};                           -- 依赖项的对象集
            AllDependItemWatch[dependItem][element] = AllDependItemWatch[dependItem][element] or {};         -- 对象的监控集
            AllDependItemWatch[dependItem][element][code] = function()                                       -- 监控集项
                -- local BeginTime = ParaGlobal.timeGetTime();
                -- 先清除
                for dependItem in pairs(OldDependItems) do
                    AllDependItemWatch[dependItem] = AllDependItemWatch[dependItem] or {};                    -- 依赖项的对象集
                    AllDependItemWatch[dependItem][element] = AllDependItemWatch[dependItem][element] or {};  -- 对象的监控集
                    AllDependItemWatch[dependItem][element][code] = nil;
                end
                -- 获取新值
                local newVal = ExecCode(code, func, element, watch);
                -- 相同退出
                -- if (type(newVal) == "table") then
                --     CompileDebug.Format('code = %s, isEqual = %s, #newval = %s, #oldval = %s', code, newVal == oldVal, #newVal, oldValSize);
                -- end

                -- print("ExecCode", code, oldVal, newVal)

                -- if (type(newVal) ~= "table" and newVal == oldVal) then return end
                if (newVal == oldVal) then
                    if (type(newVal) ~= "table") then return end
                    -- 如果为数组, 则每个元素值应相同
                    if (Table.len(newVal) == oldValLen) then
                        local isEqual = true;
                        for i = 1, oldValLen do
                            if (oldValCache[i] ~= newVal[i]) then
                                isEqual = false;
                                break;
                            end
                        end
                        if (isEqual) then return end
                    end
                end
                -- if (newVal == oldVal and (type(newVal) ~= "table" or Table.len(newVal) == oldValLen)) then return end
                
                -- 不同触发回调
                watch(newVal, oldVal);
                -- print(string.format("依赖监控, code = %s 耗时: %sms", code, ParaGlobal.timeGetTime() - BeginTime));
            end
        end
    end
    return oldVal;
end

function Compile:ctor()
    self.scope = nil;
    self.component = nil;
end

function Compile:GetScope()
    return self.scope;
end

function Compile:SetScope(scope)
    -- CompileDebug.Format("lastScopeId = %s scopeId = %s", self.scope and self.scope.__id__ or 0, scope and scope.__id__ or 0);
    self.scope = scope;
end

function Compile:PushScope(scope)
    scope = Scope:__new__(scope);
    scope:__set_metatable_index__(self:GetScope());
    self:SetScope(scope);
    return scope;
end

function Compile:PopScope()
    local scope = self:GetScope();
    scope = scope and scope:__get_metatable_index__();
    self:SetScope(scope);
end

function Compile:SetComponent(component)
    self.component = component;
end

function Compile:GetComponent()
    return self.component;
end

function Compile:ExecCode(code, element, watch, isExecWatch)
    if (type(code) ~= "string" or code == "") then return end

    local func, errmsg = loadstring("return (" .. code .. ")");
    if (not func) then return CompileDebug("Exec Code Error: " .. errmsg) end

    -- CompileDebug.Format("ComponentTagName = %s, ElementTagName = %s, ScopeId = %s", self:GetComponent():GetTagName(), object and object:GetTagName(), self:GetScope().__id__);
    setfenv(func, self:GetScope());

    local val = ExecCode(code, func, element, watch);
    if (isExecWatch and type(watch) == "function") then watch(val) end

    return val;
end

-- 移除监控
function Compile:UnWatch(element)
    if (not element) then return end
    for key, watch in pairs(AllDependItemWatch) do
        AllDependItemWatch[key][element] = nil;
    end
end

-- 移除元素的监控
function Compile:UnWatchElement(element)
    self:UnWatch(element);
    for childElement in element:ChildElementIterator() do
        self:UnWatchElement(childElement);
    end
end

-- text
function Compile:Text(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "string") then return end
    local args = ""
    local text = string.gsub(xmlNode, "{{(.-)}}", function(code)
        args = args .. ", " .. code;
        return "%s";
    end);
    local code = string.format([==[string.format([[%s]]%s)]==], text, args);
    self:ExecCode(code, element, function(value)
        element:SetText(value);
    end, true);
end

-- ref
function Compile:Ref(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["ref"] == nil) then return end
    self:GetComponent():SetRef(xmlNode.attr["ref"], element);
end

-- v-show 
function Compile:VShow(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-show"] == nil) then return end
    self:ExecCode(xmlNode.attr["v-show"], element, function(val)
        element:SetVisible(val and true or false);
        local parentElement = element:GetParentElement();
        if (not xmlNode.compiling and parentElement and not self:IsRefresh()) then parentElement:UpdateLayout() end
    end, true);
end

-- v-if
function Compile:VIf(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-if"] == nil) then return end
    local vif = true;
    local curElement = element;
    local parentElement = element:GetParentElement();
    local ifComponent = self:GetComponent();
    local ifScope = self:GetScope();

    self:ExecCode(xmlNode.attr["v-if"], element, function(val)
        val = val and true or false;
        if (val) then
            -- 没有必要重新编译元素
            -- if (not vif) then
            --     local newElement = curElement:Clone();
            --     local oldComponent = self:GetComponent();
            --     local oldScope = self:GetScope();
            --     self:SetComponent(ifComponent);
            --     self:SetScope(ifScope);
            --     -- self:UnWatchElement(curElement);
            --     self:CompileElement(newElement);
            --     parentElement:ReplaceChildElement(curElement, newElement);
            --     curElement = newElement;
            --     self:SetComponent(oldComponent);
            --     self:SetScope(oldScope);
            -- end
            curElement:SetVisible(true);
        else
            curElement:SetVisible(false);
        end
        vif = val;
        if (not xmlNode.compiling and parentElement and not self:IsRefresh()) then parentElement:UpdateLayout(true) end
    end, true);
end

-- v-for
function Compile:VFor(element)
    -- if System.os.GetPlatform() == 'mac' then
    --     self:VFor_MACOS(element)
    --     return
    -- end

    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-for"] == nil) then return end
    local vfor = xmlNode.attr["v-for"];

    local inIndex = string.find(vfor, " in ", 1, true);
    if (not inIndex) then return end 
    local keyexp = string.sub(vfor, 1, inIndex -1);
    local listexp = string.sub(vfor, inIndex + 4);

    local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w+)");
    if (not val) then val = string.gsub(keyexp, "[,%s]*$", "") end
    key = key or "index";

    local lastCount, clones, scopes = 0, {}, {};
    local parentElement = element:GetParentElement();
    local pos = parentElement:GetChildElementIndex(element);
    local forComponent = self:GetComponent();
    local forScope = self:GetScope();
    local forTimer = nil; 
    local forWindow = element:GetWindow();
    element:SetVisible(false);
    self:ExecCode(listexp, element, function(list)
        -- BeginTime();
        list = type(list) == "function" and list() or list;
        local count = type(list) == "number" and list or (type(list) == "table" and Table.len(list) or 0);
        -- CompileDebug.Format("VFor ComponentTagName = %s, ComponentId = %s, key = %s, val = %s, listexp = %s, List Count = %s, element = %s", forComponent:GetTagName(), forComponent:GetAttrValue("id"), key, val, listexp, count, tostring(element));
        local oldComponent = self:GetComponent();
        local oldScope = self:GetScope();
        local curIndex = 0;
        local lastShowIndex = 0;
        if (forTimer) then forTimer:Change(nil, nil) end
        for _, clone in ipairs(clones) do
            parentElement:RemoveChildElement(clone);
        end
        forTimer = commonlib.Timer:new({callbackFunc = function()
            if (curIndex >= count or forWindow:IsDestroy()) then
                forTimer:Change(nil, nil);
                forTimer = nil;
                lastCount = count;
                return;
            end
            curIndex = curIndex + 1;
            local isNeedCompile = false;
            if (not clones[curIndex]) then
                clones[curIndex] = element:Clone();
                isNeedCompile = true;
            end

            local clone = clones[curIndex];
            clone:SetVisible(true);
            -- 移除监控
            clone:GetXmlNode().attr["v-for"] = nil;
            -- self:UnWatchElement(clone);
            -- 构建scope数据
            local scope = scopes[curIndex] or {};
            if (val ~= key) then scope[key] = curIndex end 
            if (type(list) == "table") then
                scope[val] = list[curIndex];
            else
                scope[val] = curIndex; 
            end
            -- 设置起始scope
            self:SetComponent(forComponent);
            self:SetScope(forScope);
            -- 压入新scope
            scopes[curIndex] = self:PushScope(scope);
            -- EndTime("复制元素", true)
            -- 编译新元素
            if (isNeedCompile) then
                self:CompileElement(clone);
            end
            -- EndTime("编译元素", true);
            -- 添加至dom树
            parentElement:InsertChildElement(pos + curIndex, clone);
            clone:SetVisible(false);
            -- 弹出scope栈
            self:PopScope();
            self:SetComponent(oldComponent);
            self:SetScope(oldScope);
            if ((curIndex % 20) == 0 or curIndex == count) then
                for i = lastShowIndex + 1, curIndex do
                    clones[i]:SetVisible(true);
                end
                lastShowIndex = curIndex;
                parentElement:UpdateLayout(true);
            end
        end});
        forTimer:Change(0, 20);
        -- for i = 1, count do
        --     -- self:GetComponent():SetCompiled(false);
        --     clones[i] = clones[i] or element:Clone();
        --     local clone = clones[i];
        --     -- 移除监控
        --     clone:GetXmlNode().attr["v-for"] = nil;
        --     -- self:UnWatchElement(clone);
        --     -- 构建scope数据
        --     local scope = scopes[i] or {};
        --     if (val ~= key) then scope[key] = i end 
        --     if (type(list) == "table") then
        --         scope[val] = list[i];
        --     else
        --         scope[val] = i; 
        --     end
        --     -- 设置起始scope
        --     self:SetComponent(forComponent);
        --     self:SetScope(forScope);
        --     -- 压入新scope
        --     scopes[i] = self:PushScope(scope);
        --     -- EndTime("复制元素", true)
        --     -- 新元素
        --     if (i > lastCount) then 
        --         -- 编译新元素
        --         self:CompileElement(clone);
        --         -- EndTime("编译元素", true);

        --         -- 添加至dom树
        --         parentElement:InsertChildElement(pos + i, clone);

        --         -- EndTime("添加元素", true);
        --     end
        --     -- 弹出scope栈
        --     self:PopScope();
        --     self:SetComponent(oldComponent);
        --     self:SetScope(oldScope);
        -- end
        -- -- 移除多余元素
        -- for i = count + 1, lastCount do
        --     -- self:UnWatchElement(clones[i]);
        --     parentElement:RemoveChildElement(clones[i]);
        --     clones[i] = nil;
        --     scopes[i] = nil;
        -- end
        -- lastCount = count;
        -- if (not xmlNode.compiling and not self:IsRefresh()) then
        --     parentElement:UpdateLayout(true);
        -- end
    end, true);
    return true;
end

function Compile:VFor_MACOS(element)
    local xmlNode = element:GetXmlNode();

    if (type(xmlNode) ~= "table" or
        not xmlNode.attr or
        xmlNode.attr["v-for"] == nil) then
        return
    end

    local vfor = xmlNode.attr["v-for"];

    local inIndex = string.find(vfor, " in ", 1, true);
    
    if (not inIndex) then return end 

    local keyexp = string.sub(vfor, 1, inIndex -1);
    local listexp = string.sub(vfor, inIndex + 4);

    local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w+)");

    if (not val) then
        val = string.gsub(keyexp, "[,%s]*$", "")
    end

    key = key or "index";

    local lastCount, clones, scopes = 0, {}, {};
    local parentElement = element:GetParentElement();
    local pos = parentElement:GetChildElementIndex(element);
    local forComponent = self:GetComponent();
    local forScope = self:GetScope();

    element:SetVisible(false);

    self:ExecCode(listexp, element, function(list)
        list = type(list) == "function" and list() or list;
        local count = type(list) == "number" and list or (type(list) == "table" and Table.len(list) or 0);

        local oldComponent = self:GetComponent();
        local oldScope = self:GetScope();

        local i = 1
        local curTimer
        local RemoveUseLessElement

        curTimer = commonlib.Timer:new({
            callbackFunc = function()
                if i > count then
                    curTimer:Change(nil, nil)

                    for s_i = 1, count do
                        if clones[s_i] then
                            clones[s_i]:SetVisible(true)
                        end
                    end

                    for i = count + 1, lastCount do
                        -- self:UnWatchElement(clones[i]);
                        parentElement:RemoveChildElement(clones[i]);
                        clones[i] = nil;
                        scopes[i] = nil;
                    end

                    lastCount = count;

                    if (not xmlNode.compiling) then
                        parentElement:UpdateLayout(true);
                    end

                    return
                end

                if (i % 20) == 0 then
                    for s_i = 1, count do
                        if clones[s_i] then
                            clones[s_i]:SetVisible(true)
                        end
                    end

                    parentElement:UpdateLayout(true);
                end

                -- self:GetComponent():SetCompiled(false);
                clones[i] = clones[i] or element:Clone();
                local clone = clones[i];
                
                -- 移除监控
                clone:GetXmlNode().attr["v-for"] = nil;
                -- self:UnWatchElement(clone);
                
                -- 构建scope数据
                local scope = scopes[i] or {};
                if (val ~= key) then scope[key] = i end 
                
                if (type(list) == "table") then
                    scope[val] = list[i];
                else
                    scope[val] = i; 
                end
                
                -- 设置起始scope
                self:SetComponent(forComponent);
                self:SetScope(forScope);
                
                -- 压入新scope
                scopes[i] = self:PushScope(scope);
                
                -- 新元素
                if (i > lastCount) then 
                    -- 编译新元素
                    self:CompileElement(clone);

                    -- 添加至dom树
                    clone:SetVisible(false)
                    parentElement:InsertChildElement(pos + i, clone);
                end

                -- 弹出scope栈
                self:PopScope();
                self:SetComponent(oldComponent);
                self:SetScope(oldScope);

                i = i + 1
            end
        })

        curTimer:Change(0, 10)
    end, true);

    return true;
end

-- v-on:event=function
function Compile:VOn(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr) then return end
    for key, val in pairs(xmlNode.attr) do
        local realKey = string.match(key, "^v%-on:(%S+)");
        local realVal = val;
        if (not realKey or realKey == "") then realKey = string.match(key, "^on(%S+)") end
        if (realKey and realKey ~= "" and type(val) == "string") then 
            local isFuncExpr = string.match(val, "^%s*%a[%a%d%_]*%s*$");  -- 若为一个变量名则直接取其值
            local code_str = string.format("return function(...)\n\t%s\nend", val .. (isFuncExpr and "(...)" or ""));
            local code_func, errmsg = loadstring(code_str);
            if (code_func) then
                -- 这里使用合适的作用作用域
                setfenv(code_func, self:GetScope());
                realVal = code_func();
            else
                realVal = function() echo("null function") end;
            end
            element:SetAttrValue("on" .. realKey, realVal);
        end
    end
end

-- v-bind
function Compile:VBind(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr) then return end
    -- CompileDebug.If(xmlNode.attr.id == "test", xmlNode.attr);
    for key, val in pairs(xmlNode.attr) do
        local realKey = string.match(key, "^v%-bind:(.+)");
        local realVal = nil;
        if (realKey and realKey ~= "") then
            self:ExecCode(val, element, function(realVal)
                -- CompileDebug.If(realKey == "itemid", realVal);
                if (Scope:__is_scope__(realVal)) then realVal = realVal:ToPlainObject() end
                -- if (type(realVal) == "table" and realVal.ToPlainObject) then realVal = realVal:ToPlainObject() end
                element:SetAttrValue(realKey, realVal);
                -- CompileDebug.If(realKey == "NextPagePorjectList", element:GetAttrValue("NextPagePorjectList"));
            end, true);
        end
    end
end

-- v-model
function Compile:VModel(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-model"] == nil) then return end
    local vmodel = xmlNode.attr["v-model"];
    if (not string.match(vmodel, "^%a[%w%.]*$")) then return end
    local scope = self:GetScope();
    self:ExecCode(vmodel, element, function(val)
        if (Scope:__is_scope__(val)) then val = val:ToPlainObject() end
        element:SetAttrValue("value", val);
    end, true);
    -- 注意死循环
    element:SetAttrValue("onchange", function(val)
        element:GetAttr()["value"] = val;
        local keys = commonlib.split(vmodel, "%.");
        local subscope, size = scope, #keys;
        for i = 1, size - 1 do subscope = subscope[keys[i]] end
        if (Scope:__is_scope__(subscope[keys[size]])) then
            -- subscope[keys[size]]:__set_data__(val);
        else 
            subscope[keys[size]] = val;
        end
    end);
end

function Compile:IsComponent(element)
    return element.IsComponent and element:IsComponent();
end

function Compile:CompileElement(element)
    local isComponent = self:IsComponent(element);
    local isCurrentComponentElement = self:GetComponent() == element;
    local xmlNode = element:GetXmlNode();

    if (not isCurrentComponentElement) then
        -- local BeginTime = ParaGlobal.timeGetTime();

        -- 设置为编译中
        if (type(xmlNode) == "table") then xmlNode.compiling = true end

        if (self:VFor(element)) then
            -- 编译完成
            if (type(xmlNode) == "table") then xmlNode.compiling = false end
            return;
        end

        self:Text(element);
        self:Ref(element);
        self:VShow(element);  
        self:VIf(element);
        self:VOn(element);
        self:VBind(element);
        self:VModel(element);

        -- 编译完成
        if (type(xmlNode) == "table") then xmlNode.compiling = false end
        
        -- local EndTime = ParaGlobal.timeGetTime();
        -- local UseTime = EndTime - BeginTime;
        -- if (UseTime > 10) then
        --     print("编译元素耗时: ", ParaGlobal.timeGetTime() - BeginTime)
        --     CompileDebug(element:GetAttr());
        -- end
    end

    if (isComponent and not isCurrentComponentElement) then return end

    -- 编译子元素
    for childElement in element:ChildElementIterator() do
        self:CompileElement(childElement);
    end

end

function Compile:Compile(compoent)
    -- CompileDebug.Format("=====================begin compile component [%s]=================", compoent:GetTagName());
    self:SetComponent(compoent);
    self:SetScope(compoent:GetScope());
    self:CompileElement(compoent);
    self:SetComponent(nil);
    self:SetScope(nil);
    -- CompileDebug.Format("=====================end compile component [%s]=================", compoent:GetTagName());
end

function Compile:RefreshWindow(window)
    self:SetRefresh(true);
    for _, elements in pairs(AllDependItemWatch) do
        for element, callbacks in pairs(elements) do
            if (element:GetWindow() == window) then
                for _, callback in pairs(callbacks) do
                    callback();
                end
            end
        end
    end
    self:SetRefresh(false);
    window:UpdateLayout(true);
end

function Compile:SetRefresh(bRefresh)
    self.__is_refresh__ = bRefresh;
end

function Compile:IsRefresh()
    return self.__is_refresh__;
end

function Compile:RefreshElement(element)
    local all_refresh_element = {};

    local function GetRefreshElement(element) 
        all_refresh_element[element] = true;
        for _, child in ipairs(element.childrens) do
            GetRefreshElement(child);
        end
    end

    GetRefreshElement(element);

    self:SetRefresh(true);
    for _, elements in pairs(AllDependItemWatch) do
        for element, callbacks in pairs(elements) do
            if (all_refresh_element[element]) then
                for _, callback in pairs(callbacks) do
                    callback();
                end
            end
        end
    end
    self:SetRefresh(false);

    element:UpdateLayout(true);
end

local metatable = getmetatable(Compile);
metatable.__call = function(self, ...)
    self:Compile(...);
end

-- 初始化成单列模式
Compile:InitSingleton();