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

local Element = NPL.load("./Element.lua", IsDevEnv);
local Html = NPL.load("./Elements/Html.lua", IsDevEnv);
local Style = NPL.load("./Elements/Style.lua", IsDevEnv);
local Script = NPL.load("./Elements/Script.lua", IsDevEnv);
local Div = NPL.load("./Elements/Div.lua", IsDevEnv);
local Image = NPL.load("./Elements/Image.lua", IsDevEnv);
local BigImage = NPL.load("./Elements/BigImage.lua", IsDevEnv);
local Button = NPL.load("./Elements/Button.lua", IsDevEnv);
local Label = NPL.load("./Elements/Label.lua", IsDevEnv);
local Radio = NPL.load("./Elements/Radio.lua", IsDevEnv);
local RadioGroup = NPL.load("./Elements/RadioGroup.lua", IsDevEnv);
local CheckBox = NPL.load("./Elements/CheckBox.lua", IsDevEnv);
local CheckBoxGroup = NPL.load("./Elements/CheckBoxGroup.lua", IsDevEnv);
local Input = NPL.load("./Elements/Input.lua", IsDevEnv);
local Select = NPL.load("./Elements/Select.lua", IsDevEnv);
local TextArea = NPL.load("./Elements/TextArea.lua", IsDevEnv);
local Canvas = NPL.load("./Elements/Canvas.lua", IsDevEnv);
local Loading = NPL.load("./Elements/Loading.lua", IsDevEnv);
local Progress = NPL.load("./Elements/Progress.lua", IsDevEnv);
local QRCode = NPL.load("./Elements/QRCode.lua", IsDevEnv);
local ColorPicker = NPL.load("./Elements/ColorPicker.lua", IsDevEnv);
local DateTimeText = NPL.load("./Elements/DateTimeText.lua", IsDevEnv);
local ProxyElement = NPL.load("./Elements/ProxyElement.lua", IsDevEnv);

local Component = NPL.load("../Vue/Component.lua", IsDevEnv);
local Slot = NPL.load("../Vue/Slot.lua", IsDevEnv);

local Blockly = NPL.load("../Blockly/Blockly.lua", IsDevEnv);

local Canvas3D = NPL.load("./Controls/Canvas3D.lua", IsDevEnv);

local ElementManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local ElementManagerDebug = GGS.Debug.GetModuleDebug("ElementManagerDebug").Enable();   --Enable  Disable

ElementManager.ScrollBar = NPL.load("./Controls/ScrollBar.lua", IsDevEnv);
ElementManager.Text = NPL.load("./Controls/Text.lua", IsDevEnv);

local ElementClassMap = {};

local DivAliasTag = {"H1", "H2", "H3", "H4", "H5", "H6", "p", "span"};

function ElementManager:ctor()
    -- 注册元素
    ElementManager:RegisterByTagName("Html", Html);
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
