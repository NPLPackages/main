--[[
Title: test buffer picking
Author(s): LiXizhi
Date: 2017/4/4
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/test/test_bufferpicking.lua");
local test_bufferpicking = commonlib.gettable("System.Core.Test.test_bufferpicking");
test_bufferpicking:testDrawSceneObject()
------------------------------------------------------------
]]
-- define a new class
local test_bufferpicking = commonlib.gettable("System.Core.Test.test_bufferpicking");

function test_bufferpicking:testDrawSceneObject()
	NPL.load("(gl)script/ide/System/Scene/Overlays/Overlay.lua");
	local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
	local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
	local layer1 = Overlay:new():init();
	layer1:SetPosition(ParaScene.GetPlayer():GetPosition());
	layer1.paintEvent = function(self, painter)
		self:SetColorAndName(painter, "#ff0000");
		--painter:PushMatrix();
		painter:DrawSceneObject(ParaScene.GetPlayer(), 0)
		--painter:PopMatrix();
	end
end

function test_bufferpicking:testCustomPickingBuffer()
	NPL.load("(gl)script/ide/System/Scene/BufferPicking.lua");
	-- define a new class
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
end