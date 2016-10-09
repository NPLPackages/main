--[[
Author: LiXizhi
Date: 2009-6-24
Desc: Any file that end with ".run" will be run by lua interpreter, or one can left click the file name in visual studio and select Lua Run File Custom build tool. 
This is good for debugging pure lua file in visual studio by pressing Ctrl-F7
the rule file is in script/bin/npl_debug_rule_vs2005.rules
-----------------------------------------------
NPL.load("(gl)script/test/test.run.lua");
-----------------------------------------------
]]
--[[
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/Files.lua");

log("hello world!\n");
local files = {};
local parentDir = Map3DSystem.App.Assets.app:GetAppDirectory();
commonlib.SearchFiles(files, "/audio/", "*.wav", 5, 50, true);
-- commonlib.Find(files, "/audio/", 5, 50, "*.zip")
commonlib.echo(files);
]]