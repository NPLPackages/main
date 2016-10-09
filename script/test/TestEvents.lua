--[[
Author: LiXizhi
Date: 2008-11-29
Desc: testing key, mouse events, and GUI event systems
-----------------------------------------------
NPL.load("(gl)script/test/TestEvent.lua");
-----------------------------------------------
]]

function test_OnKeyDownEvent()
	-- in most cases, one can use the hardware key pressed testing functions. and do not handle the Key up event. see below
	local IsComboKeyPressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or 
		ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU)
	if(IsComboKeyPressed)then
		log("with Combo + ")
	end
	
	log(virtual_key..": down\n");
end

-- please note that key up event is fired to 3d scene key up handler even the GUI has focus. In other words, there are more up events than down event. 
function test_OnKeyUpEvent()
	
	log(virtual_key..": up\n");
end

-- test key events
-- %TESTCASE{"test_key_event", func = "test_key_event", input = {key="", },}%
function test_key_event(input)
	log("begin test: Please enter any key in 3d scene and check log \n")
	
	-- register key event handler
	ParaScene.RegisterEvent("_k_test", ";test_OnKeyDownEvent();");
	-- register keyup event handler
	ParaScene.RegisterEvent("_kup_test", ";test_OnKeyUpEvent();");
	
	
	-- register mouse picking event handler
	--ParaScene.RegisterEvent("_mdown_test", ";test_OnMouseDown();");
	--ParaScene.RegisterEvent("_mup_test", ";test_OnMouseUp();");
	--ParaScene.RegisterEvent("_mmove_test", ";test_OnMouseMove();");
	
	-- register network event handler
	--ParaScene.RegisterEvent("_n_test", ";test_OnNetworkEvent();");
	-- register system event handler
	--ParaScene.RegisterEvent("_s_test", ";test_OnSystemEvent();");
end


-- test top level container's onactivate event. 
-- %TESTCASE{"test_gui_event_onactivate", func = "test_gui_event_onactivate", }%
function test_gui_event_onactivate(input)
	log("begin test: click the top level container to receive onactivate event. \n")
	
	_this = ParaUI.GetUIObject("test_onactivate1");
	if(_this:IsValid() == false) then
		_this = ParaUI.CreateUIObject("container", "test_onactivate1", "_lt", 100, 20, 150, 300);
		_this.onactivate = ";test_gui_event_onactivate_handler();";
		_this:AttachToRoot();
	end
end

-- on activate callback. 
function test_gui_event_onactivate_handler()
	commonlib.echo({"onactivate: ", id, param1})
end
