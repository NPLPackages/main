--[[
Title: ParaEngine API with Luajit FFI
Author(s): LiXizhi
Date: 2013/11/22
Desc: When luajit is enabled, we will replace some frequently used ParaEngine API with LuaJit FFI, which is usually 20 times faster.
Calls to C functions can be inlined in JIT-compiled code.
Use Lib: 

---++ FFI docs:
http://luajit.org/ext_ffi_api.html
http://luajit.org/ext_ffi_semantics.html

---++ Test & Examples
See TestLuaJit.lua

---++ LuaJIT FFI callback performance
On my computer, a function call from LuaJIT into C has an overhead of 5 clock cycles (notably, just as fast as calling a function 
via a function pointer in plain C), whereas calling from C back into Lua has a 135 cycle overhead, 27x slower.

$ luajit-2.0.0-beta10 callback-bench.lua   
C into C          3.344 nsec/call
Lua into C        3.345 nsec/call
C into Lua       75.386 nsec/call
Lua into Lua      0.557 nsec/call
C empty loop      0.557 nsec/call
Lua empty loop    0.557 nsec/cal

---++ LuaJit and C++ binding
Possible, but not used widely, since performance is not that important for most ParaEngine API.
http://lua-users.org/lists/lua-l/2011-07/msg00496.html
https://speakerdeck.com/igdshare/introduction-to-luajit-how-to-bind-cpp-code-base-using-luajit-ffi

sample code: https://gist.github.com/gaspard/1087380

-------------------------------------------------------
NPL.load("(gl)script/ide/ParaEngineLuaJitFFI.lua");
if(ParaEngine.hasFFI) then
	-- we have ffi
end
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
local is64BitsSystem = ParaEngine.GetAttributeObject():GetField("Is64BitsSystem", false);
local str64BitsSystem;
if(is64BitsSystem) then
	str64BitsSystem = "64bits";
else
	str64BitsSystem = "32bits";
end

local use_ffi = jit and jit.version 
	-- skipping PARA_PLATFORM_IOS == 1, since iOS does not allow it right now.
	and ParaEngine.GetAttributeObject():GetField("Platform", 0)~=1;
	-- ffi is slow when jit is not enabled, so disable it for now. 
	-- not ParaEngine.GetAttributeObject():GetField("IsMobilePlatform", false);

-- debug version uses "lua_d.dll", so it is not jit enabled
if(use_ffi) then
	ParaGlobal.WriteToLogFile(string.format("ParaEngine LuaJIT %s version:%s\r\n", str64BitsSystem, tostring(jit.version)));
	local jit_status = {jit.status()};
	jit_status[1] = tostring(jit_status[1]) or "";
	jit_status = table.concat(jit_status, ", ");
	ParaGlobal.WriteToLogFile(string.format("Jit status:%s \r\n", jit_status or ""));

	local ffi = require("ffi")
	local C = ffi.C;

	ffi.cdef([[
	uint32_t ParaGlobal_timeGetTime();
	double ParaGlobal_getAccurateTime();
	void ParaGlobal_WriteToLogFile(const char* strMessage);

	float ParaTerrain_GetElevation(float x, float y);
	void ParaTerrain_SelectBlock(uint16_t x,uint16_t y,uint16_t z,bool isSelect, int nGroupID);
	void ParaTerrain_SetBlockTemplateId(float x,float y,float z,uint16_t templateId);
	void ParaTerrain_SetBlockTemplateIdByIdx(uint16_t x,uint16_t y,uint16_t z,uint32_t templateId);

	uint32_t ParaTerrain_GetBlockTemplateId(float x,float y,float z);
	uint32_t ParaTerrain_GetBlockTemplateIdByIdx(uint16_t x,uint16_t y,uint16_t z);
	void ParaTerrain_SetBlockUserData(float x,float y,float z,uint32_t data);
	void ParaTerrain_SetBlockUserDataByIdx(uint16_t x,uint16_t y,uint16_t z,uint32_t data);
	uint32_t ParaTerrain_GetBlockUserData(float x,float y,float z);
	uint32_t ParaTerrain_GetBlockUserDataByIdx(uint16_t x,uint16_t y,uint16_t z);
	void ParaTerrain_UpdateHoles( float x, float y );
	bool ParaTerrain_IsHole( float x, float y );
	void ParaTerrain_SetHole( float x, float y, bool bIsHold );
	int ParaTerrain_FindFirstBlock( uint16_t x,uint16_t y,uint16_t z, uint16_t nSide /*= 4*/, uint32_t max_dist /*= 32*/, uint32_t attrFilter /*= 0xffffffff*/, int nCategoryID /*= -1*/ );
	int ParaTerrain_GetFirstBlock( uint16_t x,uint16_t y,uint16_t z, int nBlockId, uint16_t nSide /*= 5*/, uint32_t max_dist /*= 32*/);
	

	void ParaBlockWorld_SetBlockId(void* pWorld, uint16_t x, uint16_t y, uint16_t z, uint32_t templateId);
	uint32_t ParaBlockWorld_GetBlockId(void* pWorld, uint16_t x, uint16_t y, uint16_t z);
	void ParaBlockWorld_SetBlockData(void* pWorld, uint16_t x, uint16_t y, uint16_t z, uint32_t data);
	uint32_t ParaBlockWorld_GetBlockData(void* pWorld, uint16_t x, uint16_t y, uint16_t z);
	int ParaBlockWorld_FindFirstBlock(void* pWorld, uint16_t x, uint16_t y, uint16_t z, uint16_t nSide /*= 4*/, uint32_t max_dist /*= 32*/, uint32_t attrFilter /*= 0xffffffff*/, int nCategoryID /*= -1*/);
	int ParaBlockWorld_GetFirstBlock(void* pWorld, uint16_t x, uint16_t y, uint16_t z, int nBlockId, uint16_t nSide /*= 4*/, uint32_t max_dist /*= 32*/);

	void ParaTerrain_GetBlockFullData(uint16_t x, uint16_t y, uint16_t z, uint16_t* pId, uint32_t* pUserData);
	
	bool ParaScene_CheckExist(int nID);

	bool ParaGlobal_SetFieldCData(const char* sFieldname, void* pValue);
	bool ParaGlobal_GetFieldCData(const char* sFieldname, void* pValueOut);

	struct Vector3{
		float x;
		float y;
		float z;
	};
	struct Vector2{
		float x;
		float y;
	};

	void ParaPainter_Flush();
	void ParaPainter_Save();
	void ParaPainter_Restore();
	void ParaPainter_CallField(const char*  sFieldname);

	void ParaPainter_SetCompositionMode(int mode);
	int ParaPainter_GetCompositionMode();
	void ParaPainter_SetOpacity(float fOpacity);
	void ParaPainter_SetClipRegion(int x, int y, int w, int h);
	void ParaPainter_SetClipping(bool enable);
	bool ParaPainter_HasClipping();
	void ParaPainter_Scale(float sx, float sy);
	void ParaPainter_Shear(float sh, float sv);
	void ParaPainter_Rotate(float a);
	void ParaPainter_Translate(float dx, float dy);
	void ParaPainter_DrawPoint(float x, float y);
	void ParaPainter_DrawLine(float x1, float y1, float x2, float y2);
	void ParaPainter_DrawRect(float x1, float y1, float w, float h);
	void ParaPainter_DrawTriangleList(struct Vector3* triangleList, int nTriangleCount, int nIndexOffset);
	void ParaPainter_DrawLineList(struct Vector3* lineList, int nLineCount, int nIndexOffset);
	void ParaPainter_DrawText(float x, float y, const char* s);
	void ParaPainter_DrawText2(float x, float y, float w, float h, const char* s, int textOption);
	]]);


	local ParaEngineClient;
	
	-- check if a given function exist in main executable.
	local function check_C_func(func_name)
		local func = loadstring([[local ffi = require("ffi"); local func = ffi.C.]]..func_name);
		if(func) then
			local result, msg = pcall(func);
			if(result) then
				return true;
			end
		end
	end

	-- @param libName: default to "C" namespace, (which is the main executable plus standard C library)
	-- possible value is "ParaEngineClient". In debug version "_d" is appended
	local function LoadSharedLib(libName)
		libName = libName or "C";
		local libNamespace;
		if(libName=="C") then
			libNamespace = ffi.C;
		else
			local func = loadstring(string.format([[local ffi = require("ffi"); return ffi.load("%s")]], libName));
			if(func) then
				local result, param1 = pcall(func);
				if(result) then
					libNamespace = param1;
				end
			end
		end
		if(libNamespace) then
			ParaGlobal.WriteToLogFile(string.format("ffi loaded shared lib: %s\n", libName))
		else
			ParaGlobal.WriteToLogFile(string.format("warn: ffi failed to load shared lib: %s\n", libName))
		end
		return libNamespace;
	end

	if(check_C_func("ParaGlobal_timeGetTime")) then
		-- using the default C namespace (which is the main executable plus standard C library)
		ParaEngineClient = LoadSharedLib("C");
	else
		local name = ParaEngine.GetAttributeObject():GetField("GetModuleFileName");
		if(not name) then
			-- backward compatibility if "GetModuleFileName" not exist. 
			name = "ParaEngineClient";
			local is_debugging = ParaEngine.GetAttributeObject():GetField("Is Debugging", false);
			if(is_debugging) then
				name = name.."_d";
			end
		end
		ParaEngineClient = LoadSharedLib(name);
	end

	if(ParaEngineClient) then
		--------------------------------------------
		-- shared by client/server
		--------------------------------------------
		if(not ParaEngineClient.ParaGlobal_timeGetTime) then
			ParaGlobal.WriteToLogFile("error: LuaJit FFI not working, possibly because dll is not found\n");
			return;
		end

		ParaGlobal.WriteToLogFile = function(strMessage)
			return ParaEngineClient.ParaGlobal_WriteToLogFile(strMessage);
		end

		ParaGlobal.timeGetTime = function()
			return ParaEngineClient.ParaGlobal_timeGetTime();
		end

		ParaGlobal.getAccurateTime = function()
			return ParaEngineClient.ParaGlobal_getAccurateTime();
		end

		--------------------------------------------
		-- following is client only
		--------------------------------------------
		if(ParaTerrain) then
			ParaGlobal.WriteToLogFile("FFI for ParaTerrain installed \n");
			ParaTerrain.GetElevation = function(x,y)
				return ParaEngineClient.ParaTerrain_GetElevation(x,y);
			end

			ParaTerrain.SelectBlock = function(x,y,z,isSelect, nGroupID)
				return ParaEngineClient.ParaTerrain_SelectBlock(x,y,z,isSelect, nGroupID or 0);
			end

			ParaTerrain.SetBlockTemplate = function(x,y,z,templateId)
				ParaEngineClient.ParaTerrain_SetBlockTemplateId(x,y,z,templateId);
			end

			ParaTerrain.SetBlockTemplateByIdx = function(x,y,z,templateId)
				ParaEngineClient.ParaTerrain_SetBlockTemplateIdByIdx(x,y,z,templateId);
			end

			ParaTerrain.GetBlockTemplate = function(x,y,z)
				return ParaEngineClient.ParaTerrain_GetBlockTemplateId(x,y,z);
			end

			ParaTerrain.GetBlockTemplateByIdx = function(x,y,z)
				return ParaEngineClient.ParaTerrain_GetBlockTemplateIdByIdx(x,y,z);
			end

			ParaTerrain.SetBlockUserData = function(x,y,z, data)
				ParaEngineClient.ParaTerrain_SetBlockUserData(x,y,z, data);
			end

			ParaTerrain.SetBlockUserDataByIdx = function(x,y,z, data)
				ParaEngineClient.ParaTerrain_SetBlockUserDataByIdx(x,y,z, data);
			end

			ParaTerrain.GetBlockUserData = function(x,y,z)
				return ParaEngineClient.ParaTerrain_GetBlockUserData(x,y,z);
			end

			ParaTerrain.GetBlockUserDataByIdx = function(x,y,z)
				return ParaEngineClient.ParaTerrain_GetBlockUserDataByIdx(x,y,z);
			end
		
			ParaTerrain.UpdateHoles = function(x,y)
				ParaEngineClient.ParaTerrain_UpdateHoles(x,y);
			end

			ParaTerrain.IsHole = function(x,y)
				return ParaEngineClient.ParaTerrain_IsHole(x,y);
			end

			ParaTerrain.SetHole = function(x,y, bIsHold)
				ParaEngineClient.ParaTerrain_SetHole(x,y, bIsHold);
			end

			ParaTerrain.FindFirstBlock = function(x,y,z, nSide, max_dist, attrFilter, nCategoryID)
				return ParaEngineClient.ParaTerrain_FindFirstBlock( x,y,z, nSide or 4, max_dist or 32, attrFilter or 0xffffffff, nCategoryID or -1);
			end

			ParaTerrain.GetFirstBlock = function(x,y,z, nBlockID, nSide, max_dist)
				return ParaEngineClient.ParaTerrain_GetFirstBlock( x,y,z, nBlockID, nSide or 5, max_dist or 32);
			end
		
			if(ParaTerrain.GetBlockFullData) then
				local pTmpId = ffi.new'uint16_t[1]';
				local pTmpUserData = ffi.new'uint32_t[1]';

				ParaTerrain.GetBlockFullData = function(x, y, z)
					--local pId = ffi.stack'uint16_t[1]';
					--local pUserData = ffi.stack'uint32_t[1]';
			
					ParaEngineClient.ParaTerrain_GetBlockFullData(x, y, z, pTmpId, pTmpUserData);
			
					return pTmpId[0], pTmpUserData[0];
				end
			end

			--------------------------------------
			-- ParaBlockWorld
			--------------------------------------
			ParaBlockWorld.SetBlockId = function(self, x,y,z, templateId)
				return ParaEngineClient.ParaBlockWorld_SetBlockId(self, x, y, z, templateId);
			end

			ParaBlockWorld.GetBlockId = function(self, x,y,z)
				return ParaEngineClient.ParaBlockWorld_GetBlockId(self, x, y, z);
			end

			ParaBlockWorld.SetBlockData = function(self, x,y,z, data)
				return ParaEngineClient.ParaBlockWorld_SetBlockData(self, x, y, z, data);
			end

			ParaBlockWorld.GetBlockData = function(self, x,y,z)
				return ParaEngineClient.ParaBlockWorld_GetBlockData(self, x, y, z);
			end

			ParaBlockWorld.GetBlockId = function(self, x,y,z)
				return ParaEngineClient.ParaBlockWorld_GetBlockId(self, x, y, z);
			end

			ParaBlockWorld.FindFirstBlock = function(self, x,y,z, nSide, max_dist, attrFilter, nCategoryID)
				return ParaEngineClient.ParaBlockWorld_FindFirstBlock(self, x, y, z, nSide, max_dist, attrFilter, nCategoryID);
			end

			ParaBlockWorld.GetFirstBlock = function(self, x,y,z, nBlockId, nSide, max_dist)
				return ParaEngineClient.ParaBlockWorld_GetFirstBlock(self, x, y, z, nBlockId, nSide, max_dist);
			end

			--------------------------------------
			-- ParaScene
			--------------------------------------
			if(ParaScene.CheckExist) then
				ParaScene.CheckExist = function(nID)
					return ParaEngineClient.ParaScene_CheckExist(nID);
				end
			end
		end

		--------------------------------------
		-- ParaAttributeObject
		--------------------------------------

		local curSelection;
		-- ffi based cdata
		ParaAttributeObject.SetFieldCData = function(self, name, cdata)
			if(curSelection~=self) then
				ParaGlobal.SelectAttributeObject(self);
			end
			return ParaEngineClient.ParaGlobal_SetFieldCData(name, cdata);
		end
		-- ffi based cdata
		ParaAttributeObject.GetFieldCData = function(self, name, cdata)
			if(curSelection~=self) then
				ParaGlobal.SelectAttributeObject(self);
			end
			return ParaEngineClient.ParaGlobal_GetFieldCData(name, cdata);
		end

		--------------------------------------
		-- ParaPainter
		--------------------------------------
		if(not ParaEngineClient.ParaPainter_Flush) then
			ParaGlobal.WriteToLogFile("warning: FFI for ParaPainter NOT installed\n");
		else
			-- this will means that we have full FFI support. 
			ParaEngine.hasFFI = true;
			ParaPainter.Flush = function() 
				ParaEngineClient.ParaPainter_Flush();
			end
			ParaPainter.Save = function()
				ParaEngineClient.ParaPainter_Save();
			end
			ParaPainter.Restore = function()
				ParaEngineClient.ParaPainter_Restore();
			end
			ParaPainter.CallField = function(sFieldname)
				ParaEngineClient.ParaPainter_CallField(sFieldname);
			end

			ParaPainter.SetCompositionMode = function(mode)
				ParaEngineClient.ParaPainter_SetCompositionMode(mode)
			end
			ParaPainter.GetCompositionMode = function ()
				return ParaEngineClient.ParaPainter_GetCompositionMode();
			end
			ParaPainter.SetOpacity = function (fOpacity)
				ParaEngineClient.ParaPainter_SetOpacity(fOpacity);
			end
			ParaPainter.SetClipRegion = function(x, y, w, h)
				ParaEngineClient.ParaPainter_SetClipRegion(x, y, w, h);
			end
			ParaPainter.SetClipping = function (enable)
				ParaEngineClient.ParaPainter_SetClipping(enable);
			end
			ParaPainter.HasClipping = function ()
				return ParaEngineClient.ParaPainter_HasClipping();
			end
			ParaPainter.Scale = function (sx, sy)
				ParaEngineClient.ParaPainter_Scale(sx, sy);
			end
			ParaPainter.Shear = function(sh, sv)
				ParaEngineClient.ParaPainter_Shear(sh, sv);
			end
			ParaPainter.Rotate = function (a)
				ParaEngineClient.ParaPainter_Rotate(a);
			end
			ParaPainter.Translate = function (dx, dy)
				ParaEngineClient.ParaPainter_Translate(dx, dy);
			end
			ParaPainter.DrawPoint = function (x, y)
				ParaEngineClient.ParaPainter_DrawPoint(x, y);
			end
			ParaPainter_DrawLine = function(x1, y1, x2, y2)
				ParaEngineClient.ParaPainter_DrawLine(x1, y1, x2, y2);
			end
			ParaPainter.DrawRect = function (x1, y1, w, h)
				ParaEngineClient.ParaPainter_DrawRect(x1, y1, w, h);
			end
			local old_DrawTriangleList = ParaPainter.DrawTriangleList;
			ParaPainter.DrawTriangleList = function (triangleList, nTriangleCount, nIndexOffset)
				if(type(triangleList) == "table") then
					old_DrawTriangleList(triangleList, nTriangleCount, nIndexOffset);
				else
					ParaEngineClient.ParaPainter_DrawTriangleList(triangleList, nTriangleCount, nIndexOffset);
				end
			end
			local old_DrawLineList = ParaPainter.DrawLineList;
			ParaPainter.DrawLineList = function (lineList, nLineCount, nIndexOffset)
				if(type(lineList) == "table") then
					old_DrawLineList(lineList, nLineCount, nIndexOffset);
				else
					ParaEngineClient.ParaPainter_DrawLineList(lineList, nLineCount, nIndexOffset);
				end
			end
			-- @param w: width or text. if width, h, s, textOption can not be nil.
			-- @param s: text 
			ParaPainter.DrawText = function (x, y, w, h, s, textOption)
				if(not h) then
					ParaEngineClient.ParaPainter_DrawText(x, y, w);
				else
					ParaEngineClient.ParaPainter_DrawText2(x, y, w, h, s, textOption);
				end
			end
		end
	end
else
	-- using standard lua without jit and ffi
	ParaGlobal.WriteToLogFile(string.format("ParaEngine Lua %s version:%s\r\n", str64BitsSystem, tostring(_VERSION)));
end

if(ParaTerrain) then
	local ParaTerrain_FindFirstBlock = ParaTerrain.FindFirstBlock;
	ParaTerrain.FindFirstBlock = function(x,y,z, nSide, max_dist, attrFilter, nCategoryID)
		return ParaTerrain_FindFirstBlock( x,y,z, nSide or 4, max_dist or 32, attrFilter or 0xffffffff, nCategoryID or -1);
	end

	local ParaTerrain_GetFirstBlock = ParaTerrain.GetFirstBlock;
	ParaTerrain.GetFirstBlock = function(x,y,z, nBlockID, nSide, max_dist)
		return ParaTerrain_GetFirstBlock( x,y,z, nBlockID or 0, nSide or 5, max_dist or 32);
	end
end