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
NPL.load("(gl)script/ide/System/Compiler/nplp_def.lua");

local gg = commonlib.gettable("System.Compiler.lib.gg")
local nplp = commonlib.inherit(commonlib.gettable("System.Compiler.lib.mlp"), commonlib.gettable("System.Compiler.nplp"))
local nplp_def = commonlib.gettable("System.Compiler.nplp_def")
local nplgen = commonlib.gettable("System.Compiler.nplgen")

----------------------------------------------------------------------
--Delete original -{}, +{} structure parser in Metalua
----------------------------------------------------------------------
nplp.expr.primary:del("+{") 
nplp.expr.suffix:del("+{")
nplp.expr.primary:del("-{")
nplp.stat:del("-{")
--nplp.lexer:del "-{"	TODO: delete "-{" keyword
nplp.metaDefined = {}

function nplp:new()
	local o = {
		metaDefined = {}
	}
	--self:construct()
	setmetatable (o, self)
	self.__index = self
	o:construct()
	return o
end

--------------------------------------------------------------------------------
-- build transformer for defined structure
--------------------------------------------------------------------------------
function nplp:transformer_maker(name)
	local template_ast = {}
	if self.metaDefined[name] then
		template_ast = self.metaDefined[name]
   	else
		print(name)
    	error("not defined symbol")
   	end

   	local function traverse_and_replace(tast, args, blk, cfg)  -- traverse template ast and replace 
   		local res_ast={}
   		if(type(tast)=='table') then
   			if tast.tag and tast.tag=='EmitAll' then 
   					--res_ast = blk
					table.insert(res_ast, blk)
					cfg.emited = true

   			elseif tast.tag and tast.tag=='Param' then
				if tast[1] == 'All' then
					res_ast=args
				elseif args[tast[1]] then
					--res_ast=args[tast[1]]
					table.insert(res_ast, args[tast[1]])
				else
					--res_ast={tag='Nil'}
					table.insert(res_ast, {tag='Nil'})
				end
			else
				local res = {}
			   	res.tag=tast.tag
				if not cfg.emited then
					res.lineinfo = {first = cfg.before, last = cfg.before}
				else
					res.lineinfo = {first = cfg.after, last = cfg.after}
				end
				for i=1, #tast do
					local r = {}
					r, cfg = traverse_and_replace(tast[i], args, blk, cfg)
					for j=1, #r do
						table.insert(res, r[j])
					end
				end
				table.insert(res_ast, res)
   			end
   		else
   			--res_ast=tast
			table.insert(res_ast, tast)
   		end
   		return res_ast, cfg
   	end

   	local function transformer(ast)
	    --table.print(ast.lineinfo.first, 60, "nohash")
		--table.print(ast.lineinfo.last, 60, "nohash")
		local cfg = {
			before = ast.lineinfo.first, 
			after = ast.lineinfo.last,
			emited = false
		}
		--table.print(ast.lineinfo.last, 60, "nohash")
   		args, blk = ast[1], ast[2]
		return traverse_and_replace(template_ast, args, blk, cfg)
   	end

   	return transformer
end

