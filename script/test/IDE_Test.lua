--[[
Author: Li,Xizhi
Date: 2008-2
Desc: testing IDE functions.
-----------------------------------------------
NPL.load("(gl)script/test/IDE_test.lua");
TestRadioBoxBinding();
-----------------------------------------------
]]

function CameraTest()
	ParaCamera.GetAttributeObject():SetField("EnableKeyboard", false)
	ParaCamera.GetAttributeObject():SetField("EnableMouseLeftButton", false)
	ParaCamera.GetAttributeObject():SetField("EnableMouseRightButton", false)
	ParaCamera.GetAttributeObject():SetField("EnableMouseWheel", false)
end

-- test passed 2008.2.2
function TestRadioBoxBinding()
	local bindingContext = commonlib.BindingContext:new();
	local package = {RadioIndex = 2}
	bindingContext:AddBinding(package, "RadioIndex", "radioButton1", commonlib.Binding.ControlTypes.IDE_radiobox, "SelectedIndex")
	
	_guihelper.ShowDialogBox("Test radio box", nil, nil, 263, 140, 
	function(_parent)
		_this = ParaUI.CreateUIObject("container", "TestRadioBoxBinding", "_fi", 0,0,0,0)
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		
		NPL.load("(gl)script/ide/RadioBox.lua");
		local ctl = CommonCtrl.radiobox:new{
			name = "radioButton1",
			alignment = "_lt",
			left = 27,
			top = 13,
			width = 109,
			height = 18,
			parent = _parent,
			isChecked = false,
			text = "radioButton1",
		};
		ctl:Show();

		NPL.load("(gl)script/ide/RadioBox.lua");
		local ctl = CommonCtrl.radiobox:new{
			name = "radioButton2",
			alignment = "_lt",
			left = 27,
			top = 37,
			width = 109,
			height = 18,
			parent = _parent,
			isChecked = false,
			text = "radioButton1",
		};
		ctl:Show();

		NPL.load("(gl)script/ide/RadioBox.lua");
		local ctl = CommonCtrl.radiobox:new{
			name = "radioButton3",
			alignment = "_lt",
			left = 27,
			top = 61,
			width = 109,
			height = 18,
			parent = _parent,
			isChecked = false,
			text = "radioButton1",
		};
		ctl:Show();
		
		bindingContext:UpdateDataToControls();
	end, 
	function(dialogResult)
		if(dialogResult == _guihelper.DialogResult.OK) then
			bindingContext:UpdateControlsToData();
			-- add to package list and update UI controls.
			_guihelper.MessageBox(tostring(package.RadioIndex).." is selected\n");
		end
		return true;
	end)
end

-- Test passed by LiXizhi 2008.6.12
function TestUIObjectLifeTime()
	local _this=ParaUI.CreateUIObject("container","bg", "_lt",0,0,100,100);
	_this:AttachToRoot();
	_this.lifetime=5;
end