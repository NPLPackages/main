--[[
Title: test Windows
Author(s): LiXizhi
Date: 2015/4/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");
test_Windows:TestMCMLPage();
test_Windows:TestEditbox();
test_Windows:TestMouseEnterLeaveEvents();
test_Windows:TestCreateWindow();
test_Windows:TestPostEvents();
test_Windows:test_pe_custom();
test_Windows:TestMultiLineEditbox();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/ide/System/Windows/Application.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/EditBox.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/MultiLineEditbox.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ProgressBar.lua");
local MultiLineEditbox = commonlib.gettable("System.Windows.Controls.MultiLineEditbox");
local EditBox = commonlib.gettable("System.Windows.Controls.EditBox");
local Application = commonlib.gettable("System.Windows.Application");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");
local UIElement = commonlib.gettable("System.Windows.UIElement");
local Window = commonlib.gettable("System.Windows.Window")
local Event = commonlib.gettable("System.Core.Event");
local ProgressBar = commonlib.gettable("System.Windows.Controls.ProgressBar");
	
-- define a new class
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");

function test_Windows:TestCreateWindow()
	
	-- create the native window
	local window = Window:new();

	-- test create rectangle
	local rcRect = Rectangle:new():init(window);
	rcRect:SetBackgroundColor("#ff0000");
	rcRect:setGeometry(10,32,64,32);

	-- test Button
	local btn = Button:new():init(window);
	btn:SetBackgroundColor("#00ff00");
	btn:setGeometry(10,64,64,32);
	btn:Connect("clicked", function (event)
		_guihelper.MessageBox("you clicked me");
	end)
	btn:Connect("released", function(event)
		_guihelper.MessageBox("mouse up");
	end)
	
	-- show the window natively
	window:Show("my_window", nil, "_mt", 0,0, 200, 200);

	self.windows = {window};
end

-- test destroy windows
function test_Windows:DestroyWindows(windows)
	windows = windows or self.windows;
	for _,window in ipairs(windows) do
		if(window and window.CloseWindow) then
			window:CloseWindow(true);
		end
	end
end

-- test passed: 2015.4.24   LiXizhi
function test_Windows:TestPostEvents()
	local window = Window:new();
	Application:postEvent(window, System.Core.LogEvent:new({"postEvent 1"}), 1);
	Application:postEvent(window, System.Core.LogEvent:new({"postEvent 2"}), 2);

	local window2 = Window:new();
	Application:postEvent(window2, System.Core.LogEvent:new({"postEvent 1 window2"}), 1);
	Application:postEvent(window2, System.Core.LogEvent:new({"postEvent 2 window2"}), 2);
	-- event compressing
	Application:postEvent(window2, System.Windows.SizeEvent:new():init({1,1}));
	Application:postEvent(window2, System.Windows.SizeEvent:new():init({2,2}));
	window2.sizeEvent = function(self, event)
		-- only one size event should be sent
		Application:postEvent(self, System.Core.LogEvent:new({"size event", event}));	
	end
	-- only post event for the first window
	Application:sendPostedEvents(window);

	echo({window.postedEvents, window2.postedEvents});

	self.windows = {window, window2};
end

function test_Windows:TestMouseEnterLeaveEvents()
	-- create the native window
	local window = Window:new();
	window.mouseEnterEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"window enter", event:localPos()}));	
	end
	window.mouseLeaveEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"window leave"}));	
	end

	-- Parent1
	local elem = UIElement:new():init(window);
	elem:SetBackgroundColor("#0000ff");
	elem:setGeometry(10,0,64,64);
	elem.mouseEnterEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"parent1 enter", event:localPos()}));	
	end
	elem.mouseLeaveEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"parent1 leave"}));	
	end

	-- Parent1:Button1
	local btn = Button:new():init(elem);
	btn:SetBackgroundColor("#ff0000");
	btn:setGeometry(0,0,64,32);
	btn.mouseEnterEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"btn1 enter", event:localPos()}));	
	end
	btn.mouseLeaveEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"btn1 leave"}));	
	end

	-- Button2
	local btn = Button:new():init(window);
	btn:SetBackgroundColor("#00ff00");
	btn:setGeometry(10,64,64,32);
	btn.mouseEnterEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"btn2 enter", event:localPos()}));	
	end
	btn.mouseLeaveEvent = function(self, event)
		Application:postEvent(self, System.Core.LogEvent:new({"btn2 leave"}));	
	end
	
	-- show the window natively
	window:Show("my_window1", nil, "_mt", 0,200, 200, 200);

	self.windows = {window};
