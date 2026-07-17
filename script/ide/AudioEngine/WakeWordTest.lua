
-- NPL.load("(gl)script/ide/AudioEngine/WakeWordTest.lua");

NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
local AudioEngine = commonlib.gettable("AudioEngine");
AudioEngine.Init()

local LuaWakeWordModel = LuaDarkNet.LuaWakeWordModel();

local ok = LuaWakeWordModel:LoadModelFromFile("D:/workspace/cmake-test/temp/darknet/model/wakeworld.bin");
if (not ok) then
    print("model load failed!!!");
else 
    print("model load success!!!");
end

local wake_word_data = "";
local wake_word_size = 16000 * 750 / 1000 * 2;  -- 12000(short)24000(byte)
local wake_word_step = 16000 * 250 / 1000 * 2;  -- 4000(short)8000(byte)
AudioEngine.StartRecording(function(data)
	wake_word_data = wake_word_data .. data;
    local sub_data = string.sub(wake_word_data, 1, wake_word_size);
    local result = LuaWakeWordModel:Predict(sub_data);
    if (result ~= "none") then
        print(result);
    end
    local wake_word_data_size = #wake_word_data;
    if (wake_word_data_size > (wake_word_step + wake_word_size)) then
        wake_word_data = string.sub(wake_word_data, wake_word_step + 1);
    elseif (wake_word_data_size > wake_word_size) then
        wake_word_data = string.sub(wake_word_data, wake_word_data_size - wake_word_size + 1);
    else 
    end
end);
commonlib.TimerManager.SetTimeout(AudioEngine.StopRecording, 50000)
