--[[
Title: ParaXModelAttr
Author(s): LiXizhi@yeah.net
Date: 2017/3/17
Desc: this class requires luajit ffi
Get information of ParaX Model asset file. It can be used to dump textures, vertices, matrices, bones, etc. 
There are two sets of API, one is cdata API, the other is scripting API. 
- cdata API function name is like xxxCData: such as GetObjectNumCData is very fast, it uses the same data reference to internal C++ ParaXModel without any memory allocation. 
Thus providing a way to read/write big C++ data without any memory allocation on scripting environment. 
Thanks to luajit ffi, the speed of referencing cdata field is close to native C++ speed.
- scripting API function name is like xxx: such as ParaXModelAttr:GetVertices() will copy cdata into standable lua table and cache the result, which could be slow 
and requires lots of memory allocations. 

use the lib:
------------------------------------------------------------
-- Example 1: load from cdata into npl table objects
NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
local attr = ParaXModelAttr:new():initFromPlayer(ParaScene.GetPlayer())
echo(attr:GetObjectNum());
echo(attr:GetRenderPasses());
echo(attr:GetGeosets());
echo(attr:GetAnimations());

for i=1, attr:GetObjectNum().nTextures do
	echo({texture = attr:GetTextureName(i-1)});
end

for i=1, attr:GetObjectNum().nBones do
	local bone = attr:GetBone(i-1);
	echo({bone_name = bone:GetField("name", ""), PivotPoint = bone:GetField("PivotPoint", {}), ParentIndex = bone:GetField("ParentIndex", -1) });
end

echo(attr:GetVertices());
echo(attr:GetIndices());

-- Example 2: loading from a given *.x or *.fbx file. 
NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
local attr = ParaXModelAttr:new():initFromAssetFile("character/bmax/test_multianim.fbx", function(attr)
	attr:DrawStaticAsText()
end)

-- Example 3: using cdata directly without any memory allocation on scripting environment
NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
local attr = ParaXModelAttr:new():initFromAssetFile("character/bmax/test_multianim.fbx", function(attr)
	local vertices = attr:GetVerticesCData();
	local nCount = attr:GetObjectNumCData().nVertices;
	for i=0, nCount-1 do
		echo({vertices[i].pos.x, vertices[i].pos.y, vertices[i].pos.z})
	end
end)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
local ffi = require('ffi');
local ParaXModelAttr = commonlib.inherit(nil, commonlib.gettable("System.Scene.Assets.ParaXModelAttr"));

function ParaXModelAttr:ctor()
	ParaXModelAttr.StaticInit();
end

function ParaXModelAttr.StaticInit()
	if(ParaXModelAttr.inited) then
		return
	end
	ParaXModelAttr.inited = true;

	ffi.cdef([[
	struct ParaXModelObjNum{
		uint32_t nGlobalSequences;
		uint32_t nAnimations;
		uint32_t nBones;
		uint32_t nVertices;
		uint32_t nViews;
		uint32_t nColors;
		uint32_t nTextures;
		uint32_t nTransparency; 
		uint32_t nTexAnims;	
		uint32_t nTexReplace;
		uint32_t nTexFlags;
		uint32_t nTexLookup;
		uint32_t nTexUnitLookup;		
		uint32_t nTransparencyLookup; 
		uint32_t nTexAnimLookup;
		uint32_t nAttachments; 
		uint32_t nAttachLookup;
		uint32_t nLights;
		uint32_t nCameras;
		uint32_t nRibbonEmitters;
		uint32_t nParticleEmitters;
		uint32_t nIndices;
	};

	struct ModelVertex {
		struct Vector3 pos;
		uint8_t weights[4];
		uint8_t bones[4];
		struct Vector3 normal;
		struct Vector2 texcoords;
		uint32_t color0; // always 0,0 if they are unused
		uint32_t color1;
	};

	struct ModelRenderPass 
	{
		/** Fix LiXizhi 2010.1.14. we may run out of 65535 vertices. so if indexStart is 0xffff, then we will use m_nIndexStart instead */
		uint16_t indexStart, indexCount;
		union {
			struct {
				uint16_t vertexStart, vertexEnd;
			};
			/** if indexStart is 0xffff, then m_nIndexStart stores the index offset in 32 bits. */
			int32_t m_nIndexStart;
		};

		//TextureID texture, texture2;
		int32_t tex;
		union{
			float m_fStripLength;
			float m_fCategoryID;
			float m_fReserved0;
		};
		
		
		int16_t texanim, color, opacity, blendmode;
		int32_t order;
		int32_t geoset;

		// bool usetex2 : 1, useenvmap : 1, cull : 1, trans : 1, unlit : 1, nozwrite : 1, swrap : 1, twrap : 1, force_local_tranparency : 1, skinningAni : 1, is_rigid_body : 1, disable_physics : 1, force_physics : 1, has_category_id : 1;
		uint32_t attrs;// Force alignment to next boundary.
	};

	struct ModelGeoset {
		uint16_t id;		// mesh part id
		uint16_t d2;		// 
		uint16_t vstart;	// first vertex
		uint16_t vcount;	// num vertices
		uint16_t istart;	// first index
		uint16_t icount;	// num indices
		union{
			struct {
				uint16_t d3;	// first vertex
				uint16_t d4;	// num vertices
			};
			int32_t m_nVertexStart; // 32bits vertex start used in bmax model
		};
		uint16_t d5;		// 
		uint16_t d6;		// root bone
		struct Vector3 v;
	};

	struct ModelAnimation {
		uint32_t animID;
		uint32_t timeStart;
		uint32_t timeEnd;

		float moveSpeed;

		uint32_t loopType; /// 1 for non-looping
		uint32_t flags;
		uint32_t d1;
		uint32_t d2;
		uint32_t playSpeed;  // note: this can't be play speed because it's 0 for some models

		struct Vector3 boxA, boxB;
		float rad;

		int16_t s[2];
	};
	]]);
end

-- @param attr: C++ attribute object of ParaXModel
function ParaXModelAttr:init(attr)
	self.attr = attr;
	self:reset();
	return self;
end

-- init from the primary asset file of the given player. 
-- @param player: player ParaObject. default to current one. 
function ParaXModelAttr:initFromPlayer(player)
	player = player or ParaScene.GetPlayer();
	return self:init(player:GetAttributeObject():GetChildAt(0,1):GetChildAt(0));
end

-- @param filename: *.x or *.fbx file
-- @param callbackFunc: because all asset file are async loaded. callbackFunc(self) is called when model is fully loaded.
function ParaXModelAttr:initFromAssetFile(filename, callbackFunc)
	local asset = ParaAsset.LoadParaX(filename, filename);
	asset:LoadAsset();
	if(asset:IsLoaded()) then
		self:init(asset:GetAttributeObject():GetChildAt(0));
		if(callbackFunc) then
			callbackFunc(self);
		end
	else
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(asset:IsLoaded()) then
				timer:Change();
				self:init(asset:GetAttributeObject():GetChildAt(0));
				if(callbackFunc) then
					callbackFunc(self);
				end
			elseif(not asset:IsValid()) then
				timer:Change();
			end
		end})
		mytimer:Change(0, 300);
	end
	return self;
