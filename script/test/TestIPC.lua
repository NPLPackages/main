--[[
Author: LiXizhi
Date: 2010.4.29
Desc: testing IPC
-----------------------------------------------
NPL.load("(gl)script/test/TestIPC.lua");
-----------------------------------------------
]]

NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

TestIPC = {} --class

function TestIPC:setUp()
    -- set up tests
    NPL.load("(gl)script/ide/IPC.lua");
end

function TestIPC:test_blockingCall()
	
	-- Example 1: synchronous call with blocking API, useful for remote Debug Engine, etc.
	
	-- Please note ipc_queue_reader and ipc_queue_writer can exist in different process and we also show two ways to create queue.
	local ipc_queue_reader = IPC.CreateGetQueue("MyQueue", 2)
	ipc_queue_reader:Clear();
	-- please note, ParaIPC.CreateGetQueue or ParaIPC.ParaIPCQueue will create another queue object with the same queue name, otherwise the code will not work in the same process. 
	local ipc_queue_writer = ParaIPC.CreateGetQueue("MyQueue", 2)

	-- send a message to the queue
	ipc_queue_writer:try_send({
		method = "NPL1", -- string [optional] default to "NPL"
		from = "writer", 
		type = 11, -- number [optional] default to 0. 
		param1 = 12, -- number [optional] default to 0. 
		param2 = 13, -- number [optional] default to 0. 
		filename = "", -- string [optional] the file name 
		code = {data=123,}, -- string or table [optional], if method is "NPL", code should be a pure table or nil.
		priority = 1, -- number [optional] default to 0. Message priority
	})

	-- read a message from the queue. This is a blocking call. 
	local out_msg = {};
	ipc_queue_reader:receive(out_msg);
	commonlib.echo(out_msg);

	assertEquals( out_msg.from , "writer" )
    assertEquals( out_msg.type , 11 )
    assertEquals( out_msg.param1 , 12 )
    assertEquals( out_msg.param2 , 13 )
    assertEquals( out_msg.code.data , 123 )
end

function TestIPC:test_IPC_activate()
	-- Example 2: using asynchrounous calls which resembles NPL.activate
	
	-- start the IPC server that listens for queue "MyIPCServer"
	local server_queue = IPC.StartNPLQueueListener("MyIPCServer", 2, 500, {["script/ide/IPC.lua"] = "script/ide/IPC.lua", ["ipc_shortname"] = "script/ide/IPC.lua"});
	
	-- In remote or local process, we can activate a file like below. 
	IPC.activate("MyIPCServer", nil, "script/ide/IPC.lua", {data=1});
	IPC.activate("MyIPCServer", "from_name", "ipc_shortname", {data=2});
	IPC.activate("MyIPCServer", "from_name", "ipc_shortname", {test_long_string= "1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\n1234567qwertyuiopasdfghjklzxcvbnm,.\nendofline SUCCEED\n"});
end


LuaUnit:run("TestIPC")