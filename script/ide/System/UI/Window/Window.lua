--[[
Title: ui
Author(s): wxa
Date: 2020/6/30
Desc: UI Window
use the lib:
-------------------------------------------------------
local Window = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Window.lua");
-------------------------------------------------------
]]
-- Window
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local SizeEvent = commonlib.gettable("System.Windows.SizeEvent");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");

local G = NPL.load("./G.lua", IsDevEnv);
local StyleManager = NPL.load("./Style/StyleManager.lua", IsDevEnv);
local Simulator = NPL.load("./Event/Simulator.lua", IsDevEnv);
local DefaultSimulator = NPL.load("./Event/DefaultSimulator.lua", IsDevEnv);
local Event = NPL.load("./Event/Event.lua", IsDevEnv);

local Element = NPL.load("./Element.lua", IsDevEnv);
local ElementManager = NPL.load("./ElementManager.lua", IsDevEnv);

local Window = commonlib.inherit(Element, NPL.export());
local WindowDebug = GGS.Debug.GetModuleDebug("WindowDebug").Enable();
local MouseDebug = GGS.Debug.GetModuleDebug("MouseDebug").Disable();  -- Enable  Disable
local EventElementList = {};

local windowId = 0;
Window:Property("NativeWindow");                    -- 原生窗口
Window:Property("PainterContext");                  -- 绘制上下文
Window:Property("ElementManager", ElementManager);  -- 元素管理器
Window:Property("StyleManager");                    -- 元素管理器
Window:Property("HoverElement");                    -- 光标所在元素
Window:Property("MouseDownElement");                -- 鼠标按下元素
Window:Property("MouseUpElement");                  -- 鼠标松开元素
Window:Property("FocusElement");                    -- 焦点元素
Window:Property("MouseCaptureElement");             -- 鼠标捕获元素
Window:Property("G");                               -- 全局对象
Window:Property("Params");                          -- 窗口参数
Window:Property("Event");                           -- 事件对象
Window:Property("WindowName");                      -- 窗口名称
Window:Property("WindowId");                        -- 窗口Id
Window:Property("3DWindow", false, "Is3DWindow");   -- 是否是3D窗口
Window:Property("Destroy", false, "IsDestroy");     -- 是否销毁窗口
Window:Property("EnableMouseWheelSimulate", true, "IsEnableMouseWheelSimulate");         -- 是否开启鼠标滚动模拟
Window:Property("EnableSimulator", true, "IsEnableSimulator");                           -- 是否开启事件模拟器

local function GetSceneViewport()
    NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	return ViewportManager:GetSceneViewport();
end

function Window:ctor()
    windowId = windowId + 1;
    self.windowId = windowId;
    self:SetWindowId("UIWindowId_" .. windowId);
    --屏幕位置,宽度,高度
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = 0, 0, 0, 0; 
    -- 窗口的位置,宽度,高度
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, 0, 0; 
    -- 缩放
    self.scaleX, self.scaleY = 1, 1;

    -- 最小根屏幕宽高  用于window窗口太小情况
    self.minRootScreenWidth, self.minRootScreenHeight = nil, nil;
    -- 默认最小根屏幕宽度
    self.defaultMinRootScreenWidth, self.defaultMinRootScreenHeight = 1280, 720;
    -- 最大根屏幕宽高 
    self.maxRootScreenWidth, self.maxRootScreenHeight = nil, nil;
    -- 设计固定根屏幕宽高, 用于全屏模式, 当于真实根宽高不一致会自动缩放
    self.fixedRootScreenWidth, self.fixedRootScreenHeight = nil, nil;

    self:SetName("Window");
    self:SetTagName("Window");
    self:SetStyleManager(StyleManager:new());
    -- 创建绘图上下文
    self:SetPainterContext(System.Core.PainterContext:new():init(self));

    self.Event = Event:new();  -- 每个窗口使用独立的事件对象

    -- 世界退出, 关闭窗口
    GameLogic:Connect("WorldUnloaded", nil, function()
        self:CloseWindow();
    end, "UniqueConnection");
