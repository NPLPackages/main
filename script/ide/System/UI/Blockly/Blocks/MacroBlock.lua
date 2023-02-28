NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
local Encoding = commonlib.gettable("System.Encoding");

local MacroBlock = NPL.export();

local function GetPlayerAndCaremaMacroText()
    local code = "";
    local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
    code = code .. string.format("CameraMove(%s, %s, %s)\n", camobjDist, LiftupAngle, CameraRotY);
	local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();
    code = code .. string.format("CameraLookat(%s, %s, %s)\n", lookatX, lookatY, lookatZ);
    local player = GameLogic.EntityManager.GetPlayer();
    if (not player) then return end
    local bx, by, bz = player:GetBlockPos();
    local facing = player:GetFacing();
    code = code .. string.format("PlayerMoveTrigger(%s, %s, %s, %s)\n", bx, by, bz, facing);
    code = code .. string.format("PlayerMove(%s, %s, %s, %s)\n", bx, by, bz, facing);
    return code;
end

local NPL_Macro_Start = {};
function NPL_Macro_Start.ToMacroCode(block)
    return "SetMacroOrigin(nil, nil, nil)";
end

function NPL_Macro_Start.ToCode()
    return "";
end

local NPL_Macro_SetSceneView = {};
local function NPL_Macro_SetSceneView_SceneView_Field_Click_Callback(field)
    local value = field:GetValue();
    field:SetValue(GetPlayerAndCaremaMacroText());
    field:SetLabel(Encoding.sha1(field:GetValue(), "base64"));
    if (field:GetValue() ~= value) then
        field:GetTopBlock():UpdateLayout();
        field:GetBlockly():OnChange();
    end
end

function NPL_Macro_SetSceneView.OnInit(option)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    for _, field in ipairs(arg) do
        if (field.type == "field_button" and field.name == "SceneView") then
            field.OnClick = NPL_Macro_SetSceneView_SceneView_Field_Click_Callback;
            field.value = GetPlayerAndCaremaMacroText();
            field.label = Encoding.sha1(field.value, "base64");
            break;
        end
    end
end

function NPL_Macro_SetSceneView.ToMacroCode(block)
    return block:GetFieldValue("SceneView");
end

function NPL_Macro_SetSceneView.ToCode()
    return "";
end

local NPL_Macro_SceneClick = {};
local function NPL_Macro_SceneClick_Angle_Field_Click_Callback(field)
    local oldValue, oldLabel = field:GetValue(), field:GetLabel();
    local value = GetPlayerAndCaremaMacroText();
    local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
    Page.Show({
        OnFinish = function(x, y)
            GameLogic.Macros:Init();
            local angleX, angleY = GameLogic.Macros.GetSceneClickParams(x, y);
            local label = string.format("%.6f, %.6f", angleX, angleY);
            field:SetLabel(label);
            field:SetValue(value);
            if (oldValue ~= value or oldLabel ~= label) then
                field:GetTopBlock():UpdateLayout();
                field:GetBlockly():OnChange();
            end
        end
    }, {
        url = "%ui%/Blockly/Pages/SceneClick.html",  
        width = "100%", 
        height = "100%", 
        zorder = 100,
        draggable = false,
    });
   
end

function NPL_Macro_SceneClick.OnInit(option)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    for _, field in ipairs(arg) do
        if (field.type == "field_button" and field.name == "Angle") then
            field.OnClick = NPL_Macro_SceneClick_Angle_Field_Click_Callback;
            field.value, field.label = "", "0, 0";
            break;
        end
    end
end

function NPL_Macro_SceneClick.ToMacroCode(block)
    local fieldButton = block:GetFieldValue("Buttons");
    local fieldAngleValue = block:GetFieldValue("Angle");
    local fieldAngleLabel = block:GetField("Angle"):GetLabel();
    return fieldAngleValue .. string.format('SceneClickTrigger("%s", %s)\nSceneClick("%s", %s)\n', fieldButton, fieldAngleLabel, fieldButton, fieldAngleLabel);
end

function NPL_Macro_SceneClick.ToCode()
    return "";
end


local NPL_Macro_Finished = {};
function NPL_Macro_Finished.ToMacroCode()
    return 'Broadcast("macroFinished")';
end

function NPL_Macro_Finished.ToCode()
    return "";
end

local NPL_Macro_UIClick = {};
local NPL_Macro_UIClick_Action_Options = {
    {"运行", "CodeBlockWindow.run"},
    {"关闭", "CodeBlockWindow.saveAndClose"},
}
function NPL_Macro_UIClick.OnInit(option)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    for _, field in ipairs(arg) do
        if (field.name == "Action") then
            field.value = "CodeBlockWindow.run";
            field.options = NPL_Macro_UIClick_Action_Options;
            break;
        end
    end
end

function NPL_Macro_UIClick.ToMacroCode(block)
    local fieldAction = block:GetFieldValue("Action");
    return string.format([[
ButtonClickTrigger("%s","left")
ButtonClick("%s","left")
]], fieldAction, fieldAction);
end

function NPL_Macro_UIClick.ToCode()
    return "";
end

local NPL_Macro_Text = {}
function NPL_Macro_Text.ToMacroCode(block) 
    local TEXT = block:GetFieldValue("TEXT");
    local DURATION = block:GetFieldValue("DURATION");
    local POS = block:GetFieldValue("POS");
    local TYPE = block:GetFieldValue("TYPE");
    return string.format('text("%s", %s, "%s", %s)', TEXT, DURATION, POS, TYPE);
end

function NPL_Macro_Text.ToCode(block)
    return "";
end


MacroBlock.NPL_Macro_Start = NPL_Macro_Start;
MacroBlock.NPL_Macro_Finished = NPL_Macro_Finished;
MacroBlock.NPL_Macro_SetSceneView = NPL_Macro_SetSceneView;
MacroBlock.NPL_Macro_SceneClick = NPL_Macro_SceneClick;
MacroBlock.NPL_Macro_UIClick = NPL_Macro_UIClick;
MacroBlock.NPL_Macro_Text = NPL_Macro_Text;
