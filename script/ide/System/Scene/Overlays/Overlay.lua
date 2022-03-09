--[[
Title: Overlay
Author(s): LiXizhi@yeah.net
Date: 2015/8/10
Desc: Overlay provides custom 3D drawings to the scene after main 3d scene is rendered. 
Overlay is usually used to render helper objects such as translation/rotation/scaling manipulators.
Internally it uses 3D object's headon display interface and GUI painter API. 
In addition to lines and triangles, one can render any kind of GUI objects and even provides interactions in the 3d scene.  

---++ On Rendering
Overlay is rendered with two passes + (on demand picking pass):
	paintZPassEvent: which rendered parts behind main 3d scene, where z test failed.  
	paintEvent: which rendered parts in front of main 3d scene, where z test succeed.
	paintPickingEvent: render picking colors, default to paintEvent().
Normally, we will render object with a transparent color or special texture in the paintZPassEvent, 
and then render the object again with a solid color in paintEvent.

---++ On Picking 
When picking is enabled, we will render all overlays to a special render target and read back 
pixel colors at current mouse rectangle. 
By default, the paintEvent() is responsible for both rendering and picking, 
although one can override paintPickingEvent to fully customize what is pickable. 

To make paintEvent() easier to write for both rendering and picking, the follow helper functions 
can be used to set pen color automatically for rendering and picking pass.
	SetColorAndName()
	GetFirstPick()

One needs to override HasPickingName in order to have mouse event delivered. 

---++ Virtual functions:
	paintEvent
		paintZPassEvent
		paintPickingEvent
	HasPickingName(pickingName)   implement this to have mouse event delivered
	mousePressEvent(event)
	mouseMoveEvent
	mouseReleaseEvent

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Overlays/Overlay.lua");
local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
local layer1 = Overlay:new():init();
layer1:SetPosition(ParaScene.GetPlayer():GetPosition());
layer1.paintEvent = function(self, painter)
	self:SetColorAndName(painter, "#ff0000");
	ParaPainter.DrawRect(-100, -100, 100, 100);
	self:SetColorAndName(painter, "#00ff00");
	ParaPainter.DrawLine(0, 0, 0, 200);
end
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Overlays/OverlayPicking.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local OverlayPicking = commonlib.gettable("System.Scene.Overlays.OverlayPicking");
local type = type;

local Overlay = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Overlays.Overlay"));

Overlay:Property("Name", "Overlay");
Overlay:Property({"enabled", true, "isEnabled", auto=true});
Overlay:Property({"visible", true, "IsVisible", "SetVisible"});
Overlay:Property({"EnableZPass", true});
Overlay:Property({"ZPassOpacity", 0.2, "GetZPassOpacity", "SetZPassOpacity", auto=true});
Overlay:Property({"zorder", nil, "GetZOrder", "SetZOrder"});
Overlay:Property({"EnablePicking", true});
-- this is usually the last system time tick that render function is called.
Overlay:Property({"PickingRenderFrame", 0, auto=true});
Overlay:Property({"m_hasMouseTracking", nil, "hasMouseTracking", "setMouseTracking", auto=true});
Overlay:Property({"m_render_pass", false, });
Overlay:Property({"m_position", nil, "getPosition", "setPosition"});
Overlay:Property({"isSolid", nil, "IsSolid", "SetSolid"});
-- always use camera position
Overlay:Property({"UseCameraPos", false, "IsUseCameraPos", "SetUseCameraPos"});
-- default to nil, which self:Tick() is not called. 
Overlay:Property({"TickInterval", nil, "GetTickInterval", "SetTickInterval"});
Overlay:Property({"localTransform", nil, "GetLocalTransform", "SetLocalTransform"});


function Overlay:ctor()
	self.localTransform = Matrix4:new():identity();
end

local function compare_zorder_less(left, right)
	return (left.zorder or 0) < (right.zorder or 0);
end

-- @param parent: if nil, we will create as root. 
function Overlay:init(parent)
	if(parent) then
		local last = parent:GetChildren():last()
		self:SetParent(parent);

		if(last and not compare_zorder_less(last, self)) then
			parent:SortChildren();
		end
	else
		self:create_sys(nil);
	end
	-- automatically start ticking
	if(self:IsUseCameraPos()) then
		self:SetUseCameraPos(true);
	end
	if(self:GetTickInterval()) then
		self:SetTickInterval(self:GetTickInterval());
	end
	return self;
end

function Overlay:SetUseCameraPos(bEnabled)
	self.UseCameraPos = bEnabled;
	if(not self:GetTickInterval()) then
		self:SetTickInterval(33);
	end
end

function Overlay:IsUseCameraPos()
	return self.UseCameraPos;
end

function Overlay:SetTickInterval(interval)
	self.TickInterval = interval;
	if(interval) then
		if(not self.tick_timer) then
			self.tick_timer = commonlib.Timer:new({callbackFunc = function(timer)
				self:Tick();
			end})
		end
		self.tick_timer:Change(interval, interval)
	elseif(self.tick_timer) then
		self.tick_timer:Change(nil, nil);
	end
end

function Overlay:GetTickInterval()
	return self.TickInterval;
end


-- virtual function: 
-- only called when TickInterval is specified or UseCameraPos is true. 
function Overlay:Tick()
	if(self:IsUseCameraPos()) then
		self:UpdateToCameraPosition();
	end
end

-- the smaller, the earlier to render
-- @param order: default to 0, set to -1 to force render first. 
function Overlay:SetRenderOrder(order)
	if(self.native_scene_obj) then
		-- TRICKY: the C++ sorts by render_tech, instead of render_order, so we just set render_tech any way. 
		self.native_scene_obj:SetField("render_tech", order)
	end
end

-- zorder 
function Overlay:SetZOrder(zorder)
	if(self.zorder ~= zorder) then
		self.zorder = zorder;
		if(self.parent) then
			self.parent:SortChildren();
		end
	end
end

function Overlay:GetZOrder()
	return self.zorder or 0;
end

function Overlay:SortChildren()
	self:GetChildren():sort(compare_zorder_less)
end

-- private: bind to native scene object.
-- @param native_scene_obj: if nil, we will create one 
function Overlay:create_sys(native_scene_obj, x, y, z)
	if(not native_scene_obj) then
		native_scene_obj = ParaScene.CreateObject("COverlayObject", "", x or 0, y or 0, z or 0);
		ParaScene.Attach(native_scene_obj);
	end
	self.native_scene_obj = native_scene_obj;

	-- painting context
	self.painterContext = System.Core.PainterContext:new():init(self);
	
	local guiObject = self.native_scene_obj:GetAttributeObject():GetChild("gui"):QueryUIObject();
	guiObject:SetScript("ondraw", function()
		self:SetPickingRenderFrame(commonlib.TimerManager.GetCurrentTime())
		self:handleRender();
	end);

	if(self:IsSolid()) then
		self.native_scene_obj:SetField("transparent", false);
	end
end

-- default to false. solid object is rendered before all transparent ones in the scene. 
function Overlay:SetSolid(bIsSolid)
	if(self.isSolid ~= bIsSolid) then
		self.isSolid = bIsSolid;
		if(self.native_scene_obj) then
			self.native_scene_obj:SetField("transparent", not bIsSolid);
		end
	end
end

function Overlay:IsSolid()
	return self.isSolid;
end


-- send key events to all child nodes
function Overlay:handleKeyEvent(event)
	if(self.children) then
		local children = self.children;
		local child = children:first();
		while (child) do
			if(child.enabled) then
				child:handleKeyEvent(event);
				if(event:isAccepted()) then
					break;
				end
			end
			child = children:next(child);
		end
	end
	if(not event:isAccepted()) then
		self:event(event);
	end
end

-- we prefer to use handleKeyEvent (key down event) for processing key strokes.
function Overlay:handleKeyReleaseEvent(event)
	if(self.children) then
		local children = self.children;
		local child = children:first();
		while (child) do
			if(child.enabled) then
				if(child.handleKeyReleaseEvent) then
					child:handleKeyReleaseEvent(event);
				end
				if(event:isAccepted()) then
					break;
				end
			end
			child = children:next(child);
		end
	end
	if(not event:isAccepted()) then
		self:event(event);
	end
end

-- private: handle system ondraw message.
function Overlay:handleRender()
	local renderState = ParaScene.GetSceneState():GetField("RenderState", 0);
	self.m_render_pass = renderState;
	if(renderState == ParaEngine.SceneStateRenderState.RenderState_Overlay_ZPass) then
		if(self.EnableZPass) then
			self:DoPaintRecursive(self.painterContext, "paintZPassEvent");
		end
	elseif(renderState == ParaEngine.SceneStateRenderState.RenderState_Overlay_Picking) then
		if(self.EnablePicking) then
			self:DoPaintRecursive(self.painterContext, "paintPickingEvent");
		end
	else
		self:DoPaintRecursive(self.painterContext, "paintEvent");
	end
	self.m_render_pass = nil;
end

-- if we are currently rendering picking
function Overlay:IsPickingPass()
	return self.m_render_pass == ParaEngine.SceneStateRenderState.RenderState_Overlay_Picking;
end

-- if we are currently rendering z pass as transparent
function Overlay:IsZPass()
	return self.m_render_pass == ParaEngine.SceneStateRenderState.RenderState_Overlay_ZPass;
end

function Overlay:Destroy()
	if(self.native_scene_obj) then
		ParaScene.Delete(self.native_scene_obj);
		self.native_scene_obj = nil;
	end
	Overlay._super.Destroy(self);
end

function Overlay:SetVisible(bVisible)
	if(self.visible ~= bVisible) then
		self.visible = bVisible;
		if(self.native_scene_obj) then
			self.native_scene_obj:SetVisible(bVisible==true);
		end
	end
end

function Overlay:IsVisible()
	return self.visible;
end

-- called whenever an event comes. Subclass can overwrite this function. 
-- @param handlerName: "paintEvent", "mouseDownEvent", "mouseUpEvent", etc. 
-- @param event: the event object. 
function Overlay:event(event)
	if(not self:isEnabled()) then
		-- do nothing if not enabled. 
	else
		local event_type = event:GetType();
		local func = self[event:GetHandlerFuncName()];
		if(type(func) == "function") then
			func(self, event);
		end
	end
end

function Overlay:GetLocalTransform()
	return self.localTransform;
end

-- recalculate world matrix all the way up to root overlay. 
-- this is slow, do not calculate it every frame
-- @param mWorld: if not nil, we will pre-multiply this matrix.
-- @param bUseRenderOffset: if true, we will substract render origin 
-- @return Matrix4 
function Overlay:CalculateWorldMatrix(mWorld, bUseRenderOffset)
	local w = self;
	while(w) do
		if(w.localTransform) then
			if(not mWorld) then
				mWorld = w.localTransform:clone();
			else
				mWorld = mWorld * w.localTransform;
			end
			if(not w.parent) then
				local x, y, z = w:GetPosition();
				mWorld:offsetTrans(x or 0, y or 0, z or 0);
				if(bUseRenderOffset) then
					local orgin = Cameras:GetCurrent():GetRenderOrigin();
					mWorld:offsetTrans(-orgin[1], -orgin[2], -orgin[3]);
				end
				w = nil;
			else
				w = w.parent;
			end
		else
			w = nil;
		end
	end
	return mWorld;
end


-- set local transform
-- @param trans: nil or 4*4.  4*4 matrix is an array of 16 floats.
function Overlay:SetLocalTransform(trans)
	self.localTransform:set(trans);
end

function Overlay:PushLocalTransform(painter)
	painter:PushMatrix();
	if(not self.localTransform:equals(Matrix4.IDENTITY)) then
		painter:MultiplyMatrix(self.localTransform);
	end
end

function Overlay:PopLocalTransform(painter)
	painter:PopMatrix();
end

-- helper function to get a scaling factor for line width, according to current world scaling matrix
-- @param painter: if not nil, we will update line scaling from painter's current transform
-- if this nil, we will return the last result or 1.
function Overlay:GetLineScale(painter)
	if(painter) then
		local scalingX, scalingY, scalingZ = painter:GetScaling();
		local lineScale = 1;
		if(scalingX and scalingX~=1 and scalingX~=0) then
			lineScale = 1 / scalingX;
		end
		self.lineScale = lineScale;
		return lineScale;
	else
		return self.lineScale or 1;
	end
end

-- @param paintFuncName: should be "paintEvent", "paintPickingEvent", "paintZPassEvent", etc.
function Overlay:DoPaintRecursive(painter, paintFuncName)
	if(not self:IsVisible()) then
		return
	end
	self:BeginPaint(painter);
	self[paintFuncName](self, painter);
	if(self.children) then
		local children = self.children;
		local child = children:first();
		while (child) do
			child.m_render_pass = self.m_render_pass;
			child:DoPaintRecursive(painter, paintFuncName);
			child = children:next(child);
		end
	end
	self:EndPaint(painter)
end

-- virtual function: setup transform for this and child overlays
function Overlay:BeginPaint(painter)
	self:PushLocalTransform(painter);
end

-- virtual function: setup transform for this and child overlays
function Overlay:EndPaint(painter)
	self:PopLocalTransform(painter);
end

-- virtual: render everything here. do not paint child overlay. 
-- @param painter: painterContext
function Overlay:paintEvent(painter)
	
end

-- virtual: render picking colors. by default it will call paintEvent
-- @param painter: painterContext
function Overlay:paintPickingEvent(painter)
	self:paintEvent(painter);
end

-- virtual: render parts of the overlay when z test failed
-- we can render nothing here, or by default we render the same object with a transparent color.  
-- @sa: painter:SetOpacity
-- @param painter: painterContext
function Overlay:paintZPassEvent(painter)
	painter:SetOpacity(self.ZPassOpacity);
	self:paintEvent(painter);
end

-- set bounding box radius of the global root object. 
function Overlay:SetBoundRadius(radius)
	if(radius) then
		if(self.native_scene_obj) then
			self.native_scene_obj:SetField("radius", radius);
		elseif(self.parent) then
			self.parent:SetBoundRadius(radius);
		end
	end
end

-- Get bounding box radius of the global root object. 
function Overlay:GetBoundRadius()
	if(self.native_scene_obj) then
		return self.native_scene_obj:GetField("radius", 0);
	elseif(self.parent) then
		return self.parent:GetBoundRadius();
	end
end

-- set global 3d position. 
function Overlay:SetPosition(x,y,z)
	if(x and y and z) then
		if(self.native_scene_obj) then
			self.native_scene_obj:SetPosition(x, y, z);
		elseif(self.parent) then
			self.parent:SetPosition(x,y,z);
		end
	end
end

function Overlay:UpdateTileContainer()
end

-- get global 3d position
-- @return x, y, z;
function Overlay:GetPosition()
	if(self.native_scene_obj) then
		return self.native_scene_obj:GetPosition();
	elseif(self.parent) then
		return self.parent:GetPosition();
	end
end

-- @return a clone of {x,y,z}
function Overlay:getPosition()
	return vector3d:new({self:GetPosition()})
end

-- @param pos: {x,y,z}
function Overlay:setPosition(pos)
	if(pos and type(pos) == "table") then
		self:SetPosition(pos[1], pos[2], pos[3]);
	end
end


-- find next color int value that should be used for the picking color for next unique pickable item.
function Overlay:GetNextPickingName()
	return OverlayPicking:GetNextPickingName();
end

-- picking name from the last picking result.
function Overlay:GetActivePickingName()
	return OverlayPicking:GetActivePickingName();
end

-- this number is increased by 1 everytime picking buffer is redrawn, 
-- this is useful to decide if a pickingName is valid or associated with the current picking frame number
function Overlay:GetPickingFrameNumber()
	return OverlayPicking:GetPickingFrameNumber();
end

-- set position using the current camera position in the scene. 
-- this is useful when you want the overlay to be always visible. 
function Overlay:UpdateToCameraPosition()
	local x, y, z = ParaCamera.GetLookAtPos();
	self:SetPosition(x, y, z);
end

-- helper function that set color and picking color(name)
-- @param color: color used for normal rendering 
-- @param pickingColor: color used drawing picking pass. if nil, it is the same as the color. if false, it means object is not pickable (we will render it as black). 
function Overlay:SetColorAndName(painter, color, pickingColor)
	if(self:IsPickingPass()) then
		if(pickingColor == false) then
			pickingColor = 0;
		else
			if(type(pickingColor) == "number") then
				-- add alpha channel.
				if(pickingColor < 0xff000000) then
					pickingColor = pickingColor + 0xff000000;
				end
			end
		end
		painter:SetBrush(pickingColor or color);
	else
		painter:SetBrush(color);
	end
end

-- @param pickingName: the picking id (color) in pick buffer. 
function Overlay:GetChildByPickingName(pickingName)
	if(self.children and not self.children:empty()) then
		local resultNode;
		local child = self.children:last();
		while (child and not resultNode) do
			if(child.enabled) then
				resultNode = child:GetChildByPickingName(pickingName);
				if(not resultNode and child:HasPickingName(pickingName)) then
					resultNode = child;
				end
			end
			child = self.children:prev(child);
		end
		return resultNode;
	end
end

-- virtual function: one should implement this function, in order to have mouse event delivered. 
-- @param pickingName: the picking id (color) in pick buffer. 
-- @return true if pickingName is one of the picking names used during last paint picking event.
function Overlay:HasPickingName(pickingName)
	
end

-- virtual: 
function Overlay:mousePressEvent(mouse_event)
end

-- virtual: 
function Overlay:mouseMoveEvent(mouse_event)
end

-- virtual: 
function Overlay:mouseReleaseEvent(mouse_event)
end

-- virtual: actually means key stroke. 
function Overlay:keyPressEvent(key_event)
end