end

function ParaXModelAttr:reset()
	self.m_objNum = nil;
	self.m_objNumCData = nil;
	self.m_origVertices = nil;
	self.m_origVerticesCData = nil;
	self.m_indices = nil;
	self.m_indicesCData = nil;
end

function ParaXModelAttr:GetTextureName(nIndex)
	if(self.attr) then
		return self.attr:GetChildAt(nIndex or 0, 1):GetField("LocalFileName", "");
	end
end

function ParaXModelAttr:GetTexture(nIndex)
	if(self.attr) then
		return self.attr:GetChildAt(nIndex or 0, 1);
	end
end

function ParaXModelAttr:GetBone(nIndex)
	if(self.attr) then
		return self.attr:GetChildAt(nIndex or 0, 0);
	end
end

-- it will cache the last result, this is as fast as C API.
-- e.g. 
-- local result = attr:GetObjectNumCData();
-- local nVertices = result.nVertices;
-- @return objnum cdata object
function ParaXModelAttr:GetObjectNumCData()
	if(self.m_objNumCData) then
		return self.m_objNumCData;
	end
	if(self.attr) then
		local objnum = ffi.new('struct ParaXModelObjNum *[1]');
		if(self.attr:GetFieldCData("ObjectNum", objnum)) then
			self.m_objNumCData = objnum[0];
			return self.m_objNumCData;
		end
	end
end

