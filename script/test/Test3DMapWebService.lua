
--NPL.load("(gl)script/test/Test3DMapWebService.lua");

NPL.load("(gl)script/ide/gui_helper.lua");

if(not Test) then Test = {}; end

function Test.WebServiceTest()

	local webservice_GetMapMarkByID = "http://www.paraweb3d.com/GetMapMarkByID.asmx";
	local webservice_GetMapMarksInRegion = "http://www.paraweb3d.com/GetMapMarksInRegion.asmx";
	local webservice_GetMapModelByIDs = "http://www.paraweb3d.com/GetMapModelByIDs.asmx";
	local webservice_GetTileInfoByID = "http://www.paraweb3d.com/GetTileInfoByID.asmx";
	local webservice_GetTilesInRegion = "http://www.paraweb3d.com/GetTilesInRegion.asmx";
	
	-- send out the web serivce
	local msg = {
			operation = "get",
			username = "user",
			password = "pass",
			markid = 2,
			--tileid = 1,
			
			x = 2,
			y = 2,
			width = 2,
			height = 2,
	}
	--local msg = {
			--operation = "get",
			--username = "user",
			--password = "pass",
			--x = 2,
			--y = 2,
			--width = 2,
			--height = 2,
			--marktype = 1,
			--markNum = 2,
			--isApproved = true,
	--}
	--local msg = {
			--operation = "get",
			--username = "user",
			--password = "pass",
			--modelIDs = {1, 2, 3},
	--}
	
	local callbackString = string.format("Test.WebService_Callback();");
	NPL.RegisterWSCallBack(webservice_GetMapMarkByID, callbackString);
	NPL.activate(webservice_GetMapMarkByID, msg);
	
	--NPL.RegisterWSCallBack(webservice_GetMapMarksInRegion, callbackString);
	--NPL.activate(webservice_GetMapMarksInRegion, msg);
	--NPL.RegisterWSCallBack(webservice_GetMapModelByIDs, callbackString);
	--NPL.activate(webservice_GetMapModelByIDs, msg);
	--NPL.RegisterWSCallBack(webservice_GetTileInfoByID, callbackString);
	--NPL.activate(webservice_GetTileInfoByID, msg);
	--NPL.RegisterWSCallBack(webservice_GetTilesInRegion, callbackString);
	--NPL.activate(webservice_GetTilesInRegion, msg);
end

function Test.WebService_Callback()

	if(msg ~= nil) then
	
		--log("MSG:"..msg.markID.."  "..msg.markType.."  "..msg.markTitle.."  "..msg.markStyle
			--.."  "..msg.startTime.."  "..msg.endTime.."  "..msg.x.."  "..msg.y.."  "..msg.cityName
			--.."  "..msg.rank.."  "..msg.logo.."  "..msg.Signature.."  "..msg.desc.."  "..msg.ageGroup
			--.."  "..msg.worldid.."  "..msg.isApproved.."  "..msg.version.."  "..msg.clickcnt
			--.."  "..msg.ownerUserID.."\r\n");

		
		NPL.load("(gl)script/kids/3DMapSystem_Data.lua");
		Map3DSystem.Misc.SaveTableToFile(msg, "TestTable/MSG.ini");
		
		
		--log("MSG:"..msg.ID.."  "..msg.X.."  "..msg.Y.."  "..msg.OwnerID
			--.."  "..msg.terrainStyle.."  "..msg.tileType.."  "..msg.Price.."  "..msg.RentPrice
			--.."  "..msg.rank.."  "..msg.Models.."  "..msg.CityName.."  "..msg.Community.."  "..msg.AgeGroup
			--.."\r\n");
		
	elseif(msg == nil) then
		_guihelper.MessageBox("Network is not available, please try again later");
	else
		--LoginBox.SwitchTabWindow(2);
		_guihelper.MessageBox("Not Authenticated.");
	end
	
end