--[[
Author: LiXizhi
Date: 2010.7.14
Desc: testing NPL profiler
-----------------------------------------------
NPL.load("(gl)script/test/TestNPLProfiler.lua");
-----------------------------------------------
]]

NPL.load("(gl)script/ide/UnitTest/luaunit.lua");
NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
local LOG = LOG;
TestNPLProfiler = {} --class

function TestNPLProfiler:setUp()
end

-- test the global log interface
function TestNPLProfiler:test_Perfs()
	NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
	local npl_profiler = commonlib.gettable("commonlib.npl_profiler");


	-- turn on perf
	npl_profiler.perf_show();

	-- method1: one can put following perf function pair in critical function. 
	npl_profiler.perf_begin("test")
	-- code here
	npl_profiler.perf_end("test")

	-- method2: one can evaluate how fast some NPC functions by writing
	local j;
	for j=1, 10 do 
		npl_profiler.perf_begin("test1")
		do
			-- code here will be perfed
			local i;
			for i = 1, 10000 do
				local player = ParaScene.GetPlayer();
				local x, y, z = player:GetPosition();
			end
		end
		npl_profiler.perf_end("test1")
	end
	-- dump perf result of test1 to log
	LOG.info(npl_profiler.perf_get("test1"));


	-- method3: to simplify method2
	npl_profiler.perf_func("test2", function() 
		local player = ParaScene.GetPlayer();
		local x, y, z = player:GetPosition();
	end, 10, 10000);

	-- "test2" result on my 2.8G CPU is test2 = {avg_value=3.52e-005,fps=138888}
	-- so the inner func fps = 10000*28000 = 0.28e9 frames per seconds (WOW)
	
	-- this will dump all stats by passing nil
	LOG.info(npl_profiler.perf_get());
end

TestNPLProfiler.NestedTable = {NestedTable2={}, a=1, b=2,c=3,d=4,e=5,f=6}

-- Some common perf result used as base line
function TestNPLProfiler:test_BaseLine()
	npl_profiler.perf_show();

	local i=0;
	npl_profiler.perf_func("baseline:i=i+1", function() 
		i = i+1
	end, 10, 10000);

	npl_profiler.perf_func("GetGlobal:A.B.C", function() 
		local a = TestNPLProfiler.NestedTable.NestedTable2
	end, 10, 10000);

	npl_profiler.perf_func("ParaScene.GetPlayer+GetPosition", function() 
		local player = ParaScene.GetPlayer();
		local x, y, z = player:GetPosition();
	end, 10, 10000);

	local i=0;
	npl_profiler.perf_func("LOG.info", function() 
		i = i+1
		LOG.info(i);
	end, 3, 1000);

	-- dump all to log. 
	npl_profiler.perf_dump_result();

	--[[INFO:dumping perf result--------------
INFO:GetGlobal:A.B.C:max_fps(inner):5000004,avg(inner):0.000000250,fps(inner):4000000cur_value=0.002000000, avg_value=0.002500000, count=10, fps=400, cfps=400, min_value=0.0020000, max_value=0.0030000
INFO:LOG.info:max_fps(inner):66667,avg(inner):0.000015667,fps(inner):63830cur_value=0.016000003, avg_value=0.015666664, count=3, fps=64, cfps=64, min_value=0.0150000, max_value=0.0160000
INFO:baseline:i=i+1:max_fps(inner):10000008,avg(inner):0.000000150,fps(inner):6666667cur_value=0.001999999, avg_value=0.001500000, count=10, fps=667, cfps=667, min_value=0.0010000, max_value=0.0020000
INFO:ParaScene.GetPlayer+GetPosition:max_fps(inner):1428573,avg(inner):0.000000960,fps(inner):1041667cur_value=0.007000014, avg_value=0.009600000, count=10, fps=104, cfps=104, min_value=0.0070000, max_value=0.0180000
	]]
end