-- it will cache the last result. so calling this function multiple times is fast. 
function ParaXModelAttr:GetObjectNum()
	if(self.m_objNum) then
		return self.m_objNum;
	end
	if(self.attr) then
		local objnum = self:GetObjectNumCData();
		if(objnum) then
			self.m_objNum = {
				nGlobalSequences = objnum.nGlobalSequences,
				nAnimations = objnum.nAnimations,
				nBones = objnum.nBones,
				nVertices = objnum.nVertices,
				nViews = objnum.nViews,
				nColors = objnum.nColors,
				nTextures = objnum.nTextures,
				nTransparency = objnum.nTransparency,
				nTexAnims = objnum.nTexAnims,
				nTexReplace = objnum.nTexReplace,
				nTexFlags = objnum.nTexFlags,
				nTexLookup = objnum.nTexLookup,
				nTexUnitLookup = objnum.nTexUnitLookup,
				nTransparencyLookup = objnum.nTransparencyLookup,
				nTexAnimLookup = objnum.nTexAnimLookup,
				nAttachments = objnum.nAttachments,
				nAttachLookup = objnum.nAttachLookup,
				nLights = objnum.nLights,
				nCameras = objnum.nCameras,
				nRibbonEmitters = objnum.nRibbonEmitters,
				nParticleEmitters = objnum.nParticleEmitters,
				nIndices = objnum.nIndices,
				-- added using attribute
				nRenderPasses = self.attr:GetField("RenderPassesCount", 0),
				nGeosets = self.attr:GetField("GeosetsCount", 0),
			}
			return self.m_objNum;
		end
	end
end

-- it will cache the last result, this is as fast as C API.
-- e.g. 
-- local result = attr:Animations();
-- echo(result[0].pos.y)
-- @return vertices* cdata object
function ParaXModelAttr:GetAnimationsCData()
	if(self.m_animsCData) then
		return self.m_animsCData;
	end
	if(self.attr) then
		local animations = ffi.new('struct ModelAnimation *[1]');
		if(self.attr:GetFieldCData("Animations", animations)) then
			self.m_animsCData = animations[0];
			return self.m_animsCData;
		end
	end
end

-- it will cache result
function ParaXModelAttr:GetAnimations()
	if(self.m_anims) then
		return self.m_anims;
	end
	if(self.attr) then
		local animations = self:GetAnimationsCData();
		if(animations) then
			local animations_ = {};
			self.m_anims = animations_;
			local nCount = self:GetObjectNum().nAnimations;
			for i=1, nCount do
				local ii = i-1;
				animations_[i] = {
					animID = animations[ii].animID,
					timeStart = animations[ii].timeStart,
					timeEnd = animations[ii].timeEnd,
					moveSpeed = animations[ii].moveSpeed,
					loopType = animations[ii].loopType,
					flags = animations[ii].flags,
				};
			end
			return self.m_anims;
		end
	end
end

-- it will cache the last result, this is as fast as C API.
-- e.g. 
-- local result = attr:GetVerticesCData();
-- echo(result[0].pos.y)
-- @return vertices* cdata object
function ParaXModelAttr:GetVerticesCData()
	if(self.m_origVerticesCData) then
		return self.m_origVerticesCData;
	end
	if(self.attr) then
		local vertices = ffi.new('struct ModelVertex *[1]');
		if(self.attr:GetFieldCData("Vertices", vertices)) then
			self.m_origVerticesCData = vertices[0];
			return self.m_origVerticesCData;
		end
	end
end

-- it will cache result
function ParaXModelAttr:GetVertices()
	if(self.m_origVertices) then
		return self.m_origVertices;
	end
	if(self.attr) then
		local vertices = self:GetVerticesCData();
		if(vertices) then
			local vertices_ = {};
			self.m_origVertices = vertices_;
			local nCount = self:GetObjectNum().nVertices;
			for i=1, nCount do
				local ii = i-1;
				vertices_[i] = {
					pos = {vertices[ii].pos.x, vertices[ii].pos.y, vertices[ii].pos.z},
					weights = {vertices[ii].weights[0], vertices[ii].weights[1], vertices[ii].weights[2], vertices[ii].weights[3]},
					bones = {vertices[ii].bones[0], vertices[ii].bones[1], vertices[ii].bones[2], vertices[ii].bones[3]},
					normal = {vertices[ii].normal.x, vertices[ii].normal.y, vertices[ii].normal.z},
					texcoords = {vertices[ii].texcoords.x, vertices[ii].texcoords.y},
					color0 = vertices[ii].color0,
					color1 = vertices[ii].color1, 
				};
			end
			return self.m_origVertices;
		end
	end
end

-- it will cache the last result, this is as fast as C API.
-- e.g. 
-- local result = attr:GetIndicesCData();
-- echo(result[0])
-- @return indices* cdata object
function ParaXModelAttr:GetIndicesCData()
	if(self.m_indicesCData) then
		return self.m_indicesCData;
	end
	if(self.attr) then
		local indices = ffi.new('uint16_t *[1]');
		if(self.attr:GetFieldCData("Indices", indices)) then
			self.m_indicesCData = indices[0];
			return self.m_indicesCData;
		end
	end
end

