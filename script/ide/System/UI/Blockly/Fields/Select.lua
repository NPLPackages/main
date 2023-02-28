--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Select = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Select.lua");
-------------------------------------------------------
]]
local DivElement = NPL.load("../../Window/Elements/Div.lua", IsDevEnv);
local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);
local SelectElement = NPL.load("../../Window/Elements/Select.lua", IsDevEnv);
local Const = NPL.load("../Const.lua");
local Options = NPL.load("../Options.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Select = commonlib.inherit(Field, NPL.export());
local select_options = {};

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