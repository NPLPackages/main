--[[
Title: API Test console window 
Author(s): CYF
Date: 2010Äê11ÔÂ17ÈÕ
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/test/APITest.lua");
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");

commonlib.setfield("Map3DSystem.App.Debug.APITestConsoleWnd", {});

local dlistNS, dlistAPI, txtRe, divParams;

function Map3DSystem.App.Debug.ShowAPITestConsoleWnd(_app)
	NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");
	local _wnd = _app:FindWindow("APITestConsoleWnd") or _app:RegisterWindow("APITestConsoleWnd", nil, Map3DSystem.App.Debug.APITestConsoleWnd.MSGProc);
	
	local _wndFrame = _wnd:GetWindowFrame();
	if(not _wndFrame) then
		_wndFrame = _wnd:CreateWindowFrame{
			icon = "Texture/3DMapSystem/common/monitor.png",
			text = "API Test",
			initialPosX = 150,
			initialPosY = 50,
			initialWidth = 810,
			initialHeight = 460,
			allowDrag = true,
			allowResize = true,
			zorder = 1005,
			ShowUICallback = Map3DSystem.App.Debug.APITestConsoleWnd.Show,
		};
	end
	_wnd:ShowWindowFrame(true);
end



--@param bShow: boolean to show or hide. if nil, it will toggle current setting. 
-- @param _parent: parent window inside which the content is displayed. it can be nil.
function Map3DSystem.App.Debug.APITestConsoleWnd.Show(bShow, _parent, parentWindow)
	local _this;
	Map3DSystem.App.Debug.APITestConsoleWnd.parentWindow = parentWindow;
	
	local objname = "APITestConsoleWnd_cont";
	_this=ParaUI.GetUIObject(objname);
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		if(_parent==nil) then
			_this=ParaUI.CreateUIObject("container",objname,"_lt",0,50, 800, 450);
			_this:AttachToRoot();
		else
			_this = ParaUI.CreateUIObject("container", objname, "_fi",0,0,0,0);
			_this.background = ""
			_parent:AddChild(_this);
		end
		
		--NPL.load("(gl)script/ide/TreeView.lua");
		--local _treeAPIs = CommonCtrl.TreeView:new{
			--name = "treeAPIs",
			--alignment = "_lt",
			--left = 20,
			--top = 30,
			--width = 200,
			--height = 300,
			--parent = _this,
			--DefaultIndentation = 5,
			--DefaultNodeHeight = 22,
			--container_bg = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
			--DrawNodeHandler = CommonCtrl.TreeView.DrawSingleSelectionNodeHandler,
			----onclick = CommonCtrl.UnitTestDlg.OnSelectTestCase
		--};
		--local _treeRoot = _treeAPIs.RootNode;
		--_treeRoot:AddChild(CommonCtrl.TreeNode:new({Text = "NODE1", Name = "n1", onclick = nil, parentName = nil}));
		--_treeAPIs:Show();

		local _lblAPI = ParaUI.CreateUIObject("text", "lblAPI", "_lt", 10, 10, 20, 15);
		_lblAPI.text = "API:"
		_this:AddChild(_lblAPI);

		NPL.load("(gl)script/ide/dropdownlistbox.lua");
		dlistNS = CommonCtrl.dropdownlistbox:new{
			name = "dlistNS",
			alignment = "_lt",
			left = 40,
			top = 10,
			width = 160,
			height = 23,
			dropdownheight = 150,
 			parent = _parent,
			items = {values={}},
			text = "",
			onselect = function(ctlname)
				--local _t = CommonCtrl.GetControl(ctlname);
				--if(_t ~= nil) then
					dlistAPI.items = {values={}};
					local _apis = dlistNS:GetValue();
					--_guihelper.MessageBox(commonlib.serialize(_apis));
					local _k, _v;
					for _k, _v in ipairs(_apis) do
						dlistAPI:InsertItem(_v["name"], true);
						dlistAPI.items.values[_v["name"]] = _v["params"];
					end
					dlistAPI:SetText("");
				--end
			end,
		};
		--dlistNS:InsertItem("N1", true);
		dlistNS:Show();

		dlistAPI = CommonCtrl.dropdownlistbox:new{
			name = "dlistAPI",
			alignment = "_lt",
			left = 220,
			top = 10,
			width = 180,
			height = 23,
			dropdownheight = 150,
 			parent = _parent,
			text = "",
			items = {values={}},
			onselect = function(ctlname)
				local _childCnt = divParams:GetChildCount();
				for _i = 0, _childCnt do
					local _cT = divParams:GetChildAt(_i);
					if(_cT ~= nil) then
						_cT.visible = false;
					end
				end
				local _k, _v;
				for _k, _v in ipairs(dlistAPI:GetValue()) do
					local _lblPName = divParams:GetChildAt((_k - 1) * 2);
					_lblPName.name = "pname_".._v["name"]
					_lblPName.visible = true;
					_lblPName.text = _v["name"]..":";
					_lblPName.p_name = _lblPName.name;
					local _txtPValue = divParams:GetChildAt((_k - 1) * 2 + 1);
					_txtPValue.name = "pvalue_".._v["name"];
					_txtPValue.visible = true;
					_txtPValue.text = "";
					_txtPValue.p_name = _txtPValue.name;
				end
			end,
		};
		dlistAPI:Show();

		local _btnTest = ParaUI.CreateUIObject("button", "btnTest", "_lt", 420, 10, 50, 23);
		_btnTest.text = "TEST";
		_this:AddChild(_btnTest);
		_btnTest.onclick = ";Map3DSystem.App.Debug.APITestConsoleWnd.btnTest_onClick();";

		NPL.load("(gl)script/ide/MultiLineEditbox.lua");
		txtRe = CommonCtrl.MultiLineEditbox:new{
			name = "txtRe",
			alignment = "_mr",
			left = 15,
			top = 40,
			width = 425,
			height = 20,
			parent = _this,
			WordWrap = true,
			ShowLineNumber = true,
			syntax_map = CommonCtrl.MultiLineEditbox.syntax_map_NPL,
		};
		txtRe:Show();

		divParams = ParaUI.CreateUIObject("container","divParams","_lt",10,40, 350, 400);
		_this:AddChild(divParams);

		local _h = 5;
		local _add = 28;
		local _i;
		for _i = 1, 20 do
			local _lblPName = ParaUI.CreateUIObject("text", "test_name_".._i, "_lt", 5, _h, 100, 20);
			divParams:AddChild(_lblPName);
			_lblPName.visible = false;
			local _txtPValue = ParaUI.CreateUIObject("editbox", "test_value_".._i, "_lt", 110, _h, 230, 23);
			--log("AAA\n");
			--_txtPValue:SetScript("onclick", function() _guihelper.MessageBox("HELLO"); end, nil, nil, nil, "test_value_".._i);
			--log("BBB\n");
			divParams:AddChild(_txtPValue);
			_txtPValue.visible= false;
			_h = _h + _add;
		end

		--paraworld.inventory.GetExtendedCost(_msgGetAPIs, "init", function(msg)
			----_guihelper.MessageBox(commonlib.echo(msg));
			--log("test................\n");
			--log(commonlib.echo(msg));
		--end);
		local o = commonlib.getfield("paraworld.GetAll");
		if(o == nil) then
			--log("test.....o is nil.\n");
			paraworld.create_wrapper("paraworld.GetAll", "%MAIN%/API/GetAll.ashx", nil, nil);
			o = commonlib.getfield("paraworld.GetAll");
		end
		if(o == nil) then
			--log("test......o is nil 2.\n");
		else
			log("test.....activate.....\n");
			o.activate(o, {}, nil, function(msg)
				log("test returned.\n");
				local k, v;
				for k, v in ipairs(msg["na"]) do
					dlistNS:InsertItem(v["ns"], true);
					dlistNS.items.values[v["ns"]] = v["apis"];
				end
				log("\ntest end.\n");
				--local k,v;
				--for k,v in ipair(list) do
					--
				--end
				--local node = list[1];
			end);
			log("test......activate end.\n");
		end
	else
		if(bShow == nil) then
			bShow = not _this.visible;
		end
		_parent = _this;
	end	
end


function Map3DSystem.App.Debug.APITestConsoleWnd.btnTest_onClick()
	local _apikey = dlistNS:GetText().."_"..dlistAPI:GetText();
	local o = commonlib.getfield(_apikey);
	if(o == nil) then
		if(dlistNS:GetText() == "__") then
			paraworld.create_wrapper(_apikey, "%MAIN%/API/"..dlistAPI:GetText()..".ashx", nil, nil);
		else
			paraworld.create_wrapper(_apikey, "%MAIN%/API/"..dlistNS:GetText().."/"..dlistAPI:GetText()..".ashx", nil, nil);
		end
		o = commonlib.getfield(_apikey);
	end
	if(o ~= nil) then
		local _apimsg = {};
		local _k, _v;
		for _k, _v in ipairs(dlistAPI:GetValue()) do
			local _txtT = divParams:GetChildAt((_k - 1) * 2 + 1);
			if(_v["type"] == "number") then
				local nValue = tonumber(_txtT.text) or 0;
				--log("test....."..nValue);
				_apimsg[_v["name"]] = nValue;
			else
				_apimsg[_v["name"]] = _txtT.text;
			end
		end
		_apimsg.ppp = "abcdefg";
		log("test.....".._apikey.."...activate....."..commonlib.serialize(_apimsg).."\n");
		o.activate(o, _apimsg, nil, function(msg)
			log("test returned.\n");
			txtRe:SetText(commonlib.serialize(msg));
		end);
	end
end


function Map3DSystem.App.Debug.APITestConsoleWnd.MSGProc(window, msg)
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