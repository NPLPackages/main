--[[
Author: Li,Xizhi
Date: 2017-3-1
Desc: this is sample mod. 
-----------------------------------------------
-----------------------------------------------
]]
local fileA = NPL.load("../fileA")
local fileB = NPL.export();

echo("fileB is loaded from "..NPL.filename())
-- uncomment to optionally export to a global position. 
-- commonlib.setfield("npl_mod.sample_mod", sample_mod);

function fileB:print()
	echo("fileB  -- "..fileA:print())
	return "fileB";
end

function fileB:CyclicDependencyTest()
	return fileA:print();
end
