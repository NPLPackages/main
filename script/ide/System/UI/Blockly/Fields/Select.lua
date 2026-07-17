--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Select = NPL.load("script/ide/System/UI/Blockly/Fields/Select.lua");
-------------------------------------------------------
]]
local DivElement = NPL.load("../../Window/Elements/Div.lua");
local InputElement = NPL.load("../../Window/Elements/Input.lua");
local SelectElement = NPL.load("../../Window/Elements/Select.lua");
local Const = NPL.load("../Const.lua");
local Options = NPL.load("../Options.lua");
local Field = NPL.load("./Field.lua");

local Select = commonlib.inherit(Field, NPL.export());

function Select:Init(block, option)
    Select._super.Init(self, block, option);

    local options = option.options;
    if (options == nil) then
        self:SetSelectType(self:GetName());
        self:SetAllowNewSelectOption(true);
    elseif (type(options) == "string" and not Options[options]) then
        self:SetSelectType(options);
    elseif (type(options) == "table" and options.selectType) then
        self:SetSelectType(options.selectType);
        self:SetAllowNewSelectOption(options.isAllowCreate)
    else
        self:SetSelectType(option.selectType);
    end

    -- self:OnValueChanged(nil, nil)
    return self;
end

function Select:SetFieldValue(value)
    value = Select._super.SetFieldValue(self, value);
    self:SetLabel(self:GetLabelByValue(self:GetValue()));
end

function Select:GetFieldEditType()
    return "select";
end

function Select:GetOptions(bRefresh)
    local selectType = self:GetSelectType();
    if (not selectType) then return Select._super.GetOptions(self, bRefresh) end
    local blockly = self:GetBlockly();
    local select_options = blockly.__select_options__ or {};
    blockly.__select_options__ = select_options;
    if (selectType == "VARIABLE" and not select_options[selectType]) then
        local global_options = self:GetGlobalVaribaleNameMap();
        local options = {};
        for varname in pairs(global_options) do
            table.insert(options, {varname, varname});
        end
        table.sort(options, function(item1, item2)
            return item1[1] < item2[1];
        end);
        select_options[selectType] = options;
    end
   
    select_options[selectType] = select_options[selectType] or {};
    return select_options[selectType];
end

function Select:OnValueChanged(newValue, oldValue)
    local selectType = self:GetSelectType();
    if (not selectType or not self:IsAllowNewSelectOption()) then return end

    local UpdateBlockMap, ValueExistMap = {}, {};
    local label = self:GetLabel();
    local options = self:GetOptions();
    local index, size = 1, #options;
    self:GetBlockly():ForEachUI(function(blockInputField)
        if (blockInputField:GetSelectType() ~= selectType) then return end
        -- 更新字段值
        if (oldValue and not blockInputField:IsAllowNewSelectOption() and blockInputField:GetValue() == oldValue) then
            -- print("======================", oldValue, newValue)
            blockInputField:SetValue(newValue);
            blockInputField:SetLabel(label);
            UpdateBlockMap[blockInputField:GetTopBlock()] = true;
        end
        -- 更新选项集
        if (blockInputField:IsAllowNewSelectOption()) then
            local value = blockInputField:GetValue();
            if (value and value ~= "" and not ValueExistMap[value]) then
                options[index] = {value, value};
                index = index + 1;
                ValueExistMap[value] = true;
            end
        end
    end)

    if (selectType == "VARIABLE") then
        local global_options = self:GetGlobalVaribaleNameMap();
        for varname in pairs(global_options) do
            if (not ValueExistMap[varname]) then
                options[index] = {varname, varname};
                index = index + 1;
                ValueExistMap[varname] = true;
            end
        end
    end

    for i = index, size do
        options[i] = nil;
    end
    
    table.sort(options, function(item1, item2)
        return item1[1] < item2[1];
    end);

    for block in pairs(UpdateBlockMap) do
        block:UpdateLayout();
    end
end

function Select:OnUI(eventName, eventData)
    if (eventName == "LoadXmlTextToWorkspace") then
        if (not self:GetSelectType()) then return end
        
        local value = self:GetValue();
        local options = self:GetOptions();
        local isExist = false;
        for _, option in ipairs(options) do 
            if (option[2] == value) then
                isExist = true;
                break;
            end
        end
        if (not isExist and value and value ~= "") then
            table.insert(options, {value, value});
        end
    end
end

function Select:GetGlobalVaribaleNameMap()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
    local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
    local entities = EntityManager.FindEntities({category="b", }) or {};
    local varnames = {};
    for _, entity in ipairs(entities) do
        if(entity.FindFile) then
            local bFound, filename, filenames = entity:FindFile([[set("]])
            if (bFound and filename) then
                local varname = string.match(filename, 'set%("([^"]+)');
                if (varname) then
                    varnames[varname] = true;
                end
            end
        end
    end
    return varnames;
end
