--[[
Title: ComponentScope
Author(s): wxa
Date: 2020/6/30
Desc: 组件脚本执行环境
use the lib:
-------------------------------------------------------
local ComponentScope = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/ComponentScope.lua");
-------------------------------------------------------
]]

local Scope = NPL.load("./Scope.lua");

local ComponentScope = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ComponentScope:Property("Component"); -- 所属组件
ComponentScope:Property("Scope");     -- 所属Scope

local exclude_scope_methods = {
    ["New"] = true,
    ["ctor"] = true,
    ["Init"] = true,
}

function ComponentScope.New(component)
    local G = component:GetWindow():GetG();
    local scope = Scope:__new__(); 
    local _scope = ComponentScope:new():Init(component, scope);
    local parentComponent = component:GetParentComponent();
    
    scope.self = scope;
    scope:__set_metatable_index__(parentComponent and parentComponent:GetScope() or G.GetGlobalScope());

    for method in pairs(ComponentScope) do
        if (type(rawget(ComponentScope, method)) == "function" and not exclude_scope_methods[method]) then
            rawset(scope,method, function(...) 
                return _scope[method](_scope, ...);
            end)
        end
    end
   
    return scope;
end

function ComponentScope:ctor(component, scope)
    
end

function ComponentScope:Init(component, scope)
    self:SetComponent(component);
    self:SetScope(scope);
    return self;
end

function ComponentScope:Watch(varname, callback)
    local scope = self:GetScope();
    scope:Watch(varname, callback);
end

function ComponentScope:SetArguments(...)
    self.args = table.pack(...);
end

function ComponentScope:GetArguments()
    return table.unpack(self.args);
end

function ComponentScope:RegisterComponent(tagname, filename)
    self:GetComponent():Register(tagname, filename);
end

function ComponentScope:GetRef(refname) 
    return self:GetComponent():GetRef(refname);
end

function ComponentScope:GetAttr()
    return self:GetComponent():GetAttr();
end

function ComponentScope:SetAttrValue(attrName, attrValue) 
    self:GetComponent():SetAttrValue(attrName, attrValue);
end

function ComponentScope:CallAttrFunction(funcname, ...)
    self:GetComponent():CallAttrFunction(funcname, nil, ...);
end

function ComponentScope:GetAttrValue(attrName, defaultValue, valueType) 
    if (valueType == "string") then return self:GetComponent():GetAttrStringValue(attrName, defaultValue)
    elseif (valueType == "number") then return self:GetComponent():GetAttrNumberValue(attrName, defaultValue)
    elseif (valueType == "boolean") then return self:GetComponent():GetAttrBoolValue(attrName, defaultValue)
    elseif (valueType == "function") then return self:GetComponent():GetAttrFunctionValue(attrName, defaultValue)
    else return self:GetComponent():GetAttrValue(attrName, defaultValue) end
end

function ComponentScope:GetAttrStringValue(attrName, defaultValue)
    return self:GetComponent():GetAttrStringValue(attrName, defaultValue);
end

function ComponentScope:GetAttrNumberValue(attrName, defaultValue)
    return self:GetComponent():GetAttrNumberValue(attrName, defaultValue);
end

function ComponentScope:GetAttrBoolValue(attrName, defaultValue)
    return self:GetComponent():GetAttrBoolValue(attrName, defaultValue);
end

function ComponentScope:GetAttrFunctionValue(attrName, defaultValue)
    return self:GetComponent():GetAttrFunctionValue(attrName, defaultValue);
end


