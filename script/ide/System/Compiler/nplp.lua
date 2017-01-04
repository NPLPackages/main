----------------------------------------------------------------------
-- NPL Parser
-- Extended from Metalua Parser
-- Add a 'def' macro structure
-- Author:Zhiyuan
-- Date: 2016-12-13
----------------------------------------------------------------------

NPL.load("(gl)script/ide/System/Compiler/lib/metalua/base.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/string2.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/table2.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/lexer.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/gg.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_lexer.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_misc.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_table.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_meta.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_expr.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_stat.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_ext.lua");
NPL.load("(gl)script/ide/System/Compiler/ast.lua");
NPL.load("(gl)script/ide/System/Compiler/FuncExpressionDef.lua");

local gg = commonlib.gettable("System.Compiler.lib.gg")
local nplp = commonlib.inherit(commonlib.gettable("System.Compiler.lib.mlp"), commonlib.gettable("System.Compiler.nplp"))
local nplgen = commonlib.gettable("System.Compiler.nplgen")
local AST = commonlib.gettable("System.Compiler.ast")
local FuncExpressionDef = commonlib.gettable("System.Compiler.FuncExpressionDef")
----------------------------------------------------------------------
--Delete original -{}, +{} structure parser in Metalua
----------------------------------------------------------------------
nplp.expr.primary:del("+{") 
nplp.expr.suffix:del("+{")
nplp.expr.primary:del("-{")
nplp.stat:del("-{")
nplp.lexer:del("-{")	
nplp.metaDefined = {}

function nplp:new()
	local o = {
		metaDefined = {}
	}
	setmetatable (o, self)
	self.__index = self
	return o
end

--------------------------------------------------------------------------------
local function lineMode(lx)
	local i = lx.i
	local j = lx.src:find("\n", i)
	local k = lx.src:find("}", i)
	--printf("line number is %s", lx.line)        --TODO:line number needs modification
	local ast = {lineinfo={first={lx.line}}}
	if not k then
		error("} expected")
	elseif not j then
		lx.i = k 
		return {tag="Line", lx.src:sub(i, k-1), lineinfo={first={lx.line}}}
	end

	while j and j < k do
		table.insert(ast, {tag="Line", lx.src:sub(i, j-1), lineinfo={first={lx.line}}})
		i = j+1
		lx.line = lx.line+1
		j = lx.src:find("\n", i)
	end
	if i < k then table.insert(ast, {tag="Line", lx.src:sub(i, k-1)}) end
	lx.i = k
	--table.print(ast, 60, "nohash")
	--print(ast.lineinfo.first[1])
	return ast
end

local function tokenMode(lx)
	local ast = {}
	print("in tokenmode")
	while not lx:is_keyword(lx:peek(), "}") and lx:peek().tag ~= "Eof" do
		table.insert(ast, lx:next())
		table.print(lx:peek())
	end
	--table.print(ast)
	return ast
end

function nplp:getBuilder(funcExpr)
	local blkParser, builder
	if funcExpr.mode == "stricted" then
		blkParser = nplp.block
		builder = function(x)
			--print(x[2].lineinfo.first[1])
			local ast = AST:new(x[1], funcExpr.mode, x[2])
			ast:setSymTbl(funcExpr.symTbl)
			local src = funcExpr:Compile(ast)
			return self:src_to_ast_raw(src)    -- recursively translate nested custom functions
		end
	elseif funcExpr.mode == "line" then
		blkParser = lineMode
		builder = function(x)
			--print(x[2].lineinfo.first[1])
			local ast = AST:new(x[1], funcExpr.mode, x[2])
			ast:setSymTbl(funcExpr.symTbl)
			local src = funcExpr:Compile(ast)
			return self:src_to_ast_raw(src)    -- recursively translate nested custom functions
		end
	elseif funcExpr.mode == "token" then
		blkParser = tokenMode
		builder = nil
	end
	return blkParser, builder
end

function nplp:register (funcExpr)
	local name = funcExpr:getName()
	--printf("registering : %s", name)
	if not self.metaDefined then self.metaDefined = {} end
	self.metaDefined[name] = funcExpr

	local blkParser, builder = self:getBuilder(funcExpr)
	nplp.lexer:add(name)
    nplp.stat:add({name, "(", nplp.func_args_content, ")", "{", blkParser, "}", builder=builder})
end


--------------------------------------------------------------------------------
local function defMode(lx)
	local previous_i = lx.i
	lx.i = lx.src:match (lx.patterns.spaces, lx.i)
	while true do
		previous_i = lx.src :find ("\n", previous_i+1, true)
        if not previous_i or previous_i> lx.i then break end 
		lx.line = lx.line+1
	end
	local pattern = "^%-%-mode:([^\n]*)\n()"
	local mode, i = lx.src:match(pattern, lx.i)
	if mode then 
		--printf("mode is : %s", mode)
		if i then lx.i, lx.line = i, lx.line+1 end
	else
		mode = "stricted"
	end
	return mode
end

