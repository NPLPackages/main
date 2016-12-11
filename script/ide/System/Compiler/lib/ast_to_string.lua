--------------------------------------------------------------------------------
-- Borrowed from Metalua project
-- Rewrite in pure lua
-- Edited By: Zhiyuan
-- Date: 2016-12-11
--------------------------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/table2.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/base.lua");
local M = { }
M.__index = M

ast_to_string = function(x) return M.run(x) end

--------------------------------------------------------------------------------
-- Instanciate a new AST->source synthetizer
--------------------------------------------------------------------------------
function M.new ()
   local self = {
      _acc           = { },  -- Accumulates pieces of source as strings
      current_indent = 0,    -- Current level of line indentation
      indent_step    = "   " -- Indentation symbol, normally spaces or '\t'
   }
   return setmetatable (self, M)
end

--------------------------------------------------------------------------------
-- Run a synthetizer on the `ast' arg and return the source as a string.
-- Can also be used as a static method `M.run (ast)'; in this case,
-- a temporary Metizer is instanciated on the fly.
--------------------------------------------------------------------------------
function M:run (ast)
   if not ast then
      self, ast = M.new(), self
   end
   self._acc = { }
   self:node (ast)
   return table.concat (self._acc)
end

--------------------------------------------------------------------------------
-- Accumulate a piece of source file in the synthetizer.
--------------------------------------------------------------------------------
function M:acc (x)
   if x then table.insert (self._acc, x) end
end

--------------------------------------------------------------------------------
-- Accumulate an indented newline.
-- Jumps an extra line if indentation is 0, so that
-- toplevel definitions are separated by an extra empty line.
--------------------------------------------------------------------------------
function M:nl ()
   if self.current_indent == 0 then self:acc "\n"  end
   self:acc ("\n" .. self.indent_step:rep (self.current_indent))
end

--------------------------------------------------------------------------------
-- Increase indentation and accumulate a new line.
--------------------------------------------------------------------------------
function M:nlindent ()
   self.current_indent = self.current_indent + 1
   self:nl ()
end

--------------------------------------------------------------------------------
-- Decrease indentation and accumulate a new line.
--------------------------------------------------------------------------------
function M:nldedent ()
   self.current_indent = self.current_indent - 1
   self:acc ("\n" .. self.indent_step:rep (self.current_indent))
end

--------------------------------------------------------------------------------
-- Keywords, which are illegal as identifiers.
--------------------------------------------------------------------------------
local keywords = table.transpose {
   "and",    "break",   "do",    "else",   "elseif",
   "end",    "false",   "for",   "function", "if",
   "in",     "local",   "nil",   "not",    "or",
   "repeat", "return",  "then",  "true",   "until",
   "while" }

--------------------------------------------------------------------------------
-- Return true iff string `id' is a legal identifier name.
--------------------------------------------------------------------------------
local function is_ident (id)
   return id:strmatch "^[%a_][%w_]*$" and not keywords[id]
end

--------------------------------------------------------------------------------
-- Return true iff ast represents a legal function name for
-- syntax sugar ``function foo.bar.gnat() ... end'':
-- a series of nested string indexes, with an identifier as
-- the innermost node.
--------------------------------------------------------------------------------
--local function is_idx_stack (ast)
   --match ast with
   --| `Id{ _ }                     -> return true
   --| `Index{ left, `String{ _ } } -> return is_idx_stack (left)
   --| _                            -> return false
   --end
--end

local function is_idx_stack (ast)
	if ast.tag == 'Id' then return true
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
   { "unary", "not", "len" },
   { "pow" },
   { "index" } }

--------------------------------------------------------------------------------
-- operator --> precedence table, generated from op_preprec.
--------------------------------------------------------------------------------
local op_prec = { }

for prec, ops in ipairs (op_preprec) do
   for op in ivalues (ops) do
      op_prec[op] = prec
   end
end

--------------------------------------------------------------------------------
-- operator --> source representation.
--------------------------------------------------------------------------------
local op_symbol = {
   add    = " + ",   sub     = " - ",   mul     = " * ",
   div    = " / ",   mod     = " % ",   pow     = " ^ ",
   concat = " .. ",  eq      = " == ",  ne      = " ~= ",
   lt     = " < ",   le      = " <= ",  ["and"] = " and ",
   ["or"] = " or ",  ["not"] = "not ",  len     = "# " }

