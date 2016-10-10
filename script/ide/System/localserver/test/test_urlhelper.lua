--[[
Title: testing url helper
Author(s): LiXizhi
Date: 2008/2/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/localserver/test/test_urlhelper.lua");
test_String()
test_WS_to_REST()
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/localserver/UrlHelper.lua");

-- passed by LiXizhi 2008.2.22
function test_WS_to_REST()
	log("testing System.localserver.UrlHelper.WS_to_REST: \n");
	log("www.paraengine.com/getPos.asmx?uid=123&pos.x=1&pos.y=2".." is expected\n")
	log(System.localserver.UrlHelper.WS_to_REST("www.paraengine.com/getPos.asmx", {uid=123, pos = {x=1, y=2}}, {"uid", "pos.x", "pos.y"}).."\n")
end

-- passed by LiXizhi 2008.2.24
function test_String()
	log("testing IsStringValidPathComponent: \n");
	
	local testcases = {
		"ParaEngine",
		".ParaEngine",
		"ParaEngine..",
		"Para?Engine",
		"Para.Engine",
		"..Para.?;:<>Engine..",
	}
	local i, case
	for i, case in ipairs(testcases) do
		log("case: "..case.."\n")
		if(System.localserver.UrlHelper.IsStringValidPathComponent(case)) then
			log("IsStringValidPathComponent returns TRUE\n")
		else
			log("IsStringValidPathComponent returns FALSE\n")
		end
		log("EnsureStringValidPathComponent:"..System.localserver.UrlHelper.EnsureStringValidPathComponent(case).."\n");
	end
end