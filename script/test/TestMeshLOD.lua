--[[
Author: Li,Xizhi
Date: 2007-12-21
Desc: testing XML parser.
-----------------------------------------------
NPL.load("(gl)script/test/TestMeshLOD.lua");
TestBMaxModel_ExportSTL("test/default.bmax");
TestBMaxModel_ExportSTL("test/default.bmax",true);
TestBMaxModel("test_bmax_template.bmax");
TestMeshFBX();
TestMeshOnAssetLoad()
TestMeshLOD()
TestMeshEffectParams(scene)

-----------------------------------------------
]]
function TestBMaxModel_ExportSTL(file_name,binary)
	file_name = file_name or "character/CC/03animals/chicken/chicken.x";
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	local model = ParaScene.CreateObject("BMaxObject", "", x,y,z);
	model:SetField("assetfile", file_name);
	ParaScene.Attach(model);
	local output_file_name = file_name .. ".stl";
	if(binary)then
		model:SetField("ExportSTLBinary", output_file_name);
	else
		model:SetField("ExportSTL", output_file_name);
	end
end
function TestBMaxModel(file_name)
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	local model = ParaScene.CreateObject("BMaxObject", "", x,y,z);
	model:SetField("assetfile", file_name or "character/CC/03animals/chicken/chicken.x");
	ParaScene.Attach(model);
end

function TestMeshFBX()
	local asset = ParaAsset.LoadStaticMesh("","model/test/test_no_embedded_png.fbx");
	obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	obj:SetPosition(x,y,z);
	obj:SetField("progress", 1);
	

	ParaScene.Attach(obj);
end


-- test passed on 2009-9-2 by LiXizhi
function TestMeshOnAssetLoad()

	local asset = ParaAsset.LoadStaticMesh("","model/skybox/skybox15/skybox15.x");
	obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	obj:SetPosition(x,y,z);
	obj:GetAttributeObject():SetField("On_AssetLoaded", ";Test_OnAssetLoaded();")
	ParaScene.Attach(obj);
	
	commonlib.echo({id = obj.id, "object is added"})
end
function Test_OnAssetLoaded()
	commonlib.echo({"asset associated with object is loaded.", sensor_name, sensor_id})
end

-- test passed on 2007-12-21 by LiXizhi
function TestMeshLOD()

	-- testing mesh LOD
	local asset = ParaAsset.LoadStaticMesh("","script/test/MeshLODtest.xml");
	obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(0, 1, 0);
	ParaScene.Attach(obj);
	
	-- testing character LOD
	asset = ParaAsset.LoadParaX("","script/test/CharLODtest.xml");
	obj = ParaScene.CreateCharacter("player", asset, "", true, 0.35, 0.5, 1);
	obj:SetPosition(0.5, 0, 0.5);
	obj:SetFacing(2);
	ParaScene.Attach(obj);
end


