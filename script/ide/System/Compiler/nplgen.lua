--[[ NPL code generator
Edited By: Zhiyuan, LiXizhi
Borrowed from Metalua project
Date: 2016-12-11
Desc: Rewrite in pure lua/npl
-------------------------------
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");
local nplgen = commonlib.gettable("System.Compiler.nplgen")
local gen = nplgen:new()
gen:SetIgnoreNewLine(true)
echo(gen:run(ast))
-------------------------------
]]
NPL.load("(gl)script/ide/System/Compiler/lib/util.lua");
local util = commonlib.gettable("System.Compiler.lib.util")
local nplgen = commonlib.inherit(nil, commonlib.gettable("System.Compiler.nplgen"))

function nplgen:ctor()
	self._acc = { }; -- Accumulates pieces of source as strings
	self.current_indent = 0; -- Current level of line indentation
	self.indent_step = "    "; -- Indentation symbol, normally spaces or '\t'
	self.current_line = 1;  -- Current line number
	self.ignore_newline = false; -- ignore multiple new lines when generating code. 
end

function nplgen:SetIgnoreNewLine(bIgnore)
	self.ignore_newline = bIgnore;
end

-- static function: prefer using nplgen.run
function nplgen.ast_to_str(x) 
	return nplgen.run(x) 
end

--------------------------------------------------------------------------------
-- Run a synthetizer on the `ast' arg and return the source as a string.
-- Can also be used as a static method `nplgen.run (ast)'; in this case,
-- a temporary Metizer is instanciated on the fly.
--------------------------------------------------------------------------------
function nplgen:run(ast)
	if not ast then
		self, ast = nplgen:new(), self
	end
	self._acc = { }
	self:node(ast)
	local code = table.concat(self._acc)
	return code;
end

--------------------------------------------------------------------------------
-- Accumulate a piece of source file in the synthetizer.
--------------------------------------------------------------------------------
function nplgen:acc(x)
	if x then table.insert(self._acc, x) end
end

--------------------------------------------------------------------------------
-- Accumulate an indented newline.
-- Jumps an extra line if indentation is 0, so that
-- toplevel definitions are separated by an extra empty line.
--------------------------------------------------------------------------------
function nplgen:nl()
	if self.current_indent == 0 then self:acc "\n" end
	self:acc("\n" .. self.indent_step:rep(self.current_indent))
end

--------------------------------------------------------------------------------
-- Increase indentation and accumulate a new line.
--------------------------------------------------------------------------------
function nplgen:nlindent()
	self.current_indent = self.current_indent + 1
	self:nl()
end

--------------------------------------------------------------------------------
-- Decrease indentation and accumulate a new line.
--------------------------------------------------------------------------------
function nplgen:nldedent()
	self.current_indent = self.current_indent - 1
	self:acc("\n" .. self.indent_step:rep(self.current_indent))
end

--------------------------------------------------------------------------------
-- Go to the line.
--------------------------------------------------------------------------------
function nplgen:goHead(node)
	local dst_line = 0
	if node.lineinfo and node.lineinfo.first then
		dst_line = node.lineinfo.first[1]
	end
	if(self.ignore_newline) then
		if(self.current_line >= dst_line - 1) then
			self:acc("\n")
		end
	else

		for i = self.current_line, dst_line - 1 do
			self:acc("\n")
		end
	end
	self.current_line = dst_line
end

function nplgen:goTail(node)
	local dst_line = 0
	if node.lineinfo and node.lineinfo.last then
		dst_line = node.lineinfo.last[1]
	end

	if(self.ignore_newline) then
		if(self.current_line >= dst_line - 1) then
			self:acc("\n")
		end
	else
		for i = self.current_line, dst_line - 1 do
			self:acc("\n")
		end
	end
	self.current_line = dst_line
end