function TestNPLProfiler:test_PrintGoodWithBadCode()
	npl_profiler.perf_show();
	-- Note: "string concat" is not that bad, it is sometimes faster than "table.concat"
	-- ["string concat"]={begin_count=0,end_time=0.53799998760223,avg_value=0.053799998015165,loop_count=1000,history={},last_begin=0.48600000143051,last_value=0.051999986171722,max_value=0.064999997615814,start_time=0,count=10,min_value=0.051999986171722,},
	-- ["table.concat"]={begin_count=0,end_time=1.1219999790192,avg_value=0.058399997651577,loop_count=1000,history={},last_begin=1.0670000314713,last_value=0.054999947547913,max_value=0.075999975204468,start_time=0.53799998760223,count=10,min_value=0.054999947547913,},
	local tostring = tostring;
	local string_format = string.format;
	local table_concat = table.concat;
	--[[
	npl_profiler.perf_func("string concat", function() 
		local str="1";
		local i=0;
		for i=5000,5030 do
			str = str..tostring(i)
		end
	end, 10, 1000);

	npl_profiler.perf_func("table.concat", function() 
		local str_table={};
		local i=0;
		for i=5000,5030 do
			str_table[#str_table + 1] = tostring(i);
		end
		str = table_concat(str_table);
	end, 10, 1000);
	]]

	-- With luajit2beta5: 
	-- ["string cat vs format"]={avg_value=0.0036,last_value=0.003,history={},start_time=0,end_time=0.036,max_value=0.005,loop_count=10000,last_begin=0.033,count=10,min_value=0.002,begin_count=0,},
	-- ["string format"]={avg_value=0.0278,last_value=0.028,history={},start_time=0.036,end_time=0.314,max_value=0.028,loop_count=10000,last_begin=0.286,count=10,min_value=0.027,begin_count=0,},}
	-- ["table.concat format"]={avg_value=0.0055,last_value=0.006,history={},start_time=0.314,end_time=0.369,max_value=0.008,loop_count=10000,last_begin=0.363,count=10,min_value=0.004,begin_count=0,},

	-- With lua51: 
	-- ["string cat vs format"]={begin_count=0,end_time=0.0489999987185,avg_value=0.0049000000581145,loop_count=10000,history={},last_begin=0.045000001788139,last_value=0.0039999969303608,max_value=0.0070000002160668,start_time=0,count=10,min_value=0.0039999969303608,},}
	-- ["string format"]={begin_count=0,end_time=0.36899998784065,avg_value=0.031999997794628,loop_count=10000,history={},last_begin=0.33700001239777,last_value=0.031999975442886,max_value=0.032000005245209,start_time=0.0489999987185,count=10,min_value=0.031999975442886,},
	-- ["table.concat format"]={begin_count=0,end_time=0.47999998927116,avg_value=0.010499998927116,loop_count=10000,history={},last_begin=0.47200000286102,last_value=0.007999986410141,max_value=0.016999989748001,start_time=0.375,count=10,min_value=0.007999986410141,},
	-- Note: again "string cat" wins, string_format is the slowest. String.format is the slowest. 
	local a = "aaaaaaaaaaaaaaaaaa";	local b = "bbbbbbbbbbbbbbbbb";	local c = "cccccccccccccccccc";	local d = "ddddddddddddddddd";	local e = "eeeeeeeeeeeeeeeeeeeee";	local f = "fffffffffffffffffffffff";	
	npl_profiler.perf_func("string cat vs format", function() 
		local a = a..b..c..d..e..f;
		return a;
	end, 10, 10000);

	npl_profiler.perf_func("string format", function() 
		local a = string_format("%s%s%s%s%s%s", a,b,c,d,e,f)
		return a;
	end, 10, 10000);

	npl_profiler.perf_func("table.concat format", function() 
		local a = table_concat({a,b,c,d,e,f})
		return a;
	end, 10, 10000);

	-- this will dump all stats by passing nil
	LOG.info(npl_profiler.perf_get());
end