-- test passed on 2008-1-10 by LiXizhi
--  CParameterBlock is implemented in AssetEntity and CBaseObject. Current the effect parameters can be set via ParaParamBlock interface from the scripting interface. 
--we offer three levels of effect parameters: per effect file, per asset file, per mesh object. Effect parameters are also applied in that order. 
--e.g. per effect file affects all object rendering with the effect file; per asset file affects all objects that use the mesh asset file; per mesh object affects only the mesh object. 
-- @param scene: a mini scene graph object. 
function TestMeshEffectParams(scene)
	-- load effect. 
	local effect = ParaAsset.LoadEffectFile("MyEffect", "script/test/media/ocean_water.fx");
	
	-- test per effect params
	local effect = ParaAsset.GetEffectFile("MyEffect");
	-- test assign handle, 
	-- Note: we can assign a different effect file at runtime to the same handle to secretly change the effect used to render an object.
	effect:SetHandle(1001); 
	local params = effect:GetParamBlock();
	params:SetVector3("sun_color", 1,1,0.3);
	params:SetVector3("sun_vec", 0,1,0.7);
	params:SetTexture(0, "script/test/media/bumpMap.dds");
	params:SetTexture(1, "script/test/media/cloud.dds");
	params:SetFloat("time", 0);
	params:SetVector3("shallowWaterColor", 0.64,0.8,0.96);
	params:SetVector3("deepWaterColor", 0.08,0.36,0.6);
	params:SetFloat("shininess", 80);
	params:SetVector2("waveDir", 1, 0);
	params:SetVector3("texCoordOffset", 1, 0, 0); -- Vector3(1.0f / texScale, texOffset.X, texOffset.Y)
	
	-- testing with per asset params. 
	local asset = ParaAsset.LoadStaticMesh("","model/06props/shared/pops/huaban.x")
	
	
	do
		-- testing bounding box of asset
		local aabb = {};
		asset:GetBoundingBox(aabb);
		log(string.format("Asset GetBoundingBox testing: min_x=%f, min_y=%f,min_z=%f,max_x=%f, max_y=%f,max_z=%f\n", aabb.min_x, aabb.min_y, aabb.min_z, aabb.max_x, aabb.max_y, aabb.max_z));
	end
	
	local params = asset:GetParamBlock();
	params:SetVector3("shallowWaterColor", 1,0,0); -- change to red
	params:SetVector3("deepWaterColor", 0.5,0,0);
	params:SetTexture(1, "script/test/media/cloud.dds");
	
	-- testing per object params
	obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(0, 1, 0);
	scene:AddChild(obj);
	local params = obj:GetEffectParamBlock();
	params:SetVector3("shallowWaterColor", 0.64,0.8,0.96); -- change to blue
	params:SetVector3("deepWaterColor", 0.08,0.36,0.6);
	
	-- associate with custom effect. 
	obj:GetAttributeObject():SetField("render_tech", 1001);
	
	do
		--[[ particle test
		asset = ParaAsset.LoadStaticMesh("", "model/common/building_point/building_point.x")
		obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
		obj:SetPosition(0, 1.2, 0);
		obj:SetScaling(3);
		obj:Rotate(0, 0 ,0);
		scene:AddChild(obj);]]
		
		
		--[[ light map test passed on 2008.1.25
		asset = ParaAsset.LoadStaticMesh("", "model/01building/V3/components/TEST/zyu/test3.x")
		--asset = ParaAsset.LoadStaticMesh("", "model/test/lightmap/lightmap_max8.x")
		
		obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
		obj:SetPosition(0, 0, 0);
		scene:AddChild(obj);]]
		
		-- test voxel mesh
		--[[obj = ParaScene.CreateVoxelMesh("", "", "terrain/data/LlanoTex.jpg");
		obj:SetPosition(0.5, 1, 0);
		asset = ParaAsset.LoadTexture("", "terrain/data/dirt2.dds", 1)
		obj:SetReplaceableTexture(0, asset);
		scene:AddChild(obj);
		log("-- test voxel mesh\n")]]
	end
end

-- test passed on 2008-1-10 by LiXizhi
function TestMeshEffectXMLParams(scene)
	-- load effect. 
	local effect = ParaAsset.LoadEffectFile("MyEffect", "script/test/media/ocean_water.fx");
	
	-- test per effect params
	local effect = ParaAsset.GetEffectFile("MyEffect");
	-- test assign handle, 
	-- Note: we can assign a different effect file at runtime to the same handle to secretly change the effect used to render an object.
	effect:SetHandle(1001); 
	local params = effect:GetParamBlock();
	params:SetVector3("sun_color", 1,1,0.3);
	params:SetVector3("sun_vec", 0,1,0.7);
	--params:SetTexture(0, "script/test/media/bumpMap.dds");
	--params:SetTexture(1, "script/test/media/cloud.dds");
	--params:SetFloat("time", 0);
	--params:SetVector3("shallowWaterColor", 0.64,0.8,0.96);
	params:SetVector3("deepWaterColor", 0.08,0.36,0.6);
	params:SetFloat("shininess", 80);
	params:SetVector2("waveDir", 1, 0);
	params:SetVector3("texCoordOffset", 1, 0, 0); -- Vector3(1.0f / texScale, texOffset.X, texOffset.Y)
	
	-- testing with per asset params. 
	local asset = ParaAsset.LoadStaticMesh("","script/test/MeshShaderParamTest.xml")
	
	-- testing per object params
	
	obj = ParaScene.CreateMeshPhysicsObject("", asset, 1,1,1, true, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(0, 1, 0);
	scene:AddChild(obj);
	
	-- associate with custom effect. 
	--obj:GetAttributeObject():SetField("render_tech", 1001);
end

--TestMeshEffectParams = TestMeshEffectXMLParams;