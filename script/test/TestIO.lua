--[[
Author: LiXizhi
Date: 2008-12-7
Desc: testing IO
-----------------------------------------------
NPL.load("(gl)script/test/TestIO.lua");
-----------------------------------------------
]]


-- convert everything in a folder to UTF8 encoding
-- %TESTCASE{"Test_io_OpenFileDialog", func = "Test_io_OpenFileDialog", input = {filter="*.*"},}%
function Test_io_OpenFileDialog(input)
	input = input or {};
	if(ParaGlobal.OpenFileDialog(input)) then
		commonlib.echo(input);
	end
	
	--local input = {filter="All Files (*.*)\0*.*\0", initialdir=ParaIO.AutoFindParaEngineRootPath("")};
	--if(ParaGlobal.OpenFileDialog(input)) then
		--commonlib.echo(input);
	--end
end	
	
-- convert everything in a folder to UTF8 encoding
-- %TESTCASE{"test_io_ConvertFileToUTF8", func = "test_io_ConvertFileToUTF8", input = {folder="script/test/", filter="*.lua"},}%
function test_io_ConvertFileToUTF8(input)
	-- list all files in the initial directory.
	local search_result = ParaIO.SearchFiles(input.folder,input.filter, "", 15, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	
	local i;
	for i = 0, nCount-1 do 
		local filename = input.folder..search_result:GetItem(i);
		local text;
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			-- get text with BOM heading
			local text = file:GetText(0, -1);
			-- check the BOM at the beginning of the file
			local isUTF8;
			if(text) then
				isUTF8 = (string.byte(text, 1) == tonumber("EF", 16) and string.byte(text, 2) == tonumber("BB", 16) and string.byte(text, 3) == tonumber("BF", 16))
					or (string.byte(text, 1) == tonumber("FF", 16) and string.byte(text, 2) == tonumber("FE", 16))
					or (string.byte(text, 1) == tonumber("FE", 16) and string.byte(text, 2) == tonumber("FF", 16))
			end		
			local puretext = file:GetText();
			file:close();
			
			if(not isUTF8) then
				file = ParaIO.open(filename, "w");
				if(file:IsValid()) then
					-- write utf8 BOM
					file:WriteString(string.char(tonumber("EF", 16), tonumber("BB", 16), tonumber("BF", 16)))
					-- convert
					file:WriteString(ParaMisc.EncodingConvert("", "utf-8", puretext));
					file:close();
				end	
				log("->"..filename.."\n")	
			else
				--file = ParaIO.open(filename, "w");
				--if(file:IsValid()) then               
					---- remove utf8 BOM header
					--file:WriteString(puretext)
					---- convert
					--file:close();
				--end	
				log("->(skip)"..filename.."\n")	
			end	
		end
		
		
	end
	search_result:Release();
end


-- convert everything in a folder to UTF8 encoding
-- %TESTCASE{"test_io_CheckFileEncoding", func = "test_io_CheckFileEncoding", input = {folder="script/test/", filter="*.lua"},}%
function test_io_CheckFileEncoding(input)
	-- list all files in the initial directory.
	local search_result = ParaIO.SearchFiles(input.folder,input.filter, "", 15, 10000, 0);
	local nCount = search_result:GetNumOfResult();
	
	local i;
	for i = 0, nCount-1 do 
		local filename = input.folder..search_result:GetItem(i);
		local text;
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			-- get text with BOM heading
			local text = file:GetText(0, -1);
			-- check the BOM at the beginning of the file
			local isUTF8;
			local isUTF16;
			if(text) then
				isUTF8 = (string.byte(text, 1) == tonumber("EF", 16) and string.byte(text, 2) == tonumber("BB", 16) and string.byte(text, 3) == tonumber("BF", 16))
				
				isUTF16 = (string.byte(text, 1) == tonumber("FF", 16) and string.byte(text, 2) == tonumber("FE", 16))
					or (string.byte(text, 1) == tonumber("FE", 16) and string.byte(text, 2) == tonumber("FF", 16))
			end		
			file:close();
			
			if(isUTF8) then
				log("->(utf8)"..filename.."\n")
			elseif(isUTF16) then
				log("->(utf16)"..filename.."\n")
			else
				log("->"..filename.."\n")	
			end	
		end
		
		
	end
	search_result:Release();
end

-- convert everything in a folder to UTF8 encoding
-- %TESTCASE{"test_IO_printFile_toLOG", func = "test_IO_printFile_toLOG", input = {filename="script/kids/3DMapSystemApp/API/test/paraworld.map.test.lua", isUTF8="true"},}%
function test_IO_printFile_toLOG(input)
	log("\r\n")
	local file = ParaIO.open(input.filename, "r");
	if(file:IsValid()) then
		--local text = file:GetText(0, -1);
		local text = file:GetText();
		if(input.isUTF8 ~= "true") then
			-- convert to UTF8
			text = ParaMisc.EncodingConvert("", "utf-8", text)
			log("converting to UTF8\n")
		end
		--text = ParaMisc.EncodingConvert("utf-8", "", text)
		commonlib.log(text);
		file:close();
	end
end


function test_file_conversion()

	-- convert all files under a folder
	NPL.load("(gl)script/ide/Files.lua");
	local result = commonlib.Files.Find({}, "xmodels/character/Spells/", 0, 500, "*.m2")
	local i, file 
	for i,file in pairs(result) do
		ParaEngine.ConvertFile("xmodels/character/Spells/"..file.filename, "character/m2/Spells/"..string.gsub(file.filename, "m2$", "x"));
	end

	local result = commonlib.Files.Find({}, "xmodels/m2/CREATURE/", 1, 500, "*.m2")
	local i, file 
	for i,file in pairs(result) do
		ParaEngine.ConvertFile("xmodels/m2/CREATURE/"..file.filename, "character/m2/Creature/"..string.gsub(file.filename, "m2$", "x"));
	end
	
	--ParaEngine.ConvertFile("xmodels/character/Spells/AbolishMagic_Base.m2", "character/m2/Spells/AbolishMagic_Base.x");
	--ParaEngine.ConvertFile("xmodels/m2/CREATURE/AncientOfLore/AncientOfLore.m2", "character/m2/Creature/AncientOfLore/AncientOfLore.x");
end

-- test open a file in asset manifest list. 
function test_IO_OpenAssetFile()
	commonlib.echo({["model/Skybox/skybox3/snowblind_up.dds"] = ParaIO.DoesAssetFileExist("model/skybox/skybox3/snowblind_up.dds")});
	
	local file = ParaIO.OpenAssetFile("model/Skybox/skybox3/Skybox3.x");
	if(file:IsValid()) then
		local line;
		repeat 
			line = file:readline()
			echo(line);
		until(not line)
		file:close();
	end
end

function test_IO_readline()
	local file = ParaIO.open("temp/test_readline.txt", "w");
	if(file:IsValid()) then
		file:WriteString("win line ending \r\n linux line ending \n last line without line ending")
		file:close();
	end
	local file = ParaIO.open("temp/test_readline.txt", "r");
	if(file:IsValid()) then
		local line;
		repeat 
			line = file:readline()
			echo(line);
		until(not line)
		file:close();
	end
end

function test_IO_SyncAssetFile_Async_callback()
	commonlib.log("asset file download is completed. msg.res = %d", msg.res)
	commonlib.echo(msg); -- msg.res == 1 means succeed
end

-- test IO file
function test_IO_SyncAssetFile_Async()
	local filename = "model/05plants/01flower/02flower/m_vegetation_3.png";
	if(ParaIO.CheckAssetFile(filename) ~= 1) then
		commonlib.echo({file=filename, "is not downloaded yet"})
		ParaIO.SyncAssetFile_Async(filename, ";test_IO_SyncAssetFile_Async_callback();")
	end
end

-- test IO write binary file
function test_IO_WriteBinaryFile()
	
	local file = ParaIO.open("temp/binaryfile.bin", "w");
	if(file:IsValid()) then	
		local data = "binary\0\0\0\0file";
		file:write(data, #data);
		-- write 32 bits int
		file:WriteUInt(0xffffffff);
		file:WriteInt(-1);
		-- write float
		file:WriteFloat(-3.14);
		-- write double (precision is limited by lua double)
		file:WriteDouble(-3.1415926535897926);
		-- write 16bits word
		file:WriteWord(0xff00);
		file:WriteBytes(3, {255, 0, 255});
		file:close();

		-- testing by reading file content back
		local file = ParaIO.open("temp/binaryfile.bin", "r");
		if(file:IsValid()) then	
			assert(file:GetText(0, #data) == data);
			file:seekRelative(#data);
			assert(file:getpos() == #data);
			assert(file:ReadUInt() == 0xffffffff);
			assert(file:ReadInt() == -1);
			assert(math.abs(file:ReadFloat() - (-3.14)) < 0.000001);
			assert(file:ReadDouble() == -3.1415926535897926);
			assert(file:ReadWord() == 0xff00);
			local o = {};
			file:ReadBytes(3, o);
			assert(o[1] == 255 and o[2] == 0 and o[3] == 255);

			file:seek(0);
			assert(file:GetText(0,6) == "binary");
			file:close();
		end
	end
end

-- test file system watcher
function test_io_FileSystemWatcher()
	-- we will modify file changes under temp and model directory. 
	local watcher = ParaIO.GetFileSystemWatcher("temp/");
	
	-- watcher:AddDirectory("E:\\Downloads\\");
	watcher:AddDirectory("temp/");
	watcher:AddCallback("commonlib.echo(msg);");
end

-- test file system watcher
function test_io_GeneratePKG()
	assert(ParaAsset.GeneratePkgFile("installer/main.zip", "installer/main.test.pkg"))
end

function test_CreateZip()
	-- testing creating zip files
	local zipname = "temp/simple.zip";
	local writer = ParaIO.CreateZip(zipname,"");
	--writer:ZipAdd("lua.dll", "lua.dll");
	writer:ZipAdd("aaa.txt", "deletefile.list");
	--writer:ZipAddFolder("temp");
	-- writer:AddDirectory("worlds/", "d:/temp/*.", 4);
	writer:close();

	-- test reading from the zip file.
	ParaAsset.OpenArchive(zipname);
	ParaIO.CopyFile("aaa.txt", "temp/aaa.txt", true);
	ParaAsset.CloseArchive(zipname);
end

--NPL.load("(gl)script/ide/UnitTest/luaunit.lua");
--SampleTestSuite = wrapFunctions( 'test_io_GeneratePKG')
--ParaGlobal.Exit(LuaUnit:run('SampleTestSuite'));

function test_MemoryFile()
	-- "<memory>" is a special name for memory file, both read/write is possible. 
	local file = ParaIO.open("<memory>", "w");
	if(file:IsValid()) then	
		file:WriteString("hello ");
		local nPos = file:GetFileSize();
		file:WriteString("world");
		file:WriteInt(1234);
		file:seek(nPos);
		file:WriteString("World");
		file:SetFilePointer(0, 2); -- 2 is relative to end of file
		file:WriteInt(0);
		file:WriteBytes(3, {100, 0, 22});
		file:WriteString("End");
		-- read entire binary text data back to npl string
		echo(#(file:GetText(0, -1)));
		file:close();
	end
end

function test_process_open()
	-- NPL.load("script/ide/commonlib.lua");
	local file = assert(io.popen('/bin/ls -la', 'r'))
	local output = file:read('*all')
	file:close()
	echo(output)
	-- exit(1)
end