function TestNPLProfiler:test_StringFormatPerf()
	npl_profiler.perf_show();
	local tostring = tostring;
	local string_format = string.format;
	local table_concat = table.concat;
	local format = format;

	local data = {};
	local i;
	for i=1,200 do
		data[i] = tostring(i + 123456789);
	end
	

	--[[ 
	["string cat"]={begin_count=0,end_time=3.3110001087189,avg_value=0.1055000051856,loop_count=1000,history={},last_begin=3.2060000896454,last_value=0.10500001907349,max_value=0.10600018501282,start_time=2.2560000419617,count=10,min_value=0.10500001907349,},
	["table cat"]={begin_count=0,end_time=3.6970000267029,avg_value=0.038599990308285,loop_count=1000,history={},last_begin=3.6579999923706,last_value=0.039000034332275,max_value=0.041999816894531,start_time=3.3110001087189,count=10,min_value=0.03600001335144,},
	["string format"]={begin_count=0,end_time=2.2560000419617,avg_value=0.22560000419617,loop_count=1000,history={},last_begin=2.0309998989105,last_value=0.22500014305115,max_value=0.2339999973774,start_time=0,count=10,min_value=0.22399997711182,},}

	baseline={begin_count=0,end_time=3.7699999809265,avg_value=0.0065999985672534,loop_count=1000,history={},last_begin=3.7639999389648,last_value=0.0060000419616699,max_value=0.0069999694824219,start_time=3.7039999961853,count=10,min_value=0.0060000419616699,},
	["string format"]={begin_count=0,end_time=2.2620000839233,avg_value=0.2262000143528,loop_count=1000,history={},last_begin=2.0369999408722,last_value=0.22500014305115,max_value=0.2419999986887,start_time=0,count=10,min_value=0.22399997711182,},
	["string cat"]={begin_count=0,end_time=3.319000005722,avg_value=0.10569999366999,loop_count=1000,history={},last_begin=3.2130000591278,last_value=0.10599994659424,max_value=0.10600018501282,start_time=2.2620000839233,count=10,min_value=0.10500001907349,},
	["table cat"]={begin_count=0,end_time=3.7039999961853,avg_value=0.038499999791384,loop_count=1000,history={},last_begin=3.6659998893738,last_value=0.038000106811523,max_value=0.04200005531311,start_time=3.319000005722,count=10,min_value=0.034999847412109,},
	
	["baseline RandomString"]={begin_count=0,end_time=7.0920000076294,avg_value=0.33219999074936,loop_count=1000,history={},last_begin=6.7600002288818,last_value=0.33199977874756,max_value=0.33400011062622,start_time=3.7699999809265,count=10,min_value=0.32999992370605,},
	["table cat RandomString"]={begin_count=0,end_time=20.802000045776,avg_value=0.37639999389648,loop_count=1000,history={},last_begin=20.42200088501,last_value=0.3799991607666,max_value=0.38100051879883,start_time=17.038000106812,count=10,min_value=0.37299919128418,},
	["string cat RandomString"]={begin_count=0,end_time=17.038000106812,avg_value=0.42880001664162,loop_count=1000,history={},last_begin=16.610000610352,last_value=0.42799949645996,max_value=0.4320011138916,start_time=12.75,count=10,min_value=0.42699909210205,},
	["string format RandomString"]={begin_count=0,end_time=12.75,avg_value=0.56580001115799,loop_count=1000,history={},last_begin=12.184000015259,last_value=0.56599998474121,max_value=0.56899976730347,start_time=7.0920000076294,count=10,min_value=0.5649995803833,},}
	]]
	-- 0.13
	npl_profiler.perf_func("npl format", function() 
		local i
		local a;
		for i=1,200 do
			if(a == nil) then
				a = data[i];
			else
				a = format("%s,%s", a, data[i]);
			end
		end
		return a;
	end, 10, 1000);

	-- 0.22
	npl_profiler.perf_func("string format", function() 
		local i
		local a;
		for i=1,200 do
			if(a == nil) then
				a = data[i];
			else
				a = string_format("%s,%s", a, data[i]);
			end
		end
		return a;
	end, 10, 1000);

	-- 0.099
	npl_profiler.perf_func("string cat", function() 
		local i
		local a;
		for i=1,200 do
			if(a == nil) then
				a = data[i];
			else
				a = a..","..data[i];
			end
		end
		return a;
	end, 10, 1000);
	-- 0.032
	npl_profiler.perf_func("table cat", function() 
		local i
		local a = {};
		for i=1,200 do
			a[#a+1] = data[i];
		end
		return table_concat(a);
	end, 10, 1000);
	
	npl_profiler.perf_func("baseline", function() 
		local i
		local a;
		for i=1,200 do
			a = data[i];
		end
		return a;
	end, 10, 1000);

	local base_id = 123456789;
	npl_profiler.perf_func("baseline RandomString", function() 
		local i
		local a;
		for i=1,200 do
			base_id = base_id + 1;
			a = tostring(base_id);
		end
		return a;
	end, 10, 1000);

	-- 0.23
	npl_profiler.perf_func("string format RandomString", function() 
		local i
		local a;
		for i=1,200 do
			base_id = base_id + 1;
			if(a == nil) then
				a = tostring(base_id);
			else
				a = string_format("%s,%s", a, tostring(base_id));
			end
		end
		return a;
	end, 10, 1000);
	
	-- 0.14
	npl_profiler.perf_func("npl format RandomString", function() 
		local i
		local a;
		for i=1,200 do
			base_id = base_id + 1;
			if(a == nil) then
				a = tostring(base_id);
			else
				a = format("%s,%s", a, tostring(base_id));
			end
		end
		return a;
	end, 10, 1000);

	-- 0.09
	npl_profiler.perf_func("string cat RandomString", function() 
		local i
		local a;
		for i=1,200 do
			base_id = base_id + 1;
			if(a == nil) then
				a = tostring(base_id);
			else
				a = a..","..tostring(base_id);
			end
		end
		return a;
	end, 10, 1000);
	-- 0.044
	npl_profiler.perf_func("table cat RandomString", function() 
		local i
		local a = {};
		for i=1,200 do
			base_id = base_id + 1;
			a[#a+1] = tostring(base_id);
		end
		return table_concat(a);
	end, 10, 1000);

	-- this will dump all stats by passing nil
	LOG.info(npl_profiler.perf_get());
end

-- format is 3-5 times faster than string.format almost in any circumstances. 
-- format is compatible with string.cat for small strings(1.5 times slower), but several times faster for bigger strings
-- table.concat is 4-5 times slower than string.cat for small strings, but 2 times faster for concatinating over 200 small strings in one pass. 
-- conclusion is: 
--   use string.cat for concartination of several(2-20) small strings. Yes, it is ok to "1".."2".."3"...."20", this is actually fatest, even though it generates many temp strings.
--   always use format instead of string.format (for concartination of over 3 long strings), unless you want special formating other than %d,%s,%f.
--   use table.concat for concatination of over 20 long strings, or over 100 short strings. 
function TestNPLProfiler:test_StringFormatPerf2()
	npl_profiler.perf_show();
	local tostring = tostring;
	local string_format = string.format;
	local table_concat = table.concat;
	local format = format;

	local data = {};
	local i;
	for i=1,200 do
		data[i] = tostring(i + 123456789);
	end
	local nSize = 2;
	-- 0.066 (nSize==20), 0.002(nSize==2)
	npl_profiler.perf_func("npl format", function() 
		local i
		local a;
		for i=1,nSize do
			if(a == nil) then
				a = data[i];
			else
				a = format("%s,%s", a, data[i]);
			end
		end
		return a;
	end, 10, 10000);

	-- 0.205(nSize==20), 0.01(nSize==2)
	npl_profiler.perf_func("string format", function() 
		local i
		local a;
		for i=1,nSize do
			if(a == nil) then
				a = data[i];
			else
				a = string_format("%s,%s", a, data[i]);
			end
		end
		return a;
	end, 10, 10000);

	-- 0.041(nSize==20), 0.001(nSize==2)
	npl_profiler.perf_func("string cat", function() 
		local i
		local a;
		for i=1,nSize do
			if(a == nil) then
				a = data[i];
			else
				a = a..","..data[i];
			end
		end
		return a;
	end, 10, 10000);
	
	-- 0.043(nSize==20), 0.008(nSize==2)
	npl_profiler.perf_func("table cat", function() 
		local i
		local a = {};
		for i=1,nSize do
			a[#a+1] = data[i];
		end
		return table_concat(a);
	end, 10, 10000);
	
	npl_profiler.perf_func("base line", function() 
		local i
		local a;
		for i=1,nSize do
			a = data[i];
		end
		return a;
	end, 10, 10000);
	
	-- this will dump all stats by passing nil
	LOG.info(npl_profiler.perf_get());
end

--INFO:empty container:max_fps(inner):35842,avg(inner):0.000028510,fps(inner):35075cur_value=0.286000000, avg_value=0.285100000, count=20, fps=4, cfps=2, min_value=0.2790000, max_value=0.3080000
--INFO:empty button:max_fps(inner):78740,avg(inner):0.000013360,fps(inner):74850cur_value=0.129000000, avg_value=0.133600000, count=20, fps=7, cfps=3, min_value=0.1270000, max_value=0.1740000
--INFO:event button:max_fps(inner):63694,avg(inner):0.000016435,fps(inner):60846cur_value=0.162000000, avg_value=0.164350000, count=20, fps=6, cfps=3, min_value=0.1570000, max_value=0.2030000
function TestNPLProfiler:test_GUICreation()
	npl_profiler.perf_show();
	npl_profiler.perf_func("empty container", function() 
		--create a container 
		local gridsize=1;
		local _this=ParaUI.CreateUIObject("container","test_me","_lt", 0, 0, gridsize, gridsize);
		_this.background = "";
		_this:AttachToRoot();
		ParaUI.Destroy(_this.id);
	end, 10, 1000);
	npl_profiler.perf_func("empty button", function() 
		local gridsize=1;
		local _this=ParaUI.CreateUIObject("button","test_me","_lt", 0, 0, gridsize, gridsize);
		_this.background = "";
		_this:AttachToRoot();
		ParaUI.Destroy(_this.id);
	end, 10, 1000);
	npl_profiler.perf_func("event button", function() 
		local gridsize=1;
		local _this=ParaUI.CreateUIObject("button","test_me","_lt", 0, 0, gridsize, gridsize);
		_this.background = "Texture/alphadot.png";
		_this.onclick = ";_guihelper.MessageBox('1')";
		_this:AttachToRoot();
		ParaUI.Destroy(_this.id);
	end, 10, 1000);
	-- this will dump all stats by passing nil
	npl_profiler.perf_dump_result()
end

-- Use combined calls as much as possible. 
-- INFO:more IO calls:max_fps(inner):5714,avg(inner):0.000177000,fps(inner):5650cur_value=0.175000000, avg_value=0.177000000, count=10, fps=6, cfps=6, min_value=0.1750000, max_value=0.1880000
-- INFO:Combined calls:max_fps(inner):500000,avg(inner):0.000002000,fps(inner):500000cur_value=0.002000000, avg_value=0.002000000, count=10, fps=500, cfps=500, min_value=0.0020000, max_value=0.0020000
function TestNPLProfiler:test_FileIO()
	npl_profiler.perf_show();
	local file = ParaIO.open("temp/iotest.txt", "w");
	local text = string.rep("1", 100);
	
	npl_profiler.perf_func("more IO calls", function() 
		local i;
		for i=1, 100 do
			file:WriteString("1")
		end
	end, 10, 1000);

	npl_profiler.perf_func("Combined calls", function() 
		file:WriteString(text)
	end, 10, 1000);

	file:close();
	ParaIO.DeleteFile("temp/iotest.txt");
	-- this will dump all stats 
	npl_profiler.perf_dump_result()
end

function TestNPLProfiler:test_RegExpression_backtracing()
	-- Wrong code with catastrophic backtracing:  the following code will take 3 minutes to execute, due to regular expression backtracing
	-- @see: http://www.regular-expressions.info/catastrophic.html	
	local value = "1116,near,18,1034,1235,life,24007,692792[a,a,a,aaa,aaa,aa,aaaa,a,a,aaa,aa,a,aa,a,aa,a][24007,990,1434,1266,1419,1327,1245,1305,][26076,]"
	local arena_id = string.match(value, "^(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)%[(.-)%]%[(.-)%]%[(.-)%]$");
	commonlib.echo({arena_id}) 

	-- Wrong code: all repetitive symbol like "+ - *" will lead to backtracing
	local value = "1116,near,18,1034,1235,life,24007,692792[a,a,a,aaa,aaa,aa,aaaa,a,a,aaa,aa,a,aa,a,aa,a][24007,990,1434,1266,1419,1327,1245,1305,][26076,]"
	local arena_id = string.match(value, "^(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+)%[(.+)%]%[(.+)%]%[(.+)%]$");
	commonlib.echo({arena_id}) 

	-- Right code: using mutually exclusive group between 2 nested repetitive group.
	local value = "1116,near,18,1034,1235,life,24007,692792[a,a,a,aaa,aaa,aa,aaaa,a,a,aaa,aa,a,aa,a,aa,a][24007,990,1434,1266,1419,1327,1245,1305,][26076,]"
	local arena_id = string.match(value, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,%[]+)%[([^%]]+)%]%[([^%]]+)%]%[([^%]]+)%]$");
	commonlib.echo({arena_id}) 

	local value = "1116,near,18,1034,1235,life,24007,692792,10,10[a,a,a,aaa,aaa,aa,aaaa,a,a,aaa,aa,a,aa,a,aa,a][24007,990,1434,1266,1419,1327,1245,1305,][26076,]"
	local arena_id = string.match(value, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,%[]+)%[([^%]]+)%]%[([^%]]+)%]%[([^%]]+)%]$");
	_guihelper.MessageBox({arena_id}) 

	NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
	local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
	npl_profiler.perf_func("more IO calls", function() 
		local value = "1116,near,18,1034,1235,life,24007,692792[a,a,a,aaa,aaa,aa,aaaa,a,a,aaa,aa,a,aa,a,aa,a][24007,990,1434,1266,1419,1327,1245,1305,][26076,]"
		local arena_id = string.match(value, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,%[]+)%[([^%]]+)%]%[([^%]]+)%]%[([^%]]+)%]$");
	end, 10, 100);
