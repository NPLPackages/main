----------------------------------------------------------------------
-- NPL Def Structure Block Parser
-- Extended from Metalua Parser
-- This parser is used only to parse block in def structure
-- Author:Zhiyuan
-- Date: 2016-12-16
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

local gg = commonlib.gettable("System.Compiler.lib.gg")
local nplp_def = commonlib.inherit(commonlib.gettable("System.Compiler.lib.mlp"), commonlib.gettable("System.Compiler.nplp_def"))


local function _expr (lx) return nplp_def.expr (lx)  end
local function _table_content (lx) return nplp_def.table_content (lx) end
local function _block (lx) return nplp_def.block (lx) end
local function _stat  (lx) return nplp_def.stat (lx)  end

nplp_def.expr_list = gg.list{ _expr, separators = "," }

--------------------------------------------------------------------------------
-- Helpers for function applications / method applications
--------------------------------------------------------------------------------
nplp_def.func_args_content = gg.list { 
   name = "function arguments",
   _expr, separators = ",", terminators = ")" } 

-- Used to parse methods
nplp_def.method_args = gg.multisequence{
   name = "function argument(s)",
   { "{", _table_content, "}" },
   { "(", nplp_def.func_args_content, ")", builder = nplp_def.fget(1) },
   default = function(lx) local r = nplp_def.opt_string(lx); return r and {r} or { } end }


nplp_def.func_params_content = gg.list{ name="function parameters",
   gg.multisequence{ { "...", builder = "Dots" }, default = nplp_def.id },
   separators  = ",", terminators = {")", "|"} } 

--local _func_params_content = function (lx) return func_params_content(lx) end

nplp_def.func_val = gg.sequence { name="function body",
   "(", nplp_def.func_params_content, ")", _block, "end", builder = "Function" }

--local _func_val = function (lx) return mlp.func_val (lx) end

local function opf1 (op) return 
   function (_,a) return { tag="Op", op, a } end end

local function opf2 (op) return 
   function (a,_,b) return { tag="Op", op, a, b } end end

local function opf2r (op) return 
   function (a,_,b) return { tag="Op", op, b, a } end end

local function op_ne(a, _, b) 
   return { tag="Op", "not", { tag="Op", "eq", a, b, lineinfo= {
            first = a.lineinfo.first, last = b.lineinfo.last } } }
end
   

----------------------------------------------------------------------
--quote builder
----------------------------------------------------------------------
local function quote_builder(x)
	x = unpack(x)
	if x.tag == 'Call' and x[1].tag		-- emit() function called in +{} 
		and x[1].tag == 'Id' and x[1][1] == "emit" then
		return {tag="EmitAll"}
	else
		return {tag="Quote", x}
	end
end

function nplp_def.id_or_literal (lx)
   local a = lx:next()
   if a.tag~="Id" and a.tag~="String" and a.tag~="Number" then
      gg.parse_error (lx, "Unexpected expr token %s",
                      _G.table.tostring (a, 'nohash'))
   end
   return a
end

function nplp_def.id_or_dots (lx)
   local a = lx:next()
   if a.tag == "Id" then return a
   elseif lx:is_keyword (a, "...") then return {tag="Dots"}
   else gg.parse_error (lx, "id or dots(...) is expected")
   end
end

----------------------------------------------------------------------
--expr parser redefined
----------------------------------------------------------------------
nplp_def.expr_in_quote = nplp_def.expr
nplp_def.expr_in_quote.primary:del ("+{")
function nplp_def.opt_expr_in_quote(lx)
	local a = lx:peek()
	if lx:is_keyword (a, "}")  then		-- if nothing inside +{}, treat is as nil
		return {tag="Nil"}
	elseif lx:is_keyword (a, "=") then
		lx:next() -- skip "="
		return nplp_def.id_or_dots(lx)
	else
		e = nplp_def.expr_in_quote (lx)
		if e.tag ~= 'Call' then 
			gg.parse_error(lx, " = or function call expected")
		end
		return e
	end
end

