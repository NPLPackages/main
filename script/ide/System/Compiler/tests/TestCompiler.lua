--[[
Author:Guo Zhiyuan
Date: 2016-12-21
Test Meta Compiler 
]]

function Test_Params()
	local test_params = [[
		def("NoParam"){
			local a = 1
			print(a)
		}

		def("IdParam", p1, p2){
			local a = 1
			a = a + +{=p1} + +{=p2}
			print(a)
		}

		def("DotsParam", ...){
			local a, b = +{=...}
			print(a)
			print(b)
		}
	]]

	pcall(NPL.loadstring(test_params, "test_params"))

	local test_noparams = [[ NoParam(){} ]]
	local test_idparams = [[ IdParam(3,5){} ]]
	local test_dotsparams = [[ DotsParam(3, 5, 7){} ]]

	pcall(NPL.loadstring(test_noparams, "test_noparams"))
	pcall(NPL.loadstring(test_idparams, "test_idparams"))
	pcall(NPL.loadstring(test_dotsparams, "test_dotsparams"))
end

function Test_Quote()
	local test_quote = [[
		def("testQuote", p1){
			print(+{=p1})
			+{emit()}
		}
		
		def("testQuoteNested", p1, p2){
			testQuote(+{=p1}){
				print(+{=p2})
			}
		}
		
		testQuote(3){}
		testQuoteNested(5,7){}	
	]]

	pcall(NPL.loadstring(test_quote, "test_quote"))
end

function Test_Emit()
	local test_emit = [[
		def("testEmit", p1){
			print(+{emit(p1)}
		}

		testEmit(5){}
	]]

	pcall(NPL.loadstring(test_emit, "test_emit"))
end

function Test_MultiEnv()
	NPL.load("(gl)script/ide/System/Compiler/nplp.lua");
	local nplp = commonlib.gettable("System.Compiler.nplp")
	local nplp_plusOne = nplp:new()
	local nplp_multiFour = nplp:new()

	local macro_plusOne = [[
		def("plusOne", p1){
			local a = 1
			a = a + +{=p1}
			print(a)
		}
	]]

	local macro_multiFour = [[
		def("multiFour", p1){
			local a = 4
			a = a * +{=p1}
			print(a)
		}
	]]

	local app_plusOne = [[ plusOne(10){} ]]
	local app_multiFour = [[ multiFour(7){} ]]

	pcall(NPL.loadstring(macro_plusOne, "macro_plusOne", nplp_plusOne))
	pcall(NPL.loadstring(macro_multiFour, "macro_multiFour", nplp_multiFour))    
	
	pcall(NPL.loadstring(app_plusOne, "app_plusOne", nplp_plusOne))		-- 11
	pcall(NPL.loadstring(app_multiFour, "app_multiFour", nplp_multiFour))    --28
	pcall(NPL.loadstring(app_plusOne, "app_plusOne", nplp_multiFour))    --nothing happened
	pcall(NPL.loadstring(app_multiFour, "app_multiFour", nplp_plusOne))    --nothing happened
end

function Test_DefParser()
	local test_defparser = [[
		def("code"){
			-- types
			local a = 10
			a = "a string"
			a = true or false
			a = nil
			a = "10" + 1
			a = {}
			a[1] =2
			a["key"] = 12

			-- expressions
			local a, b, c = 4, 5, nil
			c = a%b
			c = a*b
			c = a>=b
			c = a~=b
			c = a and b
			c = a and nil
			c = "hello" .. "world"
			c = #c
			c = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}

			if true then print(true) end
			
			do 
				local i = 1
				while c[i] do
					print(c[i])
					i = i + 1
				end
			end

			do
				local i = 1
				repeat
					print(c[i])
					i = i + 1
				until c[i] == nil
			end

			for i = 10, 1, -1 do print(i) end

			function AddOne(x) return x+1 end
			c = AddOne(5)
			print(c)
		}

		code(){}
	]]

	pcall(NPL.loadstring(test_defparser, "test_defparser"))
end


function Test_LineNumber()
	local code = [[print(debug.getinfo(1, "nSl").currentline)]]

	pcall(loadstring(code))
end
