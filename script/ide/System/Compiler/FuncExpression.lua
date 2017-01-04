----------------------------------------------------------------------
-- FuncExpression Base Class
-- Author: Zhiyuan
-- Date: 2016-12-25
----------------------------------------------------------------------
local FuncExpression = commonlib.inherit(nil, commonlib.gettable("System.Compiler.FuncExpression"))

--FuncExpression = {}
FuncExpression.name = ""
FuncExpression.mode = "stricted"

local Modes = { stricted = 1, line = 2, token = 3 }

function FuncExpression:new(name)
	local name = name or ""
	local o = {name = name, mode = "stricted"}	--default mode is "stricted"
	setmetatable(o, self)
	self.__index = self
	return o	
end

function FuncExpression:Compile(ast)
	return self.CompileCode(ast)
end

--function FuncExpression:CompileCode(ast)
	--return {ast:tostring()}
--end

function FuncExpression:setMode(mode)
	if mode and Modes[mode] 
		then self.mode=mode 
	end
end

function FuncExpression:getName()
	return self.name
end
