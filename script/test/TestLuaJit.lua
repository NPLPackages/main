--[[
Title: Testing LuaJit
Author: Li,Xizhi
Date: 2013-11-23
Desc: testing LuaJit and FFI
-----------------------------------------------
NPL.load("(gl)script/test/TestLuaJit.lua");
TestJit.TestLocalVectorInArrays()
TestJit.TestArrayMulti()
TestJit.TestFFIArrays()
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");
NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
npl_profiler.perf_enable(true);

local ffi = require("ffi")
local C = ffi.C;

TestJit = {};


-- same performance, and extremely fast
function TestJit.TestFFIArrays()

	--sparse array is also fine
	local ffi_array = ffi.new("int[51200]")
	local table_array = {};
	npl_profiler.perf_func("LuaJit FFI int[51200]", function() 
		for i=1, 20000 do
			ffi_array[i*2] = i;
		end
	end, 10, 100);

	npl_profiler.perf_func("Lua Array", function() 
		for i=1, 20000 do
			table_array[i*2] = i;
		end
	end, 10, 100);

	
	npl_profiler.perf_dump_result()
end

-- same performance, and extremely fast
-- INFO:VectorArrayWithoutLocalVariable:max_fps(inner):2041,avg(inner):0.000523000,fps(inner):1912cur_value=0.050000000, avg_value=0.052300000, count=10, fps=19, cfps=19, min_value=0.0490000, max_value=0.0680000
-- INFO:VectorArrayUsingLocalVariable:max_fps(inner):2174,avg(inner):0.000495000,fps(inner):2020cur_value=0.048000000, avg_value=0.049500000, count=10, fps=20, cfps=20, min_value=0.0460000, max_value=0.0640000
function TestJit.TestLocalVectorInArrays()
	local triangles = ffi.new('struct Vector3[24]');

	npl_profiler.perf_func("VectorArrayWithoutLocalVariable", function() 
		for k=1, 20000 do
			for i=0, 23 do
				triangles[i].x, triangles[i].y, triangles[i].z = 0,0,0;
			end
		end
	end, 10, 100);

	npl_profiler.perf_func("VectorArrayUsingLocalVariable", function() 
		for k=1, 20000 do
			for i=0, 23 do
				local triangle = triangles[i];
				triangle.x, triangle.y, triangle.z = 0,0,0;
			end
		end
	end, 10, 100);

	npl_profiler.perf_dump_result()
end

-- same performance with idx
-- FFI's multi-dimensonal array is the fastest. 
function TestJit.TestArrayMulti()

	local table_array1= {};
	local table_array2 = {};

	-- if not initialized, FFI is 3 times faster 
	table.resize(table_array1, 51200, 0)
	table.resize(table_array2, 51200, 0)
	--for i=0,51200 do
		--table_array1[i] = 0;
		--table_array2[i] = 0;
	--end	

	ffi_array_1 = ffi.new("int[51200]");
	ffi_array_2 = ffi.new("int[51200]");

	ffi_multi_array = ffi.new("int[101][101][5]");

	local multi_array = {};

	for i=0, 100 do
		multi_array[i] = multi_array[i] or {};
		for j=0, 100 do
			multi_array[i][j] = multi_array[i][j] or {};
			for k=0, 4 do
				multi_array[i][j][k] = multi_array[i][j][k] or {};
				multi_array[i][j][k] = 0;
			end
		end
	end
	
	-- simulating using one dimensonal array (4000FPS)
	npl_profiler.perf_func("FFI multi array raw", function() 
		for j=0, 100 do
			for i=0, 100 do
				for k=0, 4 do
					ffi_array_1[k*10000+i*100+j] = i;
				end
			end
		end
	end, 10, 100);

	local function idx(i,j,k)
		return k*10000+i*100+j;
	end
	npl_profiler.perf_func("FFI array with Idx func", function() 
		for j=0, 100 do
			for i=0, 100 do
				for k=0, 4 do
					ffi_array_2[idx(i,j,k)] = i;
				end
			end
		end
	end, 10, 100);

	npl_profiler.perf_func("multi array raw", function() 
		for j=0, 100 do
			for i=0, 100 do
				for k=0, 4 do
					table_array1[k*10000+i*100+j] = i;
				end
			end
		end
	end, 10, 100);

	local function idx(i,j,k)
		return k*10000+i*100+j;
	end
	npl_profiler.perf_func("array with Idx func", function() 
		for j=0, 100 do
			for i=0, 100 do
				for k=0, 4 do
					table_array2[idx(i,j,k)] = i;
				end
			end
		end
	end, 10, 100);
	
	-- this is the fastest implementation (8333FPS)
	npl_profiler.perf_func("FFI multi-array", function() 
		for j=0, 100 do
			for i=0, 100 do
				for k=0, 4 do
					ffi_multi_array[i][j][k] = i;
				end
			end
		end
	end, 10, 100);


	-- this is the slowest (1695 FPS)
	npl_profiler.perf_func("Lua multi-array", function() 
		for j=0, 100 do
			for i=0, 100 do
				for k=0, 4 do
					multi_array[i][j][k] = i;
				end
			end
		end
	end, 10, 100);

	npl_profiler.perf_dump_result()
end
