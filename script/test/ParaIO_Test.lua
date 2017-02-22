--[[
Author: Li,Xizhi
Date: 2007-1
Desc: testing ParaIO functions.
-----------------------------------------------
NPL.load("(gl)script/test/ParaIO_test.lua");
ParaIO_PathReplaceable()
-- ParaIO_FileTest();
-- ParaIO_ZipFileTest();
-- ParaIO_SearchZipContentTest();
-- ParaIO_SearchPathTest();
-- ParaIO_openimageTest()
-----------------------------------------------
]]

-- tested on 2007.1, LiXizhi
local function ParaIO_FileTest()
	
	-- file write
	log("testing file write...\r\n")
	
	local file = ParaIO.open("temp/iotest.txt", "w");
	file:WriteString("test\r\n");
	file:WriteString("test\r\n");
	file:close();
	
	-- file read
	log("testing file read...\r\n")
	
	local file = ParaIO.open("temp/iotest.txt", "r");
	log(tostring(file:readline()));
	log(tostring(file:readline()));
	log(tostring(file:readline()));
	file:close();
	
end

-- tested on 2007.6.7, LiXizhi
local function ParaIO_ZipFileTest()
	local writer = ParaIO.CreateZip("d:\\simple.zip","");
	writer:ZipAdd("temp/file1.ini", "d:\\file1.ini");
	writer:ZipAdd("temp/file2.ini", "d:\\file2.ini");
	writer:ZipAddFolder("temp");
	writer:AddDirectory("worlds/", "d:/temp/*.", 4);
	writer:AddDirectory("worlds/", "d:/worlds/*.*", 2);
	writer:close();
end

