--[[
Title: BufferPicking
Author(s): LiXizhi@yeah.net
Date: 2015/8/13
Desc: picking from frame buffer. 
## Usage 1: 
Singleton of this class represent the back buffer.
## Usage 2: 
Inherit from this class and change Name property to represent arbitrary picking buffer. 
Inherited class must also call InitSingleton(). See also `OverlayPicking.lua`

## Introduction
When there is picking query, it will render scene again (if out dated) with a special shader and read pixels from the back buffer. 
We can query a single point or we can query a rectangle region in the current viewport and see if have hit anything. 
Please note: in order for buffer picking to work, each pickable object/component should assign a different picking id in its draw method. 
In other words, picking and drawing are done using the same draw function. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/BufferPicking.lua");
-- Usage 1: picking from backbuffer
local BufferPicking = commonlib.gettable("System.Scene.BufferPicking");
local result = BufferPicking:Pick(nil, nil, 2, 2);
echo(result);
echo({System.Core.Color.DWORD_TO_RGBA(result[1] or 0)});

-- Usage 2: custom pick buffer
local MyPickBuffer = commonlib.inherit(commonlib.gettable("System.Scene.BufferPicking"), commonlib.gettable("Tests.MyPickBuffer"));
MyPickBuffer:Property("Name", "MyCustomBuffer"); 
-- only called when Pick function is called 
function MyPickBuffer:paintEvent(painter)
	self:SetColorAndName(painter, "#ff0000");
	painter:PushMatrix();
	local obj = ParaScene.GetPlayer();
	local x, y, z = obj:GetPosition();
	local vOrigin = self:GetRenderOrigin();
	x, y, z = x - vOrigin[1], y - vOrigin[2], z - vOrigin[3];
	painter:TranslateMatrix(x,y,z);
	painter:DrawSceneObject(obj, 0)
	painter:PopMatrix();
end
MyPickBuffer:InitSingleton();

-- for debugging purposes, we will show the picking buffer into the gui. 
MyPickBuffer:DebugShow("_lt", 10, 10, 128, 128)
	
-- test picking here
commonlib.Timer:new({callbackFunc = function(timer)
	-- always redraw (force paintEvent to be invoked)
	MyPickBuffer:SetDirty(true);
	-- pick at the current mouse position
	echo(MyPickBuffer:Pick(nil, nil, 2, 2));
end}):Change(0, 1000)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
		
local BufferPicking = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.BufferPicking"));

BufferPicking:Property("Name", "BufferPicking");
BufferPicking:Property({"m_nPickingRenderFrame", 0, "GetPickingRenderFrame", "SetPickingRenderFrame"});


function BufferPicking:ctor()
	self:CreatePickingBuffer_sys();
end

function BufferPicking:CreatePickingBuffer_sys()
	if(self:IsBackBuffer()) then
		self.engine = ParaEngine.GetAttributeObject():GetChild("BufferPicking");
	elseif(self:IsOverlay()) then
		self.engine = ParaEngine.GetAttributeObject():GetChild("OverlayPicking");
	else
		self.engine = ParaAsset.LoadPickingBuffer(self:GetName()):GetAttributeObject();

		-- painting context
		self.vRenderOrigin = vector3d:new(0,0,0);
		self.painterContext = System.Core.PainterContext:new():init(self);
		self.rendertarget = self.engine:GetAttributeObject():GetChild("rendertarget"):QueryObject();
		self.rendertarget:SetScript("On_Paint", function()
			self:SetPickingRenderFrame(self:GetPickingRenderFrame()+1);
			self:handleRender();
		end)
	end
end

-- backbuffer is a special buffer, which is what actually on screen. 
function BufferPicking:IsBackBuffer()
	local name = self:GetName();
	return (name == "BufferPicking" or name == "backbuffer");
end

-- overlay is a special buffer, which is an additional render pass for objects on top of 3d scene. 
function BufferPicking:IsOverlay()
	local name = self:GetName();
	return (name == "OverlayPicking" or name == "overlay");
end

-- World position has double precision which is usually far away from the camera origin. 
-- When rendering 3d objects, object's world position must subtract this vector, 
-- so that all objects are close to camera before we do any matrix4 transforms.
-- @return vector3 of render origin
function BufferPicking:GetRenderOrigin()
	return self.vRenderOrigin;
end

-- private: handle system On_Paint message.
function BufferPicking:handleRender()
	local renderState = ParaScene.GetSceneState():GetField("RenderState", 0);
	self.vRenderOrigin = ParaCamera.GetAttributeObject():GetField("RenderOrigin", self.vRenderOrigin)
	self.m_render_pass = renderState;
	if(self.paintEvent) then
		self:paintEvent(self.painterContext);
	end
	self.m_render_pass = nil;
end

-- virtual function: draw something here to be painted into the picking buffer. 
-- only called when buffer is manually set to dirty with SetDirty() and Pick() function is called. 
-- When rendering world objects in paintEvent, ensure that they are substracted by GetRenderOrigin() vector. 
function BufferPicking:paintEvent(painter)
	
end

-- if we are currently rendering picking
function BufferPicking:IsPickingPass()
	return self.m_render_pass == ParaEngine.SceneStateRenderState.RenderState_Overlay_Picking;
end


-- set name of the picking buffer
function BufferPicking:SetName(name)
	if(self:GetName() ~= name) then
		if(self.engine) then
			self.engine = nil;
			self.rendertarget = nil;
			self:CreatePickingBuffer_sys();
		end
	end
end

-- pick by a point in the viewport. 
-- Tip: to pick a thin line, one may consider picking by a small rect region. 
-- @param x, y: if nil, it is the current mouse position.
-- @param width, height: if nil, 1,1
-- @param nViewportId: viewport index, if -1 it means the current viewport.
-- @return array of picking result. if nil means nothing is picked.
function BufferPicking:Pick(x, y, width, height, nViewportId)
	width = width or 1;
	height = height or 1;
	if(not x or not y) then
		local mouse_pos = System.Windows.Mouse:pos();
		x, y = mouse_pos[1], mouse_pos[2];
		x = math.floor(x - width/2 + 0.5);
		y = math.floor(y - height/2 + 0.5);
	end
	self:SetPickLeftTop(x, y);
	self:SetPickWidthHeight(width, height);
	self:SetViewport(nViewportId);
	return self:GetPickingResult();
end


-- return array, size:  an array of unique picking id in the last pick call. it may return nil if nothing is picked
-- array start from index 0.
function BufferPicking:GetPickingResult()
	local count = self:GetPickingCount();
	if(count > 0) then
		if(ParaEngine.hasFFI) then
			if(not self.result) then
				local ffi = require('ffi');
				self.result = ffi.new('uint32_t* [1]');
			end
			self.engine:GetFieldCData("FetchPickingResult", self.result);
			return self.result[0], count;
		else
			self.result = self.result or {};
			local result = self.result;
			for i=0, count-1 do
				result[i] = self:GetPickingID(i);
			end
			return result, count;
		end
	end
end

-- return the number of objects picked. 
function BufferPicking:GetPickingCount()
	return self.engine:GetField("PickingCount", 0);
end

-- get the picked item id of the given picking item. if no data at the index return 0. 
-- @param nIndex: if -1, it will use m_currentPickIndex;
function BufferPicking:GetPickingID(nIndex)
	if(nIndex and nIndex >= 0) then
		self:SetPickIndex(nIndex);
	end
	return self.engine:GetField("PickingID", 0);
end

-- clear last picking result 
function BufferPicking:ClearPickingResult()
	self.engine:CallField("ClearPickingResult");
end

function BufferPicking:SetPickLeftTop(x, y)
	if(x and y) then
		self.engine:SetField("PickLeftTop", {x,y});
	end
end
function BufferPicking:GetPickLeftTop()
	local res = self.engine:GetField("PickLeftTop", {0,0});
	return res[1], res[2];
end

function BufferPicking:SetPickWidthHeight(w,h)
	if(w and h) then
		self.engine:SetField("PickWidthHeight", {w,h});
	end
end
function BufferPicking:GetPickWidthHeight()
	local res = self.engine:GetField("PickWidthHeight", {0,0});
	return res[1], res[2];
end

function BufferPicking:GetPickIndex()
	return self.engine:GetField("PickIndex", 0);
end
function BufferPicking:SetPickIndex(nIndex)
	if(nIndex and nIndex>=0) then
		self.engine:SetField("PickIndex", nIndex);
	end
end

function BufferPicking:IsResultDirty()
	return self.engine:GetField("ResultDirty", false);
end

function BufferPicking:SetResultDirty(bDirty)
	self.engine:SetField("ResultDirty", bDirty == true);
end

-- if content is dirty
function BufferPicking:IsDirty()
	if(self.rendertarget) then
		return self.rendertarget:GetField("Dirty", false);
	end
end

-- if content is dirty, next pick event will repaint and buffer using paintEvent
-- this is only valid when buffer name is not backbuffer or overlay
function BufferPicking:SetDirty(bDirty)
	if(self.rendertarget) then
		return self.rendertarget:SetField("Dirty", bDirty == true);
	end
end

-- in which viewport to pick. default to -1, which is the default one. 
function BufferPicking:GetViewport()
	return self.engine:GetField("Viewport", -1);
end

-- in which viewport to pick. if -1, it is the default one. 
function BufferPicking:SetViewport(nViewportIndex)
	if(nViewportIndex) then
		self.engine:SetField("Viewport", nViewportIndex);
	end
end

-- get the rendertarget ParaObject
function BufferPicking:GetRenderTarget()
	return self.rendertarget;
end

-- helper function that set color and picking color(name)
-- @param color: color used for normal rendering 
-- @param pickingColor: color used drawing picking pass. if nil, it is the same as the color. if false, it means object is not pickable (we will render it as black). 
function BufferPicking:SetColorAndName(painter, color, pickingColor)
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

-- show the buffer on GUI for debugging purposes
-- e.g. self:DebugShow("_lt", 10, 10, 128, 128)
-- @param alignment: default to "_lt" left top.
-- @param left, top, width, height:
function BufferPicking:DebugShow(alignment, left, top, width, height)
	if(self.rendertarget) then
		alignment, left, top, width, height = alignment or "_lt", left or 10, top or 60, width or 128, height or 128;
		if(not self.debug_ui) then
			-- create a GUI object that displays the render target. 
			local _parent = ParaUI.CreateUIObject("button", "paintDevice", alignment, left, top, width, height);
			_parent.zorder=10;
			_parent.tooltip = "click to make dirty and redraw";
			_parent:SetScript("onclick", function()
				-- click to redraw
				-- renderTarget:SetField("Dirty", true);
			end)
			_parent:AttachToRoot();
			self.debug_ui = _parent;
		else
			self.debug_ui:Reposition(alignment, left, top, width, height);
		end
		self.debug_ui:SetBGImage(self.rendertarget:GetPrimaryAsset());
	end
end
	

BufferPicking:InitSingleton();