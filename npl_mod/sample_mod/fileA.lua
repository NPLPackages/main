--[[
Author: Li,Xizhi
Date: 2017-3-1
Desc: this is sample mod. 
-----------------------------------------------
-----------------------------------------------
]]
local fileB = NPL.load("./subfolder/fileB.lua")
local fileA = NPL.export();

-- uncomment to optionally export to a global position. 
-- commonlib.setfield("npl_mod.sample_mod", sample_mod);

echo("fileA is loaded from "..NPL.filename())

function fileA:print()
	echo("fileA")
	return "fileA";
end

function fileA:CyclicDependencyTest()
	return fileB:print();
end