local function defBlock(lx)
	local i = lx.i
	local ast = {}
	local bracket_stack = {false}
	local in_string = false
	local string_left 
	local current_chunk = {}
	while i <= lx.src:len() do  -- avoid dead loop
		local c = lx.src:sub(i, i)
		--printf("current char: %s", c)
		local c_next = lx.src:sub(i+1, i+1)
		if c=="+" and c_next == "{" and not in_string then
			if #current_chunk > 0 then
				table.insert(ast, {tag="Raw", table.concat(current_chunk)})  --FIXME:not 100% Raw here
				current_chunk = {}
			end
			table.insert(bracket_stack, true)
			i=i+2
		elseif c == "{" and not in_string then 
			table.insert(bracket_stack, false)
			table.insert(current_chunk, c)
			i=i+1
		elseif c == "}" and not in_string then
			if(bracket_stack[#bracket_stack]) then
				if #current_chunk > 0 then
					table.insert(ast, {tag="Slice", table.concat(current_chunk)})
				end
				current_chunk = {}
				table.remove(bracket_stack)
				i=i+1
			else 
				table.remove(bracket_stack)
				if #bracket_stack == 0 then
					if #current_chunk > 0 then
						table.insert(ast, {tag="Raw", table.concat(current_chunk)})
					end
					break
				end
				table.insert(current_chunk, c)
				i=i+1
			end
		elseif c == "p" and lx.src:sub(i, i+6) == "params(" and not in_string then	-- FIXME:transform id to string, in order to call params() properly
			table.insert(current_chunk, lx.src:sub(i, i+6)..'"')
			i = i+string.len("params(")
			local prev_i = i
			while lx.src:sub(i, i) ~= ")" do
				i = i+1
			end
			table.insert(current_chunk, lx.src:sub(prev_i, i-1)..'"'..")")
			i=i+1
		elseif c == '"' or c == "'" then
			if not in_string then
				in_string = true
				string_left = c
			elseif c == string_left and lx.src:sub(i-1, i-1) ~= "\\" then
				in_string = false	
			end
			table.insert(current_chunk, c)
			i=i+1
		elseif c == "[" and lx.src:sub(i+1, i+1) == "["  and not in_string then
			in_string = true
			string_left = "[["
			table.insert(current_chunk, "[[")
			i=i+2
		elseif c == "]" and lx.src:sub(i+1, i+1) == "]"  and in_string and string_left == "[[" then
			in_string = false
			table.insert(current_chunk, "]]")
			i=i+2
		elseif c == "\n" then
			lx.line = lx.line + 1
			i=i+1
		else
			table.insert(current_chunk, c)
			i=i+1
		end
	end
	lx.i=i
	return ast
end

function nplp:defBuilder()
	return function(x)
		local funcDef = FuncExpressionDef:new()
		local f = funcDef:buildFunc(AST:new(x[1], x[2], x[3]))
		self:register(f)
		end
end
--------------------------------------------------------------------------------
function nplp.string (lx)
   local a = lx:peek()
   if a.tag == "String" then return lx:next()
   else gg.parse_error (lx, "String expected") end
end

nplp.id_list = gg.list{name="params",
   nplp.id ,
   separators  = ",", terminators = ")"}

local function defParams (lx) 
	local res = {}
	local name = nplp.string (lx)
	table.insert(res, name)
	local a = lx:peek()
	if lx:is_keyword(a, ')') then
	elseif lx:is_keyword(a, ',') then
		lx:next() -- skip ','
		local b = lx:peek()
		if lx:is_keyword(b, '...') then
		    lx:next()
			table.insert(res, {tag="Dots"})
		else
			local params = nplp.id_list (lx)
			for i=1, #params do
				table.insert(res, params[i])
			end
		end
	else
		gg.parse_error(lx, "unexpected token in def parameters")
	end
	return res
end
--------------------------------------------------------------------------------
-- Add def structure to parser
--------------------------------------------------------------------------------
function nplp:construct()
	nplp.lexer:add("def")
	nplp.stat:add({"def", "(", defParams, ")", "{", defMode, defBlock, "}", builder=self:defBuilder()})
end

function nplp:deconstruct()
	nplp.stat:del("def")
end

--------------------------------------------------------------------------------
-- set environment before parsing
--------------------------------------------------------------------------------
function nplp:setEnv()
	self:construct()
	for name, funcExpr in pairs(self.metaDefined) do 
		--printf("in set env: %s", name)
		local blkParser, builder = self:getBuilder(funcExpr)
		nplp.lexer:add(name)
		nplp.stat:add({name, "(", nplp.func_args_content, ")", "{", blkParser, "}", builder=builder})
	end
end

--------------------------------------------------------------------------------
-- clear environment after parsing
--------------------------------------------------------------------------------
function nplp:clearEnv()
	for name, v in pairs(self.metaDefined) do 
		--printf("in clear env: %s", name)
		nplp.lexer:del(name)
		nplp.stat:del(name)
	end
	self:deconstruct()
end
--------------------------------------------------------------------------------
-- Parse src code and translate to ast
--------------------------------------------------------------------------------
function nplp:src_to_ast(src)
	self:setEnv()
	local  lx  = nplp.lexer:newstream (src)
	local  ast = nplp.chunk (lx)
	self:clearEnv()
	return ast
end

function nplp:src_to_ast_raw(src)
	local  lx  = nplp.lexer:newstream (src)
	local  ast = nplp.chunk (lx)
	return ast
end

---------------------------------
