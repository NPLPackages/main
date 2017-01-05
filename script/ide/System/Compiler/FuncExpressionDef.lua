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
		local maxlnum = 0
		local curline = 1
		local function insertLines(code, line)
			if not line then return end
			local prev_line = line
			local i = 1
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
			if line > maxlnum then maxlnum = line end
			return line	- prev_line + 1	-- return total lines of emitted string
		end

		local f_scope = {
			emit = function(code, line)
				if code then
					if line then
						insertLines(code, line)
					else
						insertLines(code, curline)
					end
				else
					local lines = ast:getContent()
					local lnum = insertLines(lines, 1)	
					curline = lnum
				end	
			end,
			emitline = function(fl, ll)
				local fl = fl or 1
				local lnum = insertLines(ast:getLines(fl, ll), fl)
				curline = fl+lnum-1
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

	for i=1, maxlnum do
		if not compiledCode[i] then compiledCode[i] = {} end
	end

	for i=1, #compiledCode do
		compiledCode[i] = table.concat(compiledCode[i], " ")
	end
	
	compiledCode = table.concat(compiledCode, "\n")
	compiledCode = "do "..compiledCode.." end"
	local startline = ast:getOffset()
	for i=1, startline-1 do
		compiledCode = "\n"..compiledCode
	end
	
	return compiledCode
	end
	]]
	f.CompileCode = loadstring(table.concat(compiledCode))()
	return f
end