--------------------------------------------------------------------------------
-- When meet params in +{}, label them with tag `Param #
--------------------------------------------------------------------------------
function nplp:label_params(ast, symTbl)
	local res_ast = {}
	if type(ast) == 'table' then
		if ast.tag == 'Id' and symTbl[ast[1]] and self.in_a_quote_or_emit then
			res_ast.tag = 'Param'-- symTle[ast[1]] reflects ith param
			res_ast[1] = symTbl[ast[1]]
		elseif ast.tag == 'Dots' and symTbl[1] and self.in_a_quote_or_emit then
			res_ast.tag = 'Param'
			res_ast[1] = 'All'
		elseif ast.tag == 'Quote' or ast.tag == 'Emit' then
			local prev_quote = self.in_a_quote_or_emit
			if prev_quote then
				error "not support quote in a quote"
			end
			self.in_a_quote_or_emit = true
			if #ast > 1 then
				error "quote only support one expression"
			else
				res_ast = self:label_params(ast[1], symTbl)
				if ast[1].lineinfo then
					res_ast.lineinfo = ast[1].lineinfo
				end
			end
			self.in_a_quote_or_emit = prev_quote
		else
			res_ast.tag = ast.tag
			res_ast.lineinfo = ast.lineinfo
			for i=1, #ast do
				if type(ast[i]) == 'table' then
					res_ast[i] = self:label_params(ast[i], symTbl)
					res_ast[i].lineinfo = ast[i].lineinfo
				else
					res_ast[i] = ast[i]
				end
			end
		end
	else
		res_ast = ast
	end
	return res_ast
end

--------------------------------------------------------------------------------
-- register the defined structure
--------------------------------------------------------------------------------
function nplp:register (name, tempAst)
	printf("registering : ", name)
	if not self.metaDefined then self.metaDefined = {} end
	self.metaDefined[name] = tempAst
	nplp.lexer:add(name)
    nplp.stat:add{name, "(", nplp.func_args_content, ")", "{", nplp.block, "}", builder=nil, transformers={self:transformer_maker(name)}}
	nplp_def.stat:add{name, "(", nplp_def.func_args_content, ")", "{", nplp_def.block, "}", builder=nil, transformers={self:transformer_maker(name)}}
end

------------------------------------------------------------------------------------------
-- Define builder for def structure, including structure registeration, params replacement  
------------------------------------------------------------------------------------------
function nplp:defbuilder_maker()
	local def_builder = function (x)
   	local elems, blk = x[1], x[2]
	--table.print(elems, 60, "nohash")
   	if #elems > 0 then
		if(elems[1].tag ~= 'String') then
			error("name needed for def structure")
		end
      	name=elems[1][1]
		symTbl = {}
		for i=2, #elems do					-- read from second params to store as parameters for func in symbol table
			if elems[i].tag == "Id" then 
				symTbl[elems[i][1]] = i-1
			elseif elems[i].tag == "Dots" then
				table.print(elems[i], 60, "nohash")
				symTbl[1] = true           -- use a special position to store '...'
			else
				error ("def params only allow identifiers")
			end
		end
		--table.print(blk, 60, "nohash")
		self.in_a_quote_or_emit = false
		labeld_blk = self:label_params(blk, symTbl)
		--table.print(labeld_blk, 60, "nohash")
      	if type(name)=='string' then
         	self:register(name, labeld_blk)
      	elseif type(s)=='table' then
      	end
   	else
      	error("def construction error")
   	end
	end

	return def_builder
end

function nplp:def_builder(x)
   	local elems, blk = x[1], x[2]
	--table.print(elems, 60, "nohash")
   	if #elems > 0 then
		if(elems[1].tag ~= 'String') then
			error("name needed for def structure")
		end
      	name=elems[1][1]
		symTbl = {}
		for i=2, #elems do					-- read from second params to store as parameters for func in symbol table
			if elems[i].tag == "Id" then 
				symTbl[elems[i][1]] = i-1
			elseif elems[i].tag == "Dots" then
				table.print(elems[i], 60, "nohash")
				symTbl[1] = true           -- use a special position to store '...'
			else
				error ("def params only allow identifiers")
			end
		end
		--table.print(blk, 60, "nohash")
		self.in_a_quote_or_emit = false
		labeld_blk = label_params(blk, symTbl)
		--table.print(labeld_blk, 60, "nohash")
      	if type(name)=='string' then
         	self:register(name, labeld_blk)
      	elseif type(s)=='table' then
      	end
   	else
      	error("def construction error")
   	end
end

--------------------------------------------------------------------------------
-- Add def structure to parser
--------------------------------------------------------------------------------
function nplp:construct()
	nplp.lexer:add "def"
	nplp.stat:add{"def", "(", nplp_def.params, ")", "{", nplp_def.block, "}", builder=self:defbuilder_maker()}
end

function nplp:deconstruct()
	--nplp.lexer:add "def"
	nplp.stat:del("def")
end

--nplp:construct()

--------------------------------------------------------------------------------
-- set environment before parsing
--------------------------------------------------------------------------------
function nplp:setEnv()
	self:construct()
	print("in set env")
	for name, v in pairs(self.metaDefined) do 
		printf("in set env: %s", name)
		nplp.lexer:add(name)
		nplp.stat:add{name, "(", nplp.func_args_content, ")", "{", nplp.block, "}", builder=nil, transformers={self:transformer_maker(name)}}
		nplp_def.stat:add{name, "(", nplp_def.func_args_content, ")", "{", nplp_def.block, "}", builder=nil, transformers={self:transformer_maker(name)}}
	end
end

--------------------------------------------------------------------------------
-- clear environment after parsing
--------------------------------------------------------------------------------
function nplp:clearEnv()
	print("in clear env")
	for name, v in pairs(self.metaDefined) do 
		printf("in clear env: %s", name)
		nplp.lexer:del(name)
		nplp.stat:del(name)
		nplp_def.stat:del(name)
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
