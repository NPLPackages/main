--[[
Title: Test console window 
Author(s): LiXizhi
Date: 2008/3/5
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/DebugApp/TestConsoleWnd.lua");
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");

commonlib.setfield("Map3DSystem.App.Debug.TestConsoleWnd", {});

-- display the main Debug window for the current user.
function Map3DSystem.App.Debug.ShowTestConsoleWnd(_app)
	NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");
	local _wnd = _app:FindWindow("TestConsoleWnd") or _app:RegisterWindow("TestConsoleWnd", nil, Map3DSystem.App.Debug.TestConsoleWnd.MSGProc);
	
	local _wndFrame = _wnd:GetWindowFrame();
	if(not _wndFrame) then
		_wndFrame = _wnd:CreateWindowFrame{
			icon = "Texture/3DMapSystem/common/monitor.png",
			text = "测试面板",
			initialPosX = 237,
			initialPosY = 100,
			initialWidth = 810,
			initialHeight = 460,
			allowDrag = true,
			allowResize = true,
			zorder = 1005,
			ShowUICallback = Map3DSystem.App.Debug.TestConsoleWnd.Show,
		};
	end
	_wnd:ShowWindowFrame(true);
end



--@param bShow: boolean to show or hide. if nil, it will toggle current setting. 
-- @param _parent: parent window inside which the content is displayed. it can be nil.
function Map3DSystem.App.Debug.TestConsoleWnd.Show(bShow, _parent, parentWindow)
	local _this;
	Map3DSystem.App.Debug.TestConsoleWnd.parentWindow = parentWindow;
	
	_this=ParaUI.GetUIObject("TestConsoleWnd_cont");
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		if(_parent==nil) then
			_this=ParaUI.CreateUIObject("container","TestConsoleWnd_cont","_lt",0,50, 600, 450);
			_this:AttachToRoot();
		else
			_this = ParaUI.CreateUIObject("container", "TestConsoleWnd_cont", "_fi",0,0,0,0);
			_this.background = ""
			_parent:AddChild(_this);
		end	
		_parent = _this;

		NPL.load("(gl)script/ide/UnitTest/unit_test_dlg.lua");
		local ctl = CommonCtrl.UnitTestDlg:new{
			name = "UnitTestDlg",
			alignment = "_fi",
			left = 0,
			top = 0,
			width = 0,
			height = 0,
			parent = _parent,
		};
		ctl:Show();
	else
		if(bShow == nil) then
			bShow = not _this.visible;
		end
		_parent = _this;
	end	
	if(bShow) then
	else	
	end
end

function Map3DSystem.App.Debug.TestConsoleWnd.MSGProc(window, msg)
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	if(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		window:ShowWindowFrame(false);
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
	end
end