end

function Window:IsWindow()
    return true;
end

function Window:LoadXmlNodeByUrl(url)
    if (type(url) == "table") then return url end
    if (type(url) ~= "string") then return nil end

    local file = ParaIO.open(url, "r");
    if(not file:IsValid()) then
        WindowDebug.Format("ERROR: read file failed: %s ", url);
        return ;
    end
    local text = file:GetText();
    file:close();
    return commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString(text), "//html");
end

function Window:LoadXmlNodeByTemplate(template)
    if (type(template) == "table") then return template end
    if (type(template) ~= "string") then return nil end
    return commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString(template), "//html");
end

function Window:LoadXmlNodeByHtml(html)
    local nodes = ParaXML.LuaXML_ParseString(html);
    return nodes and nodes[1];
end

function Window:LoadXmlNode(params)
    if (params.html) then return self:LoadXmlNodeByHtml(params.html) end
    if (params.template) then return self:LoadXmlNodeByTemplate(params.template) end
    if (params.url) then return self:LoadXmlNodeByUrl(params.url) end
end

-- 新建一个全局表
function Window:NewG(g)
    return G.New(self, g);
end

function Window:OnWorldLoaded()
end

function Window:OnWorldUnloaded()
    self:CloseWindow();
end

function Window:Init()
    if (not self:Is3DWindow()) then
        -- GetSceneViewport():Connect("sizeChanged", self, self.OnScreenSizeChanged, "UniqueConnection");
        Screen:Connect("sizeChanged", self, self.OnScreenSizeChanged, "UniqueConnection");
    end
    
    local params = self:GetParams();

    -- 卸载世界自动关闭窗口  默认为真
    if (params.__is_auto_close_in_world_unload__ or params.__is_auto_close_in_world_unload__ == nil) then
        GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
        GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
    end

    self:SetWindow(self);
    self:SetWindowName(params.windowName);
    if (self:IsSupportSimulator()) then Simulator:RegisterWindow(self) end

    self:SetG(self:NewG(params.G));      -- 设置全局G表
    -- 设置窗口元素
    self:InitElement({
        name = "Window",
        attr = {
            -- style="background-color:#ffffff;",
            draggable = if_else(params.draggable == false, false, true),   -- 窗口默认可以拖拽
        }, 
    }, self, nil);
    self:SetVisible(true);

    -- 设置根元素
    local xmlNode = self:LoadXmlNode(params);
    local rootElement = xmlNode and self:CreateFromXmlNode(xmlNode, self, self);
    if (rootElement) then table.insert(self.childrens, rootElement) end

    -- 加载元素, 提供一种置顶向下执行的机制
    self:LoadElement();
end

-- 窗口显示
function Window.Show(self, params)
    if (not self or not self.isa or self == Window or not self:isa(Window)) then 
        params = self ~= Window and self or params;
        self = Window:new();
    end

    params = params or self:GetParams() or {};
    self:Set3DWindow(params.__is_3d_ui__ and true or false);
    self:SetParams(params);
    self:SetNativeWindow(self:Is3DWindow() and self:Create3DNativeWindow() or self:CreateNativeWindow());
    self:SetDestroy(false);
    -- 初始化
    self:Init();
    -- 文档化
    self:Attach();
    -- 更新布局
    self:UpdateLayout(true);
    return self;
end

-- 窗口关闭
function Window:CloseWindow()
    GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Disconnect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");

    if (not self:GetNativeWindow()) then return end
    -- GetSceneViewport():Disconnect("sizeChanged", self, self.OnScreenSizeChanged, "UniqueConnection");
    Screen:Disconnect("sizeChanged", self, self.OnScreenSizeChanged, "UniqueConnection");

    if (self:IsSupportSimulator()) then Simulator:UnregisterWindow(self) end

    ParaUI.Destroy(self:GetNativeWindow().id);
    self:SetNativeWindow(nil);
    self:SetVisible(false);
    self:SetDestroy(true);
    local G = self:GetG();
    if (type(rawget(G, "OnClose")) == "function") then G.OnClose(G) end
