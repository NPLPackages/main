----------------------------------------------------------------------
-- Ast Class
-- Author: Zhiyuan
-- Date: 2016-12-22
-- provide helper function to manipulate ast
----------------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");
NPL.load("(gl)script/ide/System/Compiler/nplp.lua");

local nplgen = commonlib.gettable("System.Compiler.nplgen")
local ast = commonlib.inherit(nil, commonlib.gettable("System.Compiler.ast"))

ast.content = {}
ast.params= {}

function ast:new(params, mode, con)
	local con = con or {}
	local params = params or {}
	local mode = mode or "stricted"
	local symTbl = {}
	local o = { 
		content = con, 
		mode = mode, 
		params = params,
		symTbl = symTbl
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ast:print()
	table.print(self.content, 60, "nohash")
end

function ast:getMode()
	return self.mode
end

function ast:setSymTbl(symTbl)
	self.symTbl = symTbl
end

function ast:getContent()
	return nplgen.ast_to_str(self.content)
end

function ast:getAst()
	--self:updateAst()
	return self.content
end

function ast:appendAst(a)
	a.lineinfo = self.content[#self.content].lineinfo
	table.insert(self.content, a)
end

function ast:getParam(p)
	if type(p) == "number" then
		if self.params[p] then
			return self.params[p][1]
		else
			return "nil"
		end
	elseif type(p) == "string" then
		print("get params in ast")
		if p == ""  and self.symTbl.dots then
			local pList = {}
			for i=1, #self.params do
				table.insert(pList, self.params[i][1])
			end
			return table.concat(pList, ",")
		elseif self.symTbl[p] and self.params[self.symTbl[p]] then
			return self.params[self.symTbl[p]][1]
		else
			return "nil"
		end
	end
end

function ast:buildSymTbl()
	local symTbl = {}
	if #self.params < 2 then return symTbl end
	if self.params[2].tag == "Dots" then
		symTbl.dots = true
	else
		for i=2, #self.params do
			symTbl[self.params[i][1]] = i-1
		end
	end
	return symTbl
end