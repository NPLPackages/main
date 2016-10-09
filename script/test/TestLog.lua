--[[
Author: LiXizhi
Date: 2010.7.13
Desc: testing IPC
-----------------------------------------------
NPL.load("(gl)script/test/TestLog.lua");
-----------------------------------------------
]]

NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

TestLog = {} --class

function TestLog:setUp()
    -- set up tests
    NPL.load("(gl)script/ide/log.lua");
end

-- test the global log interface
function TestLog:test_logging_global_simple()
	local LOG = LOG; -- this makes LOG API faster in subsequent calls
	LOG.level = "TRACE";

	if (LOG("INFO")) then
		LOG.info(string.format("string formatting is %s", "expensive. That is why we do a if before log."));
	end
	LOG.info("this is less expansive %s", "even without checking is isLoggable.");
	LOG.debug("for non-time critical log simply %s", "write without check isLoggable");
	LOG.error("some error is seen");
	LOG.fatal({table_is_fine = "fatal error is seen"});
	LOG.trace("tracing should be removed at release time: 11111111111111111111");
	LOG.applog("write the applog with date time which is always printed. ");
	LOG.ui("keyname", {value="show in UI on left top corner"})
	LOG.show("keyname1", "LOG.show is same as LOG.ui")
end

-- create a logger that is shared by a sub system(module)
function TestLog:test_logging_instance()
	-- create an instance
	local LOG = commonlib.logging.GetLogger("MySubSystemXX")
	LOG.level = "TRACE";
	LOG.trace("from logging instance MySubSystemXX");

	LOG.setAppender(function (level, ...)
		log("From appender(log listener): ");
		commonlib.log(...);
		log("\n")
	end)
	LOG.trace("This message should appear from appender");
end

LuaUnit:run("TestLog")