end

function Window:Init3DWindowPosition()
    local params = self:GetParams();
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = params.x or 0, params.y or 0, params.width or 100, params.height or 100;
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, self.screenWidth, self.screenHeight;
    return self.screenX, self.screenY, self.screenWidth, self.screenHeight
end

-- 创建原生窗口
function Window:Create3DNativeWindow()
    if (self:GetNativeWindow()) then return self:GetNativeWindow() end

    local windowX, windowY, windowWidth, windowHeight = self:Init3DWindowPosition();
    local native_window = ParaUI.CreateUIObject("container", self:GetWindowId(), "_lt", windowX, windowY, windowWidth, windowHeight);  -- container
    native_window:SetField("OwnerDraw", true);         
        
    native_window.enabled = false;
    native_window.visible = false;
    -- 加到有效窗口上
    native_window:AttachToRoot();
	
    native_window:SetScript("ondraw", function()
        self:HandleRender();
    end);

    local obj = self:GetParams().__3d_object__;
    local params = self:GetParams();
    if (obj) then
        obj:ShowHeadOnDisplay(true, 0);
        obj:SetHeadOnUITemplateName(self:GetWindowId(), 0);
        obj:SetField("HeadOn3DFacing", params.__facing__);
        -- obj:SetField("HeadOn3DFacing", params.__facing__ or -1.57);
        obj:SetHeadOnOffset(params.__offset_x__ or 0, params.__offset_y__ or 0, params.__offset_z__ or 0, 0);
    end

    return native_window;
end

-- 获取父原生窗口
function Window:GetParentNativeWindow()
    return self:GetParams().parent or ParaUI.GetUIObject("root");
end

