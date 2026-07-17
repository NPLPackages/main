--[[
Title: text to audio
Author(s): pbb
Date: 2024/8/26
Desc: this class is used to convert text to audio using System API.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/Text2Audio.lua");
local Text2Audio = commonlib.gettable("System.os.Text2Audio");
Text2Audio.PlayText("Hello World!",callback);
------------------------------------------------------------
]]
local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
NPL.load("(gl)script/ide/System/os/os.lua");

local Text2Audio = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.Text2Audio"));
--[[
    Rate: Control the speed of speech synthesis. You can adjust the speech rate by setting the Rate property of SpeechSynthesizer. The value range is generally between -10 and 10, and the default value is 0.
    Pitch: Controls the pitch of the voice. The pitch can be adjusted by setting the Pitch property of SpeechSynthesizer. The value range is generally between -10 and 10, and the default value is 0.
    Volume: Control the volume of the voice. The volume can be adjusted by setting the Volume property of SpeechSynthesizer. The value range is generally between 0 and 100, and the default value is 100.
]]
Text2Audio:Property({"pitch", 0, "GetPitch", "SetPitch"});
Text2Audio:Property({"rate", 0, "GetRate", "SetRate"});
Text2Audio:Property({"volume", 80, "GetVolume", "SetVolume"});
local tempFilePath = "temp/playtext/tempvoice.txt"
function Text2Audio:ctor()
    
end

function Text2Audio.IsSupport()
    if System.os.GetPlatform() == "win32" or System.os.IsEmscripten() then
        return true
    end
    return false
end

function Text2Audio.PlayText(text, callback)
    if not text or text == "" then
        return
    end
    Text2Audio.callback = callback;
    if System.os.GetPlatform() == "win32" then
        Text2Audio:playTextWin32(text);
        return
    elseif System.os.IsEmscripten() then
        Text2Audio:playTextEmscripten(text)
    end
end

function Text2Audio:GetPlayTextMd5(text)
    if not text or text == "" then
        return ""
    end
    local md5Str = string.format("%s_%s_%s_%s", text, 
                tostring(self.rate),
                tostring(self.pitch),
                tostring(self.volume))
    local md5_value = ParaMisc.md5(md5Str)
    return md5_value
end

function Text2Audio:GetPlayTextDiskFolder()
    if(not DiskFolder) then
		DiskFolder = ParaIO.GetWritablePath().."temp/PlayText"
   end
    
	return DiskFolder
end

function Text2Audio:GetTempSoundFile(textToSpeak)
	local md5_value = self:GetPlayTextMd5(textToSpeak)
	local filename = md5_value..".mp3"
	NPL.load("(gl)script/ide/Files.lua");
	local disk_folder = self:GetPlayTextDiskFolder()
	local file_path = string.format("%s/%s", disk_folder, filename)
	if ParaIO.DoesFileExist(file_path, true) then
		local file = ParaIO.open(file_path, "r")
		if file then
			if(file:IsValid()) then
				file:close()
                return file_path , true
			end
			file:close()
		end
	end
    return file_path
end

function Text2Audio:playTextEmscripten(textToSpeak)
    local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
    Emscripten:SendMsg("Function_PlayText", {
        text = textToSpeak,
        rate = self.rate,
        pitch = self.pitch,
        volume = self.volume,
    }, nil, self.callback);
end

function Text2Audio:playTextWin32(textToSpeak)
    local tmp_file = ParaIO.open(tempFilePath, "w");
    if tmp_file then
        tmp_file:WriteString(textToSpeak,#textToSpeak)
        tmp_file:close()
    end

    local rate = self.rate;
    local pitch = self.pitch;
    local volume = self.volume;
    local filePath,bExists = self:GetTempSoundFile(textToSpeak)
    if not bExists then
        --ParaIO.CreateDirectory(filePath)
    end
    local tempwav = "temp/playtext/output.wav"
    local command = "powershell -Command  Add-Type -AssemblyName System.Speech; $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; "..
    "$synth.Rate = "..rate..
    "; $synth.Volume = "..volume..
    "; $synth.Pitch = "..pitch..
    "; $synth.Speak([System.IO.File]::ReadAllText('"..tempFilePath.."'))"
    -- "; $synth.SetOutputToWaveFile('"..tempwav.."')"..
    -- "; $synth.Speak([System.IO.File]::ReadAllText('"..tempFilePath.."'))"..
    -- "; Convert-Audio -InputPath '"..tempwav.."' OutputPath '"..filePath.."'"..
    -- "; Remove-Item '"..tempwav.."'"
    LOG.std(nil,"info" ,"Text2Audio","Text2Audio:playTextWin32 command: %s",command)
    ParaGlobal.ShellExecute("popen",command,"isAsync",LuaCallbackHandler.createHandler(function(msg)
       if self.callback and type(self.callback) == "function" then
           self.callback(true)
           print("Text2Audio:playTextWin32 callback")
       end
       ParaIO.DeleteFile(tempFilePath)
    end));
end

Text2Audio:InitSingleton();