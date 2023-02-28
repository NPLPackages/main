
--[[
Title: Simulator
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local Simulator = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/Simulator.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Params = NPL.load("./Params.lua", IsDevEnv);
local Simulator = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local ConvertToWebMode = NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/ConvertToWebMode/ConvertToWebMode.lua");

Simulator:Property("SimulatorName", "Simulator");                    -- 模拟器名称

local windows = {};
local simulators = {};
if (IsDevEnv) then
    _G.windows = _G.windows or {};
    windows = _G.windows;
    _G.simulators = _G.simulators or {};
    simulators = _G.simulators;
end
local simulated = false;  -- 是否已模拟
local window_id = 0;
local default_simulator_name = "DefaultSimulatorName";
local macro_cache_obj = {};

function Macros.UIWindowEvent(params)
    local window = windows[params.window_name];
    local simulator = simulators[params.simulator_name];
    if (not window or not simulator) then return end
    return simulator:Handler(params, window);
end

function Macros.UIWindowEventTrigger(params)
    local window = windows[params.window_name];
    local simulator = simulators[params.simulator_name];
    if (not window or not simulator) then return end
    return simulator:Trigger(params, window);
end

function Simulator:GetVirtualEventParams()
    return Params:GetVirtualEventParams();
end

function Simulator:AddVirtualEvent(virtualEventType, virtualEventParams)
    if (not self:IsRecording() or not virtualEventParams) then return end 
    local macroCount = #Macros.macros;
    local lastMacro = Macros.macros[macroCount];

    if (macro_cache_obj.lastMacro and macro_cache_obj.lastMacro == lastMacro 
        and macro_cache_obj.virtual_event_type == "UIWindowInputMethodEvent" and virtualEventType == "UIWindowKeyBoardEvent" 
        and macro_cache_obj.virtual_event_params.commit_string == virtualEventParams.commit_string) then
        Macros.macros[macroCount - 1], Macros.macros[macroCount] = nil, nil;
    end

    Macros:AddMacro("UIWindowEvent", {
        window_name = Params:GetWindowName(),
        event_type = Params:GetEventType(),
        simulator_name = self:GetSimulatorName(),
        virtual_event_type = virtualEventType,
        virtual_event_params = virtualEventParams,
    });  
    
    macroCount = #Macros.macros;
    macro_cache_obj.lastMacro = Macros.macros[macroCount];
    macro_cache_obj.virtual_event_type = virtualEventType;
    macro_cache_obj.virtual_event_params = virtualEventParams;
end

function Simulator:IsRecording()
    return Macros:IsRecording()
end

function Simulator:IsPlaying()
    return Macros:IsPlaying()
end

function Simulator:IsRecordingOrPlaying()
    return self:IsRecording() or self:IsPlaying();
end

function Simulator:SetClickTrigger(mouseX, mouseY, mouseButton, callbackFunction)
    if (Macros.GetHelpLevel() == -2) then
        ConvertToWebMode:StopComputeRecordTime();
        local macros = Macros.macros[Macros.curLine];

        if (macros) then
            macros.processTime = ConvertToWebMode.processTime;
            macros.mouseButton = mouseButton;
            macros.mousePosition = { mouseX = mouseX, mouseY = mouseY }
        end
    end

    local callback = {};
    MacroPlayer.SetClickTrigger(mouseX, mouseY, mouseButton or "left", function()
        if (Macros.GetHelpLevel() == -2) then
            local nextNextLine = Macros.macros[Macros.curLine + 2];

            if (nextNextLine and
                nextNextLine.name ~= "Broadcast" and
                nextNextLine.params ~= "macroFinished") then
                commonlib.TimerManager.SetTimeout(function()
                    ConvertToWebMode:StopCapture();

                    ConvertToWebMode:StartComputeRecordTime();
                    ConvertToWebMode:BeginCapture(function()
                        if (callback.OnFinish and type(callback.OnFinish) == "function") then
                            callback.OnFinish();
                        end

                        if (callbackFunction and type(callbackFunction) == "function") then
                            callbackFunction();
                        end
                    end);
                end, 4000);
            else
                if (callback.OnFinish and type(callback.OnFinish) == "function") then
                    callback.OnFinish();
                end

                if (callbackFunction and type(callbackFunction) == "function") then
                    callbackFunction();
                end
            end
        else
            if (callback.OnFinish and type(callback.OnFinish) == "function") then
                callback.OnFinish();
            end

            if (callbackFunction and type(callbackFunction) == "function") then
                callbackFunction();
            end
        end
    end);
    return callback;
end

function Simulator:SetMouseWheelTrigger(delta, mouseX, mouseY)
    local callback = {};
    MacroPlayer.SetMouseWheelTrigger(delta, mouseX, mouseY, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function Simulator:SetDragTrigger(startX, startY, endX, endY, mouseButton)
    if (Macros.GetHelpLevel() == -2) then
        ConvertToWebMode:StopComputeRecordTime();
        local macros = Macros.macros[Macros.curLine];

        if (macros) then
            macros.processTime = ConvertToWebMode.processTime;
            macros.isDrag = true;
            macros.mouseButton = mouseButton;
            macros.mousePosition = {
                startX = startX,
                startY = startY,
                endX = endX,
                endY = endY,
            }
        end
    end

    local callback = {};
    MacroPlayer.SetDragTrigger(startX, startY, endX, endY, mouseButton or "left", function()
        if (Macros.GetHelpLevel() == -2) then
            local nextNextLine = Macros.macros[Macros.curLine + 2];

            if (nextNextLine and
                nextNextLine.name ~= "Broadcast" and
                nextNextLine.params ~= "macroFinished") then
                commonlib.TimerManager.SetTimeout(function()
                    ConvertToWebMode:StopCapture();

                    ConvertToWebMode:StartComputeRecordTime();
                    ConvertToWebMode:BeginCapture(function()
                        if (callback.OnFinish and type(callback.OnFinish) == "function") then
                            callback.OnFinish();
                        end
                    end);
                end, 4000);
            else
                if (callback.OnFinish and type(callback.OnFinish) == "function") then
                    callback.OnFinish();
                end
            end
        else
            if (callback.OnFinish and type(callback.OnFinish) == "function") then
                callback.OnFinish();
            end
        end
    end);
    return callback;
end

function Simulator:SetKeyPressTrigger(buttons, targetText)
    local callback = {};
    MacroPlayer.SetKeyPressTrigger(buttons, targetText, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function Simulator:SetInputTextTrigger(text)
    local callback = {};
    local index, size = 1, ParaMisc.GetUnicodeCharNum(text);
    local function ExecTrigger()
        local char = ParaMisc.UniSubString(text, index, index);
        local buttons = Macros.TextToKeyName(char);
        MacroPlayer.SetKeyPressTrigger(buttons or char, text, function()
            index = index + 1;
            if (index <= size) then
                return ExecTrigger();
            end
            if(callback.OnFinish) then 
                callback.OnFinish();
            end
        end);
    end
    ExecTrigger();
    return callback;
end

function Simulator:SetDefaultSimulatorName(simulator_name)
    default_simulator_name = simulator_name;
end

function Simulator:GetDefaultSimulatorName()
    return default_simulator_name;
end

function Simulator:GetDefaultSimulator()
    return default_simulator_name and simulators[default_simulator_name] or Simulator;
end

function Simulator:ctor()
    self:RegisterSimulator();
end

function Simulator:IsSimulated()
    return simulated;
end

function Simulator:SetSimulated(bSimulated)
    simulated = bSimulated;
end

function Simulator:Init(event, window)
    self:SetSimulated(false);
    Params:Init(event, window);

    return self;
end

function Simulator:Simulate(event, window)
    if (self:IsSimulated()) then return end 
end

function Simulator:Trigger(params, window)
    return self:TriggerVirtualEvent(params.virtual_event_type, params.virtual_event_params, window);
end

function Simulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
end

function Simulator:Handler(params, window)
    return self:HandlerVirtualEvent(params.virtual_event_type, params.virtual_event_params, window);
end

function Simulator:HandlerVirtualEvent(virtualEventType, virtualEventParams, window)
end

function Simulator:RegisterSimulator()
    simulators[self:GetSimulatorName()] = self;
end

function Simulator:RegisterWindow(window)
    local windowName = window:GetWindowName();
    if (not windowName or windowName == "") then return end
    windows[windowName] = window;
end

function Simulator:UnregisterWindow(window)
    local windowName = window:GetWindowName();
    if (not windowName or windowName == "") then return end
    windows[windowName] = nil;
end


function Simulator:BeginPlay()
end

function Simulator:EndPlay()
end

Simulator:InitSingleton();

local function MacroBeginRecord()
    window_id  = 0;
end
local function MacroEndRecord()
end

local function MacroBeginPlay()
    window_id  = 0;

    for _, simulator in pairs(simulators) do
        simulator:BeginPlay();
    end
end

local function MacroEndPlay()
    for _, simulator in pairs(simulators) do
        simulator:EndPlay();
    end
end
GameLogic.GetFilters():add_filter("Macro_BeginRecord", MacroBeginRecord);
GameLogic.GetFilters():add_filter("Macro_EndRecord", MacroEndRecord);
GameLogic.GetFilters():add_filter("Macro_BeginPlay", MacroBeginPlay);
GameLogic.GetFilters():add_filter("Macro_EndPlay", MacroEndPlay);