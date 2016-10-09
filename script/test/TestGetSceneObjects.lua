--[[
Author: LiXizhi
Date: 2007-9-3
Desc: 
-----------------------------------------------
NPL.load("(gl)script/test/TestGetSceneObjects.lua");
-----------------------------------------------
]]

if(not test) then test = {} end
--passed by LiXizhi 2008-3-16
-- %TESTCASE{"Get Scene Objects By Sphere", func="test.GetObjectsBySphere", input={radius = 20, filter = "anyobject"}}%
function test.GetObjectsBySphere(input)
	input = input or {};
	input.radius = input.radius or 20
	input.filter = input.filter or "anyobject"
	local objlist = {};
	local fromX, fromY, fromZ = ParaScene.GetPlayer():GetPosition();
	-- NOTE: radius agianst the object center, 
	local nCount = ParaScene.GetObjectsBySphere(objlist, fromX, fromY, fromZ, input.radius, input.filter);
	
	local k = 1;
	-- find the xref object with the same position in mini scene graph
	for k = 1, nCount do
		local obj = objlist[k];
		log(k..": "..obj.name.."\n");
	end		
end

--passed by LiXizhi 2008-12-22
-- %TESTCASE{"test_ParaScene_GetObject_ByID", func="test_ParaScene_GetObject_ByID", input={id = 0,}}%
function test_ParaScene_GetObject_ByID(input)
	input = input or {};
	if(not input.id or input.id == 0) then
		input.id = ParaScene.GetPlayer():GetID();
	end
	local obj = ParaScene.GetObject(input.id);
	commonlib.log(obj:GetID().." is found\n")
	commonlib.log("name is "..obj.name.."\n")
end
