--[[
Author: Li,Xizhi
Date: 2007-9-22
Desc: testing XML parser.
-----------------------------------------------
NPL.load("(gl)script/test/TestLuaXML.lua");
TestLuaXML()
-----------------------------------------------
]]

-- test passed on 2007-9-22 by LiXizhi
NPL.load("(gl)script/ide/commonlib.lua");


main_state = nil;

local function activate()
	-- commonlib.echo("heart beat: 30 times per sec");
	if(main_state==0) then
		-- this is the main game loop
	elseif(main_state==nil) then
		main_state=0;
		log("Hello World from script/test/TestAutoUpdater.lua\n");
		
		--NPL.activate("AutoUpdater.dll", {cmd="update",curver="0.0.1",callback="(gl)script/test/TestHelloWorld.lua",});
		NPL.activate("AutoUpdater.dll", {cmd="restart",version="1.0.0",filelist="Update\\1.0.0\\full.txt",});
		
		--NPL.activate("D:\\lxzsrc\\ParaEngine\\Server\\trunk\\AutoUpdater\\Debug\\AutoUpdater.dll", {ver="1.0", my_nid=1000,count=3,data0={table_begin=0,table_end=287,db_nid=1001},data1={table_begin=288,table_end=575,db_nid=1001},data2={table_begin=576,table_end=863,db_nid=1001},});
		--NPL.activate("D:\lxzsrc\ParaEngine\Server\trunk\AutoUpdater\Debug\AutoUpdater.dll", {ver="1.0", my_nid=1000,count=3,data0={table_begin=0,table_end=287,db_nid=1001},data1={table_begin=288,table_end=575,db_nid=1001},data2={table_begin=576,table_end=863,db_nid=1001},});
		--NPL.load("(gl)script/apps/NPLRouter/NPLRouter.lua");
		--NPLRouter:Start();
		--router_start_server();

	end	
end
NPL.this(activate);

