--[[
Title: MouseEvent
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local MouseEvent = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/MouseEvent.lua");
-------------------------------------------------------
]]

local BaseEvent = NPL.load("./BaseEvent.lua");

local MouseEvent = commonlib.inherit(BaseEvent, NPL.export());

MouseEvent:Property("TripleClick", false, "IsTripleClick");
MouseEvent:Property("DoubleClick", false, "IsDoubleClick");
MouseEvent:Property("BlocklyMouseWheelDirection", 1);   -- 图块滚轮方向

local firstPressTime, secondPressTime = 0, 0;
local firstPressPositionX  = 0;
local secondPressPositionX = 0;
local thirdPressPositionX = 0;

local function isDoublePress(self)
    if(firstPressPositionX == secondPressPositionX and ParaGlobal.timeGetTime() - firstPressTime < 250) then
        secondPressTime = ParaGlobal.timeGetTime();
        return true;
    end
    firstPressPositionX, firstPressTime = self.x, ParaGlobal.timeGetTime();
    return false;
end

local function isTriplePress(self)
	if(thirdPressPositionX == secondPressPositionX and ParaGlobal.timeGetTime() - secondPressTime < 250) then return true end
	secondPressPositionX = self.x;
	return false;
end

local function isDoubleAndTripleClick(self)
    if(self.mouse_button == "left" and self.event_type == "onmousedown") then
		thirdPressPositionX = self.x;
        self:SetTripleClick(isTriplePress(self));
        self:SetDoubleClick(isDoublePress(self));
    end
end

function MouseEvent:ctor()
end

function MouseEvent:Init(event_type, window, params)
    MouseEvent._super.Init(self, event_type, window, params);

    if(event_type == "onmousemove") then
        self.x, self.y = ParaUI.GetMousePosition();
	else
		if(not mouse_x) then mouse_x, mouse_y = ParaUI.GetMousePosition() end
		self.x, self.y = mouse_x, mouse_y;
	end

    self.shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
	self.ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
	self.alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
    self.mouse_button = mouse_button;
	self.mouse_wheel = mouse_wheel;

    if (event_type == "onmousedown" or event_type == "onmousemove") then
        self.buttons_state = 0;

        if (ParaUI.IsMousePressed(0)) then
            self.buttons_state = self.buttons_state + 1
        end

        if (ParaUI.IsMousePressed(1)) then
            self.buttons_state = self.buttons_state + 2
        end

        if (event_type == "onmousedown") then
            self.down_buttons_state = self.buttons_state -- 记录按下值
        end        
    elseif (event_type == "onmouseup") then
        self.buttons_state = self.down_buttons_state;                                                -- 抬起使用与按下相同的按键状态
    end
	
    if (type(params) == "table") then
        self.x, self.y, self.mouse_button, self.buttons_state, self.mouse_wheel = params.x or params.mouse_x or self.x, params.y or params.mouse_y or self.y, params.mouse_button or self.mouse_button, params.buttons_state or self.buttons_state, params.mouse_wheel or self.mouse_wheel;
        self.shift_pressed, self.ctrl_pressed, self.alt_pressed = params.shift_pressed or self.shift_pressed, params.ctrl_pressed or self.ctrl_pressed, params.alt_pressed or self.alt_pressed;
    end

    if (event_type == "onmousedown") then 
        self.down_mouse_screen_x, self.down_mouse_screen_y = self.x, self.y;
    end
    
    self.last_mouse_x, self.last_mouse_y = self.mouse_x, self.mouse_y;
    self.mouse_x, self.mouse_y = self.x, self.y;

    if (event_type == "onmousemove") then 
        if (self.last_event_type == "onmousedown" and self.down_mouse_screen_x == self.x and self.down_mouse_screen_y == self.y) then 
            self.last_event_type = "onmousemove";           -- 重置上次事件为 onmousemove
            self.event_type = "onmousedown";                -- 改写事件名     底层bug 触发 onmousedown 后会立即触发onmousemove事件, 但鼠标并未移动, 则忽略掉 
            return nil;                                     -- 无效事件
        end
        if (self.last_event_type == "onmousemove" and self.last_mouse_x == self.x and self.last_mouse_y == self.y) then return nil end
    end
    
    if (event_type == "onmouseup") then 
        self.up_mouse_screen_x, self.up_mouse_screen_y = self.x, self.y;
    end

    isDoubleAndTripleClick(self);

	return self;
end

function MouseEvent:GetScreenXY()
    return self.x, self.y;
end

function MouseEvent:GetWindowXY()
    return self:GetWindow():ScreenPointToWindowPoint(self.x, self.y);
end

function MouseEvent:IsMove()
    return math.abs(self.x - (self.down_mouse_screen_x or 0)) >= 4 or math.abs(self.y - (self.down_mouse_screen_y or 0)) >= 4;
end

-- 鼠标滚动距离
function MouseEvent:GetDelta()
    return self.mouse_wheel or 0;
end

-- 是否鼠标左键按下
function MouseEvent:IsLeftButton()
    -- local isTouchMode = System.os.IsTouchMode();
    local isTouchMode = GameLogic.options:HasTouchDevice();

    if (isTouchMode) then
        return self.mouse_button == "left";
    else
	    return self.buttons_state == 1;
    end
end

-- 是否鼠标右键按下
function MouseEvent:IsRightButton()
    -- local isTouchMode = System.os.IsTouchMode();
    local isTouchMode = GameLogic.options:HasTouchDevice();
    if (isTouchMode) then
        return self.mouse_button == "right";
    else
        return self.buttons_state == 2;
    end
end

-- 是否是鼠标中键按下 
function MouseEvent:IsMiddleButton()
    return self.mouse_button == "middle";
end

function MouseEvent:IsMouseEvent()
    return true;
end


---------------------------------------------以下代码均为兼容代码, 后续废弃-------------------------------------------------

-- 此函数冬令营再用, 后续废弃, 勿用
function MouseEvent:GetWindowPos()
    return self:GetWindowXY();
end
