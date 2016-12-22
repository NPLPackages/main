----------------------------------------------------------------------
-- Ast Class
-- Author: Zhiyuan
-- Date: 2016-12-22
-- provide helper function to manipulate ast
----------------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");
NPL.load("(gl)script/ide/System/Compiler/nplp.lua");

local nplgen = commonlib.gettable("System.Compiler.nplgen")
local nplp = commonlib.gettable("System.Compiler.nplp")
local ast = commonlib.inherit(nil, commonlib.gettable("System.Compiler.ast"))

ast.content = {}
ast.lines = {}
function ast:new(con)
	local con = con or {}
	local o = { content = con, lines = nplgen.ast_to_rawstr(con) }
	setmetatable(o, self)
	self.__index = self
	return o
end

function ast:print()
	table.print(self.content, 60, "nohash")
end

function ast:getlines()
	return self.lines
end

function ast:replaceline(i, line)
	self.lines[i] = line
end

function ast:updateAst()
	local lines = self.lines
	for i=#lines, 2, -1 do
		table.insert(lines, i, "\n")
	end
	local src = table.concat(lines)
	self.content = nplp:src_to_ast(src)
end

function ast:getAst()
	return self.content
end