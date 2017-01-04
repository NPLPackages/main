----------------------------------------------------------------------
-- FucExpression Def Class
-- Author: Zhiyuan
-- Date: 2016-12-25
----------------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/FuncExpression.lua");
local FuncExpression = commonlib.gettable("System.Compiler.FuncExpression")
local FuncExpressionDef = commonlib.inherit(commonlib.gettable("System.Compiler.FuncExpression"), commonlib.gettable("System.Compiler.FuncExpressionDef"))

function FuncExpressionDef:new()
	local o = {name = "Def", mode = "unstricted"}
	setmetatable(o, self)
	self.__index = self
	return o	
end

function FuncExpressionDef:buildFunc(ast)
	--local mode = self:GetModeFromAst(ast)
	--print(ast:getParam(1))
	local f = FuncExpression:new(ast:getParam(1))
	f.symTbl = ast:buildSymTbl()
	f.mode= ast:getMode() or "stricted"
	local compiledCode={}
	local function compile()
		local tast = ast.content
		for i=1, #tast do
			if tast[i].tag == "Raw" then
				compiledCode[#compiledCode+1] = "emit([["..tast[i][1].."]]) "	--TODO:handle [[ & ]]
			elseif tast[i].tag == "Slice" then
				compiledCode[#compiledCode+1] = tast[i][1].." "
			end
		end
	end

	compiledCode[#compiledCode+1] = [[return function(ast)
		local compiledCode = {{}}
		local function insertLines(code, offset)
			local i = 1
			local line = offset
			for k=#compiledCode+1, line do
				compiledCode[k] = {}
			end
			while true do
				local prev_i = i
				i = string.find(code, "\n", i)
				if not compiledCode[line] then compiledCode[line] = {} end
				if not i then
					table.insert(compiledCode[line], code:sub(prev_i))
					break
				else
					table.insert(compiledCode[line], code:sub(prev_i, i-1))
				end
				i = i+1
				line = line+1
			end
		end

		local f_scope = {
			emit = function(code, line)
				if code then
					if line then
						insertLines(code, line)
					else
						insertLines(code, #compiledCode)
					end
				else
					lines = ast:getContent()
					insertLines(lines, 1)
				end	
			end,
			params = function(p)
				table.insert(compiledCode[#compiledCode], ast:getParam(p))
			end
		}

		local function compile()
	]]

	compile()

	compiledCode[#compiledCode+1] = [[
	end
	setfenv(compile, f_scope)
	compile()

	for i=1, #compiledCode do
		compiledCode[i] = table.concat(compiledCode[i], " ")
	end
	
	compiledCode = table.concat(compiledCode, "\n")
	local startline = ast:getOffset()
	for i=1, startline-1 do
		compiledCode = "\n"..compiledCode
	end
	return compiledCode
	end
	]]
	--print(table.concat(compiledCode))
	f.CompileCode = loadstring(table.concat(compiledCode))()
	return f
end