--------------------------------------------------------------------------------
-- Keywords, which are illegal as identifiers.
--------------------------------------------------------------------------------
local keywords = util.table_transpose {
"and", "break", "do", "else", "elseif",
"end", "false", "for", "function", "if",
"in", "local", "nil", "not", "or",
"repeat", "return", "then", "true", "until",
"while", "goto" }

--------------------------------------------------------------------------------
-- Return true iff string `id' is a legal identifier name.
--------------------------------------------------------------------------------
local function is_ident(id)
	return id:match "^[%a_][%w_]*$" 
end


--------------------------------------------------------------------------------
-- Return true iff ast represents a legal function name for
-- syntax sugar ``function foo.bar.gnat() ... end'':
-- a series of nested string indexes, with an identifier as
-- the innermost node.
--------------------------------------------------------------------------------
local function is_idx_stack(ast)
	if ast.tag == 'Id' then return true
    elseif ast.tag == 'Keyword' then return true
	elseif ast.tag == 'Index' then return is_idx_stack(ast[1])
	else return false
	end
end

--------------------------------------------------------------------------------
-- Operator precedences, in increasing order.
-- This is not directly used, it's used to generate op_prec below.
--------------------------------------------------------------------------------
local op_preprec = {
{ "or", "and" },
{ "lt", "le", "eq", "ne" },
{ "concat" }, 
{ "add", "sub" },
{ "mul", "div", "mod" },
{ "unm", "not", "len" },
{ "pow" },
{ "index" } }

--------------------------------------------------------------------------------
-- operator --> precedence table, generated from op_preprec.
--------------------------------------------------------------------------------
local op_prec = { }

for prec, ops in ipairs(op_preprec) do
	for op in util.ivalues(ops) do
		op_prec[op] = prec
	end
end

--------------------------------------------------------------------------------
-- operator --> source representation.
--------------------------------------------------------------------------------
local op_symbol = {
add = " + ", sub = " - ", mul = " * ",
div = " / ", mod = " % ", pow = " ^ ",
concat = " .. ", eq = " == ", ne = " ~= ",
lt = " < ", le = " <= ",["and"] = " and ",
["or"] = " or ",["not"] = "not ", len = "# " , unm = "-"}

--------------------------------------------------------------------------------
-- Accumulate the source representation of AST `node' in
-- the synthetizer. Most of the work is done by delegating to
-- the method having the name of the AST tag.
-- If something can't be converted to normal sources, it's
-- instead dumped as a `-{ ... }' splice in the source accumulator.
--------------------------------------------------------------------------------
function nplgen:node(node)
	assert(self~=nplgen and self._acc)
	if not node.tag then -- tagless block.
		self:list(node, " ") -- space as line sperator
	else
		local f;
        if node.tag == 'Keyword' then   -- Handle Keyword as string
            f = node[1]
        else
            f = nplgen[node.tag]
        end
		if type(f) == "function" then -- Delegate to tag method.
			f(self, node, unpack(node))
		elseif type(f) == "string" then -- tag string.
			self:acc(f)
		else -- No appropriate method, fall back to splice dumping.
		-- This cannot happen in a plain Lua AST.
		--self:acc " -{ "
		--self:acc (util.table_tostring (node, "nohash"), 80)
		--self:acc " }"
		end
	end
end

--------------------------------------------------------------------------------
-- Convert every node in the AST list `list' passed as 1st arg.
-- `sep' is an optional separator to be accumulated between each list element,
-- it can be a string or a synth method.
-- `start' is an optional number (default == 1), indicating which is the
-- first element of list to be converted, so that we can skip the begining
-- of a list. 
--------------------------------------------------------------------------------
function nplgen:list(list, sep, start)
	for i = start or 1, # list do
		self:node(list[i])
		--print("in List")
		if list[i + 1] then
			if not sep then            
			elseif type(sep) == "function" then sep(self)
			elseif type(sep) == "string" then self:acc(sep)
			else error "Invalid list separator" end
		end
	end
end

