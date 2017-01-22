local util = commonlib.inherit(nil, commonlib.gettable("System.Compiler.lib.util"))

function util.values(x)
   assert(type(x)=='table', 'values() expects a table')
   local function iterator (state)
      local it
      state.content, it = next(state.list, state.content)
      return it
   end
   return iterator, { list = x }
end

function util.ivalues(x)
   assert(type(x)=='table', 'ivalues() expects a table')
   local i = 1
   local function iterator ()
      local r = x[i]; i=i+1; return r
   end
   return iterator
end

function util.min(a, ...)
   for n in util.values{...} do if n<a then a=n end end
   return a
end

function util.max(a, ...)
   for n in util.values{...} do if n>a then a=n end end
   return a
end

function util.printf(...) return print(string.format(...)) end
function util.eprintf(...) 
   io.stderr:write(string.format(...).."\n") 
end

function util.table_iforeach(f, ...)
   -- assert (type (f) == "function") [wouldn't allow metamethod __call]
   local nargs = select("#", ...)
   if nargs==1 then -- Quick iforeach (most common case), just one table arg
      local t = ...
      assert (type (t) == "table")
      for i = 1, #t do 
         local result = f (t[i])
         -- If the function returns non-false, stop iteration
         if result then return result end
      end
   else -- advanced case: boundaries and/or multiple tables
      -- 1 - find boundaries if any
      local  args, fargs, first, last, arg1 = {...}, { }
      if     type(args[1]) ~= "number" then first, arg1 = 1, 1
      elseif type(args[2]) ~= "number" then first, last, arg1 = 1, args[1], 2
      else   first,  last, i = args[1], args[2], 3 end
      assert (nargs > arg1)
      -- 2 - determine upper boundary if not given
      if not last then for i = arg1, nargs do 
            assert (type (args[i]) == "table")
            last = util.max (#args[i], last) 
      end end
      -- 3 - perform the iteration
      for i = first, last do
         for j = arg1, nargs do fargs[j] = args[j][i] end -- build args list
         local result = f (unpack (fargs)) -- here is the call
         -- If the function returns non-false, stop iteration
         if result then return result end
      end
   end
end

function util.table_imap(f, ...)
   local result, idx = { }, 1
   local function g(...) result[idx] = f(...);  idx=idx+1 end
   util.table_iforeach(g, ...)
   return result
end

function util.table_deep_copy(x) 
   local tracker = { }
   local function aux (x)
      if type(x) == "table" then
         local y=tracker[x]
         if y then return y end
         y = { }; tracker[x] = y
         setmetatable (y, getmetatable (x))
         for k,v in pairs(x) do y[aux(k)] = aux(v) end
         return y
      else return x end
   end
   return aux(x)
end

function util.table_transpose(t)
   local tt = { }
   for a, b in pairs(t) do tt[b] = a end
   return tt
end

function util.table_tostring(t)
	return commonlib.serialize_compact(t)
end