-- 初始化窗口位置
function Window:InitWindowPosition()
    local params = self:GetParams();
    local screenX, screenY, screenWidth, screenHeight = self:GetParentNativeWindow():GetAbsPosition();
    local nativeScreenX, nativeScreenY, nativeScreenWidth, nativeScreenHeight = screenX, screenY, screenWidth, screenHeight;
    self.minRootScreenWidth, self.minRootScreenHeight = self.minRootScreenWidth or params.minRootScreenWidth or self.defaultMinRootScreenWidth, self.minRootScreenHeight or params.minRootScreenHeight or self.defaultMinRootScreenHeight;
    self.maxRootScreenWidth, self.maxRootScreenHeight = self.maxRootScreenWidth or params.maxRootScreenWidth, self.maxRootScreenHeight or params.maxRootScreenHeight;
    self.fixedRootScreenWidth, self.fixedRootScreenHeight = self.fixedRootScreenWidth or params.fixedRootScreenWidth, self.fixedRootScreenHeight or params.fixedRootScreenHeight;
    local scale = 1;
    
    if (self.fixedRootScreenWidth and self.fixedRootScreenHeight) then 
        scale = math.min(nativeScreenWidth / self.fixedRootScreenWidth, nativeScreenHeight / self.fixedRootScreenHeight);
        screenX, screenY, screenWidth, screenHeight = 0, 0, math.max(math.floor(nativeScreenWidth / scale), self.fixedRootScreenWidth), math.max(math.floor(nativeScreenHeight / scale), self.fixedRootScreenHeight); 
    elseif (self.maxRootScreenWidth and self.maxRootScreenHeight and (nativeScreenWidth > self.maxRootScreenWidth or nativeScreenHeight > self.maxRootScreenHeight)) then
        -- 自动放大  
    elseif (nativeScreenWidth < self.minRootScreenWidth or nativeScreenHeight < self.minRootScreenHeight) then
        scale = math.min(nativeScreenWidth / self.minRootScreenWidth, nativeScreenHeight / self.minRootScreenHeight);
        screenX, screenY, screenWidth, screenHeight = 0, 0, math.max(math.floor(nativeScreenWidth / scale), self.minRootScreenWidth), math.max(math.floor(nativeScreenHeight / scale), self.minRootScreenHeight); 
    end

    local windowX, windowY, windowWidth, windowHeight = 0, 0, tonumber(params.width) or params.width or screenWidth, tonumber(params.height) or params.height or screenHeight;
    local offsetX, offsetY = tonumber(params.x) or params.x or 0, tonumber(params.y) or params.y or 0;
    if (type(windowWidth) == "string" and string.match(windowWidth, "^%d+%%$")) then windowWidth = math.floor(screenWidth * tonumber(string.match(windowWidth, "%d+")) / 100) end
    if (type(windowHeight) == "string" and string.match(windowHeight, "^%d+%%$")) then windowHeight = math.floor(screenHeight * tonumber(string.match(windowHeight, "%d+")) / 100) end
    if (type(offsetX) == "string" and string.match(offsetX, "^%d+%%$")) then offsetX = math.floor(screenWidth * tonumber(string.match(offsetX, "%d+")) / 100) end
    if (type(offsetY) == "string" and string.match(offsetY, "^%d+%%$")) then offsetY = math.floor(screenHeight * tonumber(string.match(offsetY, "%d+")) / 100) end
    
    if (params.alignment == "_ctb") then                 -- *	- "_ctb": align to center bottom of the screen
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_ctt") then             -- *	- "_ctt": align to center top of the screen
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY;
    elseif (params.alignment == "_ctl") then             -- *	- "_ctl": align to center left of the screen
        windowX, windowY = offsetX, offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_ctr") then             -- *	- "_ctr": align to center right of the screen
        windowX, windowY = offsetX + screenWidth - windowWidth , offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_lt") then              -- *	- "_lt" align to left top of the screen
        windowX, windowY = offsetX, offsetY;
    elseif (params.alignment == "_lb") then              -- *	- "_lb" align to left bottom of the screen
        windowX, windowY = offsetX, offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_rt") then              -- *	- "_rt" align to right top of the screen
        windowX, windowY = offsetX + screenWidth - windowWidth, offsetY;
    elseif (params.alignment == "_rb") then              -- *	- "_rb" align to right bottom of the screen
        windowX, windowY = offsetX + screenWidth - windowWidth, offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_mt") then              -- *	- "_mt": align to middle top
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY;
    elseif (params.alignment == "_mb") then              -- *	- "_mb": align to middle bottom
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_ml") then              -- *	- "_ml": align to middle left
        windowX, windowY = offsetX, offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_mr") then              -- *	- "_mr": align to middle right
        windowX, windowY = offsetX + screenWidth - windowWidth, offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_fi") then              -- *	- "_fi": align to left top and right bottom. This is like fill in the parent window.
        windowX, windowY, windowWidth, windowHeight = 0, 0, screenWidth, screenHeight;
    else                                                 -- *	- "_ct" align to center of the screen
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + math.floor((screenHeight - windowHeight) / 2);
    end

    if (scale == 1) then
        self.screenX, self.screenY, self.screenWidth, self.screenHeight = windowX, windowY, windowWidth, windowHeight;
    elseif (scale > 1) then
        self.screenX, self.screenY, self.screenWidth, self.screenHeight = nativeScreenX, nativeScreenY, nativeScreenWidth, nativeScreenHeight;
    else 
        self.screenX, self.screenY, self.screenWidth, self.screenHeight = math.max(windowX, 0) * scale, math.max(windowY, 0) * scale, windowWidth * scale, windowHeight * scale;
    end

    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, windowWidth, windowHeight;
    self.rootScreenX, self.rootScreenY, self.rootScreenWidth, self.rootScreenHeight = screenX, screenY, screenWidth, screenHeight;
    self.scaleX, self.scaleY = scale, scale;

    -- WindowDebug(
    --     string.format("root window screenX = %s, screenY = %s, screenWidth = %s, screenHeight = %s", screenX, screenY, screenWidth, screenHeight),
    --     string.format("screenX = %s, screenY = %s, screenWidth = %s, screenHeight = %s", windowX, windowY, windowWidth, windowHeight),
    --     string.format("windowX = %s, windowY = %s, windowWidth = %s, windowHeight = %s", 0, 0, windowWidth, windowHeight)
    -- );
    return self.screenX, self.screenY, self.screenWidth, self.screenHeight;