--------------------------------------------------------------------------------
--
-- Tag methods.
-- ------------
--
-- Specific AST node dumping methods, associated to their node kinds
-- by their name, which is the corresponding AST tag.
-- synth:node() is in charge of delegating a node's treatment to the
-- appropriate tag method.
--
-- Such tag methods are called with the AST node as 1st arg.
-- As a convenience, the n node's children are passed as args #2 ... n+1.
--
-- There are several things that could be refactored into common subroutines
-- here: statement blocks dumping, function dumping...
-- However, given their small size and linear execution
-- (they basically perform series of :acc(), :node(), :list(), 
-- :nl(), :nlindent() and :nldedent() calls), it seems more readable
-- to avoid multiplication of such tiny functions.
--
-- To make sense out of these, you need to know metalua's AST syntax, as
-- found in the reference manual or in metalua/doc/ast.txt.
--
--------------------------------------------------------------------------------

function nplgen:Do(node)
	self:goHead(node)
	self:acc "do"
	self:acc " "
	self:list(node, " ")
	self:acc " "
	self:goTail(node)
	self:acc "end"
end

function nplgen:Set(node)
	do
		-- ``... = ...'', no syntax sugar --
		local lhs = node[1]
		local rhs = node[2]
		self:goHead(node)
		self:list(lhs, ", ")
		self:acc " = "
		self:goTail(node)
		self:list(rhs, ", ")
		return
	end
	-- Note by Xizhi: following code is wrong for "a[1] = function() end"


	-- ``function foo:bar(...) ... end'' --
	if type(node[1][1]) == 'table'
	and node[1][1].tag == 'Index' 
	and type(node[2][1]) == 'table'
	and node[2][1].tag == 'Function'
    and node[2][1][1]
    and node[2][1][1][1] 
	and node[2][1][1][1][1] == 'self' 
	and is_idx_stack(node[1][1][1])
	and node[1][1][2].tag == 'String'
	and is_ident(node[1][1][2][1]) then
		
		local lhs = node[1][1][1]
		local method = node[1][1][2][1]
		local params = node[2][1][1]
		local body = node[2][1][2]
		self:goHead(node)
		self:acc "function "
		self:node(lhs)
		self:acc ":"
		self:acc(method)
		self:acc " ("
		self:list(params, ", ", 2)
		self:acc ")"
		self:acc " "
		self:list(body, " ")
		self:acc " "
		self:goTail(node)
		self:acc "end"
	
	elseif type(node[2][1]) == 'table'
	and node[2][1].tag == 'Function' 
	and is_idx_stack(node[1][1]) then
		-- ``function foo(...) ... end'' --
		local lhs = node[1][1]
		local params = node[2][1][1]
		local body = node[2][1][2]
		self:goHead(node)
		self:acc "function "
		self:node(lhs)
		self:acc " ("
		self:list(params, ", ")
		self:acc ")"
		self:acc " "
		self:list(body, " ")
		self:acc " "
		self:goTail(node)
		self:acc "end"
	
	elseif #node == 2 then 
		-- ``... = ...'', no syntax sugar --
		local lhs = node[1]
		local rhs = node[2]
		self:goHead(node)
		self:list(lhs, ", ")
		self:acc " = "
		self:goTail(node)
		self:list(rhs, ", ")
	end
end

function nplgen:While(node, cond, body)
	self:goHead(node)
	self:acc "while "
	self:node(cond)
	self:acc " do" -- TODO: put 'do' in right position
	self:acc " "
	self:list(body, " ")
	self:acc " "
	self:goTail(node)
	self:acc "end"
end

function nplgen:Repeat(node, body, cond)
	self:goHead(node)
	self:acc "repeat"
	self:acc " "
	self:list(body, " ")
	self:acc " "
	self:acc "until " -- TODO: put 'until' in right position
	self:node(cond)
end

