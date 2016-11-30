--[[
Title: test mcml window frame
Author(s): devilwalk, LiXizhi
Date: 2016/11/25

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/test/testMCMLWindowFrame.lua");
local TEST = commonlib.gettable("TEST");
TEST.show();
------------------------------------------------------------
]]
local TEST = commonlib.gettable("TEST");

function TEST.show()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/test/testMCMLWindowFrame.html",
			name = "test", 
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			isShowTitleBar = false,
			bShow = true,
			zorder = 1000,
			click_through = false, 
			directPosition = true,
			cancelShowAnimation = true,
			align = "_ctb",
			x = 0,
			y = 0,
			width = 500,
			height = 100,
		});
end

local page;
function TEST.init()
	page = document:GetPageCtrl();
end

function TEST.testReposition()
	if(page) then
		local win = page:GetWindow();
		win:Reposition("_ctb", -200, -60, 500, 100);

		--local obj = page:GetParentUIObject()
		--obj:Reposition("_ctb", -200, 0, 500, 100);	
	end
end