nplp_def.expr = gg.expr { name = "expression",

   primary = gg.multisequence{ name="expr primary",
      { "(", _expr, ")",           builder = 'Paren' },
      { "function", nplp_def.func_val,     builder = nplp_def.fget(1) },
      { "+{", nplp_def.opt_expr_in_quote, "}",  builder = quote_builder }, 
      { "nil",                     builder = "Nil" },
      { "true",                    builder = "True" },
      { "false",                   builder = "False" },
      { "...",                     builder = "Dots" },
      nplp_def.table,
      default = nplp_def.id_or_literal },

   infix = { name="expr infix op",
      { "+",  prec = 60, builder = opf2 "add"  },
      { "-",  prec = 60, builder = opf2 "sub"  },
      { "*",  prec = 70, builder = opf2 "mul"  },
      { "/",  prec = 70, builder = opf2 "div"  },
      { "%",  prec = 70, builder = opf2 "mod"  },
      { "^",  prec = 90, builder = opf2 "pow",    assoc = "right" },
      { "..", prec = 40, builder = opf2 "concat", assoc = "right" },
      { "==", prec = 30, builder = opf2 "eq"  },
      { "~=", prec = 30, builder = op_ne  },
      { "<",  prec = 30, builder = opf2 "lt"  },
      { "<=", prec = 30, builder = opf2 "le"  },
      { ">",  prec = 30, builder = opf2r "lt"  },
      { ">=", prec = 30, builder = opf2r "le"  },
      { "and",prec = 20, builder = opf2 "and" },
      { "or", prec = 10, builder = opf2 "or"  } },

   prefix = { name="expr prefix op",
      { "not", prec = 80, builder = opf1 "not" },
      { "#",   prec = 80, builder = opf1 "len" },
      { "-",   prec = 80, builder = opf1 "unm" } },

   suffix = { name="expr suffix op",
      { "[", _expr, "]", builder = function (tab, idx) 
         return {tag="Index", tab, idx[1]} end},
      { ".", nplp_def.id, builder = function (tab, field) 
         return {tag="Index", tab, nplp_def.id2string(field[1])} end },
      { "(", nplp_def.func_args_content, ")", builder = function(f, args) 
         return {tag="Call", f, unpack(args[1])} end },
      { "{", _table_content, "}", builder = function (f, arg)
         return {tag="Call", f, arg[1]} end},
      { ":", nplp_def.id, nplp_def.method_args, builder = function (obj, post)
         return {tag="Invoke", obj, nplp_def.id2string(post[1]), unpack(post[2])} end},
    --  { "+{", _expr, "}", builder = quote_builder },
      default = { name="opt_string_arg", parse = nplp_def.opt_string, builder = function(f, arg) 
		return {tag="Call", f, arg } end } } }

--nplp_def.expr.primary:add({"+{", nplp_def.expr, "}", builder=quote_builder})

--nplp_def.expr_list = gg.list{ nplp_def.expr, separators = "," }

--nplp_def.func_args_content = gg.list { 
   --name = "function arguments",
   --nplp_def.expr, separators = ",", terminators = ")" } 
--
--nplp_def.method_args = gg.multisequence{
   --name = "function argument(s)",
   --{ "{", nplp_def.table_content, "}" },
   --{ "(", nplp_def.func_args_content, ")", builder = nplp_def.fget(1) },
   --default = function(lx) local r = nplp_def.opt_string(lx); return r and {r} or { } end }
--
--nplp_def.func_params_content = gg.list{ name="function parameters",
   --gg.multisequence{ { "...", builder = "Dots" }, default = nplp_def.id },
   --separators  = ",", terminators = {")", "|"} } 
--
--nplp_def.func_val = gg.sequence { name="function body",
   --"(", nplp_def.func_params_content, ")", nplp_def.block, "end", builder = "Function" }

----------------------------------------------------------------------
--stat and block parser redefined
----------------------------------------------------------------------
local block_terminators = { "else", "elseif", "end", "until", ")", "}", "]" }


nplp_def.block = gg.list {
   name        = "statements block",
   terminators = block_terminators,
   primary     = function (lx)
      -- FIXME use gg.optkeyword()
      local x = _stat (lx)
      if lx:is_keyword (lx:peek(), ";") then lx:next() end
      return x
   end }


local return_expr_list_parser = gg.multisequence{
   { ";" , builder = function() return { } end }, 
   default = gg.list { 
      nplp_def.expr, separators = ",", terminators = block_terminators } }