end

-- 创建原生窗口
function Window:CreateNativeWindow()
    if (self:GetNativeWindow()) then return self:GetNativeWindow() end
    -- 创建窗口
    local windowX, windowY, windowWidth, windowHeight = self:InitWindowPosition();
    local native_window = ParaUI.CreateUIObject("container", self:GetWindowId(), "_lt", windowX, windowY, windowWidth, windowHeight);
    -- WindowDebug.Format("CreateNativeWindow windowX = %s, windowY = %s, windowWidth = %s, windowHeight = %s", windowX, windowY, windowWidth, windowHeight);
    native_window:SetField("OwnerDraw", true);               -- enable owner draw paint event
    native_window:SetField("CanHaveFocus", true);
    native_window:SetField("InputMethodEnabled", true);
    -- native_window:SetField("MoveViewWhenAttachWithIME", true);
	native_window:GetAttributeObject():SetDynamicField("isWindow", true); -- 宏示教忽略

    local params = self:GetParams();
    if (params.zorder) then native_window.zorder = params.zorder end
    if (params.isTopLevel ~= nil) then native_window.isTopLevel = params.isTopLevel end
    if (params.isPinned ~= nil) then native_window.isPinned = params.isPinned end 
    if (params.isClickThrough ~= nil) then native_window:GetAttributeObject():SetField("ClickThrough", params.isClickThrough) end

    -- 加到有效窗口上
    if(params.parent) then
        params.parent:AddChild(native_window);
    else 
        native_window:AttachToRoot();
    end
	local event_list = { "ondraw", "onsize", "onmousedown", "onmouseup", "onmousemove", "onmousewheel", "onmouseleave", "onmouseenter", "onkeydown", "onkeyup", "oninputmethod", "onactivate", "onfocusin", "onfocusout", "ondestroy"};
	if (self:IsTouchMode()) then
        event_list = {"ondraw", "onsize", "onmousedown", "onmouseup", "onmousemove", "onmouseleave", "onmouseenter", "onkeydown", "onkeyup", "oninputmethod", "onactivate", "onfocusin", "onfocusout", "ondestroy"};
    else
        -- note tricky: we will disable mouse wheel emulation in windows' touch devices
        native_window:SetField("TouchTranslationAtt", 1);
    end
    
    local function GetHandle(event_type)
        return function()
            -- 鼠标事件
            if (event_type == "onmousedown" or event_type == "onmouseup" or event_type == "onmousemove" or event_type == "onmousewheel" or event_type == "onmouseleave" or event_type == "onmouseenter") then
                -- 正在播放宏示教则不处理系统事件
                if (self:IsPlaySimulateEvent()) then return end 
            end

            self:OnEvent(event_type);
        end
    end
    for _, event_type in ipairs(event_list) do
        native_window:SetScript(event_type, GetHandle(event_type));
    end

    return native_window;
end

function Window:OnEvent(event_type, event_args)
    local event = self.Event:Init(event_type, self, event_args);
    if (not event) then return end
    self:HandleEvent(event);
end

