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
	end	
		--log("Hello World from script/test/TestHelloWorld.lua\n");
		--commonlib.echo(msg);
		if(msg.isfinished == "yes") then
			if(msg.allcount == msg.finishcount) then
				log("Update progeress is finished!\n");
			else
				log("Update progeress is failed!Some files download failed\n");
			end
		else
			local per = string.format("%.2f",100*msg.finishcount/msg.allcount);
			log("Update progress to " .. per .. "%!\n");
		end	
end
NPL.this(activate);

