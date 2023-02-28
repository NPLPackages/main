--[[
Title: Json
Author(s): wxa
Date: 2020/6/30
Desc: 对象字段
use the lib:
-------------------------------------------------------
local Json = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Json.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");

local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

local Json = commonlib.inherit(Field, NPL.export());

function Json:OnBeginEdit()
    local text = self:GetText();

    Page.Show({
        title = "Json 编辑",
        text = text == "" and self:GetValue() or self:GetText(),

        confirm = function(value)
            self:SetText(value);
            -- 识别 JSON 有效性
            local json = commonlib.Json.Decode(value);
            -- print(value);
            -- echo(json, true);
            if (not json) then
                self:SetValue(commonlib.Json.Encode({}));
                self:SetLabel("无效 JSON 对象");
            else
                self:SetValue(commonlib.Json.Encode(json));
                self:SetLabel(self:GetValue());
            end
            
            self:FocusOut();
        end,

        close = function()
            self:FocusOut();
        end
    }, {
        url = "%ui%/Blockly/Pages/FieldEditTextArea.html",
        draggable = false,
    });
end