end

-- test loading componets via url
function test_Windows:TestMCMLPage(url)
	-- remove old window
	local window = commonlib.gettable("test.window")
	if(window and window.CloseWindow) then
		window:CloseWindow(true);
	end

	-- create a new window
	NPL.load("(gl)script/ide/System/Windows/Window.lua");
	local Window = commonlib.gettable("System.Windows.Window")
	local window = Window:new();
	window:Show({
		url=url or "script/ide/System/test/test_mcml_page.html", 
		alignment="_lt", left = 0, top = 0, width = 800, height = 400,
	});
	-- keep a reference for refresh
	--test.window = window;
	self.windows = {window};

	-- testing loading another mcml layout after window is created.  
	-- window:LoadComponent("script/ide/System/test/test_mcml_page.html?page=2");
end

function test_Windows:test_pe_custom()
	local window = Window:new();
	window:Show({
		url="script/ide/System/test/test_pe_custom.html", 
		alignment="_mt", left = 0, top = 0, width = 200, height = 400,
	});
	self.windows = {window};
end

function test_Windows:TestEditbox()
	
	-- create the native window
	local window = Window:new();

	-- test UI element
	local elem = EditBox:new():init(window);
	elem:setGeometry(60,30,64,25);
	-- elem:setMaxLength(6);
	-- show the window natively
	window:Show("my_window", nil, "_lt", 0,0, 200, 200);
	self.windows = {window};
end

function test_Windows:TestMultiLineEditbox()
	local window = Window:new();
	local mulLine = MultiLineEditbox:new():init(window);
	mulLine:setGeometry(100, 100, 200, 20 * 5+10);
--	mulLine:AddItem("我是第一行");
--	mulLine:AddItem("我是第二行");
--	mulLine:AddItem("我是第三行");
--	mulLine:AddItem("我是第四行");
--	mulLine:AddItem("我是第五行");
--	mulLine:AddItem("我是第六行");
	--mulLine:AddItem("我是第七行");
	--mulLine:AddItem("我是第八行");
	--mulLine:AddItem("我是第九行");
	--mulLine:AddItem("我是第十行");
	--mulLine:SetBackgroundColor("#cccccc");

	window:Show("my_window", nil, "_mt", 0,0, 600, 600);
	self.windows = {window};
end

function test_Windows:test_draggableWindow()
	NPL.load("(gl)script/ide/System/Windows/Window.lua");
	local Window = commonlib.gettable("System.Windows.Window");

	local window = Window:new();
	window:Show({
		url="script/ide/System/test/test_mcml_page.html", 
		alignment="_mt", left = 0, top = 0, width = 200, height = 400,
		allowDrag=true, 
	});
	self.windows = {window};
end

function test_Windows:test_button()
	local window = Window:new();
	local button = Button:new():init(window);
	local style = "check";

	button:SetPolygonStyle(style);
	if(style == "normal") then
		button:SetBackgroundColor("#00ff00");
		button:setText("按钮");
	--elseif(style == "check") then
	--	self:paintCheckButton(painter);
	elseif(style == "narrow") then
		button:SetDirection("down");
	end


	button:setGeometry(50, 50, 60, 20);

	window:Show("my_window", nil, "_mt", 0,0, 600, 600);
	test_Windows.windows = {window};
end

function test_Windows:test_progressbar()
	local window = Window:new();
	local progressBar = ProgressBar:new():init(window);
	progressBar:setRange(0,10);
	progressBar:SetValue(0,true);
--	progressBar:SetDirection("vertical");
--	progressBar:setGeometry(50,50,32,200);
	progressBar:setGeometry(100,100,200,32);

	local button = Button:new():init(window);
	local style = "normal";
	button:SetPolygonStyle(style);
	button:setText("Add");
	button:Connect("clicked",function()
		progressBar:SliderSingleStepAdd();
	end)
	button:setGeometry(50, 300, 60, 20);

	window:Show("my_window", nil, "_mt", 0,0, 500, 500);

	test_Windows.windows = {window};
end