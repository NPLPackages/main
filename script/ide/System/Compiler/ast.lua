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

function ast:ctor()

end

function ast:init(params, mode, con)
	local params = params or {}
	local mode = mode or "strict"
	local con = con or {}
	self.params = params
	self.mode = mode
	self.content = con
	self.symTbl = {}
	return self
end

function ast:getMode()
	return self.mode
end

function ast:setSymTbl(symTbl)
	self.symTbl = symTbl
end

function ast:getContent()
	if self.mode=="strict" then
		local con = nplgen.ast_to_str(self.content)
		local startline = self:getOffset()
		return con:sub(startline)
	elseif self.mode=="line" then
		local con=""
		for i=1, #self.content-1 do
			con = con..self.content[i][1].."\n"
		end
		con=con..self.content[#self.content][1]
		return con
	elseif self.mode=="token" then   -- FIXME:not implemented yet
		return 
	else
		error("unknown mode")
	end
end

function ast:getOffset()
	return self.content.lineinfo.first[1]
end

function ast:getAst()
	return self.content
end

function ast:getParam(p)
	if type(p) == "number" then
		if self.params[p] then
			return self.params[p][1]
		else
			return "nil"
		end
	elseif type(p) == "string" then
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

function ast:getLines(fl, ll)
	--printf("in ast:getLines, mode is %s", self.mode)
	if self.mode ~= "line" then return end
	local lines = {}
	local fl = fl or 1
	local ll = ll or #self.content
	for i=fl, ll do
		if not self.content[i] then break end
		table.insert(lines, self.content[i][1])
	end
	return table.concat(lines, "\n")
end