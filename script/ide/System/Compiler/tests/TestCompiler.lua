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
			a = a + +{params(p1)} + +{params(p2)}
			print(a)
		}

		def("DotsParam", ...){
			local a, b = +{params()}
			print(a)
			print(b)
		}
	]]

	pcall(NPL.loadstring(test_params))

	local test_noparams = [[ NoParam(){} ]]
	local test_idparams = [[ IdParam(3,5){} ]]
	local test_dotsparams = [[ DotsParam(3, 5, 7){} ]]

	pcall(NPL.loadstring(test_noparams))
	pcall(NPL.loadstring(test_idparams))
	pcall(NPL.loadstring(test_dotsparams))
end

function Test_Quote()
	local test_quote = [[
		def("testQuote", p1){
			print(+{params(p1)})
			+{emit()}
		}
		
		def("testQuoteNested", p1, p2){
			testQuote(+{params(p1)}){
				print(+{params(p2)})
			}
		}
		
		testQuote(3){}
		testQuoteNested(5,7){}	
	]]

	pcall(NPL.loadstring(test_quote))
end

function Test_Emit()
	local test_emit = [[
		def("testEmit"){
			+{emit("local a = 2", 2)}
			+{for i=1, 10 do}
			circle()
			+{end}
			+{emit()}
		}

		testEmit(){
			local c=2
		}
	]]

	pcall(NPL.loadstring(test_emit))
end

function Test_MultiEnv()
	NPL.load("(gl)script/ide/System/Compiler/nplp.lua");
	local nplp = commonlib.gettable("System.Compiler.nplp")
	local nplp_plusOne = nplp:new()
	local nplp_multiFour = nplp:new()

	local macro_plusOne = [[
		def("plusOne", p1){
			local a = 1
			a = a + +{params(p1)}
			print(a)
		}
	]]

	local macro_multiFour = [[
		def("multiFour", p1){
			local a = 4
			a = a * +{params(p1)}
			print(a)
		}
	]]

	local app_plusOne = [[ plusOne(10){} ]]
	local app_multiFour = [[ multiFour(7){} ]]

	pcall(NPL.loadstring(macro_plusOne, nplp_plusOne))
	pcall(NPL.loadstring(macro_multiFour, nplp_multiFour))    
	
	pcall(NPL.loadstring(app_plusOne, nplp_plusOne))		-- 11
	pcall(NPL.loadstring(app_multiFour, nplp_multiFour))    --28
	pcall(NPL.loadstring(app_plusOne, nplp_multiFour))    --nothing happened
	pcall(NPL.loadstring(app_multiFour, nplp_plusOne))    --nothing happened
end

function Test_LineNumber()
	local code = [[ assert(debug.getinfo(1, "nSl").currentline == 1)
		def("testQuote", p1){
			print(+{params(p1)})
			+{emit()}
		}
		assert(debug.getinfo(1, "nSl").currentline == 6)
		def("testQuoteNested", p1, p2){
			testQuote(+{params(p1)}){
				print(+{params(p2)})
			}
		}
		assert(debug.getinfo(1, "nSl").currentline == 12)
		testQuote(3){
		
		assert(debug.getinfo(1, "nSl").currentline == 15)
		}
		testQuoteNested(5,7){
		assert(debug.getinfo(1, "nSl").currentline == 18)
		}	
		assert(debug.getinfo(1, "nSl").currentline == 20)
	]]

	NPL.loadstring(code)()
end

function Test_NPLCAD()
	local code = [[
	def("playwithSphere", p1){
		push()
		+{emit()}
		sphere(+{params(p1)})
		pop()
	}


	playwithSphere(3){
		translate(2,3,4)
		color('blue')
	}
	]]

	pcall(NPL.loadstring(code))
end

function Test_LineMode()
	local code = [[
		def("loop"){
			--mode:line
			+{local line = ast:getLines(1,1)
			  local times, i = line:match("execute the code (%w+) times with (%l)")
	          if not times then times="1" end
	          if not i then i="i" end
	         }
			for +{emit(i)}=1, +{emit(times)} do
				+{emitline(2)}
			end
        }

		loop(){execute the code 10 times with j
			print(2+j)
			print(3)
			print(4)
		}
	]]
	NPL.loadstring(code)()
end

function Test_LineModeEmit()
	local code = [[
		def("lines"){
			--mode:line
			+{emit()}
		}

		lines(){
			local a = 1
			a = 2*3
		}
	]]
	NPL.loadstring(code)()
end
