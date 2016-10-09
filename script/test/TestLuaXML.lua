--[[
Author: Li,Xizhi
Date: 2007-9-22, updated to xUnit test in 2010.6.6
Desc: testing XML parser.
-----------------------------------------------
NPL.load("(gl)script/test/TestLuaXML.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

TestLuaXML = {}

function TestLuaXML:setUp()
	NPL.load("(gl)script/ide/LuaXML.lua");
end

-- test passed on 2007-9-22 by LiXizhi
function TestLuaXML:test_LuaXML_CPlusPlus()
	--NPL.load("(gl)script/ide/LuaXML.lua");
	--local x = commonlib.XML2Lua[[
     --<methodCall kind="xuxu">
      --<methodName>examples.getStateName</methodName>
      --<params>
         --<param>
            --<value><i4>41</i4></value>
            --</param>
         --</params>
      --</methodCall>
	--]]
	--log(commonlib.serialize(x));
	--
	
	local input = [[<paragraph justify="centered" >first child<b >bold</b>second child</paragraph>]]
	local x = ParaXML.LuaXML_ParseString(input);
	assert(x[1].name == "paragraph");
end

function TestLuaXML:test_LuaXML_NPL()
	local input = [[<paragraph justify="centered" >first child<b >bold</b>second child</paragraph>]]
	local xmlRoot = commonlib.XML2Lua(input)
	assert(commonlib.Lua2XmlString(xmlRoot) == input);
	log(commonlib.Lua2XmlString(xmlRoot, true))
end

LuaUnit:run("TestLuaXML");