function nplp_def.for_header (lx)
   local var = nplp_def.id (lx)
   if lx:is_keyword (lx:peek(), "=") then 
      -- Fornum: only 1 variable
      lx:next() -- skip "="
      local e = nplp_def.expr_list (lx)
      assert (2 <= #e and #e <= 3, "2 or 3 values in a fornum")
      return { tag="Fornum", var, unpack (e) }
   else
      -- Forin: there might be several vars
      local a = lx:is_keyword (lx:next(), ",", "in")
      if a=="in" then var_list = { var, lineinfo = var.lineinfo } else
         -- several vars; first "," skipped, read other vars
         var_list = gg.list{ 
            primary = nplp_def.id, separators = ",", terminators = "in" } (lx)
         _G.table.insert (var_list, 1, var) -- put back the first variable
         lx:next() -- skip "in"
      end
      local e = nplp_def.expr_list (lx)
      return { tag="Forin", var_list, e }
   end
end

local function fn_builder (list)
   local r = list[1]
   for i = 2, #list do r = { tag="Index", r, nplp_def.id2string (list[i]) } end
   return r
end
local func_name = gg.list{ nplp_def.id, separators = ".", builder = fn_builder }

local method_name = gg.onkeyword{ name = "method invocation", ":", nplp_def.id, 
   transformers = { function(x) return x and nplp_def.id2string (x) end } }

local function funcdef_builder(x)
   local name, method, func = x[1], x[2], x[3]
   if method then 
      name = { tag="Index", name, method, lineinfo = {
         first = name.lineinfo.first,
         last  = method.lineinfo.last } }
      _G.table.insert (func[1], 1, {tag="Id", "self"}) 
   end
   local r = { tag="Set", {name}, {func} } 
   r[1].lineinfo = name.lineinfo
   r[2].lineinfo = func.lineinfo
   return r
end 

local function if_builder (x)
   local cb_pairs, else_block, r = x[1], x[2], {tag="If"}
   for i=1,#cb_pairs do r[2*i-1]=cb_pairs[i][1]; r[2*i]=cb_pairs[i][2] end
   if else_block then r[#r+1] = else_block end
   return r
end 

local elseifs_parser = gg.list {
   gg.sequence { nplp_def.expr, "then", nplp_def.block },
   separators  = "elseif",
   terminators = { "else", "end" } }

local function assign_or_call_stat_parser (lx)
   local e = nplp_def.expr_list (lx)
   local a = lx:is_keyword(lx:peek())
   local op = a and nplp_def.stat.assignments[a]
   if op then
      --FIXME: check that [e] is a LHS
      lx:next()
      local v = nplp_def.expr_list (lx)
      if type(op)=="string" then return { tag=op, e, v }
      else return op (e, v) end
   else 
      assert (#e > 0)
      if #e > 1 then 
         gg.parse_error (lx, "comma is not a valid statement separator") end
      if e[1].tag ~= "Call" and e[1].tag ~= "Invoke" then
         gg.parse_error (lx, "This expression is of type '%s'; "..
            "only function and method calls make valid statements", 
            e[1].tag or "<list>")
      end
      return e[1]
   end
end

local local_stat_parser = gg.multisequence{
   -- local function <name> <func_val>
   { "function", nplp_def.id, nplp_def.func_val, builder = 
      function(x) 
         local vars = { x[1], lineinfo = x[1].lineinfo }
         local vals = { x[2], lineinfo = x[2].lineinfo }
         return { tag="Localrec", vars, vals } 
      end },
   -- local <id_list> ( = <expr_list> )?
   default = gg.sequence{ nplp_def.id_list, gg.onkeyword{ "=", nplp_def.expr_list },
      builder = function(x) return {tag="Local", x[1], x[2] or { } } end } }

--------------------------------------------------------------------------------
-- statement
--------------------------------------------------------------------------------
nplp_def.stat = gg.multisequence { 
   name="statement",
   { "do", nplp_def.block, "end", builder = 
      function (x) return { tag="Do", unpack (x[1]) } end },
   { "for", nplp_def.for_header, "do", nplp_def.block, "end", builder = 
      function (x) x[1][#x[1]+1] = x[2]; return x[1] end },
   { "function", func_name, method_name, nplp_def.func_val, builder=funcdef_builder },
   { "while", nplp_def.expr, "do", nplp_def.block, "end", builder = "While" },
   { "repeat", nplp_def.block, "until", nplp_def.expr, builder = "Repeat" },
   { "local", local_stat_parser, builder = nplp_def.fget (1) },
   { "return", return_expr_list_parser, builder = nplp_def.fget (1, "Return") },
   { "break", builder = function() return { tag="Break" } end },
   { "+{", nplp_def.expr, "}", builder = quote_builder}, 
   { "if", elseifs_parser, gg.onkeyword{ "else", nplp_def.block }, "end", 
     builder = if_builder },
   default = assign_or_call_stat_parser }

nplp_def.stat.assignments = {
   ["="] = "Set" }


----------------------------------------------------------------------
--table parser redefined
----------------------------------------------------------------------
local bracket_field = gg.sequence{ "[", nplp_def.expr, "]", "=", nplp_def.expr, builder = "Pair" }

function nplp_def.table_field (lx)
   if lx:is_keyword (lx:peek(), "[") then return bracket_field (lx) end
   local e = nplp_def.expr (lx)
   if lx:is_keyword (lx:peek(), "=") then 
      lx:next(); -- skip the "="
      local key = nplp_def.id2string (e)
      local val = nplp_def.expr (lx)
      local r = { tag="Pair", key, val } 
      r.lineinfo = { first = key.lineinfo.first, last = val.lineinfo.last }
      return r
   else return e end
end

local function _table_field (lx) return nplp_def.table_field (lx) end

nplp_def.table_content = gg.list { _table_field, 
   separators = { ",", ";" }, terminators = "}", builder = "Table" }

local function _table_content (lx) return nplp_def.table_content (lx) end

nplp_def.table = gg.sequence{ "{", _table_content, "}", builder = nplp_def.fget (1) }