--------------------------------------------------------------------------------
-- Accumulate the source representation of AST `node' in
-- the synthetizer. Most of the work is done by delegating to
-- the method having the name of the AST tag.
-- If something can't be converted to normal sources, it's
-- instead dumped as a `-{ ... }' splice in the source accumulator.
--------------------------------------------------------------------------------
function M:node (node)
   assert (self~=M and self._acc)
   if not node.tag then -- tagless block.
      self:list (node, self.nl)
   else
      local f = M[node.tag]
      if type (f) == "function" then -- Delegate to tag method.
         f (self, node, unpack (node))
      elseif type (f) == "string" then -- tag string.
         self:acc (f)
      else -- No appropriate method, fall back to splice dumping.
           -- This cannot happen in a plain Lua AST.
         self:acc " -{ "
         self:acc (table.tostring (node, "nohash"), 80)
         self:acc " }"
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
function M:list (list, sep, start)
   for i = start or 1, # list do
      self:node (list[i])
	  --print("in List")
      if list[i + 1] then
         if not sep then            
         elseif type (sep) == "function" then sep (self)
         elseif type (sep) == "string"   then self:acc (sep)
         else   error "Invalid list separator" end
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

function M:Do (node)
   self:acc      "do"
   self:nlindent ()
   self:list     (node, self.nl)
   self:nldedent ()
   self:acc      "end"
end