end

function TestNPLProfiler:test_Random()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
	local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
	local r = FastRandom:new({_seed = 1234})
	
	npl_profiler.perf_enable(true);

	echo(r:randomLong())
	npl_profiler.perf_func("LuaJit Random", function() 
		for i=1, 10000 do
			r:randomLong();
		end
	end, 10, 100);

	npl_profiler.perf_func("Lua Math.Random", function() 
		for i=1, 10000 do
			math.random();
		end
	end, 10, 100);
	
	npl_profiler.perf_dump_result()
end

function TestNPLProfiler:test_randomDouble()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
	local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
	local r = FastRandom:new({_seed = 1234})
	
	npl_profiler.perf_enable(true);

	r:randomDouble();

	npl_profiler.perf_func("LuaJit randomDouble", function() 
		for i=1, 10000 do
			r:randomDouble();
		end
	end, 10, 100);

	npl_profiler.perf_func("Lua Math.Random", function() 
		for i=1, 10000 do
			math.random();
		end
	end, 10, 100);
	
	npl_profiler.perf_dump_result()
end

function TestNPLProfiler:test_TimeGetTime()
	npl_profiler.perf_enable(true);

	local ParaGlobal_timeGetTime = ParaGlobal.timeGetTime

	local ffi = require("ffi")
	ffi.cdef[[
	unsigned int GetTickCount(void);
	]]
	local C = ffi.C;

	echo({C.GetTickCount()});

	local c=0;
		
	npl_profiler.perf_func("ParaGlobal_timeGetTime", function() 
		for i=1, 10000 do
			c=c+ParaGlobal_timeGetTime();
		end
	end, 10, 100);

	npl_profiler.perf_func("LuaJit time get time", function() 
		for i=1, 10000 do
			c=c+C.GetTickCount();
		end
	end, 10, 100);
	
	local timeGetTime = function()
		return C.GetTickCount();
	end

	npl_profiler.perf_func("LuaJit func wrapper", function() 
		for i=1, 10000 do
			c=c+timeGetTime();
		end
	end, 10, 100);
	
	echo(c);

	npl_profiler.perf_dump_result()
end

-- LuaUnit:run("TestNPLProfiler:test_Perfs")
-- LuaUnit:run("TestNPLProfiler:test_PrintGoodWithBadCode")
--LuaUnit:run("TestNPLProfiler:test_BaseLine")
-- LuaUnit:run("TestNPLProfiler:test_StringFormatPerf")
--LuaUnit:run("TestNPLProfiler:test_StringFormatPerf2")
-- LuaUnit:run("TestNPLProfiler:test_GUICreation")
--LuaUnit:run("TestNPLProfiler:test_FileIO")
--LuaUnit:run("TestNPLProfiler:test_Random")
--LuaUnit:run("TestNPLProfiler:test_randomDouble")
LuaUnit:run("TestNPLProfiler:test_TimeGetTime")