-- tested on 2007.6.7, LiXizhi
local function ParaIO_SearchZipContentTest()
	-- test case 1 
	log("test case 1\n");
	local search_result = ParaIO.SearchFiles("","*.", "d:\\simple.zip", 0, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		log(search_result:GetItem(i).."\n");
	end
	search_result:Release();
	-- test case 2 
	log("test case 2\n");
	local search_result = ParaIO.SearchFiles("","*.ini", "d:\\simple.zip", 0, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		log(search_result:GetItem(i).."\n");
	end
	search_result:Release();
	-- test case 3 
	log("test case 3\n");
	local search_result = ParaIO.SearchFiles("","temp/*.", "d:\\simple.zip", 0, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		log(search_result:GetItem(i).."\n");
	end
	search_result:Release();
	-- test case 4 
	log("test case 4\n");
	local search_result = ParaIO.SearchFiles("temp/","*.*", "d:\\simple.zip", 0, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		log(search_result:GetItem(i).."\n");
	end
	search_result:Release();
	-- test case 5 
	log("test case 5\n");
	local search_result = ParaIO.SearchFiles("","temp/*.*", "d:\\simple.zip", 0, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		log(search_result:GetItem(i).."\n");
	end
	search_result:Release();	
end

local function ParaIO_SearchPathTest()
	ParaIO.CreateDirectory("npl_packages/test/")
	local file = ParaIO.open("npl_packages/test/test_searchpath.lua", "w");
	file:WriteString("echo('from test_searchpath.lua')")
	file:close();

	ParaIO.AddSearchPath("npl_packages/test");
	ParaIO.AddSearchPath("npl_packages/test/"); -- same as above, check for duplicate
	
	assert(ParaIO.DoesFileExist("test_searchpath.lua"));
	
	ParaIO.RemoveSearchPath("npl_packages/test");
	
	assert(not ParaIO.DoesFileExist("test_searchpath.lua"));

	-- ParaIO.AddSearchPath("npl_packages/test/");
	-- this is another way of ParaIO.AddSearchPath, except that it will check for folder existence.
	-- in a number of locations.
	NPL.load("npl_packages/test/");
	
	-- test standard open api
	local file = ParaIO.open("test_searchpath.lua", "r");
	if(file:IsValid()) then
		log(tostring(file:readline()));
	else
		log("not found\n");	
	end
	file:close();

	-- test script file
	NPL.load("(gl)test_searchpath.lua");
	
	ParaIO.ClearAllSearchPath();
	
	assert(not ParaIO.DoesFileExist("test_searchpath.lua"));
end

-- TODO: test passed on 2008.4.20, LiXizhi
function ParaIO_PathReplaceable()
	ParaIO.AddPathVariable("WORLD", "worlds/MyWorld")
	if(ParaIO.AddPathVariable("userid", "temp/LIXIZHI_PARAENGINE")) then
		local fullpath;
		commonlib.echo("test simple");
		fullpath = ParaIO.DecodePath("%WORLD%/%userid%/filename");
		commonlib.echo(fullpath);
		fullpath = ParaIO.EncodePath(fullpath)
		commonlib.echo(fullpath);
		
		commonlib.echo("test encoding with a specified variables");
		fullpath = ParaIO.DecodePath("%WORLD%/%userid%/filename");
		commonlib.echo(fullpath);
		commonlib.echo(ParaIO.EncodePath(fullpath, "WORLD"));
		commonlib.echo(ParaIO.EncodePath(fullpath, "WORLD, userid"));
		
		commonlib.echo("test encoding with inline path");
		fullpath = ParaIO.DecodePath("%WORLD%/%userid%_filename");
		commonlib.echo(fullpath);
		fullpath = ParaIO.EncodePath(fullpath)
		commonlib.echo(fullpath);
		
		
		commonlib.echo("test nested");
		fullpath = ParaIO.DecodePath("%userid%/filename/%userid%/nestedtest");
		commonlib.echo(fullpath);
		fullpath = ParaIO.EncodePath(fullpath)
		commonlib.echo(fullpath);
		
		commonlib.echo("test remove");
		if(ParaIO.AddPathVariable("userid", nil)) then
			fullpath = ParaIO.DecodePath("%userid%/filename");
			commonlib.echo(fullpath);
			fullpath = ParaIO.EncodePath(fullpath)
			commonlib.echo(fullpath);
		end
		
		commonlib.echo("test full path");
		fullpath = ParaIO.DecodePath("NormalPath/filename");
		commonlib.echo(fullpath);
		fullpath = ParaIO.EncodePath(fullpath)
		commonlib.echo(fullpath);
	end
end

function ParaIO_SearchFiles_reg_expr()
	-- test case 1 
	local search_result = ParaIO.SearchFiles("script/ide/",":.*", "*.zip", 2, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		log(search_result:GetItem(i).."\n");
	end
	search_result:Release();
end

function test_excel_doc_reader()
	NPL.load("(gl)script/ide/Document/ExcelDocReader.lua");
	local ExcelDocReader = commonlib.gettable("commonlib.io.ExcelDocReader");
	local reader = ExcelDocReader:new();

	-- schema is optional, which can change the row's keyname to the defined value. 
	reader:SetSchema({
		[1] = {name="npcid", type="number"},
		[2] = {name="superclass", validate_func=function(value)  return value or "menu1"; end },
		[3] = {name="class", validate_func=function(value)  return value or "normal"; end },
		[4] = {name="class_name", validate_func=function(value)  return value or "Õ®”√"; end },
		[5] = {name="gsid", type="number" },
		[6] = {name="exid", type="number" },
		[7] = {name="money_list", },
	})
	-- read from the second row
	if(reader:LoadFile("config/Aries/NPCShop/npcshop.xml", 2)) then 
		local rows = reader:GetRows();
		echo(rows);
	end



	NPL.load("(gl)script/ide/Document/ExcelDocReader.lua");
	local ExcelDocReader = commonlib.gettable("commonlib.io.ExcelDocReader");
	local reader = ExcelDocReader:new();

	-- schema is optional, which can change the row's keyname to the defined value. 
	local function card_and_level_func(value)  
		if(value) then
			local level, card_gsid = value:match("^(%d+):(%d+)");
			return {level=level, card_gsid=card_gsid};
		end
	end
	reader:SetSchema({
		{name="gsid", type="number"},
		{name="displayname"},
		{name="max_level", type="number" },
		{name="hp", type="number" },
		{name="attack", type="number" },
		{name="defense", type="number" },
		{name="powerpips_rate", type="number" },
		{name="accuracy", type="number" },
		{name="critical_attack", type="number" },
		{name="critical_block", type="number" },
		{name="card1",  validate_func= card_and_level_func},
		{name="card2",  validate_func= card_and_level_func},
		{name="card3",  validate_func= card_and_level_func},
		{name="card4",  validate_func= card_and_level_func},
		{name="card5",  validate_func= card_and_level_func},
		{name="card6",  validate_func= card_and_level_func},
		{name="card7",  validate_func= card_and_level_func},
		{name="card8",  validate_func= card_and_level_func},
	})
	-- read from the second row
	if(reader:LoadFile("config/Aries/Others/combatpet_levels.excel.teen.xml", 2)) then 
		local rows = reader:GetRows();
		log(commonlib.serialize(rows, true));
	end
end
