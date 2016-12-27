----------------------------------------------------------------------
-- FuncExpression Base Class
-- Author: Zhiyuan
-- Date: 2016-12-25
----------------------------------------------------------------------
local FuncExpression = commonlib.inherit(nil, commonlib.gettable("System.Compiler.FuncExpression"))

local mode = {strict = 1, unstrict = 2}

--FuncExpression = {}
FuncExpression.name = ""
FuncExpression.mode = mode.strict

function FuncExpression:new(name)
	local name = name or ""
	local o = {name = name, mode = mode.strict}
	setmetatable(o, self)
	self.__index = self
	return o	
end


function FuncExpression:Compile(ast)
	local lines = self.CompileCode(ast)
	return table.concat(lines)
end

--function FuncExpression:CompileCode(ast)
	--return {ast:tostring()}
--end

function FuncExpression:setMode(mode)
	if mode then self.mode=mode end
end

function FuncExpression:getName()
	return self.name
end
