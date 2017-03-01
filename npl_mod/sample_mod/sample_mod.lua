--[[
Author: Li,Xizhi
Date: 2017-3-1
Desc: this is sample mod. 
the mod is written using file-based module only. 
-----------------------------------------------
local sample_mod = NPL.load("sample_mod");
assert(sample_mod:print() == "hello");
local fileA = NPL.load("sample_mod.fileA");
assert(fileA:print() == "fileA");
local fileB = NPL.load("sample_mod.subfolder.fileB");
assert(fileB:print() == "fileB");
-----------------------------------------------
]]
local fileA = NPL.load("./fileA.lua");
local fileB = NPL.load("./subfolder/fileB");  -- file name can be ignored. 

local sample_mod = NPL.export();

-- uncomment to optionally export to a global position. 
-- commonlib.setfield("npl_mod.sample_mod", sample_mod);

function sample_mod:print()
	echo("hello sample_mod")
	
	fileA:CyclicDependencyTest();

	return "hello";
end

