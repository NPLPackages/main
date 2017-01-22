----------------------------------------------------------------------
-- Metalua:  $Id: mlp_meta.lua,v 1.4 2006/11/15 09:07:50 fab13n Exp $
--
-- Summary: Meta-operations: AST quasi-quoting and splicing
--
----------------------------------------------------------------------
--
-- Copyright (c) 2006, Fabien Fleutot <metalua@gmail.com>.
--
-- This software is released under the MIT Licence, see licence.txt
-- for details.
--
----------------------------------------------------------------------


--------------------------------------------------------------------------------
--
-- Exported API:
-- * [mlp.splice_content()]
-- * [mlp.quote_content()]
--
--------------------------------------------------------------------------------

local mlp = commonlib.inherit(nil, commonlib.gettable("System.Compiler.lib.mlp"))
--------------------------------------------------------------------------------
-- External splicing: compile an AST into a chunk, load and evaluate
-- that chunk, and replace the chunk by its result (which must also be
-- an AST).
--------------------------------------------------------------------------------

function mlp.splice (ast)
   local f = mlc.function_of_ast (ast, '=splice')
   local result=f()
   return result
end

--------------------------------------------------------------------------------
-- Going from an AST to an AST representing that AST
-- the only key being lifted in this version is ["tag"]
--------------------------------------------------------------------------------
function mlp.quote (t)
   --print("QUOTING:", util.table_tostring(t, 60))
   local cases = { }
   function cases.table (t)
      local mt = { tag = "Table" }
      --table.insert (mt, { tag = "Pair", quote "quote", { tag = "True" } })
      if t.tag == "Splice" then
		 printf("IN_QUOTE:\n%s", util.table_tostring(t, "nohash", 60))
         assert (#t==1, "Invalid splice")
         local sp = t[1]
         return sp
      elseif t.tag then
         table.insert (mt, { tag = "Pair", mlp.quote "tag", mlp.quote (t.tag) })
      end
      for _, v in ipairs (t) do
         table.insert (mt, mlp.quote (v))
      end
      return mt
   end
   function cases.number (t) return { tag = "Number", t, quote = true } end
   function cases.string (t) return { tag = "String", t, quote = true } end
   return cases [ type (t) ] (t)
end

--------------------------------------------------------------------------------
-- when this variable is false, code inside [-{...}] is compiled and
-- avaluated immediately. When it's true (supposedly when we're
-- parsing data inside a quasiquote), [-{foo}] is replaced by
-- [`Splice{foo}], which will be unpacked by [quote()].
--------------------------------------------------------------------------------
mlp.in_a_quote = false

--------------------------------------------------------------------------------
-- Parse the inside of a "-{ ... }"
--------------------------------------------------------------------------------
function mlp.splice_content (lx)
	--print("I'm in mlp splice_content")
   local parser_name = "expr"
   if lx:is_keyword (lx:peek(2), ":") then
      local a = lx:next()
      lx:next() -- skip ":"
      assert (a.tag=="Id", "Invalid splice parser name")
      parser_name = a[1]
   end
   local ast = mlp[parser_name](lx)
   if mlp.in_a_quote then
      printf("SPLICE_IN_QUOTE:\n%s", util.table_tostring(ast, "nohash", 60))
      return { tag="Splice", ast }
   else
      if parser_name == "expr" then ast = { { tag="Return", ast } }
      elseif parser_name == "stat"  then ast = { ast }
      elseif parser_name ~= "block" then
         error ("splice content must be an expr, stat or block") end
      --printf("EXEC THIS SPLICE:\n%s", util.table_tostring(ast, "nohash", 60))
      return mlp.splice (ast)
   end
end

--------------------------------------------------------------------------------
-- Parse the inside of a "+{ ... }"
--------------------------------------------------------------------------------
function mlp.quote_content (lx)
	print("I'm in mlp quote content")
   local parser 
   if lx:is_keyword (lx:peek(2), ":") then -- +{parser: content }
      parser = mlp[mlp.id (lx)[1]]
      lx:next()
   else -- +{ content }
      parser = mlp.expr
   end

   local prev_iq = mlp.in_a_quote
   mlp.in_a_quote = true
   --print("IN_A_QUOTE")
   local content = parser (lx)
   local q_content = mlp.quote (content)
   mlp.in_a_quote = prev_iq
   return q_content
end

