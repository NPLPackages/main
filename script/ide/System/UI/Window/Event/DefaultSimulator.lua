
--[[
Title: DefaultSimulator
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local DefaultSimulator = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/DefaultSimulator.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Simulator = NPL.load("./Simulator.lua");

local DefaultSimulator = commonlib.inherit(Simulator, NPL.export());
DefaultSimulator:Property("SimulatorName", "DefaultSimulator");

function DefaultSimulator:ctor()
    self:RegisterSimulator();
    self:SetDefaultSimulatorName(self:GetSimulatorName());
end

function DefaultSimulator:Simulate(event, window)
    local event_type = event:GetEventType();
    if (event_type == "onmouseup") then
        self:AddVirtualEvent("UIWindowClickEvent", self:GetVirtualEventParams());
    elseif (event_type == "onmousewheel") then
        self:AddVirtualEvent("UIWindowWheelEvent", self:GetVirtualEventParams());
    elseif (event_type == "onkeydown") then 
        self:AddVirtualEvent("UIWindowKeyBoardEvent", self:GetVirtualEventParams());
    elseif (event_type == "oninputmethod") then 
        self:AddVirtualEvent("UIWindowInputMethodEvent", self:GetVirtualEventParams());
    end
end

function DefaultSimulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
    if (virtualEventType == "UIWindowClickEvent") then
        return self:UIWindowClickTrigger(virtualEventParams, window);
    elseif (virtualEventType == "UIWindowWheelEvent") then
        return self:UIWindowWheelTrigger(virtualEventParams, window);
    elseif (virtualEventType == "UIWindowKeyBoardEvent") then
        return self:UIWindowKeyBoardTrigger(virtualEventParams, window);
    elseif (virtualEventType == "UIWindowInputMethodEvent") then 
    end
end

function DefaultSimulator:HandlerVirtualEvent(virtualEventType, virtualEventParams, window)
    if (virtualEventType == "UIWindowClickEvent") then
        return self:UIWindowClick(virtualEventParams, window);
    elseif (virtualEventType == "UIWindowWheelEvent") then
        return self:UIWindowWheel(virtualEventParams, window);
    elseif (virtualEventType == "UIWindowKeyBoardEvent") then
        return self:UIWindowKeyBoard(virtualEventParams, window);
    elseif (virtualEventType == "UIWindowInputMethodEvent") then 
        return self:UIWindowInputMethod(virtualEventParams, window);
    end
end

function DefaultSimulator:UIWindowClick(params, window)
    local mouse_down_x, mouse_down_y = window:WindowPointToScreenPoint(params.down_mouse_window_x, params.down_mouse_window_y);
    local mouse_up_x, mouse_up_y = window:WindowPointToScreenPoint(params.up_mouse_window_x, params.up_mouse_window_y);
    local mouse_button, buttons_state = params.mouse_button, params.buttons_state;
    -- print("simulator onmousedown:", mouse_down_x, mouse_down_y, mouse_button, buttons_state);
    mouse_up_x, mouse_up_y = mouse_up_x + params.window_offset_x, mouse_up_y + params.window_offset_y;
    window:OnEvent("onmousedown", {mouse_x = mouse_down_x, mouse_y = mouse_down_y, mouse_button = mouse_button, buttons_state = buttons_state});
    if (params.mouse_down_up_distance > 4) then 
        window:OnEvent("onmousemove", {mouse_x = mouse_down_x + (mouse_up_x > mouse_down_x and 4 or -4), mouse_y = mouse_down_y, mouse_button = mouse_button, buttons_state = buttons_state});
        window:OnEvent("onmousemove", {mouse_x = mouse_up_x, mouse_y = mouse_up_y, mouse_button = mouse_button, buttons_state = buttons_state});
    end
    -- print("simulator onmouseup:", mouse_up_x, mouse_up_y, mouse_button, buttons_state);
    window:OnEvent("onmouseup", {mouse_x = mouse_up_x, mouse_y = mouse_up_y, mouse_button = mouse_button, buttons_state = buttons_state});
end

function DefaultSimulator:UIWindowClickTrigger(params, window)
    if (params.mouse_down_up_distance > 4) then 
        local startX, startY = window:WindowPointToScreenPoint(params.down_mouse_window_x, params.down_mouse_window_y);
        local endX, endY = window:WindowPointToScreenPoint(params.up_mouse_window_x, params.up_mouse_window_y);
        return self:SetDragTrigger(startX, startY, endX + params.window_offset_x, endY + params.window_offset_y, params.mouse_button);
    else
        local x, y = window:WindowPointToScreenPoint(params.down_mouse_window_x, params.down_mouse_window_y);
        return self:SetClickTrigger(x, y, params.mouse_button);
    end
end

-- 鼠标滚动
function DefaultSimulator:UIWindowWheel(params, window)
    local mouse_x, mouse_y = window:WindowPointToScreenPoint(params.mouse_window_x, params.mouse_window_y);
    window:OnEvent("onmousewheel", {mouse_x = mouse_x, mouse_y = mouse_y, mouse_wheel = params.mouse_wheel, version = params.version or 0});
end

function DefaultSimulator:UIWindowWheelTrigger(params, window)
    local mouse_x, mouse_y = window:WindowPointToScreenPoint(params.mouse_window_x, params.mouse_window_y);
    return self:SetMouseWheelTrigger(params.mouse_wheel, mouse_x, mouse_y);
end

function DefaultSimulator:UIWindowInputMethod(params, window)
    window:OnEvent("oninputmethod", params.commit_string);  
end

function DefaultSimulator:UIWindowKeyBoard(params, window)
    if (params.is_input_method) then window:OnEvent("oninputmethod", params.commit_string) end  
    window:OnEvent("onkeydown", params);  
end

function DefaultSimulator:UIWindowKeyBoardTrigger(params, window)
    local buttons = params.keyname or "";
	if(params.ctrl_pressed) then buttons = "ctrl+"..buttons end
	if(params.alt_pressed) then buttons = "alt+"..buttons end
	if(params.shift_pressed) then buttons = "shift+"..buttons end
    if (buttons == "") then return end

    -- get final text in editbox
    local nOffset = 0;
    local targetText = "";
    while(true) do
        nOffset = nOffset + 1;
        local nextMacro = Macros:PeekNextMacro(nOffset)
        if (not nextMacro or (nextMacro.name ~= "Idle" and nextMacro.name ~= "UIWindowEvent" and nextMacro.name ~= "UIWindowEventTrigger")) then break end
        if(nextMacro.name == "UIWindowEvent") then
            local params = nextMacro:GetParams()[1];
            if (params.virtual_event_type ~= "UIWindowKeyBoardEvent") then break end
            params = params.virtual_event_params;
            if(not params.commit_string or not params.keyname or not Macros.IsButtonLetter(params.keyname)) then break end
            targetText = targetText .. params.commit_string;
        end
    end
    if(targetText and targetText ~= "") then
        local nOffset = 0;
        while(true) do
            nOffset = nOffset - 1;
            local nextMacro = Macros:PeekNextMacro(nOffset)
            if (not nextMacro or (nextMacro.name ~= "Idle" and nextMacro.name ~= "UIWindowEvent" and nextMacro.name ~= "UIWindowEventTrigger")) then break end
            if(nextMacro.name == "UIWindowEvent") then
                local params = nextMacro:GetParams()[1];
                if (params.virtual_event_type ~= "UIWindowKeyBoardEvent") then break end
                params = params.virtual_event_params;
                if(not params.commit_string or not params.keyname or not Macros.IsButtonLetter(params.keyname)) then break end
                targetText = params.commit_string .. targetText;
            end
        end
    end

    return self:SetKeyPressTrigger(buttons, (params.ctrl_pressed or params.alt_pressed or params.shift_pressed) and "" or targetText);
end

DefaultSimulator:InitSingleton();