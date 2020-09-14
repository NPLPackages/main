--[[
Title: Window GUI
Author(s): LiXizhi
Date: 2015/4/20
Desc: Window is the only connector between ParaUI system and self painted NPL UI.
It redirect (mouse/key) events from ParaUI system to self-painted UI element system. 

handleXXX or XXX_sys are handlers of the native ParaUI system
eventXXX are event of the widget system. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local Window = commonlib.gettable("System.Windows.Window")
local my_window = Window:new();
my_window:Show("my_window", nil, "_lt", 0,0, 200, 100);

local my_window = System.Windows.Window:new();
my_window:Show({url="script/apps/Aries/Creator/Game/Login/SelectModulePage.html", alignment="_lt", left=0, top=0, width=300, height=200, zorder=10, allowDrag=true});
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Application.lua");
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/ide/System/Windows/KeyEvent.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/System/Core/Event.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/gui_helper.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local Point = commonlib.gettable("mathlib.Point");
local Event = commonlib.gettable("System.Core.Event");
local SizeEvent = commonlib.gettable("System.Windows.SizeEvent");
local InputMethodEvent = commonlib.gettable("System.Windows.InputMethodEvent");
local Mouse = commonlib.gettable("System.Windows.Mouse")
local Application = commonlib.gettable("System.Windows.Application");
local UIElement = commonlib.gettable("System.Windows.UIElement");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local Window = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Window"));

Window:Property("Name", "Window");
Window:Property({"AutoClearBackground", true, nil, "SetAutoClearBackground"});
Window:Property({"CanDrag", false, auto=true});
Window:Property({"Alignment", "_lt", auto=true});
Window:Property({"zorder", nil, "GetZOrder", "SetZOrder", auto=true});
Window:Property({"uiScaling", nil, "GetUIScaling", "SetUIScaling"}); -- x, y
Window:Property({"InputMethodEnabled", true, "IsInputMethodEnabled", "SetInputMethodEnabled", auto=true});
Window:Property({"DestroyOnClose", true,  "IsDestroyOnClose", "SetDestroyOnClose", auto=true});


Window:Signal("urlChanged", function(url) end)
Window:Signal("windowClosed", function() end)


function Window:ctor()
	self.window = self;
	self:setAttribute("WA_AlwaysShowToolTips", true);
	self:setFocusPolicy(FocusPolicy.NoFocus);
end

-- show and bind to a new ParaUI control object to receive events from. 
-- @param name_or_params: name or params {}
-- @param parent: if nil, it is the root GUI object. 
-- @param left,top, width, height: if nil, we will render at full size of parent.  
function Window:Show(name_or_params, parent, alignment, left, top, width, height, zorder)
	local params;
	if(type(name_or_params) == "table") then
		params = name_or_params;
	else
		params = {
			name = name_or_params,
			parent = parent,
			alignment = alignment,
			left = left,
			top = top,
			width = width,
			height = height,
			zorder = zorder,
		};
	end
	return self:ShowWithParams(params);
end

-- goto a new mcml v2 url
function Window:Goto(url)
	self.url = url;
	self:RefreshUrlComponent();
end

function Window:RefreshUrlComponent()
	if(self.url) then
		self:LoadComponent(self.url);
		self:urlChanged(self.url);
		-- generate size event
		local event = SizeEvent:new():init(self.crect)
		Application:sendEvent(self, event);
	end
end

-- @return mcml page object if valid
function Window:LoadComponent(url)
	local page = Window._super.LoadComponent(self, url);	
	if(page and self.pageGlobalTable) then
		-- force creating page scope
		page:GetPageScope();
	end
	return page;
end

function Window:GetZOrder()
	return self.zorder
end

function Window:SetZOrder(zorder)
	if(self.zorder~=zorder) then
		self.zorder = zorder;
		local nativeWnd = self:GetNativeWindow();
		if(nativeWnd) then
			nativeWnd.zorder = zorder;
		end
	end
end

-- virtual function
function Window:FilterImage(filename)
	return filename;
end

-- @param params: {url="", alignment, x,y,width, height, allowDrag,zorder, enable_esc_key, DestroyOnClose, parent, pageGlobalTable}
-- pageGlobalTable can be a custom page environment table, if nil, it will be the global _G. 
function Window:ShowWithParams(params)
	self.name = params.name;
	self.pageGlobalTable = params.pageGlobalTable;

	-- load component if url has changed
	if(self.url ~= params.url) then
		self.url = params.url;
		if(params.url) then
			self:LoadComponent(params.url);
			self:urlChanged(self.url);
		end
	end
	if(not self:isCreated()) then
		self:create_sys();
	end
	local bShow = true;
	if(bShow) then
		local nativeWnd = self:GetNativeWindow();
		if(nativeWnd) then
			-- attach to parent if not
			if(not nativeWnd.parent:IsValid()) then
				local parent = params.parent or ParaUI.GetUIObject("root");
				parent:AddChild(nativeWnd);
			end
			-- reposition/attach to parent
			local left, top, width, height, alignment = params.left, params.top, params.width, params.height, params.alignment or "_lt";
			self.showParams = {left = left or 0, top = top or 0, width = width or self:width(), height=height or self:height(), alignment = alignment}
			self:SetAlignment(alignment);
			nativeWnd:Reposition(alignment, left or 0, top or 0, width or self:width(), height or self:height());
			local x, y, width, height = nativeWnd:GetAbsPosition();
			self.screen_x, self.screen_y = x, y;

			-- update geometry
			self:setGeometry(x, y, width, height);

			if(params.allowDrag) then
				self:SetCanDrag(true);
			end

			if(params.isTopLevel) then
				-- TODO:	
			end

			if(params.zorder) then
				nativeWnd.zorder = params.zorder;
				self.zorder = params.zorder;
			end
		end
	end
	self:SetDestroyOnClose(params.DestroyOnClose)
	if(params.enable_esc_key) then
		self.esc_state = self.esc_state or {name = "McmlEscKey", OnEscKey = function()  
			self:CloseWindow();
		end}
		System.PushState(self.esc_state);
	end

	-- show the window
	self:show();
end

-- @param bDestroy: if true or nil, it will destroy the window, otherwise it will just hide it.
function Window:CloseWindow(bDestroy)
	if(bDestroy == nil) then
		bDestroy = self:IsDestroyOnClose();
	end
	if(self:isActiveWindow()) then
		local wnd = self:GetNativeWindow()
		if(wnd) then
			wnd:LostFocus()
		end
	end
	if(bDestroy == false) then
		self:hide();
	else
		self:destroy();
	end
	if(self.esc_state) then
		System.PopState(self.esc_state);
	end
	self:windowClosed();
	if (bDestroy) then 
		self:Destroy();
	end
end

function Window:GetNativeWindow()
	return self.native_ui_obj;
end

-- set the window's size to be the layout's used size
function Window:SetSizeToUsedSize()
	if(self:isVisible()) then
		local layout = self:GetLayout();
		if(layout and layout.GetUsedSize) then
			local width, height = layout:GetUsedSize();
			self:setGeometry_sys(self.screen_x, self.screen_y, width, height);
		end
	end
end

-- virtual: if this element is a native window, destroy it. 
function Window:destroy_sys()
	if(self.native_ui_obj) then
		ParaUI.Destroy(self.native_ui_obj.id);
		self.native_ui_obj = nil;
	end
end

-- bind to native window.
function Window:create_sys(native_window, initializeWindow, destroyOldWindow)
	if(self:testAttribute("WA_WState_Created")) then
		LOG.std(nil, "warn", "Window", "window already created before");
		return;
	end

	if(not native_window) then
		native_window = ParaUI.CreateUIObject("container", self.name or "Window", "_lt", 0, 0, self:width(), self:height());
		native_window.background = "";
		native_window:SetField("OwnerDraw", true); -- enable owner draw paint event
	end

	-- painting context
	self.painterContext = System.Core.PainterContext:new():init(self);
	
	local _this = native_window;
	self.native_ui_obj = _this;
	self:setAttribute("WA_WState_Created");     
	self:UpdateGeometry_Sys();
	if(self.bSelfPaint~=nil) then
		self:EnableSelfPaint(self.bSelfPaint);
	end
	if(not self.AutoClearBackground) then
		self:SetAutoClearBackground(self.AutoClearBackground);
	end

	-- redirect events from native ParaUI object to this object. 
	_this:SetScript("onsize", function()
		self:handleGeometryChangeEvent();
	end);
	_this:SetScript("ondraw", function()
		self:handleRender();
	end);
	_this:SetScript("onmousedown", function()
		self:handleMouseEvent(MouseEvent:init("mousePressEvent", self));
	end);
	_this:SetScript("onmouseup", function()
		self:handleMouseEvent(MouseEvent:init("mouseReleaseEvent", self));
	end);
	_this:SetScript("onmousemove", function()
		self:handleMouseEvent(MouseEvent:init("mouseMoveEvent", self));
	end);
	_this:SetScript("onmousewheel", function()
		self:handleMouseEvent(MouseEvent:init("mouseWheelEvent", self));
	end);
	_this:SetScript("onmouseleave", function()
		self:handleMouseEnterLeaveEvent(MouseEvent:init("mouseLeaveEvent", self));
	end);
	_this:SetScript("onmouseenter", function()
		self:handleMouseEnterLeaveEvent(MouseEvent:init("mouseEnterEvent", self));
	end);
	_this:SetScript("onkeydown", function()
		local event = KeyEvent:init("keyPressEvent")
		
		self:HandlePagePressKeyEvent(event);
		if(not event:isAccepted()) then
			Application:sendEvent(self:focusWidget(), event);
		end

		if(not event:isAccepted()) then
			local context = SceneContextManager:GetCurrentContext();
			if(context) then
				context:handleKeyEvent(event);
			end
		end
	end);
	_this:SetScript("onkeyup", function()
		Application:sendEvent(self:focusWidget(), KeyEvent:init("keyReleaseEvent"));
	end);
	_this:SetScript("oninputmethod", function()
		Application:sendEvent(self:focusWidget(), InputMethodEvent:new():init(msg));
	end);
	_this:SetScript("onactivate", function()
		local isActive = (param1 and param1>0);
		self:handleActivateEvent(isActive);
	end);
	_this:SetScript("onfocusin", function()
		self:handleActivateEvent(true);
	end);
	_this:SetScript("onfocusout", function()
		if(self:focusWidget() and self:focusWidget():hasFocus()) then
			self:handleActivateEvent(false);
		end
	end);
	_this:SetScript("ondestroy", function()
		self:handleDestroy_sys();
	end);
end

function Window:handleGeometryChangeEvent()
	self:UpdateGeometry_Sys();
end

function Window:isWindow()
	return true;
end

-- @param event_type: "mousePressEvent", "mouseMoveEvent", "mouseWheelEvent", "mouseReleaseEvent"
function Window:handleMouseEvent(event)
	event:updateModifiers();
	
	-- which child should have it?
	local widget = self:childAt(event:pos()) or self;
	local mapped = event:pos();

	if(event:GetType() == "mousePressEvent") then
		Application.qt_button_down = widget;
	end

	local receiver = Application:pickMouseReceiver(self, event:windowPos(), mapped, event:GetType(), event:buttons(), Application.qt_button_down, widget);

	if(receiver~=self) then
		event:localPos():set(receiver:mapFromGlobal(event:globalPos()));
	end

	Application:sendMouseEvent(receiver, event);

	if(event:GetType() == "mouseReleaseEvent") then
		Application.qt_button_down = nil;
	end
end

-- @param event_type: "mouseEnterEvent", "mouseLeaveEvent"
function Window:handleMouseEnterLeaveEvent(mouse_event)
	mouse_event:updateModifiers();
	if(mouse_event:GetType() == "mouseLeaveEvent") then
		local enter;
		-- TODO: shall we peek the message queue? 
		if(not enter) then
			local receiver = Mouse:GetCapture() or self:childAt(mouse_event:localPos()) or self;
			if(receiver~=self) then
				mouse_event:localPos():set(receiver:mapFromGlobal(mouse_event:globalPos()));
			end
			Application:dispatchMouseEnterLeave(enter, receiver, mouse_event:globalPos());
			Application.lastMouseReceiver = enter;
		end
	else -- "mouseEnterEvent"
		local receiver = Mouse:GetCapture() or self:childAt(mouse_event:localPos()) or self;
		if(receiver~=self) then
			mouse_event:localPos():set(receiver:mapFromGlobal(mouse_event:globalPos()));
		end
		Application:dispatchMouseEnterLeave(receiver, nil, mouse_event:globalPos());
        Application.lastMouseReceiver = receiver;
	end
end

-- update geometry according to native ParaUI object
function Window:UpdateGeometry_Sys()
	local x, y, width, height = self.native_ui_obj:GetAbsPosition();
	self.screen_x, self.screen_y = x, y;
	local scalingX, scalingY = self:GetUIScaling();
	if(scalingX~=1 or scalingY~=1) then
		width, height = math.floor(width/scalingX + 0.5), math.floor(height/scalingY + 0.5)
	end
	if(self:width() ~= width or self:height() ~= height) then
		self:setGeometry(self.screen_x, self.screen_y, width, height);
	end
end

function Window:GetScreenPos()
	return self.screen_x, self.screen_y;
end

function Window:setGeometry_sys(ax, ay, aw, ah)
	local isResize = self:width()~=aw or self:height()~=ah;
	local isMove = self.screen_x~=ax or self.screen_y~=ay;
	if(not isResize and not isMove) then
		-- We only care about stuff that changes the geometry
		return;
	end
	if(isResize) then
		self.crect:setRect(0, 0, aw, ah);

		if (self:isVisible()) then
			if(not isMove) then
				if(self:GetAlignment() == "_lt") then
					-- ignore resizing the native window if the alignment type is not left top. 
					local scalingX, scalingY = self:GetUIScaling();
					if(scalingX~=1 or scalingY~=1) then
						aw, ah = math.floor(aw*scalingX + 0.5), math.floor(ah*scalingY + 0.5)
					end
					self.native_ui_obj:SetSize(aw, ah);
				end
			end
			-- generate size event
			local event = SizeEvent:new():init(self.crect)
			Application:sendEvent(self, event);
		else
			-- not visible
			if(isResize or isMove) then
				self:setAttribute("WA_PendingSizeEvent");
			end
		end
		self:emitSizeChanged();
	end
	if(self:isVisible()) then
		if(isMove) then
			self.screen_x=ax;
			self.screen_y=ay;
			-- always use left top alignment when dragging a window with other alignment types. 
			self:SetAlignment("_lt");
			local scalingX, scalingY = self:GetUIScaling();
			if(scalingX~=1 or scalingY~=1) then
				aw, ah = math.floor(aw*scalingX + 0.5), math.floor(ah*scalingY + 0.5)
			end
			self.native_ui_obj:Reposition("_lt", ax, ay, aw, ah);
		
			-- generate size event
			local event = SizeEvent:new():init(self.crect)
			Application:sendEvent(self, event);
		end
	end
end

function Window:show_sys()
	self:setVisible_sys(true);
end

function Window:hide_sys()
	self:setVisible_sys(false);
end

function Window:setVisible_sys(visible)
	if(self.native_ui_obj) then
		self.native_ui_obj.visible = visible == true;
	end
end

-- set whether the window will paint on its own render target. default is false. 
function Window:EnableSelfPaint(bSelfPaint)
	self.bSelfPaint = bSelfPaint;
	if(self.native_ui_obj) then
		self.native_ui_obj:SetField("SelfPaint", self.bSelfPaint);
	end
end

-- force repaint in the next frame.
function Window:repaint()
	self.isRepaintScheduled = true;
			
	if(self.bSelfPaint) then
		if(self.native_ui_obj) then
			self.native_ui_obj:SetField("IsDirty", true);
		end
	else
		-- it will be repainted anyway, so do nothing. 
	end
end

-- set key focus to the window. 
function Window:SetFocus_sys()
	if(self.native_ui_obj) then
		if(not self.CanHaveFocus) then
			-- enable key focus only once
			self.CanHaveFocus = true;
			self.native_ui_obj:SetField("CanHaveFocus", self.CanHaveFocus); 
			self.native_ui_obj:SetField("InputMethodEnabled", self.CanHaveFocus and self:IsInputMethodEnabled()); 
		end
		self.native_ui_obj:Focus();
	end
end

function Window:SetInputMethodEnabled(bEnabled)
	self.InputMethodEnabled = bEnabled;
	if(self.native_ui_obj) then
		self.native_ui_obj:SetField("InputMethodEnabled", bEnabled==true); 
	end
end

-- Updates the widget unless updates are disabled or the widget is hidden.
-- This function does not cause an immediate repaint; instead it schedules a paint in the next frame.
function Window:update()
	self:markDirty();
end

-- causing a repaint
function Window:markDirty()
	if(not self.isRepaintScheduled) then
		self:repaint();
	end
end

-- handle ondraw callback from system ParaUI object. 
function Window:handleRender()
	local page = self:Page();
	if(page and page.bindingContext) then
		page.bindingContext:ApplyGetters();
	end
	self.isRepaintScheduled = false;
	self:Render(self.painterContext);
	if(self.bSelfPaint) then
		-- for some reason, opengl sprites needs to be flushed in order to paint
		self.painterContext:Flush();
	end
end

-- whether to automatically clear the background to fully transparent when doing self paint on its own render target.
function Window:SetAutoClearBackground(bEnabled)
	self.AutoClearBackground = (bEnabled == true);
	if(self.native_ui_obj) then
		self.native_ui_obj:SetField("AutoClearBackground", self.AutoClearBackground);
	end
end

-- Sets whether mouse capture should be enabled or not
-- If the return value is true, the window receives all mouse events until SetMouseGrabEnabled(false) is
-- called; other windows get no mouse events at all. Keyboard events are not affected.
function Window:SetMouseCaptureEnabled(bEnabled)
	if(self.native_ui_obj) then
		self.MouseCaptureEnabled = (bEnabled == true);
		self.native_ui_obj:SetField("MouseCaptured", self.MouseCaptureEnabled);
	end
end

function Window:IsMouseCaptureEnabled()
	return self.MouseCaptureEnabled;
end

function Window:handleActivateEvent(isActivate)
	if(isActivate) then
		Application:setActiveWindow(self);
	else
		Application:setActiveWindow(nil);
	end
end

-- native windows have been forcibly closed. 
function Window:handleDestroy_sys()
	self:setAttribute("WA_WState_Created", false);
	self.native_ui_obj = nil;
	
	Application:sendEvent(self, Event:new_static("windowDestroyEvent"));

	if(self:IsMouseCaptureEnabled()) then
		local capturedElem = Mouse:GetCapture();
		if(capturedElem and capturedElem.window == self) then
			Mouse:Capture(nil);
		end
	end
end

-- virtual called when native window is destroyed. 
function Window:windowDestroyEvent()
end

-- convert to global position
-- @return the returned Point is temporary, do not hold it for long
function Window:mapToGlobal(pos)
	if((self.uiScalingX or 1) == 1 and (self.uiScalingY or 1) == 1) then
		return Point:new_from_pool(self.screen_x + pos:x(), self.screen_y + pos:y());
	else
		return Point:new_from_pool(self.screen_x + math.floor(pos:x()*self.uiScalingX+0.5), self.screen_y + math.floor(pos:y()*self.uiScalingY+0.5));
	end
end

-- convert from global to local pos. 
-- @return the returned Point is temporary, do not hold it for long
function Window:mapFromGlobal(pos)
	if((self.uiScalingX or 1) == 1 and (self.uiScalingY or 1) == 1) then
		return Point:new_from_pool(-self.screen_x + pos:x(), -self.screen_y + pos:y());
	else
		return Point:new_from_pool(math.floor((-self.screen_x + pos:x())/self.uiScalingX+0.5), math.floor((-self.screen_y + pos:y())/self.uiScalingY+0.5));
	end
end

function Window:SetUIScaling(scaleX, scaleY)
	scaleX = scaleX or 1;
	scaleY = scaleY or scaleX;
	self.uiScalingX = scaleX;
	self.uiScalingY = scaleY;
	if(scaleX == 1 and scaleY==1) then
		self.transform = nil
	else
		self.transform = self.transform or {};
		self.transform.scale = {scaleX, scaleY};
	end
end

function Window:GetUIScaling()
	return self.uiScalingX or 1, self.uiScalingY or 1;
end

function Window:setCompositionPoint_sys(p)
	if(self.native_ui_obj and p and p[1]) then
		self.native_ui_obj:SetField("CompositionPoint", p);
	end
end

function Window:paintEvent(painter)
end

-- virtual: 
function Window:mousePressEvent(event)
	if(event:isAccepted()) then
		return true;
	end
	if(self:GetCanDrag() and event:button()=="left") then
		self.isMouseDown = true;
		self.startDragPosition = event:screenPos():clone();
		event:accept();
	end
end

function Window:mouseMoveEvent(event)
	if(event:isAccepted()) then
		return true;
	end
	if(self.isMouseDown and self:GetCanDrag() and event:button() == "left") then
		if(not self.isDragging) then
			if(event:screenPos():dist2(self.startDragPosition[1], self.startDragPosition[2]) > 2) then
				self.isDragging = true;
				self.startDragWinLocation = Point:new():init(self.screen_x, self.screen_y);
				self:CaptureMouse();
			end
		elseif(self.isDragging) then
			local newPos = self.startDragWinLocation + event:screenPos() - self.startDragPosition;
			self:move(newPos[1], newPos[2]);
		end
		if(self.isDragging) then
			event:accept();
		end
	end
end

function Window:mouseReleaseEvent(event)
	if(self.isDragging) then
		self.isDragging = false;
		self:ReleaseMouseCapture();
		event:accept();
	end
	self.isMouseDown = nil;
end

function Window:SetEnabled(enabled)
	self.enabled = enabled;
	if(self.native_ui_obj) then
		self.native_ui_obj.enabled = enabled;
	end
end

function Window:isEnabled()
	return self.enabled;
end

function Window:Page()
	if(self.layout) then
		return self.layout:GetPage();
	end
end

function Window:HandlePagePressKeyEvent(event)
	local page = self:Page();
	if(page) then
		if(page:HandlKeyPressEvent(event:KeyName())) then
			event:accept();
		end
	end
end

-- the parent container must be larger than or equal to this screen size
-- otherwise we will scale the screen.
function Window:SetMinimumScreenSize(minScreenWidth,minScreenHeight)
	self.minScreenWidth = minScreenWidth;
	self.minScreenHeight = minScreenHeight;
	
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	viewport:Connect("sizeChanged", self, "OnViewportSizeChange", "UniqueConnection")

	self:OnViewportSizeChange();
end

function Window:OnViewportSizeChange()
	if(self.minScreenWidth and self.minScreenHeight) then
		local nativeWnd = self:GetNativeWindow();
		if(nativeWnd) then
			local parent = nativeWnd.parent
			if(not parent:IsValid()) then
				parent = ParaUI.GetUIObject("root");
			end
			local x, y, width, height = parent:GetAbsPosition();
			local scalingWidth, scalingHeight = 1, 1;
			if(width < self.minScreenWidth) then
				scalingWidth = width / self.minScreenWidth;
			end
			if(height < self.minScreenHeight) then
				scalingHeight = height / self.minScreenHeight;
			end
			local scaling = math.min(scalingWidth, scalingHeight);
			self:SetUIScaling(scaling, scaling);

			if(self.showParams) then
				local params = self.showParams;
				local left, top, width, height, alignment = params.left, params.top, params.width, params.height, params.alignment or "_lt";
				self:SetAlignment(alignment);
				nativeWnd:Reposition(alignment, math.floor(left * scaling+0.5), math.floor(top * scaling + 0.5), math.floor(width * scaling + 0.5), math.floor(height * scaling+0.5));

				local x, y, width, height = nativeWnd:GetAbsPosition();
				width, height = math.floor(width/scaling + 0.5), math.floor(height/scaling + 0.5)
				self:setGeometry(self.screen_x, self.screen_y, width, height);
			end
		end
	end
end