function M:Set (node)
   --match node with
   --| `Set{ { `Index{ lhs, `String{ method } } }, 
           --{ `Function{ { `Id "self", ... } == params, body } } } 
         --if is_idx_stack (lhs) and is_ident (method) ->
      -- ``function foo:bar(...) ... end'' --
	if  type(node[1][1]) == 'table'
		and node[1][1].tag == 'Index' 
		and type(node[2][1]) == 'table'
		and node[2][1].tag == 'Function' 
		and node[2][1][1][1] == 'self' 
		and is_idx_stack(node[1][1][1])
		and is_ident(node[1][1][2][1]) then
	
	  print("in case 1")
	  local lhs = node[1][1][1]
	  local method = node[1][1][2][1]
	  local params = node[2][1]
	  local body = node[2][2]
	  self:acc      "function "
      self:node     (lhs)
      self:acc      ":"
      self:acc      (method)
      self:acc      " ("
      self:list     (params, ", ", 2)
      self:acc      ")"
      self:nlindent ()
      self:list     (body, self.nl)
      self:nldedent ()
      self:acc      "end"

 --  | `Set{ { lhs }, { `Function{ params, body } } } if is_idx_stack (lhs) ->
	elseif type(node[2][1]) == 'table'
		and node[2][1].tag == 'Function' 
		and is_idx_stack(node[1][1]) then
      -- ``function foo(...) ... end'' --
	  print("in case 2")
	  local lhs = node[1][1]
	  local params = node[2][1][1]
	  local body = node[2][1][2]
      self:acc      "function "
      self:node     (lhs)
      self:acc      " ("
      self:list     (params, ", ")
      self:acc      ")"
      self:nlindent ()
      self:list    (body, self.nl)
      self:nldedent ()
      self:acc      "end"

 --  | `Set{ { `Id{ lhs1name } == lhs1, ... } == lhs, rhs } 
 --        if not is_ident (lhs1name) ->
     elseif node[1][1][1] and not is_ident(node[1][1][1]) then
	  -- ``foo, ... = ...'' when foo is *not* a valid identifier.
      -- In that case, the spliced 1st variable must get parentheses,
      -- to be distinguished from a statement splice.
      -- This cannot happen in a plain Lua AST.
	    print("in case 3")
		local lhs1 = node[1][1]
		local lhs = node[1]
		local rhs = node[2]
		self:acc      "("
		self:node     (lhs1)
		self:acc      ")"
		if lhs[2] then -- more than one lhs variable
			 self:acc   ", "
			 self:list  (lhs, ", ", 2)
		end
		self:acc      " = "
		self:list     (rhs, ", ")

  -- | `Set{ lhs, rhs } ->
     elseif #node == 2 then 
	  -- ``... = ...'', no syntax sugar --
		print("in final else")
		local lhs = node[1]
		local rhs = node[2]
		self:list  (lhs, ", ")
		self:acc   " = "
		self:list  (rhs, ", ")
	end
end

function M:While (node, cond, body)
   self:acc      "while "
   self:node     (cond)
   self:acc      " do"
   self:nlindent ()
   self:list     (body, self.nl)
   self:nldedent ()
   self:acc      "end"
end

function M:Repeat (node, body, cond)
   self:acc      "repeat"
   self:nlindent ()
   self:list     (body, self.nl)
   self:nldedent ()
   self:acc      "until "
   self:node     (cond)
end

function M:If (node)
   for i = 1, #node-1, 2 do
      -- for each ``if/then'' and ``elseif/then'' pair --
      local cond, body = node[i], node[i+1]
      self:acc      (i==1 and "if " or "elseif ")
      self:node     (cond)
      self:acc      " then"
      self:nlindent ()
      self:list     (body, self.nl)
      self:nldedent ()
   end
   -- odd number of children --> last one is an `else' clause --
   if #node%2 == 1 then 
      self:acc      "else"
      self:nlindent ()
      self:list     (node[#node], self.nl)
      self:nldedent ()
   end
   self:acc "end"
end

function M:Fornum (node, var, first, last)
   local body = node[#node]
   self:acc      "for "
   self:node     (var)
   self:acc      " = "
   self:node     (first)
   self:acc      ", "
   self:node     (last)
   if #node==5 then -- 5 children --> child #4 is a step increment.
      self:acc   ", "
      self:node  (node[4])
   end
   self:acc      " do"
   self:nlindent ()
   self:list     (body, self.nl)
   self:nldedent ()
   self:acc      "end"
end

function M:Forin (node, vars, generators, body)
   self:acc      "for "
   self:list     (vars, ", ")
   self:acc      " in "
   self:list     (generators, ", ")
   self:acc      " do"
   self:nlindent ()
   self:list     (body, self.nl)
   self:nldedent ()
   self:acc      "end"
end

function M:Local (node, lhs, rhs)
   if next (lhs) then
      self:acc     "local "
      self:list    (lhs, ", ")
      if rhs[1] then
         self:acc  " = "
         self:list (rhs, ", ")
      end
   else -- Can't create a local statement with 0 variables in plain Lua
      self:acc (table.tostring (node, 'nohash', 80))
   end
end

function M:Localrec (node, lhs, rhs)
   --match node with
   --| `Localrec{ { `Id{name} }, { `Function{ params, body } } }
         --if is_ident (name) ->
	if node[1][1].tag == 'Id' 
		and node[2][1].tag == 'Function' then
      -- ``local function name() ... end'' --
      local name = node[1][1][1]
	  local params = node[2][1][1]
	  local body = node[2][1][2]
	  self:acc      "local function "
      self:acc      (name)
      self:acc      " ("
      self:list     (params, ", ")
      self:acc      ")"
      self:nlindent ()
      self:list     (body, self.nl)
      self:nldedent ()
      self:acc      "end"

   else
      -- Other localrec are unprintable ==> splice them --
          -- This cannot happen in a plain Lua AST. --
      self:acc "-{ "
      self:acc (table.tostring (node, 'nohash', 80))
      self:acc " }"
   end
end

function M:Call (node, f)
   -- single string or table literal arg ==> no need for parentheses. --
   local parens
   --match node with
   --| `Call{ _, `String{_} }
   --| `Call{ _, `Table{...}} -> parens = false
   --| _ -> parens = true
   --end

	if node[2].tag == 'String' or node[2].tag == 'Table' then
		parens = false
	else parens = true
	end
	self:node (f)
	self:acc  (parens and " (" or  " ")
	self:list (node, ", ", 2) -- skip `f'.
	self:acc  (parens and ")")
end

function M:Invoke (node, f, method)
   -- single string or table literal arg ==> no need for parentheses. --
   local parens
   --match node with
   --| `Invoke{ _, _, `String{_} }
   --| `Invoke{ _, _, `Table{...}} -> parens = false
   --| _ -> parens = true
   --end

	if node[3].tag == 'String' or node[3].tag == 'Table' then
		parens = false
	else parens = true
	end
	self:node   (f)
	self:acc    ":"
	self:acc    (method[1])
	self:acc    (parens and " (" or  " ")
	self:list   (node, ", ", 3) -- Skip args #1 and #2, object and method name.
	self:acc    (parens and ")")
end

function M:Return (node)
   self:acc  "return "
   self:list (node, ", ")
end

M.Break = "break"
M.Nil   = "nil"
M.False = "false"
M.True  = "true"
M.Dots  = "..."

function M:Number (node, n)
   self:acc (tostring (n))
end

function M:String (node, str)
   -- format "%q" prints '\n' in an umpractical way IMO,
   -- so this is fixed with the :gsub( ) call.
   self:acc (string.format ("%q", str):gsub ("\\\n", "\\n"))
end

function M:Function (node, params, body)
   self:acc      "function ("
   self:list     (params, ", ")
   self:acc      ")"
   self:nlindent ()
   self:list     (body, self.nl)
   self:nldedent ()
   self:acc      "end"
end

function M:Table (node)
   if not node[1] then self:acc "{ }" else
      self:acc "{"
      if #node > 1 then self:nlindent () else self:acc " " end
      for i, elem in ipairs (node) do
         --match elem with
         --| `Pair{ `String{ key }, value } if is_ident (key) ->
            if elem.tag == 'Pair' 
				and elem[1].tag == 'String' 
				and is_ident(elem[1][1]) then
			---- ``key = value''. --
				local key = elem[1][1]
				local value = elem[2]
				self:acc  (key)
				self:acc  " = "
				self:node (value)
--
         --| `Pair{ key, value } ->
            ---- ``[key] = value''. --
			elseif elem.tag == 'Pair' then
				local key = elem[1]
				local value = elem[2]
				self:acc  "["
				self:node (key)
				self:acc  "] = "
				self:node (value)
--
         --| _ -> 
            ---- ``value''. --
			else
				self:node (elem)
			end
         --end



			
         if node [i+1] then
            self:acc ","
            self:nl  ()
         end
      end
      if #node > 1 then self:nldedent () else self:acc " " end
      self:acc       "}"
   end
end

function M:Op (node, op, a, b)
   -- Transform ``not (a == b)'' into ``a ~= b''. --
   --match node with
   --| `Op{ "not", `Op{ "eq", _a, _b } }
   --| `Op{ "not", `Paren{ `Op{ "eq", _a, _b } } } ->  
      --op, a, b = "ne", _a, _b
   --| _ ->
   --end

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
      --match a with
      --| `Op{ op_a, ...} if op_prec[op] >= op_prec[op_a] -> left_paren = true
      --| _ -> left_paren = false
      --end

	  if a.tag == 'Op' and op_prec[op] >= op_prec[a[1]] then
			left_paren = true
	  else
			left_paren = false
	  end
      --match b with -- FIXME: might not work with right assoc operators ^ and ..
      --| `Op{ op_b, ...} if op_prec[op] >= op_prec[op_b] -> right_paren = true
      --| _ -> right_paren = false
      --end

	  if b.tag == 'Op' and op_prec[op] >= op_prec[b[1]] then
			right_paren = true
	  else
			right_paren = false
	  end

      self:acc  (left_paren and "(")
      self:node (a)
      self:acc  (left_paren and ")")

      self:acc  (op_symbol [op])

      self:acc  (right_paren and "(")
      self:node (b)
      self:acc  (right_paren and ")")

   else -- unary operator.     
      local paren
      --match a with
      --| `Op{ op_a, ... } if op_prec[op] >= op_prec[op_a] -> paren = true
      --| _ -> paren = false
      --end
	  if a.tag == 'Op' and op_prec[op] >= op_prec[a[1]] then
			paren = true
	  else
			paren = false
	  end
      self:acc  (op_symbol[op])
      self:acc  (paren and "(")
      self:node (a)
      self:acc  (paren and ")")
   end
end

function M:Paren (node, content)
   self:acc  "("
   self:node (content)
   self:acc  ")"
end

function M:Index (node, table, key)
   local paren_table
   -- Check precedence, see if parens are needed around the table --
   --match table with
   --| `Op{ op, ... } if op_prec[op] < op_prec.index -> paren_table = true
   --| _ -> paren_table = false
   --end

   if table.tag == 'Op' and op_prec[op] < op_prec.index then
		paren_table = true
   else
		paren_table = false
   end

   self:acc  (paren_table and "(")
   self:node (table)
   self:acc  (paren_table and ")")

   --match key with
   --| `String{ field } if is_ident (field) -> 
   if key.tag == 'String' and is_ident(key[1]) then
      -- ``table.key''. --
      self:acc "."
      self:acc (field)
   else
      -- ``table [key]''. --
      self:acc   "["
      self:node (key)
      self:acc   "]"
   end
end

function M:Id (node, name)
   if is_ident (name) then
      self:acc (name)
   else -- Unprintable identifier, fall back to splice representation.
        -- This cannot happen in a plain Lua AST.
      self:acc    "-{`Id "
      self:String (node, name)
      self:acc    "}"
   end 
end


