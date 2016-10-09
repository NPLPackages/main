--[[
Title: gridviewtest
Author(s): zhangruofei
Date: 2010/05/24

use the lib:

------------------------------------------------------------
NPL.load("(gl)script/test/gridviewtest.lua");
test.gridviewtest.show();
------------------------------------------------------------
]]

local gridviewtest = {
	selecteditem=nil,
	sellitem=nil,
	
	filter={[17045]=true},
	
	data={
		{name="NewspaperShirt",gsid=1, copies=10, price=50, guid = 1, icon="Texture/Aries/Item/1221_NewspaperShirt.png", },
		{name="NewspaperHat",gsid=2, copies=11, price=60, guid = 2, icon="Texture/Aries/Item/1220_NewspaperHat.png", },
		{name="PoliceSolute", gsid=3, copies=12, price=80, guid = 3, icon="Texture/Aries/Item/9001_PoliceSolute.png", },
		{name="Swallow", gsid=4, copies=12, price=180, guid = 4, icon="Texture/Aries/Item/10130_Swallow.png", },

		}
	};


commonlib.setfield("test.gridviewtest", gridviewtest);
function gridviewtest.OnInit()
	local self = gridviewtest; 
	self.page = document:GetPageCtrl();
end
function gridviewtest.show()
System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/test/gridviewtest.html", 
			--url = "script/apps/Aries/NPCs/Farm/30368_FruitSaleShop_panel.html",
			name = "gridviewtest.ShowPage", 
			app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			isTopLevel = true,
			allowDrag = false,
			directPosition = true,
				align = "_ct",
				x = -320,
				y = -250,
				width = 720,
				height = 480,
		});

end


function gridviewtest.close()
	local self = gridviewtest;
	if(self.page)then
		self.page:CloseWindow();
	end
end

function gridviewtest.onclick(icon)
	local self = gridviewtest;
	if(icon~=nil) then
		self.page:SetValue("fruiticon",icon);
		self.page:Refresh(0);
	end
end

function gridviewtest.DS_Func(index)
	if(index == nil) then
		return #gridviewtest.data;
	else
		return gridviewtest.data[index];
	end
end