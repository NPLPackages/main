----------------------------------------------------------------------
-- FucExpression Def Class
-- Author: Zhiyuan
-- Date: 2016-12-25
----------------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/FuncExpression.lua");
local FuncExpression = commonlib.gettable("System.Compiler.FuncExpression")
local FuncExpressionDef = commonlib.inherit(commonlib.gettable("System.Compiler.FuncExpression"), commonlib.gettable("System.Compiler.FuncExpressionDef"))

-- FIXME: make mode structure global
local mode = {strict = 1, unstrict = 2}

function FuncExpressionDef:new()
	local o = {name = "Def", mode = mode.unstrict}
	setmetatable(o, self)
	self.__index = self
	return o	
end

function FuncExpressionDef:buildFunc(ast)
	--local mode = self:GetModeFromAst(ast)
	print(ast:getParam(1))
	local f = FuncExpression:new(ast:getParam(1))
	f.symTbl = ast:buildSymTbl()
	local compiledCode={}

	local function compile()
		local tast = ast.content
		for i=1, #tast do
			if tast[i].tag == "Raw" then
				compiledCode[#compiledCode+1] = "emit([["..tast[i][1].."]]) "
			elseif tast[i].tag == "Slice" then
				compiledCode[#compiledCode+1] = tast[i][1].." "
			end
		end
	end

	compiledCode[#compiledCode+1] = [[return function(ast)
		local compiledCode = {}
		print("hahhahaha")
		local f_scope = {
			emit = function(code)
			if(code) then
				compiledCode[#compiledCode+1] = code
			else
				compiledCode[#compiledCode+1] = ast:getContent()
			end	
			end,
			params = function(p) 
				compiledCode[#compiledCode+1] = ast:getParam(p) 
			end
		}

		local function compile()

	]]

	compile()

	compiledCode[#compiledCode+1] = [[
	end
	setfenv(compile, f_scope)
	compile()
	return compiledCode
	end
	]]
	--print(table.concat(compiledCode))
	f.CompileCode = loadstring(table.concat(compiledCode))()
	return f
end
