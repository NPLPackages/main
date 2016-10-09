--[[
Author: WangTian
Date: 2008-1-5, 2010-6.5 tested again by LiXizhi for imp2. 
Desc: testing XPath parser.
-----------------------------------------------
NPL.load("(gl)script/test/TestXPath.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

NPL.load("(gl)script/ide/XPath.lua");
local XPath = commonlib.XPath
function TestXPathOld()
	
	local xmlFileName = "script/test/TestXPath.xml";
	
	local xmlDocIP = ParaXML.LuaXML_ParseFile(xmlFileName);
	
	--NPL.load("(gl)script/kids/3DMapSystem_Misc.lua");
	--Map3DSystem.Misc.SaveTableToFile(xmlDocIP, "TestTable/xmlDocIP.ini");
	
	--local xpath = "/mcml:mcml/mcml:packageList/mcml:package/mcml:URL";
	local xpath = "//mcml:IPList/mcml:IP[@version = 5]";
	local xpath = "//mcml:IPList/mcml:IP[@version < 6]";
	local xpath = "//mcml:IPList/mcml:IP[@version > 4]";
	local xpath = "//mcml:IPList/mcml:IP[@version >= 5]";
	local xpath = "//mcml:IPList/mcml:IP[@version <= 5]";
	local xpath = "//mcml:IPList/mcml:IP[@text = 'Level2_2']";
	local xpath = "/mcml:mcml/mcml:packageList/mcml:package/";
	
	---- debug: print the result table
	--NPL.load("(gl)script/kids/3DMapSystem_Misc.lua");
	--Map3DSystem.Misc.SaveTableToFile(result, "TestTable/result.ini");
	
	
	local xmlFileName = "script/test/MeshLODtest.xml";
	
	local xmlDocIP = ParaXML.LuaXML_ParseFile(xmlFileName);
	
	local xpath = "/mesh/boundingbox/@minx";
	local xpath = "/mesh/submesh/@filename";
	local xpath = "/mesh/shader/@index";
	local xpath = "/mesh/submesh";
	local xpath = "//mesh";
	
	NPL.load("(gl)script/kids/3DMapSystem_Misc.lua");
	Map3DSystem.Misc.SaveTableToFile(xmlDocIP, "TestTable/mesh.ini");
	
	--local result = XPath.selectNodes(xmlDocIP, xpath);
	
	--%TESTCASE{"TestXPath", func="TestXPath", }%
	
	local node;
	for node in XPath.eachNode(xmlDocIP, xpath) do
		log("get node: "..commonlib.serialize(node).."\n");
	end
	
	-- debug: print the result table
	NPL.load("(gl)script/kids/3DMapSystem_Misc.lua");
	Map3DSystem.Misc.SaveTableToFile(result, "TestTable/result.ini");
end


TestXPath = {} --class

function TestXPath:setUp()
    
end

function TestXPath:test_XPath()
	local xmlTest =
	[[
	<?xml version="1.0" encoding="ISO-8859-1"?>
	<root>
		<element id="1" name="element1">text of the first element</element>
		<element id="2" name="element2">
			<subelement>text of the second element</subelement>
		</element>
	</root>
	]]

	local xmlDocIP = ParaXML.LuaXML_ParseString(xmlTest);
	-- get all elements
	assert(XPath.selectNodes2(xmlDocIP,'//element')[1].attr.id == "1")
	-- get the subelement text
	assert(XPath.selectNodes2(xmlDocIP,'//element/subelement/text()')[1] == "text of the second element")
	-- get the first element
	assert(XPath.selectNodes2(xmlDocIP,'//root/element[@id="1"]')[1].attr.id == "1")
end

function TempFixMe()
	NPL.load("(gl)script/ide/XPath.lua");
	local XPath = commonlib.XPath
	local i;
	for i=1,4 do
		local filename = format("config/Aries/WorldData/HaqiTown_LightHouse_S%d.Arenas_Mobs.xml", i);
		local xmlRootNode = ParaXML.LuaXML_ParseFile(filename);
		local node;
		for node in XPath.eachNode(xmlRootNode, "//arena") do
			local id = tonumber(node.attr.id)
			if(id) then
				local level_id = id - 10000;
				if(level_id>=1 and level_id<=100) then
					-- width is 150
					local x = 10000 + level_id * 150; 
					node.attr.position = string.format("%.1f,%.1f,%.1f", x, 20005.2, 20000);
				end
			end
		end
		local output = commonlib.Lua2XmlString(xmlRootNode, true);
		local file = ParaIO.open(filename, "w");
		if(file:IsValid()) then
			-- convert
			file:WriteString(output);
			file:close();
		end	
	end
end
LuaUnit:run('TestXPath')