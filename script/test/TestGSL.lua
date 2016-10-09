--[[
Author: LiXizhi
Date: 2010.5.20
Desc: testing GSL and IMServer_client static (local) functions (without any networking)
-----------------------------------------------
NPL.load("(gl)script/test/TestGSL.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

------------------------------------------------
-- GSL 
------------------------------------------------
TestGSL = {} --class

local GSL, GSL_grid, GSL_msg, GSL_proxy, GSL_stat, GSL_gateway, agentstate;

function TestGSL:setUp()
    -- set up tests
    NPL.load("(gl)script/apps/GameServer/GSL.lua");
    NPL.load("(gl)script/apps/GameServer/GSL_grid.lua");
    NPL.load("(gl)script/apps/GameServer/GSL_gateway.lua");
    
    GSL = commonlib.gettable("Map3DSystem.GSL");
	GSL_grid = commonlib.gettable("Map3DSystem.GSL_grid");
	GSL_homegrid = commonlib.gettable("Map3DSystem.GSL_homegrid");
	GSL_msg = commonlib.gettable("Map3DSystem.GSL.GSL_msg");
	GSL_proxy = commonlib.gettable("Map3DSystem.GSL.GSL_proxy");
	GSL_stat = commonlib.gettable("Map3DSystem.GSL.GSL_stat");
	GSL_gateway = commonlib.gettable("Map3DSystem.GSL.gateway");
	agentstate = commonlib.gettable("Map3DSystem.GSL.agentstate");
	
	-- now populate the table with some test data manually here. 
	local config = commonlib.gettable("Map3DSystem.GSL.config");
	config.GridNodeRules={{worldfilter=".*"}};
	
	GSL_gateway.config = {nid="101", ws_id="1001", addr="127.0.01", homegrids}
	GSL_gateway:GetUser("10001")
	GSL_gateway:GetUser("10002")
	GSL_gateway:GetUser("10003")
	
	GSL_grid:Reset();
	
	GSL_grid.config = {nid="101", ws_id="1001", addr="127.0.0.1"};
	
	local function init_agent_(agent)
		agent.state = agentstate.agent;
	end
	
	local node, agent;
	node = GSL_grid:CreateGetBestGridNode("worlds/TestWorld1", 0,0,0);
	init_agent_(node:CreateAgent("10001"));
	init_agent_(node:CreateAgent("10002"));
	
	node = GSL_grid:CreateGetBestGridNode("worlds/TestWorld2", 0,0,0);
	init_agent_(node:CreateAgent("10003"));
end

function TestGSL:test_GSL_grid()
	-- test GetAllOnlineUsers
	local users, users_count = GSL_grid:GetAllOnlineUsers();
	
	assert(string.find(users, "10001") and string.find(users, "10002") and string.find(users, "10003"));
	
	-- test GetTotalAgentCount
	local total_agent_count = GSL_grid:GetTotalAgentCount();
	assertEquals( total_agent_count, 3)
end

------------------------------------------------
-- IMserver_client.lua
------------------------------------------------
TestIMClient = {} --class
local JabberClientManager;


function TestIMClient:setUp()
	NPL.load("(gl)script/apps/IMServer/IMserver_client.lua");
	JabberClientManager = commonlib.gettable("IMServer.JabberClientManager");
	
	JabberClientManager.CreateJabberClient("1234567@paraengine.com");
end

function TestIMClient:test_FindJabberClient()
	local client = JabberClientManager.FindJabberClient(1234567);
	assert(JabberClientManager.FindJabberClient(1234567).nid == 1234567);
	assert(JabberClientManager.FindJabberClient("1234567").nid == 1234567);
	assert(JabberClientManager.FindJabberClient("1234567@paraengine.com").nid == 1234567);
	
	assert(client:GetJidFromNid(1234567) == "1234567@paraengine.com");
	assert(client:GetJidFromNid("1234567") == "1234567@paraengine.com");
end

function TestIMClient:test_ParseCode()
	local roster = JabberClientManager.ParseRosterListString("1,2,", "a,b,");
	
	assert(roster[1].nid == 1)
	assert(roster[1].sig == "a")
	assert(roster[2].nid == 2)
	assert(roster[2].sig == "b")
	assert(roster[3] == nil)
	
	-- now without the ending commar should also work. 
	local roster = JabberClientManager.ParseRosterListString("1,2", "a,b");
	assert(roster[1].nid == 1)
	assert(roster[1].sig == "a")
	assert(roster[2].nid == 2)
	assert(roster[2].sig == "b")
	assert(roster[3] == nil)
end

-- used by test_EventCallback
function TestIMClient.eventCallBack()
	assert(msg.data == "hello");
	assert(msg.type == "TestMethod");
	assert(msg.jckey == "1234567@paraengine.com");
end

function TestIMClient:test_EventCallback()
	-- test event callbacks
	local client = JabberClientManager.FindJabberClient(1234567);
	
	-- string based event
	client:AddEventListener("TestMethod", "TestIMClient.eventCallBack()");
	
	-- function based event
	client:AddEventListener("TestMethod", function(self, msg) 
			assert(self == client);
			assert(msg.data == "hello");
			assert(msg.type == "TestMethod");
			assert(msg.jckey == "1234567@paraengine.com");
		end);
		
	-- test fire event
	client:FireEvent({type="TestMethod", data = "hello"})
	
	-- test clear event
	client:ClearEventListener("TestMethod");
	client:FireEvent({type="TestMethod", data = "never be called"})
end

function TestIMClient:test_RosterPresence()
	-- test event callbacks
	local client = JabberClientManager.FindJabberClient(1234567);

	-- add some static data	
	client:UpdateRosterItem(111, nil, "sig_111");
	client:UpdateRosterItem(222, nil, "sig_222");
	client:UpdateRosterItem(333, nil, "sig_333");
	
	client:AddEventListener("JE_OnRosterPresence", function(self, msg)
		assert(msg.jid == "111@paraengine.com")
		assert(msg.presence == 0)
		assert(msg.msg == "new one")
	end);
	
	-- this should fire the JE_OnRosterPresence event
	client:UpdatePresence(111, "online", "new one", "normal");
	
	client:ResetAllEventListeners();
end

------------------------------------------------
-- IMserver_client.lua (team server test)
------------------------------------------------
TestTeamIMServer = {} --class
local JabberClientManager;
local TeamClientLogics = commonlib.gettable("MyCompany.Aries.Team.TeamClientLogics");

function TestTeamIMServer:setUp()
	NPL.load("(gl)script/apps/IMServer/IMserver_client.lua");
	JabberClientManager = commonlib.gettable("IMServer.JabberClientManager");
	self.jc1 = JabberClientManager.CreateJabberClient("100001@paraengine.com");
	self.jc2 = JabberClientManager.CreateJabberClient("100002@paraengine.com");
	self.jc3 = JabberClientManager.CreateJabberClient("100003@paraengine.com");
	self.jc4 = JabberClientManager.CreateJabberClient("100004@paraengine.com");
end

function TestTeamIMServer:testSetTeam()
	local msg = {
		action = "setteam",
		data_table = {team_member="100001,100002,100003,100004", src_nid="", team_number=4},
		user_nid=100001,
		dest="imclient",ver="1.0",
		nid = "imserver1",
	}
	assert(self.jc1:IsSelf("100001"));

	JabberClientManager.Activate(msg)
	self.jc1:PrintTeam();

	assert(self.jc1:IsInTeam());
	assert(self.jc1:IsTeamLeader());
	assert(self.jc1:IsTeamFull());
	assert(self.jc1:GetTeamMemberByNid(100004).nid == 100004);

	msg.data_table = {team_member="100001,100002,100004", src_nid="", team_number=3};
	JabberClientManager.Activate(msg)
	self.jc1:PrintTeam();
	assert(not self.jc1:IsTeamFull());

	msg.data_table = {team_member="100001", src_nid="", team_number=3};
	JabberClientManager.Activate(msg)
	self.jc1:PrintTeam();
	assert(not self.jc1:IsInTeam());

	msg.data_table = {team_member="100002,100001,100003,100004", src_nid="", team_number=3};
	JabberClientManager.Activate(msg)
	self.jc1:PrintTeam();
	assert(self.jc1:IsInTeam());
	assert(not self.jc1:IsTeamLeader());

	msg.data_table = {team_member="100003,100004", src_nid="", team_number=3};
	JabberClientManager.Activate(msg)
	self.jc1:PrintTeam();
	assert(not self.jc1:IsInTeam());
end


function TestTeamIMServer:testClientLogics()
	NPL.load("(gl)script/apps/Aries/Team/TeamClientLogics.lua");
	TeamClientLogics:SetJC(self.jc1); 
	TeamClientLogics:Init();

	local msg = {
		action = "setteam",
		data_table = {team_member="100001,100003,100004", src_nid="", team_number=4},
		user_nid=100001,
		dest="imclient",ver="1.0",
		nid = "imserver1",
	}
	JabberClientManager.Activate(msg)
	assert(self.jc1:IsInTeam());

	local msg_talk = {
		action = "team_message",
		data_table = {msg="hello world", src_nid="100003"},
		user_nid=100001,
		dest="imclient", ver="1.0",
		nid = "imserver1",
	}
	JabberClientManager.Activate(msg_talk)

	-- try to invite a new team member
	TeamClientLogics:InviteTeamMember(100002)
	

	msg_talk.data_table = {msg={type="join"}, src_nid="100002"};
	JabberClientManager.Activate(msg_talk)
end

LuaUnit:run("TestTeamIMServer")
-- LuaUnit:run("TestIMClient")
-- LuaUnit:run("TestGSL")