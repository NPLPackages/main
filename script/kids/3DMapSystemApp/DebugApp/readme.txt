--[[
Title: Debug app readme file
Author(s): LiXizhi
Date: 2008/3/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/DebugApp/readme.lua");
------------------------------------------------------------
]]
--[[wiki page
---+!! Debug Application

When this application is installed, press F12 key to bring the debug window at any time. 
The debug applications have two modules: 
   * Debug window: one can write and run any code snippet directory in the debug window. 
      * Press F12 key to open it. Or one can open it from the help menu. 
   * Test Console Window: one can write and run unit test files from a GUI interface. 
      * Please see UnitTest for more information. One can open the test console from the help menu

%TOC%

---++ Summary of Contents
---+++ Debug Window 
	Copy and paste NPL script code to the debug window and click run. Each time a script code runs, 
it will be saved to a file so that the debugger will automatically reload the last script code. 
One can also save script code to files, the first line of the script code is used as the file name. 
So it is letter to write debug code as this
<verbatim>
-- some description
CallActualCode();
</verbatim>
	Debug Window is useful for casual unit testing as well. For serious unit testing with automatic result and wiki documentation generation,
please use the Test Console window
	
---+++ Test Console Window
Test Console Window is a GUI front end for the unit test framework in NPL. 
%INCLUDE{"UnitTest"}%

---++ Screenshots & User Guide


]]