-- it will cache result
function ParaXModelAttr:GetIndices()
	if(self.m_indices) then
		return self.m_indices;
	end
	if(self.attr) then
		local indices = self:GetIndicesCData();
		if(indices) then
			local indices_ = {};
			self.m_indices = indices_;
			local nCount = self:GetObjectNum().nIndices;
			for i=1, nCount do
				indices_[i] = indices[i-1];
			end
			return self.m_indices;
		end
	end
end

-- it will cache the last result, this is as fast as C API.
-- e.g. 
-- local result = attr:GetRenderPassesCData();
-- echo(result[0])
-- @return renderpass* cdata object
function ParaXModelAttr:GetRenderPassesCData()
	if(self.m_passesCData) then
		return self.m_passesCData;
	end
	if(self.attr) then
		local passes = ffi.new('struct ModelRenderPass *[1]');
		if(self.attr:GetFieldCData("RenderPasses", passes)) then
			self.m_passesCData = passes[0];
			return self.m_passesCData;
		end
	end
end

-- it will cache result
function ParaXModelAttr:GetRenderPasses()
	if(self.m_passes) then
		return self.m_passes;
	end
	if(self.attr) then
		local passes = self:GetRenderPassesCData();
		if(passes) then
			local passes_ = {};
			self.m_passes = passes_;
			for i=1, self:GetObjectNum().nRenderPasses do
				local ii = i-1;
				passes_[i] = {
					indexStart = passes[ii].indexStart,
					indexCount = passes[ii].indexCount,
					m_nIndexStart = passes[ii].m_nIndexStart,
					tex = passes[ii].tex,
					m_fCategoryID = passes[ii].m_fCategoryID,
					texanim = passes[ii].texanim,
					color = passes[ii].color,
					opacity = passes[ii].opacity,
					blendmode = passes[ii].blendmode,
					order = passes[ii].order,
					geoset = passes[ii].geoset,
					attrs = passes[ii].attrs,
				};
			end
			return self.m_passes;
		end
	end
end


-- it will cache the last result, this is as fast as C API.
-- e.g. 
-- local result = attr:GetGeosetsCData();
-- echo(result[0])
-- @return ModelGeoset* cdata object
function ParaXModelAttr:GetGeosetsCData()
	if(self.m_geosetsCData) then
		return self.m_geosetsCData;
	end
	if(self.attr) then
		local geosets = ffi.new('struct ModelGeoset *[1]');
		if(self.attr:GetFieldCData("Geosets", geosets)) then
			self.m_geosetsCData = geosets[0];
			return self.m_geosetsCData;
		end
	end
end

-- it will cache result
function ParaXModelAttr:GetGeosets()
	if(self.m_geosets) then
		return self.m_geosets;
	end
	if(self.attr) then
		local geosets = self:GetGeosetsCData();
		if(geosets) then
			local geosets_ = {};
			self.m_geosets = geosets_;
			for i=1, self:GetObjectNum().nGeosets do
				local ii = i-1;
				geosets_[i] = {
					id = geosets[ii].id,
					d2 = geosets[ii].d2,
					vstart = geosets[ii].vstart,
					vcount = geosets[ii].vcount,
					istart = geosets[ii].istart,
					icount = geosets[ii].icount,
					m_nVertexStart = geosets[ii].m_nVertexStart,
					d5 = geosets[ii].d5,
					d6 = geosets[ii].d6,
					v = geosets[ii].v,
				};
			end
			return self.m_geosets;
		end
	end
end

function ParaXModelAttr:IsValid()
	return self:GetObjectNum()~=nil;
end

-- this function emulate drawing the static 3d object using text output. 
function ParaXModelAttr:DrawStaticAsText()
	if(not self:IsValid()) then
		LOG.std(nil, "warn", "ParaXModelAttr", "invalid paraxmodel");
		return;
	end
	-- render a single pass
	local function DrawPass_(p)
		if (p.indexCount == 0) then
			return;
		end
		if(p.tex >= 0) then
			echo({"SetTexture: ", self:GetTextureName(p.tex)})
		end
		echo({"SetBlendMode: ", p.blendmode})

		local origVertices = self:GetVertices();
		local nIndexOffset = p.m_nIndexStart;
		local indices = self:GetIndices();
		local numFaces = p.indexCount / 3;
		echo({"triangle count:", numFaces})
		for i = 1, numFaces do
			local nVB = 3 * i;
			log("triangle"..i..": ")
			for k = 0, 2 do
				local a = indices[nIndexOffset + nVB + k];
				local vert = origVertices[a+1];
				log({"vert"..k, vert.pos, vert.normal, vert.color0})
			end
			log("\n")
		end
	end

	for nPass=1, self:GetObjectNum().nRenderPasses do
		local p = self:GetRenderPasses()[nPass];
		DrawPass_(p);
	end
end