function Window:HandleEvent(event)
    local event_type = event:GetEventType();

    -- 事件模拟器预处理
    if (self:IsCanSimulateEvent()) then Simulator:Init(event, self) end

    if (event_type == "ondraw") then self:HandleRender() 
    elseif (event_type == "onsize") then self:HandleGeometryChangeEvent() 
    elseif (event_type == "onmousedown") then self:HandleMouseEvent(event)
    elseif (event_type == "onmouseup") then self:HandleMouseEvent(event)
    elseif (event_type == "onmousemove") then self:HandleMouseEvent(event)
    elseif (event_type == "onmousewheel") then self:HandleMouseEvent(event)
    elseif (event_type == "onmouseleave") then self:HandleMouseEnterLeaveEvent(event)
    elseif (event_type == "onmouseenter") then self:HandleMouseEnterLeaveEvent(event)
    elseif (event_type == "onkeydown") then self:HandleKeyEvent(event)
    elseif (event_type == "onkeyup") then self:HandleKeyEvent(event)
    elseif (event_type == "oninputmethod") then self:HandleKeyEvent(event)
    -- elseif (event_type == "onactivate") then self:HandleActivateEvent(event)
    elseif (event_type == "onfocusin") then self:HandleActivateEvent(event)
    elseif (event_type == "onfocusout") then self:HandleActivateEvent(event)
    elseif (event_type == "ondestroy") then self:HandleDestroyEvent()
    end

    -- 事件模拟生成机制
    if (self:IsCanSimulateEvent() and not Simulator:IsSimulated()) then Simulator:GetDefaultSimulator():Simulate(event, self) end
end

-- 获取窗口位置
function Window:GetWindowPosition()
    return self.windowX, self.windowY, self.windowWidth, self.windowHeight;
end

-- 设置窗口位置
function Window:SetWindowPosition(x, y, w, h)
    local isChangeSize = self.windowWidth ~= w or self.windowHeight ~= h;
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, w, h;
    if (isChangeSize) then self:UpdateLayout() end
end

-- 获取元素相对屏幕的坐标
function Window:GetScreenPosition()
    return self.screenX, self.screenY, self.screenWidth, self.screenHeight;
end

-- 窗口大小改变
function Window:HandleGeometryChangeEvent()
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = self:GetNativeWindow():GetAbsPosition();
end

-- Handle ondraw callback from system ParaUI object. 
function Window:HandleRender()
    if (not self:GetNativeWindow()) then return end
    local painter = self:GetPainterContext();
    painter:Scale(self.scaleX, self.scaleY);
    self:Render(painter);
    painter:Scale(1 / self.scaleX, 1 / self.scaleY);
    painter:Flush();
end

-- 获取方法名通过事件名
function Window:GetEventTypeFuncName(event)
    local eventName = event:GetType();
    if (eventName == "mousePressEvent") then
        return "OnMouseDownCapture", "OnMouseDown";
    elseif (eventName == "mouseReleaseEvent") then
        return "OnMouseUpCapture", "OnMouseUp";
    elseif (eventName == "mouseMoveEvent") then
        return "OnMouseMoveCapture", "OnMouseMove";
    elseif (eventName == "mouseWheelEvent") then
        return "OnMouseWheelCapture", "OnMouseWheel";
    elseif (eventName == "mouseEnterEvent") then
        return "OnMouseEnterCapture", "OnMouseEnter";
    elseif (eventName == "mouseLeaveEvent") then
        return "OnMouseLeaveCapture", "OnMouseLeave";
    else 
        return "OnMouseCapture", "OnMouse";
    end
end

