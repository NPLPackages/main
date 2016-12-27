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
-- build transformer for defined structure
--------------------------------------------------------------------------------
--function nplp:transformer_maker(name)
	--local template_ast, symTbl = {}, {}
	--if self.metaDefined[name] then
		--template_ast = self.metaDefined[name].tempAst
		--symTbl = self.metaDefined[name].symTbl
   	--else
    	--error("not defined symbol")
   	--end
--
   	--local function traverse_and_replace(tast, args, blk, cfg)  -- traverse template ast and replace 
   		--local res_ast={}
   		--if(type(tast)=='table') then
   			--if tast.tag and tast.tag=='EmitAll' then 
   					----res_ast = blk
					--table.insert(res_ast, blk)
					--cfg.emited = true
   			--elseif tast.tag and tast.tag=='Param' then
				--if tast[1] and tast[1].tag == 'Dots' and symTbl[1] then
					--res_ast=args
				--elseif tast[1] and tast[1].tag == 'Id' and 
						--symTbl[tast[1][1]] and args[symTbl[tast[1][1]]] then
					--table.insert(res_ast, args[symTbl[tast[1][1]]])
				--else
					--table.insert(res_ast, {tag='Nil'})
				--end
			--elseif tast.tag and tast.tag=='Execute' then
				--local execute_src = nplgen.ast_to_str(tast[1])
				--printf("Execute src: %s", execute_src)
				--local f = loadstring(execute_src)
				----local blk_ast = AST:new(blk)
				-------------------------------------------------------
				--local e = {}
				--e.emited = false
				--e.dump = function() e.emited = true end
				--
				--setmetatable(e, {__call = function(e) e.dump() end})
				--local env = { 
					--ast = AST:new(blk),
					--emit = e,
				--}
				--------------------------------------------------------
				--setfenv(f, env)
				--f()
				--if env.emit.emited then res_ast = env.ast:getAst() end
			--else
				--local res = {}
			   	--res.tag=tast.tag
				--if not cfg.emited then
					--res.lineinfo = {first = cfg.before, last = cfg.before}
				--else
					--res.lineinfo = {first = cfg.after, last = cfg.after}
				--end
				--for i=1, #tast do
					--local r = {}
					--r, cfg = traverse_and_replace(tast[i], args, blk, cfg)
					--for j=1, #r do
						--table.insert(res, r[j])
					--end
				--end
				--table.insert(res_ast, res)
   			--end
   		--else
			--table.insert(res_ast, tast)
   		--end
   		--return res_ast, cfg
   	--end
--
   	--local function transformer(ast)
		--local cfg = {
			--before = ast.lineinfo.first, 
			--after = ast.lineinfo.last,
			--emited = false
		--}
   		--args, blk = ast[1], ast[2]
		--local local_ast = traverse_and_replace(template_ast, args, blk, cfg)
		--local res_ast = {tag="Do"}		-- wrap the generated ast with do ... end
		--res_ast.lineinfo = local_ast.lineinfo
		--res_ast[1] = local_ast
		--return res_ast
   	--end
--
   	--return transformer
--end
--
--function nplp.raw(lx)
	--local lines = {}
	--local a = lx:nextLine()
	--while a.tag ~= "LastLine" do
		--table.insert(lines, a)
		--table.print(a, 60, "nohash")
		--a = lx:nextLine()
	--end
	--table.print(a, 60, "nohash")
	--table.insert(lines, a)
	--return lines
--end
--

--------------------------------------------------------------------------------
-- register the defined structure
--------------------------------------------------------------------------------
--function nplp:register (name, tempAst, symTbl)
	--printf("registering : %s", name)
	--if not self.metaDefined then self.metaDefined = {} end
	--self.metaDefined[name] = {tempAst = tempAst, symTbl = symTbl}
	--nplp.lexer:add(name)
    --nplp.stat:add({name, "(", nplp.func_args_content, ")", "{", nplp.block, "}", builder=nil, transformers={self:transformer_maker(name)}})
	----nplp.stat:add({name, "(", nplp.func_args_content, ")", "{", nplp.raw, "}", builder=nil, transformers={self:transformer_maker(name)}})
	--nplp_def.stat:add({name, "(", nplp_def.func_args_content, ")", "{", nplp_def.block, "}", builder=nil, transformers={self:transformer_maker(name)}})
--end

