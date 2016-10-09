--[[
Author: Li,Xizhi
Date: 2009-5-18
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestMessageBox.lua");
-----------------------------------------------
]]

function Test_NestedMessageBox()
	_guihelper.MessageBox("Hello ParaEngine!", function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			-- pressed YES
			_guihelper.MessageBox("you pressed YES")
		else
			_guihelper.MessageBox("you pressed NO")
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end
