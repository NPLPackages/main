--[[
Author: Li,Xizhi
Date: 2010-8-19
Desc: moved from source code to test script
-----------------------------------------------
NPL.load("(gl)script/test/TestRegion.lua");
local RegionMonitor = commonlib.gettable("Map3DSystem.App.worlds.RegionMonitor");
RegionMonitor.TestMCImporter()
-----------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionMonitor.lua");

local RegionMonitor = commonlib.gettable("Map3DSystem.App.worlds.RegionMonitor");
--[[
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionMonitor.lua");
Map3DSystem.App.worlds.RegionMonitor.TerrainRegionTest();
--]]
function RegionMonitor.TerrainRegionTest()

	-- get a pixel value of a given region layer.
	local x, _, y = ParaScene.GetPlayer():GetPosition();
	commonlib.echo( { 
		alpha = ParaTerrain.GetRegionValue("test", x, y, "a"),
		r = ParaTerrain.GetRegionValue("test", x, y, "r"),
		g = ParaTerrain.GetRegionValue("test", x, y, "g"),
		b = ParaTerrain.GetRegionValue("test", x, y, "b"),
		argb = ParaTerrain.GetRegionValue("test", x, y, ""),
		})

	-- iterate and display all region layers
	local att = ParaTerrain.GetAttributeObjectAt(x,y);
	att:SetField("CurrentRegionIndex", 0);
	commonlib.echo{ 
		NumOfRegions = att:GetField("NumOfRegions", 0), 
		CurrentRegionName = att:GetField("CurrentRegionName", ""),
		CurrentRegionFilepath = att:GetField("CurrentRegionFilepath", ""),
	};
	
	--create a region layer if not done before. 
	att:SetField("CurrentRegionName", "test");
	att:SetField("CurrentRegionFilepath", "%WORLD%/regions/test_37_37.png");
	commonlib.echo{ 
		CurrentRegionName = att:GetField("CurrentRegionName", ""),
		CurrentRegionFilepath = att:GetField("CurrentRegionFilepath", ""),
		NumOfRegions = att:GetField("NumOfRegions", 0), 
	};
	commonlib.echo( { 
		alpha = ParaTerrain.GetRegionValue("test", x, y, "a"),
		r = ParaTerrain.GetRegionValue("test", x, y, "r"),
		g = ParaTerrain.GetRegionValue("test", x, y, "g"),
		b = ParaTerrain.GetRegionValue("test", x, y, "b"),
		argb = ParaTerrain.GetRegionValue("test", x, y, ""),
		})
end

-- testing region
function RegionMonitor.TestMCImporter()
	echo("now testing MCImporter.dll")
	NPL.activate("MCImporter.dll", {cmd="load_region"});
end