
--[[
Title: Params
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local Params = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/Params.lua");
-------------------------------------------------------
]]


local Params = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Params.event_params = {};
Params.cache_params = {};

function Params:GetEventParams()
    if (not self.event_params[self.event_type]) then self.event_params[self.event_type] = {} end
    return self.event_params[self.event_type];
end

function Params:GetCacheParams()
    return self.cache_params;
end

function Params:GetEventType()
    return self.event_type;
end

function Params:GetWindowName()
    return self.window_name;
end

function Params:Init(event, window)
    local event_type = event:GetEventType();
    if (event_type == "ondraw") then return end
    local last_event_type = self.event_type;
    self.event_type = event_type;
    self.window_name = window:GetWindowName();
    self.event_params[self.event_type] = nil;
    local cache_params = self.cache_params;

    if (event_type == "onmousedown") then 
        cache_params.down_mouse_x, cache_params.down_mouse_y = event:GetScreenXY(); 
        cache_params.down_mouse_window_x, cache_params.down_mouse_window_y = event:GetWindowXY();   -- 窗口坐标为虚拟的绝对坐标, 不启用窗口自动缩放, 该不会变化
        cache_params.down_window_x, cache_params.down_window_y = window:GetScreenPosition();
        -- 鼠标按键信息以按下为准
        cache_params.buttons_state = event.buttons_state;  
        cache_params.mouse_button = event.mouse_button;
    end
    
    if (event_type == "onmouseup") then 
        cache_params.up_mouse_x, cache_params.up_mouse_y = event:GetScreenXY();
        cache_params.up_mouse_window_x, cache_params.up_mouse_window_y = event:GetWindowXY();
        cache_params.up_window_x, cache_params.up_window_y = window:GetScreenPosition();
        cache_params.window_offset_x, cache_params.window_offset_y = cache_params.up_window_x - cache_params.down_window_x, cache_params.up_window_y - cache_params.down_window_y;
        cache_params.mouse_down_up_distance = math.max(math.abs(cache_params.up_mouse_x - cache_params.down_mouse_x), math.abs(cache_params.up_mouse_y - cache_params.down_mouse_y));         -- 距离为屏幕距离
    end

    if (event_type == "onkeydown") then
        local is_input_method = last_event_type == "oninputmethod";                                                            -- oninputmethod => onkeydown  不一定准确 中间可能穿插ondraw事件
        cache_params.ctrl_pressed, cache_params.shift_pressed, cache_params.alt_pressed, cache_params.keyname, cache_params.key_sequence = event.ctrl_pressed, event.shift_pressed, event.alt_pressed, event.keyname, event.key_sequence;
        cache_params.is_input_method = is_input_method; 
        cache_params.commit_string = is_input_method and cache_params.commit_string or nil;   -- 
    end 

    if (event_type == "oninputmethod") then
        cache_params.commit_string = event:GetCommitString();
    end

    if (event_type == "onmousewheel") then
        cache_params.mouse_x, cache_params.mouse_y = event:GetScreenXY(); 
        cache_params.mouse_window_x, cache_params.mouse_window_y = event:GetWindowXY();   -- 窗口坐标为虚拟的绝对坐标, 不启用窗口自动缩放, 该不会变化
        cache_params.mouse_wheel = event.mouse_wheel;
        cache_params.version = event:GetVersion();
    end
end

function Params:GetVirtualEventParams()
    local event_type = self:GetEventType();
    local params, cache_params = {}, self.cache_params;
    if (event_type == "onmouseup") then
        params.mouse_button = cache_params.mouse_button; 
        params.buttons_state = cache_params.buttons_state; 
        params.down_mouse_window_x = cache_params.down_mouse_window_x; 
        params.down_mouse_window_y = cache_params.down_mouse_window_y; 
        params.up_mouse_window_x = cache_params.up_mouse_window_x; 
        params.up_mouse_window_y = cache_params.up_mouse_window_y; 
        params.window_offset_x = cache_params.window_offset_x; 
        params.window_offset_y = cache_params.window_offset_y; 
        params.mouse_down_up_distance = cache_params.mouse_down_up_distance;
    end

    if (event_type == "onkeydown") then
        params.ctrl_pressed = cache_params.ctrl_pressed;
        params.shift_pressed = cache_params.shift_pressed;
        params.alt_pressed = cache_params.alt_pressed;
        params.keyname = cache_params.keyname;
        params.key_sequence = cache_params.key_sequence;
        params.is_input_method = cache_params.is_input_method;
        params.commit_string = cache_params.commit_string;

        -- 忽略独立的ctrl, shift, alt 按键
        if (params.keyname == "DIK_LCONTROL" or params.keyname == "DIK_LSHIFT" or params.keyname == "DIK_LALT") then return end 
    end

    if (event_type == "onmousewheel") then
        params.mouse_window_x, params.mouse_window_y, params.mouse_wheel = cache_params.mouse_window_x, cache_params.mouse_window_y, cache_params.mouse_wheel;
        params.version = cache_params.version;
    end

    if (event_type == "oninputmethod") then
        params.commit_string = cache_params.commit_string;
    end
    
    return params;
end
