--[[
Title: ElementManager
Author(s): wxa
Date: 2020/6/30
Desc: 元素管理器
use the lib:
-------------------------------------------------------
local ElementManager = NPL.load("script/ide/System/UI/Window/ElementManager.lua");
-------------------------------------------------------
]]
-- NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
-- local mcml = commonlib.gettable("System.Windows.mcml");
-- -- 初始化基本元素
-- mcml:StaticInit();

local IsRecursiveLoadFile = __rts__:GetField("IsRecursiveLoadFile", true);
__rts__:SetField("IsRecursiveLoadFile", false);
local Element = NPL.load("./Element.lua");
local Html = NPL.load("./Elements/Html.lua");
local Style = NPL.load("./Elements/Style.lua");
local Script = NPL.load("./Elements/Script.lua");
local Div = NPL.load("./Elements/Div.lua");
local Template = NPL.load("./Elements/Template.lua");
local TemplateList = NPL.load("./Elements/TemplateList.lua");
local Image = NPL.load("./Elements/Image.lua");
local BigImage = NPL.load("./Elements/BigImage.lua");
local Button = NPL.load("./Elements/Button.lua");
local Label = NPL.load("./Elements/Label.lua");
local Radio = NPL.load("./Elements/Radio.lua");
local RadioGroup = NPL.load("./Elements/RadioGroup.lua");
local CheckBox = NPL.load("./Elements/CheckBox.lua");
local CheckBoxGroup = NPL.load("./Elements/CheckBoxGroup.lua");
local Input = NPL.load("./Elements/Input.lua");
local Select = NPL.load("./Elements/Select.lua");
local TextArea = NPL.load("./Elements/TextArea.lua");
local Canvas = NPL.load("./Elements/Canvas.lua");
local Loading = NPL.load("./Elements/Loading.lua");
local Progress = NPL.load("./Elements/Progress.lua");
local QRCode = NPL.load("./Elements/QRCode.lua");
local ColorPicker = NPL.load("./Elements/ColorPicker.lua");
local DateTimeText = NPL.load("./Elements/DateTimeText.lua");
local ProxyElement = NPL.load("./Elements/ProxyElement.lua");

local Component = NPL.load("../Vue/Component.lua");
local Slot = NPL.load("../Vue/Slot.lua");

local Blockly = NPL.load("../Blockly/Blockly.lua");
local BlocklyBlock = NPL.load("../Blockly/BlocklyBlock.lua");

local Canvas3D = NPL.load("./Controls/Canvas3D.lua");

local ElementManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local ElementManagerDebug = System.Util.Debug.GetModuleDebug("ElementManagerDebug").Enable();   --Enable  Disable

ElementManager.ScrollBar = NPL.load("./Controls/ScrollBar.lua");
ElementManager.Text = NPL.load("./Controls/Text.lua");

__rts__:SetField("IsRecursiveLoadFile", IsRecursiveLoadFile);

local ElementClassMap = {};

local DivAliasTag = {"H1", "H2", "H3", "H4", "H5", "H6", "p", "span"};

function ElementManager:ctor()
    -- 注册元素
    ElementManager:RegisterByTagName("Html", Html);
    ElementManager:RegisterByTagName("Template", Template);
    ElementManager:RegisterByTagName("TemplateList", TemplateList);
    ElementManager:RegisterByTagName("Style", Style);
    ElementManager:RegisterByTagName("Script", Script);
    ElementManager:RegisterByTagName("Div", Div);
    ElementManager:RegisterByTagName("Image", Image);
    ElementManager:RegisterByTagName("BigImage", BigImage);
    ElementManager:RegisterByTagName("Button", Button);    
    ElementManager:RegisterByTagName("Label", Label);    
    ElementManager:RegisterByTagName("Radio", Radio);
    ElementManager:RegisterByTagName("RadioGroup", RadioGroup);
    ElementManager:RegisterByTagName("CheckBox", CheckBox);
    ElementManager:RegisterByTagName("CheckBoxGroup", CheckBoxGroup);
    ElementManager:RegisterByTagName("Select", Select);
    ElementManager:RegisterByTagName("Input", Input);
    ElementManager:RegisterByTagName("TextArea", TextArea);
    ElementManager:RegisterByTagName("Canvas", Canvas);
    ElementManager:RegisterByTagName("Loading", Loading);
    ElementManager:RegisterByTagName("Progress", Progress);
    ElementManager:RegisterByTagName("QRCode", QRCode);
    ElementManager:RegisterByTagName("ColorPicker", ColorPicker);
    ElementManager:RegisterByTagName("DateTimeText", DateTimeText);
    ElementManager:RegisterByTagName("ProxyElement", ProxyElement);

    ElementManager:RegisterByTagName("Component", Component);
    ElementManager:RegisterByTagName("Slot", Slot);

    ElementManager:RegisterByTagName("Blockly", Blockly);
    ElementManager:RegisterByTagName("BlocklyBlock", BlocklyBlock);

    -- 控件元素
    ElementManager:RegisterByTagName("Canvas3D", Canvas3D);

    for _, tagname in ipairs(DivAliasTag) do
        ElementManager:RegisterByTagName(tagname, Div);
    end
end

function ElementManager:RegisterByTagName(tagname, class)
    ElementClassMap[string.lower(tagname)] = class;
    -- ElementManagerDebug.Format("Register TagElement %s, class = %s", tagname, class ~= nil);
end

function ElementManager:GetElementByTagName(tagname)
    local TagElement = ElementClassMap[string.lower(tagname)];
    -- ElementManagerDebug.Format("GetElementByTagName TagName = %s", tagname);
    -- if (not TagElement) then ElementManagerDebug.Format("TagElement Not Exist, TagName = %s", tagname) end
    return TagElement or Element;
end

function ElementManager:GetTextElement()
    return self.Text;
end

-- 初始化成单列模式
ElementManager:InitSingleton();
