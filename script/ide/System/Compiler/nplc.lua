--[[
Title: NPL Compiler
Author:Zhiyuan
Date: 2016-12-13
Desc: the goal of NPL Compiler is to extend NPL Syntax
compiling procedure: source - > ast - > source
NPL.loadstring is implemented here
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/nplc.lua");
NPL.loadstring('def("activate", p1){NPL.this(function() local +{params(p1)} = msg; +{emit()} end);}')
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/System/Compiler/nplp.lua");
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");

local nplpClass = commonlib.gettable("System.Compiler.nplp")
local nplgen = commonlib.gettable("System.Compiler.nplgen")
local nplc = commonlib.inherit(nil, commonlib.gettable("System.Compiler.nplc"))

local nplp = nplpClass:new()

-- only for debugging purposes
function nplc.compile(src_filename, dst_filename)
	local src_file = assert(io.open(src_filename, 'r'))
	local src = src_file:read '*a'; src_file:close()
	--src = src:gsub('^#[^\r\n]*', '') 
	local ast = nplp:src_to_ast(src)
	local compiled_src = nplgen.ast_to_str(ast)
	local dst_file = assert(io.open(dst_filename, 'w')) -- debug only
	dst_file:write(compiled_src)
	dst_file:close()
end

-- NOT used: only for debugging
-- force load/reload an NPL file
-- similar to NPL.load(filename, true);
-- @param filename 
function nplc.load(filename)
	filename = filename:gsub("^%([^%)]*%)", "")
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		local text = file:GetText(0, -1);
		if(text) then
			local pFunc = NPL.loadstring(text, filename);
			if(pFunc) then
				return pcall(pFunc);
			end
		end
		file:close();
	end
	LOG.std(nil, "warn", "NPL.load", "file not exist: %s", filename);
end

local dsl_loaded;
-- these *.npl files are preloaded before any user defined *.npl file is loaded for the global environment. 
local function CheckLoadDefaultNplDslExtension()
	if(dsl_loaded) then
		return
	end
	dsl_loaded = true;
	
	LOG.std(nil, "info", "DomainSpecificLanguage", "NPL language extension loaded");
	
	-- TODO: add more core NPL extension dsl here.
	NPL.load("(gl)script/ide/System/Compiler/dsl/DSL_NPL.npl");
end

-- similar to loadstring() except that it support function-expression in NPL.
-- @param code: NPL source code 
-- @param filename: virtual filename 
-- @param nplp_obj: the parser object. If nil, it is in global environment. 
-- @return return a function that represent the code. 
function nplc.loadstring(code, filename, nplp_obj)
	if(code) then
		local ast = {}
		
		if nplp_obj then
			ast = nplp_obj:src_to_ast(code, filename)
		else
			CheckLoadDefaultNplDslExtension();
			ast = nplp:src_to_ast(code, filename)
		end
		local compiled_src = nplgen.ast_to_str(ast)
		return loadstring(compiled_src, filename)
	end
end
NPL.loadstring = nplc.loadstring