--[[
Title: 
Author(s): ported to NPL by Zhiyuan
Date: 2016/1/25
]]
----------------------------------------------------------------------
-- Metalua:  $Id: mll.lua,v 1.3 2006/11/15 09:07:50 fab13n Exp $
--
-- Summary: Source file lexer. ~~Currently only works on strings.
-- Some API refactoring is needed.
--
----------------------------------------------------------------------
--
-- Copyright (c) 2006-2007, Fabien Fleutot <metalua@gmail.com>.
--
-- This software is released under the MIT Licence, see licence.txt
-- for details.
--
----------------------------------------------------------------------
NPL.load("(gl)script/ide/System/Compiler/lib/lexer.lua");
local mlp = commonlib.inherit(nil, commonlib.gettable("System.Compiler.lib.mlp"))
local lexer = commonlib.gettable("System.Compiler.lib.lexer")
local util = commonlib.gettable("System.Compiler.lib.util")
local mlp_lexer = lexer:clone()

local keywords = {
    "and", "break", "do", "else", "elseif",
    "end", "false", "for", "function", "if",
    "in", "local", "nil", "not", "or", "repeat",
    "return", "then", "true", "until", "while",
    "...", "..", "==", ">=", "<=", "~=", 
    "+{", "-{" }
 
for w in util.values(keywords) do mlp_lexer:add(w) end

--_M.lexer = mlp_lexer
mlp.lexer = mlp_lexer