------------------------------------------------------------------------------------------
-- Define builder for def structure, including structure registeration, params replacement  
------------------------------------------------------------------------------------------
--function nplp:defbuilder_maker()
	--local def_builder = function (x)
   		--local elems, mode, blk = x[1], x[2], x[3]
		--print(mode)
   		--if #elems > 0 then
			--if(elems[1].tag ~= 'String') then
				--error("name needed for def structure")
			--end
      		--name=elems[1][1]
			--symTbl = {}
			--for i=2, #elems do					-- read from second params to store as parameters for func in symbol table
				--if elems[i].tag == "Id" then 
					--symTbl[elems[i][1]] = i-1
				--elseif elems[i].tag == "Dots" then
					--symTbl[1] = true           -- use a special position to store '...'
				--else
					--error ("def params only allow identifiers")
				--end
			--end
      		--if type(name)=='string' then
         		--self:register(name, blk, symTbl)
      		--elseif type(s)=='table' then
      		--end
   		--else
      		--error("def construction error")
   		--end
	--end
--
	--return def_builder
--end
--
--
--function nplp.modeParser(lx)
	--local previous_i = lx.i
	--lx.i = lx.src:match (lx.patterns.spaces, lx.i)
	--while true do
		--previous_i = lx.src :find ("\n", previous_i+1, true)
        --if not previous_i or previous_i> lx.i then break end 
		--lx.line = lx.line+1
	--end
	--local pattern = "^%-%-mode:([^\n]*)()\n"
	--local mode, i = lx.src:match(pattern, lx.i)
	--if mode then 
		--printf("mode is : %s", mode)
		--if i then lx.i, lx.line = i, lx.line+1 end
	--else
		--mode = "stricted"
	--end
	--return mode
--end

--------------------------------------------------------------------------------
function nplp:builder(funcExpr)
	return function(x)
		local ast = AST:new(x[1], x[2])
		ast:setSymTbl(funcExpr.symTbl)
		local src = funcExpr:Compile(ast)
		return self:src_to_ast(src)	-- recursively translate nested custom functions
	end
end

function nplp:register (funcExpr)
	local name = funcExpr:getName()
	printf("registering : %s", name)
	if not self.metaDefined then self.metaDefined = {} end
	self.metaDefined[name] = funcExpr
	nplp.lexer:add(name)
    nplp.stat:add({name, "(", nplp.func_args_content, ")", "{", nplp.block, "}", builder=self:builder(funcExpr)})
end

local function defBlock(lx)
	local i = lx.i
	local ast = {}
	local bracket_stack = {false}
	local in_string = false 
	local current_chunk = {}
	while i <= lx.src:len() do  -- avoid dead loop
		local c = lx.src:sub(i, i)
		--printf("current char: %s", c)
		local c_next = lx.src:sub(i+1, i+1)
		if c=="+" and c_next == "{" then
			if #current_chunk > 0 then
				table.insert(ast, {tag="Raw", table.concat(current_chunk)})  --FIXME:not 100% Raw here
				current_chunk = {}
			end
			table.insert(bracket_stack, true)
			i=i+2
		elseif c == "{" then 
			table.insert(bracket_stack, false)
			table.insert(current_chunk, c)
			i=i+1
		elseif c == "}" then
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
		elseif c == "p" and lx.src:sub(i, i+6) == "params(" then	-- FIXME:transform id to string, in order to call params() properly
			table.insert(current_chunk, lx.src:sub(i, i+6)..'"')
			i = i+7
			local prev_i = i
			while lx.src:sub(i, i) ~= ")" do
				i = i+1
			end
			table.insert(current_chunk, lx.src:sub(prev_i, i-1)..'"'..")")
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
		a, b = x[1], x[2]
		--table.print(b, 60, "nohash")
		local funcDef = FuncExpressionDef:new()
		local f = funcDef:buildFunc(AST:new(x[1], x[2]))
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
	nplp.stat:add({"def", "(", defParams, ")", "{", defBlock, "}", builder=self:defBuilder()})
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
		printf("in set env: %s", name)
		nplp.lexer:add(name)
		nplp.stat:add({name, "(", nplp.func_args_content, ")", "{", nplp.block, "}", builder=self:builder(funcExpr)})
	end
end

--------------------------------------------------------------------------------
-- clear environment after parsing
--------------------------------------------------------------------------------
function nplp:clearEnv()
	for name, v in pairs(self.metaDefined) do 
		printf("in clear env: %s", name)
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

---------------------------------
