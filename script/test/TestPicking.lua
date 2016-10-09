--[[
Author: Li,Xizhi
Date: 2008-11-25
Desc: scene picking test
-----------------------------------------------
NPL.load("(gl)script/test/TestPicking.lua");
-----------------------------------------------
]]

-- Test scene picking. 
-- please note that: objects must be completely inside the near and far planes in order to pass the test. 
-- %TESTCASE{"test_GetObjectsByScreenRect", func = "test_GetObjectsByScreenRect", input = {left=400, top=300, right=600, bottom=450, filter="anyobject"}, }%
function test_GetObjectsByScreenRect(input)
	local left, top, right, bottom = tonumber(input.left), tonumber(input.top), tonumber(input.right), tonumber(input.bottom)
	local result = {};
	ParaScene.GetObjectsByScreenRect(result, left, top, right, bottom, input.filter, -1);
	
	_this = ParaUI.GetUIObject("GetObjectsByScreenRect");
	if(_this:IsValid() == false) then
		_this = ParaUI.CreateUIObject("container", "GetObjectsByScreenRect", "_lt", 0, 0, 150, 300);
		_this:AttachToRoot();
	end
	_this.x = left;
	_this.y = top;
	_this.width = right - left;
	_this.height = bottom - top;
			
	local _, obj;
	for _, obj in pairs(result) do
		commonlib.log("-->"..tostring(obj.name)..": asset:")
		commonlib.echo(obj:GetPrimaryAsset():GetKeyName())
	end
	log("Done!\n")
end

-- change the physics group id for the object are the current mouse position. 
function test_ChangePhysicsGroup(nGroupID)
	local obj = ParaScene.MousePick(40, "anyobject"); 
	if(obj:IsValid()) then
		obj:SetPhysicsGroup(nGroupID or 1);
		commonlib.echo(obj:GetPhysicsGroup())
	end
end

-- change the physics group id for the object are the current mouse position. 
function test_ChangeCameraMask(mask)
	-- bitwise mask. 
	ParaCamera.GetAttributeObject():SetField("PhysicsGroupMask", mask or 15); 
end