function Window:GetMouseTargetElement(event)
    if (self:IsTouchMode()) then
        if (event:GetType() == "mousePressEvent") then 
            local fingerSize, fingerStepSize = 20, 5;
            local stepCount = fingerSize / fingerStepSize / 2;
            local lastZIndex, lastRadius, lastMouseX, lastMouseY, lastEl, lastIsExistMouseEvent = "", 0, 0, 0, self, false;
            local mouseX, mouseY = event.x, event.y;
            for i = -stepCount, stepCount do
                for j = -stepCount, stepCount do 
                    local newMouseX, newMouseY = mouseX + i * fingerStepSize,  mouseY + j * fingerStepSize;
                    event.x, event.y = newMouseX, newMouseY;
                    local el, zindex = self:GetMouseHoverElement(event);
                    local radius = i * i + j * j;
                    local isExistMouseEvent = el and el:IsExistMouseEvent();
                    local selected = not lastIsExistMouseEvent and isExistMouseEvent;
                    selected = selected or (lastIsExistMouseEvent == isExistMouseEvent and zindex > lastZIndex);
                    selected = selected or (lastIsExistMouseEvent == isExistMouseEvent and zindex == lastZIndex and radius < lastRadius);
                    if (selected) then
                         lastMouseX, lastMouseY, lastZIndex, lastRadius, lastEl, lastIsExistMouseEvent = newMouseX, newMouseY, zindex, radius, el, isExistMouseEvent;
                    end
                end
            end
            event.x, event.y = lastMouseX, lastMouseY;
            self.last_mouse_down_x, self.last_mouse_down_y, self.last_hover_element = lastMouseX, lastMouseY, lastEl;
        end
        if (event:GetType() == "mouseReleaseEvent" and event:GetLastType() == "mousePressEvent") then
            event.x, event.y = self.last_mouse_down_x, self.last_mouse_down_y;
        end
    end

    local element, eventType = nil, event:GetType();
    if (eventType == "mouseMoveEvent") then
        element = self:Hover(event, true);
    else 
        element = self:GetMouseHoverElement(event);
    end
    return element or self;
end

