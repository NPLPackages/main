----------------------------------------------------------------------
-- FuncExpression Base Class
-- Author: Zhiyuan
-- Date: 2016-12-25
----------------------------------------------------------------------
local FuncExpression = commonlib.inherit(nil, commonlib.gettable("System.Compiler.FuncExpression"))

function FuncExpression:ctor()
	
end

function FuncExpression:init(name)
	local name = name or ""
	self.name = name
	self.mode = "strict"
	return self
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