function nplgen:If(node)
	self:goHead(node)
	for i = 1, #node - 1, 2 do
		-- for each ``if/then'' and ``elseif/then'' pair --
		local cond, body = node[i], node[i + 1]
		self:acc(i==1 and "if " or "elseif ")
		self:node(cond)
		self:acc " then" -- TODO: put 'then' in right position
		self:acc " "
		self:list(body, " ")
		self:acc " "
	end
	-- odd number of children --> last one is an `else' clause --
	if #node%2 == 1 then 
		self:acc "else" -- TODO: put 'else' in right position
		self:acc " "
		self:list(node[#node], " ")
		self:acc(" ")
	end
	self:goTail(node)
	self:acc "end"
end

function nplgen:Fornum(node, var, first, last)
	local body = node[#node]
	self:goHead(node)
	self:acc "for "
	self:node(var)
	self:acc " = "
	self:node(first)
	self:acc ", "
	self:node(last)
	if #node==5 then -- 5 children --> child #4 is a step increment.
		self:acc ", "
		self:node(node[4])
	end
	self:acc " do"
	self:acc " "
	self:list(body, " ")
	self:acc " "
	self:goTail(node)
	self:acc "end"
end

function nplgen:Forin(node, vars, generators, body)
	self:goHead(node)
	self:acc "for "
	self:list(vars, ", ")
	self:acc " in "
	self:list(generators, ", ")
	self:acc " do"
	self:acc " "
	self:list(body, " ")
	self:acc " "
	self:goTail(node)
	self:acc "end"
end

function nplgen:Local(node, lhs, rhs)
	self:goHead(node)
	--	if next (lhs) then
	self:acc "local "
	self:list(lhs, ", ")
	if rhs[1] then
		self:acc " = "
		self:list(rhs, ", ")
	end
--  end
end

function nplgen:Localrec(node, lhs, rhs)
	if node[1][1].tag == 'Id' 
	and node[2][1].tag == 'Function' then
		-- ``local function name() ... end'' --
		local name = node[1][1][1]
		local params = node[2][1][1]
		local body = node[2][1][2]
		self:goHead(node)
		self:acc "local function "
		self:acc(name)
		self:acc " ("
		self:list(params, ", ")
		self:acc ")"
		self:acc " "
		self:list(body, " ")
		self:acc " "
		self:goTail(node)
		self:acc "end"
	
	else
	-- Other localrec are unprintable ==> splice them --
	-- This cannot happen in a plain Lua AST. --
	--self:acc "-{ "
	--self:acc (util.table_tostring (node, 'nohash', 80))
	--self:acc " }"
	end
end

function nplgen:Call(node, f)
	-- Set parentheses all the time
	local parens = true
	-- single string or table literal arg ==> no need for parentheses. --
	--if #node == 2 and (node[2].tag == 'String' or node[2].tag == 'Table') then
	--parens = false
	--else parens = true
	--end
	self:goHead(node)
	self:node(f)
	self:acc(parens and "(" or " ")
	self:list(node, ", ", 2) -- skip `f'.
	--self:goTail (node)
	self:acc(parens and ")")
end

function nplgen:Invoke(node, f, method)
	-- single string or table literal arg ==> no need for parentheses. --
	local parens
	
	if #node == 3 and(node[3].tag == 'String' or node[3].tag == 'Table') then
		parens = false
	else parens = true
	end
	self:goHead(node)
	self:node(f)
	self:acc ":"
	self:acc(method[1])
	self:acc(parens and "(" or " ")
	self:list(node, ", ", 3) -- Skip args #1 and #2, object and method name.
	self:acc(parens and ")")
end

function nplgen:Return(node)
	self:goHead(node)
	self:acc "return "
	self:list(node, ", ")
end

nplgen.Break = "break"
nplgen.Nil = "nil"
nplgen.False = "false"
nplgen.True = "true"
nplgen.Dots = "..."

function nplgen:Number(node, n)
	self:acc(tostring(n))
end

