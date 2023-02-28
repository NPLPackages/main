
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

_G.AddMacro = function(macro_type, macro_params)
    if (not Macros:IsRecording()) then return end 
    Macros:AddMacro(macro_type, macro_params);           
end


_G.PauseMacroRecord = function()
    Macros:Pause();
end

_G.RestoreMacroRecord = function()
    Macros:Restore();
end