-- 鼠标事件处理函数
function Window:HandleMouseEvent(event)
    if (not self:GetNativeWindow()) then return end
    -- local BeginTime = ParaGlobal.timeGetTime();
    local isCanSimulateEvent = self:IsCanSimulateEvent();
    local eventType = event:GetType();
    local captureFuncName, bubbleFuncName = self:GetEventTypeFuncName(event);

    -- 优先捕获鼠标元素
    local captureElement = self:GetMouseCapture();
    event.target = captureElement;
    if (captureElement) then
        -- captureElement:HandleMouseEventBefore(event);
        captureElement:HandleMouseCaptureEventBefore(event);
        captureElement:CallEventCallback(captureFuncName, event);
        captureElement:HandleMouseCaptureEventAfter(event);
        captureElement:HandleMouseBubbleEventBefore(event);
        captureElement:CallEventCallback(bubbleFuncName, event);
        captureElement:HandleMouseBubbleEventAfter(event);
        -- captureElement:HandleMouseEventAfter(event);
        if (isCanSimulateEvent and not Simulator:IsSimulated()) then captureElement:SimulateEvent(event) end 
        return ;        
    end

    -- 获取悬浮元素
    -- local hoverElement = self:Hover(event, true) or self;
    local hoverElement = self:GetMouseTargetElement(event);
    local lastHoverElement = self:GetHoverElement();
    if (lastHoverElement ~= hoverElement) then
        if (lastHoverElement) then lastHoverElement:CallEventCallback("OnMouseOut", event) end
        self:SetHoverElement(hoverElement);
        hoverElement:CallEventCallback("OnMouseOver", event);
    end

    event.target = hoverElement;
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "Hover 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);

    -- 获取事件元素列表
    local el = hoverElement;
    -- while (el and el:IsContainPoint(event.x, event.y)) do -- 不再识别是否为在元素内, 否则无法为元素事件处理添加过滤处理
    while (el) do
        table.insert(EventElementList, el);
        el = el:GetParentElement();
    end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "获取元素列表 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 不在任何元素内, 则丢给窗口处理
    if (#EventElementList == 0) then EventElementList[1] = hoverElement or self end 

    -- 模拟手机滚动事件
    -- self:SimulateTouchMouseWheelEvent(EventElementList, event);

    -- 捕获事件
    local EventElementCount = #EventElementList;
    -- for i = EventElementCount, 1, -1 do
    --     EventElementList[i]:HandleMouseEventBefore(event);
    --     if (event:IsAccepted()) then break end
    -- end
    for i = EventElementCount, 1, -1 do
        EventElementList[i]:HandleMouseCaptureEventBefore(event);
        if (event:IsAccepted()) then break end
    end
    for i = EventElementCount, 1, -1 do
        el = EventElementList[i];
        el:CallEventCallback(captureFuncName, event);
        if (isCanSimulateEvent and not Simulator:IsSimulated()) then el:SimulateEvent(event) end 
        if (event:IsAccepted()) then break end
    end
    for i = EventElementCount, 1, -1 do
        EventElementList[i]:HandleMouseCaptureEventAfter(event);
        if (event:IsAccepted()) then break end
    end
    
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "捕获事件 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 冒泡事件
    for i = 1, EventElementCount, 1 do
        EventElementList[i]:HandleMouseBubbleEventBefore(event);
        if (event:IsAccepted()) then break end
    end
    for i = 1, EventElementCount, 1 do
        el = EventElementList[i];
        el:CallEventCallback(bubbleFuncName, event);
        if (event:IsAccepted()) then break end
    end 
    for i = 1, EventElementCount, 1 do
        EventElementList[i]:HandleMouseBubbleEventAfter(event);
        if (event:IsAccepted()) then break end
    end
    -- for i = 1, EventElementCount, 1 do
    --     EventElementList[i]:HandleMouseEventAfter(event);
    --     if (event:IsAccepted()) then break end
    -- end

    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "冒泡事件 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 清空列表
    for i = 1, EventElementCount, 1 do EventElementList[i] = nil end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "清除元素列表 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 聚焦目标元素  聚焦与事件是否处理无关
    -- if (event:IsAccepted()) then return end

    if((eventType == "mousePressEvent" or eventType == "mouseReleaseEvent") and event:IsLeftButton()) then
        self:SetMouseUpElement(hoverElement);
        if (eventType == "mousePressEvent") then
            self:SetMouseDownElement(hoverElement);
        end
        -- self:SetFocus(if_else(hoverElement:IsDisabled(), nil, hoverElement));
    end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "鼠标事件 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
end

function Window:HandleMouseEnterLeaveEvent(event)
    if (event:GetType() == "mouseLeaveEvent") then
        -- self:SetHover(nil);
    end
end

function Window:HandleKeyEvent(event)
    if (not self:GetNativeWindow()) then return end

    local focusElement = self:GetFocus();
    if (focusElement) then
        if (event:GetType() == "keyPressEvent") then
            focusElement:CallEventCallback("OnKeyDown", event);
        elseif (event:GetType() == "keyReleaseEvent") then 
            focusElement:CallEventCallback("OnKeyUp", event);  -- 不生效
        else
            focusElement:CallEventCallback("OnKey", event);
        end
    end
end

function Window:HandleActivateEvent(event)
    local isActivate = event:IsActivate();
    local G = self:GetG();
    if (type(G.OnActivate) == "function") then
        G.OnActivate(isActivate);
    end
end

function Window:HandleDestroyEvent()
end

-- 执行字符串代码  返回 result, errmsg
function Window:ExecCode(code)
    local code_func, errmsg = loadstring(code);
    if (not code_func) then 
        WindowDebug.Format("Window ExecCode Error: %s", errmsg);
        return nil, errmsg;
    end
    -- 设置脚本执行环境
    setfenv(code_func, self:GetG());
    -- 执行脚本
    local result = code_func();
    return result, nil;
end

-- 设置最小根窗口宽高
function Window:SetMinRootScreenWidthHeight(minRootScreenWidth, minRootScreenHeight)
    self.minRootScreenWidth, self.minRootScreenHeight = minRootScreenWidth, minRootScreenHeight;
    if (not self.minRootScreenWidth or not self.minRootScreenHeight) then return end
    self:OnScreenSizeChanged();
end

-- 屏幕窗口大小改变
function Window:OnScreenSizeChanged()
    if (self:Is3DWindow()) then return end;
    if (not self.rootScreenWidth or not self.rootScreenHeight) then return end
    local nativeWnd = self:GetNativeWindow();
	if (not nativeWnd) then return end 
    local screenX, screenY, screenWidth, screenHeight = self:InitWindowPosition();
    nativeWnd:Reposition("_lt", screenX, screenY, screenWidth, screenHeight);
    self:UpdateLayout(true);
end