function nplgen:String(node, str)
	-- format "%q" prints '\n' in an umpractical way IMO,
	-- so this is fixed with the :gsub( ) call.
	self:acc(string.format("%q", str):gsub("\\\n", "\\n"))
end

function nplgen:Function(node, params, body)
	self:goHead(node)
	self:acc "function ("
	self:list(params, ", ")
	self:acc ")"
	self:acc " "
	self:list(body, " ")
	self:acc " "
	self:goTail(node)
	self:acc "end"
end

function nplgen:Table(node)
	if not node[1] then self:acc "{ }" else
		self:acc "{"
		self:acc " "
		--if #node > 1 then self:nlindent () else self:acc " " end
		for i, elem in ipairs(node) do
			if elem.tag == 'Pair' 
			and elem[1].tag == 'String' 
			and is_ident(elem[1][1]) and not keywords[elem[1][1]] then
				---- ``key = value''. --
				local key = elem[1][1]
				local value = elem[2]
				self:acc(key)
				self:acc " = "
				self:node(value)
			
			---- ``[key] = value''. --
			elseif elem.tag == 'Pair' then
				local key = elem[1]
				local value = elem[2]
				self:acc "["
				self:node(key)
				self:acc "] = "
				self:node(value)
			
			---- ``value''. --
			else
				self:node(elem)
			end
			
			if node[i + 1] then
				self:acc ","
				self:acc " "
			end
		end
		--if #node > 1 then self:nldedent () else self:acc " " end
		self:acc " "
		self:acc "}"
	end
end

function nplgen:Op(node, op, a, b)
	-- Transform ``not (a == b)'' into ``a ~= b''. --
	if node[1] == "not"
	and node[2].tag == 'Op'
	and node[2][1] == 'eq' then
		
		local _a = node[2][2]
		local _b = node[2][3]
		op, a, b = "ne", _a, _b
	
	elseif node[1] == 'not'
	and node[2].tag == 'Paren'
	and node[2][1].tag == 'Op'
	and node[2][1][1] == 'eq' then
		
		local _a = node[2][1][2]
		local _b = node[2][1][3]
		op, a, b = "ne", _a, _b
	else
	end
	
	if b then -- binary operator.
		local left_paren, right_paren
		if a.tag == 'Op' and a[1] and op_prec[op] >= op_prec[a[1]] then
			left_paren = true
		else
			left_paren = false
		end
		
		if type(b) == 'table' and b.tag == 'Op' and b[1] and op_prec[op] >= op_prec[b[1]] then
			right_paren = true
		else
			right_paren = false
		end
		
		self:acc(left_paren and "(")
		self:node(a)
		self:acc(left_paren and ")")
		
		self:acc(op_symbol[op])
		
		self:acc(right_paren and "(")
		self:node(b)
		self:acc(right_paren and ")")
	
	else -- unary operator.     
		local paren
		
		if type(a) == 'table' and a.tag == 'Op' and a[1] and op_prec[op] >= op_prec[a[1]] then
			paren = true
		else
			paren = false
		end
		self:acc(op_symbol[op])
		self:acc(paren and "(")
		self:node(a)
		self:acc(paren and ")")
	end
end

function nplgen:Paren(node, content)
	self:acc "("
	self:node(content)
	self:acc ")"
end

function nplgen:Index(node, table, key)
	local paren_table
	-- Check precedence, see if parens are needed around the table --
	
	if table.tag == 'Op' and op_prec[op] < op_prec.index then
		paren_table = true
	else
		paren_table = false
	end
	
	self:acc(paren_table and "(")
	self:node(table)
	self:acc(paren_table and ")")
	
	if key.tag == 'String' and is_ident(key[1]) and not keywords[key[1]] then
		-- ``table.key''. --
		self:acc "."
		self:acc(key[1])
	else
		-- ``table [key]''. --
		self:acc "["
		self:node(key)
		self:acc "]"
	end
end

function nplgen:Id(node, name)
	if is_ident(name) then
		self:acc(name)
	end 
end


