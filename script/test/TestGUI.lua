--[[
Author: LiXizhi
Date: 2008-12-4
Desc: testing GUI objects
-----------------------------------------------
NPL.load("(gl)script/test/TestGUI.lua");
TestGUI:test_mobile_applyanim();
TestGUI:test_GUI_SelfPaint();
TestGUI:test_RenderTarget_paint();
TestGUI:test_gui_OwnerDraw();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

TestGUI = {}

function TestGUI:test_gui_OwnerDraw()
	local _parent = ParaUI.CreateUIObject("container", "test_OwnerDraw", "_lt", 200, 50, 400, 300);
	_parent.zorder=10;
	_parent:AttachToRoot();

	-- create used GUI resources
	local dx = 0;
	local tex1 = ParaAsset.LoadTexture("", "Texture/checkbox.png",1);

	local my_font = {family="System", size=11, bold=true};
	local my_white_pen = {color="#ffffff"};
	local my_pen_wide = {color="#00ff0088", width=5};
	
	-- the paint event callback
	local function OnPaint(obj)
		dx = dx + 1;
		if(dx > 60) then
			dx = 0;
		end
		-- set pen with color
		ParaPainter.SetPen("#ff0000");
		ParaPainter.DrawRect(10+dx, 10, 64, 32);

		do	-- save/restore drawing states 
			ParaPainter.Save();

			-- advanced set pen
			ParaPainter.SetPen(my_white_pen);

			
			do -- save/restore transform
				local old_trans = ParaPainter.GetTransform({});
				-- rotation transform in degrees
				ParaPainter.Rotate(45);
				-- draw textures
				ParaPainter.DrawTexture(10+dx, 32, 32, 32, tex1);
				-- restore last transform: second params is bCombineTransform
				ParaPainter.SetTransform(old_trans, false);
			end
			-- shear transform
			ParaPainter.Shear(-dx*0.01, 0);
			-- draw textures with sub region
			ParaPainter.DrawTexture(10 + 48, 32, 32, 32, "Texture/checkbox.png", 10, 10, 16, 16);

			ParaPainter.Restore();
		end
		-- advanced set font
		ParaPainter.SetFont(my_font);
		ParaPainter.DrawText(10+dx, 64, "hello");
		-- simple set font
		ParaPainter.SetFont("System;14;bold");
		-- with some transparency
		ParaPainter.SetPen("#0000ff88");
		ParaPainter.DrawText(70+dx, 64, "world");
		-- pen with width
		ParaPainter.SetPen(my_pen_wide);
		ParaPainter.DrawPoint(10+2*dx, 20); ParaPainter.DrawPoint(10+3*dx, 20);
		ParaPainter.DrawLine(10+2*dx, 70, 10+3*dx, 90);
	end

	local _ownerDrawBtn = ParaUI.CreateUIObject("button", "canvas", "_lt", 10, 10, 100, 64);
	_ownerDrawBtn:SetField("OwnerDraw", true); -- enable owner draw paint event
	_ownerDrawBtn:SetScript("ondraw", OnPaint); -- add event handler
	_parent:AddChild(_ownerDrawBtn);
end

-- test GUI container with private rendertarget(SelfPaint attribute to true)
function TestGUI:test_GUI_SelfPaint()
	ParaUI.Destroy("paintDevice");
	-- non-power of 2 region is auto scaled up to the next POT integer. Hence following 100,90 is scaled to 128,128
	local _parent = ParaUI.CreateUIObject("container", "paintDevice", "_lt", 10, 60, 100, 90);
	-- enable self painting on its own private render target whose name is same as the GUI object. 
	-- "SelfPaint" can be turn on or off anytime, anywhere. It needs to SetField("IsDirty", true) to cause a refresh. 
	_parent:SetField("SelfPaint", true); 
	_parent.zorder=10;
	_parent.background = "Texture/whitedot.png";
	_parent:AttachToRoot();

	-- standard button rendered with default renderer. 
	local _stdBtn = ParaUI.CreateUIObject("button", "stdButton", "_lt", 0, 10, 100, 32);
	_stdBtn.text="click to refresh";
	_stdBtn:SetScript("onclick", function()
		-- cause parent device to repaint
		_parent:SetField("IsDirty", true);
	end)
	_parent:AddChild(_stdBtn);

	-- the owner draw object and default GUI object can coexist on the same SelfPainted parent device. 
	local _ownerDrawBtn = ParaUI.CreateUIObject("button", "canvas", "_lt", 0, 48, 100, 64);
	_ownerDrawBtn:SetField("OwnerDraw", true); -- enable owner draw paint event
	local dx = 0;
	_ownerDrawBtn:SetScript("ondraw", function()
		ParaPainter.SetPen("#0000ff");
		ParaPainter.DrawRect(0, 0, 100, 64);
		ParaPainter.SetPen("#ff0000");
		dx = dx + 1;
		if(dx > 60) then
			dx = 0;
		end
		ParaPainter.DrawRect(10+dx, 10, 64, 32);
	end); -- add event handler
	_parent:AddChild(_ownerDrawBtn);
end

-- lazy update to GUI surface via render target
function TestGUI:test_RenderTarget_paint()
	-- create render target with Paint event
	local renderTarget = ParaScene.CreateObject("CRenderTarget", "rt_test", 0, 0, 0);
	-- set to dirty whenever you want to repaint. 
	renderTarget:SetField("RenderTargetSize", {128, 128});
	renderTarget:SetField("Dirty", true);
	local dx = 0;
	renderTarget:SetScript("On_Paint", function()
		ParaPainter.SetPen("#0000ff");
		ParaPainter.DrawRect(0, 0, 128, 128);
		ParaPainter.SetPen("#ff00ff");
		dx = dx + 3;
		if(dx > 60) then
			dx = 0;
		end
		ParaPainter.Shear(dx*0.01, 0);
		ParaPainter.DrawRect(10, 10, 32, 32);
		ParaPainter.DrawText(10, 64, "Click me to redraw");
	end)
	ParaScene.Attach(renderTarget);

	-- create a GUI object that displays the render target. 
	local _parent = ParaUI.CreateUIObject("button", "paintDevice", "_lt", 10, 60, 128, 128);
	_parent.zorder=10;
	_parent:SetScript("onclick", function()
		-- click to redraw
		renderTarget:SetField("Dirty", true);
	end)
	--_parent.background = "Texture/checkbox.png";
	_parent:SetBGImage(renderTarget:GetPrimaryAsset());
	_parent:AttachToRoot();
end

-- Basic anim properties
-- %TESTCASE{"test_gui_anim_properties", func = "TestGUI:test_gui_anim_properties", input = {colormask="255 255 255 128",  scalingx = 1, scalingy=1,},}%
function TestGUI:test_gui_anim_properties(input)
	log("begin test ... \n")
	local _this = ParaUI.GetUIObject("test_gui_anim_properties");
	if(_this:IsValid() == false) then
		_this = ParaUI.CreateUIObject("button", "test_gui_anim_properties", "_lt", 300, 50, 150, 300);
		_this.text= "Test"
		_this:AttachToRoot();
		_parent = _this;
	end
	log("colormask".._this.colormask.."  -->")
	_this.colormask = input.colormask or "255 255 255 128";	
	_this.scalingx = input.scalingx or 1;
	_this.scalingy = input.scalingy or 1;
	log(_this.colormask.."\n")
end

-- nested animation : ParaUIObject.ApplyAnim test
-- %TESTCASE{"test_gui_anim_nested", func = "TestGUI:test_gui_anim_nested", input = { scalingx = 1, scalingy=1, rotation=0, translationx=0, translationy=0,colormask="255 255 255 255"},}%
function TestGUI:test_gui_anim_nested(input)
	log("begin test ... \n")
	local _this = ParaUI.GetUIObject("test_gui_anim_nested");
	if(_this:IsValid() == false) then
		local _parent;
		_this = ParaUI.CreateUIObject("container", "test_gui_anim_nested", "_lt", 200, 100, 100, 200);
		_this:AttachToRoot();
		_parent = _this;
		
		_this = ParaUI.CreateUIObject("button", "b1", "_lt", 10, 10, 30, 20);
		_this.text= "Test"
		_this.animstyle = 14;
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("text", "b1", "_lt", 10, 40, 700, 20);
		_this.text= "static text here 中文"
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("imeeditbox", "b1", "_lt", 10, 70, 30, 20);
		_this.text= "editbox"
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("listbox", "b1", "_lt", 10, 100, 50, 40);
		_parent:AddChild(_this);
		
		_this = _parent;
	end
	_this.scalingx = input.scalingx or 1;
	_this.scalingy = input.scalingy or 1;
	_this.rotation = input.rotation or 0;
	_this.translationx = input.translationx or 0;
	_this.translationy = input.translationy or 0;
	_this.colormask = input.colormask or "255 255 255 128";	
	-- apply nested animation. 
	_this:ApplyAnim();
end

function TestGUI:Test_texture_layers_adv()
	local _this = ParaUI.GetUIObject("Test_texture_layers_adv");
	if(_this:IsValid() == false) then
		_this = ParaUI.CreateUIObject("button", "Test_texture_layers_adv", "_lt", 200, 100, 52, 28);
		_guihelper.SetVistaStyleButton3(_this, 
			"Texture/Aquarius/Desktop/Channel_Btn_Norm_32bits.png; 0 0 52 28", 
			"Texture/Aquarius/Desktop/Channel_Btn_Over_32bits.png; 0 0 52 28", 
			"Texture/Aquarius/Desktop/Channel_Btn_Norm_32bits.png; 0 0 52 28", 
			"Texture/Aquarius/Desktop/Channel_Btn_Pressed_32bits.png; 0 0 52 28");
		_this:AttachToRoot();	
	end	
end

--[[ test onmouseleave  and onmouseenter on nested containers. 
please note that there is an additional outer enter event. this allows the outer container to be able to know that one of its inner must have lost mouse focus. 
-- output should be: 
outer enter
   inner enter
   inner leave
outer enter
outer leave
]]
function TestGUI:test_gui_nested_onmouseleave()
	local _this = ParaUI.CreateUIObject("container", "test_onmouseleave_outer", "_lt", 200, 100, 300, 300);
	_this.onmouseenter = [[;commonlib.log("outer enter\n")]]
	_this.onmouseleave = [[;commonlib.log("outer leave----------------\n")]]
	_this:AttachToRoot();
	
	local _parent = _this;
	_this = ParaUI.CreateUIObject("container", "inner", "_fi", 50, 50, 50, 50);
	_this.onmouseenter = [[;commonlib.log("   inner enter\n")]]
	_this.onmouseleave = [[;commonlib.log("   inner leave\n")]]
	_parent:AddChild(_this);
end


local last_anim_style;
-- test animation style. 
-- @param: like 1, 12, 22, 31, 41
-- 1 is gradually enlarge 5% when getting focus.2 is 10%, 3 is 15%, 4 is 20%, 5 is 25% 
-- 11-15 means the same as 1-5, except that the normal state alpha is the same as the highlighted state.
-- 21-25 means the same as 11-15, except that the button animation will not stop in the highlighted state.
-- 31-39 is clock-wise rotation
-- 41-49 is counter-clock-wise rotation. 
function TestGUI:test_gui_animationstyles(style)
	local _this = ParaUI.GetUIObject("test_gui_animationstyles");
	if(_this:IsValid() == false) then
		last_anim_style = style or 31;
		_this = ParaUI.CreateUIObject("button", "test_gui_animationstyles", "_lt", 200, 100, 52, 28);
		_this.animstyle = last_anim_style;
		_this:AttachToRoot();
	elseif(style and style ~= last_anim_style) then	
		last_anim_style = style;
		_this.animstyle = last_anim_style;
	end	
end

-- for gui helper only
TestGUIHelper = {}

function TestGUIHelper:test_gui_trim_text()
	local text = "abcdefg123456789一二三四五六七八九十";
	commonlib.echo({_guihelper.TrimUtf8TextByWidth(text, 200)})
	commonlib.echo({_guihelper.TrimUtf8TextByWidth(text, 100)})
	commonlib.echo({_guihelper.TrimUtf8TextByWidth(text, 10)})
	commonlib.echo({_guihelper.TrimUtf8TextByWidth(text, 0)})
end

function TestGUI:test_gui_click_through()
	local _this = ParaUI.CreateUIObject("container", "test_gui_animationstyles", "_lt", 200, 100, 32, 32);
	_this.animstyle = last_anim_style;
	_this:GetAttributeObject():SetField("ClickThrough", true);
	_this:AttachToRoot();
end

function TestGUI:test_gui_webbrowser()
	local _this = ParaUI.CreateUIObject("webbrowser", "abc", "_ct", 0, 0, 400, 300);
	_this.text = "www.baidu.com";
	_this:AttachToRoot();
end

-- nested animation : ParaUIObject.ApplyAnim test
function TestGUI:test_mobile_applyanim()
	log("begin test ... \n")
	local _this = ParaUI.GetUIObject("test_gui_anim_nested");
	if(_this:IsValid() == false) then
		local _parent;
		_this = ParaUI.CreateUIObject("container", "test_gui_anim_nested", "_lt", 60, 30, 100, 200);
		_this:AttachToRoot();
		_this.zorder = 1002;
		_this.background = "";
		_parent = _this;
		
		_this = ParaUI.CreateUIObject("button", "b1", "_lt", 10, 10, 30, 20);
		_this.text= "Test"
		_parent:AddChild(_this);
		_this = _parent;
	end
	-- _this.scalingx = 1;
	-- _this.scalingy = 1;
	-- _this.rotation = 0;
	_this.translationx = 200;
	_this.translationy = 100;
	-- apply nested animation. 
	_this:ApplyAnim();
end

-- LuaUnit:run('TestGUIHelper:test_gui_trim_text')