--[[
Title: Options
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Options = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Options.lua");
-------------------------------------------------------
]]


local Options = NPL.export();

local actor_options = {};
local function GetActorNameOptions()
    if (not GameLogic.EntityManager) then return actor_options end
    
    local actor_options = {};
    local size = #actor_options;
    local index = 1;
    local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
    if(entities and #entities>0) then
        for _, entity in ipairs(entities) do
            local key = entity:GetFilename();
            if (key and key ~= "") then
                actor_options[index] = {key, key};
                index = index + 1;
            end
        end
    end
    -- local actors = GameLogic.GetCodeGlobal().actors;
    -- for key in pairs(actors) do
    --     actor_options[index] = {key, key};
    --     index = index + 1;
    -- end
    for i = index, size do
        actor_options[i] = nil;
    end
    return actor_options;
end
Options.ActorNameOptions = GetActorNameOptions;

local actor_bone_options = {};
local function GetActorBoneOptions()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
    local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    local codeblock = CodeBlockWindow.GetCodeBlock();
    local codeEnv = codeblock and codeblock:GetCodeEnv();
    local actor = codeEnv and codeEnv.actor;
    local variable = type(actor) == "table" and type(actor.GetBonesVariable) == "function" and actor:GetBonesVariable() or nil;
    local bones = type(variable) == "table" and type(variable.GetVariables) == "function" and variable:GetVariables() or nil;
    local index, size = 1, #actor_bone_options;
    if (bones) then
        for key in pairs(bones) do
            actor_bone_options[index] = {key, key};
            index = index + 1;
        end
    end
    for i = index, size do
        actor_bone_options[i] = nil;
    end
    return actor_bone_options;
end


local variable_options = {};
Options.variable_options_callback = function()
    local options = GameLogic.GetCodeGlobal():GetCurrentGlobals();
    local index, size = 1, #variable_options;
    for key in pairs(options) do
        variable_options[index] = {key, key};
        index = index + 1;
    end
    for i = index, size do
        variable_options[i] = nil;
    end
    return variable_options;
end

Options.targetNameType = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"最近的玩家", "@p"});
    table.insert(actor_options, 1, {L"摄影机", "camera"});
    table.insert(actor_options, 1, {L"鼠标", "mouse-pointer"});
    return actor_options;
end

Options.becomeAgentOptions = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"当前玩家", "@p"});
    return actor_options;
end

Options.actorNames = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"此角色", "myself"});
    return actor_options;
end

Options.focus_list = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"此角色", "myself"});
    table.insert(actor_options, 1, {L"主角", "player"});
    return actor_options;
end

Options.isTouchingOptions = function() 
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, { L"某个方块id", "-1" });
    table.insert(actor_options, 1, { L"附近玩家", "@a" });
    table.insert(actor_options, 1, { L"方块", "block" });
    return actor_options;
end

Options.actorBoneNameOptions = GetActorBoneOptions;

Options.actorProperties = function()
    return {
        { L"名字", "name" },
        { L"物理半径", "physicsRadius" },
        { L"物理高度", "physicsHeight" },
        { L"是否有阻挡", "isBlocker" },
        { L"开启LOD", "isLodEnabled" },
        { L"组Id", "groupId" },
        { L"感知半径", "sentientRadius" },
        { "x", "x" },
        { "y", "y" },
        { "z", "z" },
        { L"时间", "time" },
        { L"朝向", "facing" },
        { L"行走速度", "walkSpeed" },
        { L"俯仰角度", "pitch" },
        { L"翻滾角度", "roll" },
        { L"颜色", "color" },
        { L"透明度", "opacity" },
        { L"选中特效", "selectionEffect" },
        { L"文字", "text" },
        { L"是否为化身", "isAgent" },
        { L"模型文件", "assetfile" },
        { L"绘图代码", "rendercode" },
        { L"Z排序", "zorder" },
        { L"电影方块的位置", "movieblockpos" },
        { L"电影角色", "movieactor" },
        { L"电影播放速度", "playSpeed" },
        { L"广告牌效果", "billboarded" },
        { L"是否投影", "shadowCaster" },
        { L"是否联机同步", "isServerEntity" },

        { L"禁用物理仿真", "dummy" },
        { L"重力加速度", "gravity" },
        { L"速度", "velocity" },
        { L"增加速度", "addVelocity" },
        { L"摩擦系数", "surfaceDecay" },
        { L"空气阻力", "airDecay" },
        { L"相对位置播放", "isRelativePlay" },
        { L"播放时忽略皮肤", "isIgnoreSkinAnim"},
         
        { L"父角色", "parent" },
        { L"父角色位移", "parentOffset" },
        { L"父角色旋转", "parentRot" },

        { L"初始化参数", "initParams" },
        { L"自定义数据", "userData" },
    }
end

Options.keyEventNames = function() 
    return {
        { L"空格", "space" },{ L"任意", "any" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" }, { "ESC", "escape" },
        {"a","a"},{"b","b"},{"c","c"},{"d","d"},{"e","e"},{"f","f"},{"g","g"},{"h","h"},
        {"i","i"},{"j","j"},{"k","k"},{"l","l"},{"m","m"},{"n","n"},{"o","o"},{"p","p"},
        {"q","q"},{"r","r"},{"s","s"},{"t","t"},{"u","u"},{"v","v"},{"w","w"},{"x","x"},
        {"y","y"},{"z","z"},
        {"1","1"},{"2","2"},{"3","3"},{"4","4"},{"5","5"},{"6","6"},{"7","7"},{"8","8"},{"9","9"},{"0","0"},
        {"f1","f1"},{"f2","f2"},{"f3","f3"},{"f4","f4"},{"f5","f5"},{"f6","f6"},{"f7","f7"},{"f8","f8"},{"f9","f9"},{"f10","f10"},{"f11","f11"},{"f12","f12"},
        { L"回车", "return" },{ "-", "minus" },{ "+", "equal" },{ "back", "back" },{ "tab", "tab" },
        { "lctrl", "lcontrol" },{ "lshift", "lshift" },{ "lalt", "lmenu" },
        {"num0","numpad0"},{"num1","numpad1"},{"num2","numpad2"},{"num3","numpad3"},{"num4","numpad4"},{"num5","numpad5"},{"num6","numpad6"},{"num7","numpad7"},{"num8","numpad8"},{"num9","numpad9"},
        {L"鼠标滚轮","mouse_wheel"},{L"鼠标按钮","mouse_buttons"}
    }
end

Options.agentEventTypes = function()
    return {
        { L"TryCreate", "TryCreate" },
        { L"OnSelect", "OnSelect" },
        { L"OnDeSelect", "OnDeSelect" },
        { L"GetIcon", "GetIcon" },
        { L"GetTooltip", "GetTooltip" },
        { L"OnClickInHand", "OnClickInHand" },
    }
end

Options.networkEventTypes = function()
    return {
        { L"ps_用户加入", "ps_user_joined" },
        { L"ps_用户离开", "ps_user_left" },
        { L"ps_服务器启动", "ps_server_started" },
        { L"ps_服务器关闭", "ps_server_shutdown" },
        { L"用户加入", "connect" },
    }
end

Options.cmdExamples = function()
    return {
        { L"/tip", "/tip" },
        { L"改变时间[-1,1]", "/time"},
        { L"加载世界:项目id", "/loadworld"},
        { L"设置真实光影[1|2|3]", "/shader"},
        { L"设置光源颜色[0,2] [0,2] [0,2]", "/light"},
        { L"设置太阳颜色[0,2] [0,2] [0,2]", "/sun"},
        { L"发送事件HelloEvent", "/sendevent HelloEvent {data=1}" },
        { L"添加规则:Lever可放在Glowstone上", "/addrule Block CanPlace Lever Glowstone" },
        { L"添加规则:Glowstone可被删除", "/addrule Block CanDestroy Glowstone true" },
        { L"添加规则:人物自动爬坡", "/addrule Player AutoWalkupBlock" },
        { L"添加规则:人物可跳跃", "/addrule Player CanJump" },
        { L"添加规则:人物摄取距离为5米", "/addrule Player PickingDist 5" },
        { L"添加规则:人物可在空中继续跳跃", "/addrule Player CanJumpInAir" },
        { L"添加规则:人物可飞行", "/addrule Player CanFly" },
        { L"添加规则:人物在水中可跳跃", "/addrule Player CanJumpInWater" },
        { L"添加规则:人物跳起的速度", "/addrule Player JumpUpSpeed 5" },
        { L"添加规则:人物可跑步", "/addrule Player AllowRunning" },
        { L"设置最小人物出现距离", "/property -scene MinPopUpDistance 100"},
        { L"设置最大人物多边形数目", "/property -scene MaxCharTriangles 500000"},
        { L"禁用自动人物细节", "/lod off"},
        { L"关闭自动等待", "/autowait false"},
        { L"隐藏物品栏", "/hide quickselectbar"},
        { L"显示物品栏", "/show quickselectbar"},
        { L"激活方块", "/activate" },
    }
end

Options.WindowAlignmentOptions = function()
    return {
        { L"左上", "_lt" },
        { L"左下", "_lb" },
        { L"居中", "_ct" },
        { L"居中上", "_ctt" },
        { L"居中下", "_ctb" },
        { L"居中左", "_ctl" },
        { L"居中右", "_ctr" },
        { L"右上", "_rt" },
        { L"右下", "_rb" },
        { L"中间上", "_mt" },
        { L"中间左", "_ml" },
        { L"中间右", "_mr" },
        { L"中间下", "_mb" },
        { L"全屏", "_fi" },
        { L"全局"..":"..L"左上", "global_lt" },
        { L"全局"..":"..L"居中", "global_ct" },
        { L"人物头顶", "headon" },
        { L"人物头顶".."3D", "headon3D" },
    }
end

Options.playNoteTypes = function()
    return {
        { "1", "1" },{ "2", "2" },{ "3", "3" },{ "4", "4" },{ "5", "5" },{ "6", "6" },{ "7", "7" },
        { "c", [["c"]] },{ "d", [["d"]] },{ "e", [["e"]] },{ "f", [["f"]] },{ "g", [["g"]] },{ "a", [["a"]] },{ "b", [["b"]] },
        { "c'", [["c'"]] },{ "d'", [["d'"]] },{ "e'", [["e'"]] },{ "f'", [["f'"]] },{ "g'", [["g'"]] },{ "a'", [["a'"]] },{ "b'", [["b'"]] },
        { "c''", [["c''"]] },{ "d''", [["d''"]] },{ "e''", [["e''"]] },{ "f''", [["f''"]] },{ "g''", [["g''"]] },{ "a''", [["a''"]] },{ "b''", [["b''"]] },
    }
end

Options.playMusicFileTypes = function()
    return {
        { "1", "1" },
        { "2", "2" },
        { "3", "3" },
        { "4", "4" },
        { "5", "5" },
        
        {"黑暗森林", "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
        {"黑暗森林海", "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg"},
        {"黑暗平原", "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg"},
        {"荒漠", "Audio/Haqi/AriesRegionBGMusics/ambDesert.ogg"},
        {"森林1", "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
        {"草原", "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg"},
        {"海洋", "Audio/Haqi/AriesRegionBGMusics/ambOcean.ogg"},
        {"嘉年华1", "Audio/Haqi/AriesRegionBGMusics/Area_Carnival.ogg"},
        {"圣诞节", "Audio/Haqi/AriesRegionBGMusics/Area_Christmas.ogg"},
        {"火洞1", "Audio/Haqi/AriesRegionBGMusics/Area_FireCavern.ogg"},
        {"森林2", "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg"},
        {"新年", "Audio/Haqi/AriesRegionBGMusics/Area_NewYear.ogg"},
        {"下雪", "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg"},
        {"阳光海滩1", "Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg"},
        {"城镇", "Audio/Haqi/AriesRegionBGMusics/Area_Town.ogg"},
        {"音乐盒-来自舞者", "Audio/Haqi/Homeland/MusicBox_FromDancer.ogg"},
        {"并行世界", "Audio/Haqi/keepwork/common/bigworld_bgm.ogg"},
        {"开场引导音", "Audio/Haqi/keepwork/common/guide_bgm.ogg"},
        {"登录音效", "Audio/Haqi/keepwork/common/login_bgm.ogg"},
        {"小游戏音效", "Audio/Haqi/keepwork/common/minigame_bgm.ogg"},
        {"单机音效", "Audio/Haqi/keepwork/common/offline_bgm.ogg"},  
        {"行星环绕音效", "Audio/Haqi/keepwork/common/planet_bgm.ogg"},
        {"音频主题", "Audio/Haqi/New/cAudioTheme1.ogg"},
        {"岩浆洞", "Audio/Haqi/AriesRegionBGMusics/Area_MagmaCave.ogg"},
        {"农场", "Audio/Haqi/AriesRegionBGMusics/Area_Farm.ogg"},
        {"霜吼岛", "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg"},
        {"火焰凤凰岛", "Audio/Haqi/AriesRegionBGMusics/Area_FlamingPhoenixIsland.ogg"},
        {"古埃及岛", "Audio/Haqi/AriesRegionBGMusics/Area_AncientEgyptIsland.ogg"},
        {"黑暗森林岛", "Audio/Haqi/AriesRegionBGMusics/Area_DarkForestIsland.ogg"},
        {"云堡岛", "Audio/Haqi/AriesRegionBGMusics/Area_CloudFortressIsland.ogg"},
        {"61哈奇小镇10", "Audio/Haqi/AriesRegionBGMusics/Area_61HaqiTown_teen.ogg"},
        {"战斗鼓声", "Audio/Haqi/AriesRegionBGMusics/Combat_Drumbeat.ogg"},
        {"打小兵", "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg"},
        {"打boss", "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Boss_TrialVersion.ogg"},
        {"哈奇岛背景音", "Audio/Haqi/AriesRegionBGMusics/HaqiIslandBg.ogg"},
        {"红色蘑菇竞技场战斗", "Audio/Haqi/AriesRegionBGMusics/Combat_RedMushroomArena.ogg"},
        {"哈奇小镇背景音", "Audio/Haqi/AriesRegionBGMusics/HaqiTownBg.ogg"},
        {"龙之荣耀", "Audio/Haqi/AriesRegionBGMusics/Area_HaqiTown_DragonGlory_teen.ogg"},
        {"新用户教程", "Audio/Haqi/AriesRegionBGMusics/Area_NewUserTutorial_teen.ogg"},
        {"新用户教程（小）", "Audio/Haqi/AriesRegionBGMusics/Area_NewUserTutorial_teen_small.ogg"},
        {"海边", "Audio/Haqi/AriesRegionBGMusics/ambOcean.ogg"},
        {"城镇市场", "Audio/Haqi/AriesRegionBGMusics/ambHaqiTownMarket.ogg"},
        {"城镇2", "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
        {"凤凰岛", "Audio/Haqi/AriesRegionBGMusics/ambPhoenixIsland.ogg"},
        {"岩浆", "Audio/Haqi/AriesRegionBGMusics/ambLava.ogg"},
        {"冰海边", "Audio/Haqi/AriesRegionBGMusics/ambIceSeaSide.ogg"},
        {"雪山", "Audio/Haqi/AriesRegionBGMusics/ambSnowMountain.ogg"},

        {"游戏背景乐1", "Audio/Haqi/OldFiles/game_bg1.ogg"},
        {"游戏背景乐2", "Audio/Haqi/OldFiles/game_bg2.ogg"},
        {"游戏背景乐3", "Audio/Haqi/OldFiles/game_bg3.ogg"},
        {"马里奥", "Audio/Haqi/OldFiles/Mario.ogg"},
        {"马里奥低音", "Audio/Haqi/OldFiles/MarioLow.ogg"},
        {"MIDI", "Audio/Haqi/OldFiles/MIDI01.ogg"},
        {"任务完成", "Audio/Haqi/OldFiles/MissionComplete.ogg"},
        {"音乐盒1", "Audio/Haqi/OldFiles/MusicBox1.ogg"},
        {"音乐盒2", "Audio/Haqi/OldFiles/MusicBox2.ogg"},
        {"音乐盒3", "Audio/Haqi/OldFiles/MusicBox3.ogg"},
        {"创建植物", "Audio/Haqi/OldFiles/plant_create.ogg"},
        {"水马", "Audio/Haqi/OldFiles/Region_AquaHorse.ogg"},
        {"蜜蜂", "Audio/Haqi/OldFiles/Region_Bee.ogg"},
        {"嘉年华2", "Audio/Haqi/OldFiles/Region_Carnival.ogg"},
        {"龙森林", "Audio/Haqi/OldFiles/Region_DragonForest.ogg"},
        {"火洞2", "Audio/Haqi/OldFiles/Region_FireCavern.ogg"},
        {"跳跳农场", "Audio/Haqi/OldFiles/Region_JumpJumpFarm.ogg"},
        {"春天生活", "Audio/Haqi/OldFiles/Region_LifeSpring.ogg"},
        {"魔法森林", "Audio/Haqi/OldFiles/Region_MagicForest.ogg"},
        {"阳光海滩2", "Audio/Haqi/OldFiles/Region_SunnyBeach.ogg"},
        {"城镇广场", "Audio/Haqi/OldFiles/Region_TownSquare.ogg"},
        {"多彩舞曲08", "Audio/Haqi/New/RICH08.ogg"},
        {"多彩舞曲16", "Audio/Haqi/New/RICH16.ogg"},
        {"多彩舞曲17", "Audio/Haqi/New/RICH17.ogg"},
        {"多彩舞曲18", "Audio/Haqi/New/RICH18.ogg"},
        {"多彩舞曲19", "Audio/Haqi/New/RICH19.ogg"},
        {"多彩舞曲20", "Audio/Haqi/New/RICH20.ogg"},
        {"多彩舞曲21", "Audio/Haqi/New/RICH21.ogg"},
        {"科技舞曲", "Audio/Haqi/New/Techno_1.ogg"},
        {"比赛为冠", "Audio/Haqi/New/NewBgMusic/RaceIsWinner.ogg"},
        {"捕猎", "Audio/Haqi/New/NewBgMusic/Hunting.ogg"},
        {"赛场", "Audio/Haqi/New/NewBgMusic/Arena.ogg"},
        {"赛桨", "Audio/Haqi/New/NewBgMusic/Paddle.ogg"},
        {"激昂", "Audio/Haqi/New/NewBgMusic/Passionate.ogg"},
        {"胜利之歌", "Audio/Haqi/New/NewBgMusic/SongOfVictory.ogg"},
        {"鼓舞人心", "Audio/Haqi/New/NewBgMusic/Inspirational.ogg"},
        {"争分夺秒", "Audio/Haqi/New/NewBgMusic/AgainstTime.ogg"},
        {"追风筝的人", "Audio/Haqi/New/NewBgMusic/KiteChaser.ogg"},
        {"赛场欢呼声1", "Audio/Haqi/New/NewBgMusic/ArenaCheers1.ogg"},
        {"赛场欢呼声2", "Audio/Haqi/New/NewBgMusic/ArenaCheers2.ogg"},
        {"赛场掌声1", "Audio/Haqi/New/NewBgMusic/Applause1.ogg"},
        {"赛场掌声2", "Audio/Haqi/New/NewBgMusic/Applause2.ogg"},
        {"尖叫喝彩", "Audio/Haqi/New/NewBgMusic/Screaming.ogg"},
        {"欢快聚会1", "Audio/Haqi/New/NewBgMusic/PartyCheers1.ogg"},
        {"欢快聚会2", "Audio/Haqi/New/NewBgMusic/PartyCheers2.ogg"},
        {"欢快聚会3", "Audio/Haqi/New/NewBgMusic/PartyCheers3.ogg"},
        {"节目现场欢呼掌声1", "Audio/Haqi/New/NewBgMusic/ShowCheersandApplause1.ogg"},
        {"节目现场欢呼掌声2", "Audio/Haqi/New/NewBgMusic/ShowCheersandApplause2.ogg"},
        {"节目现场欢呼掌声3", "Audio/Haqi/New/NewBgMusic/ShowCheersandApplause3.ogg"},
        {"节目现场欢呼掌声4", "Audio/Haqi/New/NewBgMusic/ShowCheersandApplause4.ogg"},

        -- { L"ogg文件", "ogg" },
        -- { L"wav文件", "filename.wav" },
        -- { L"mp3文件", "filename.mp3" },
    }
end

Options.playSoundFileTypes = function()
    return {
        { L"击碎", "break" },
        { L"ogg文件", "filename.ogg" },
        { L"wav文件", "filename.wav" },
        { L"mp3文件", "filename.mp3" },
        { L"开箱", "chestclosed" },
        { L"关箱", "chestopen" },
        { L"开门", "door_open" },
        { L"关门", "door_close" },
        { L"点击", "click" },
        { L"激活", "trigger" },
        { L"溅射", "splash" },
        { L"水", "water" },
        { L"吃", "eat1" },
        { L"爆炸", "explode1" },
        { L"升级", "levelup" },
        { L"弹出", "pop" },
        { L"掉下", "fallbig1" },
        { L"火", "fire" },
        { L"弓箭", "bow" },
        { L"呼吸", "breath" },

        {"按钮音1", "Audio/Haqi/UI/Button01.ogg"},
        {"按钮音4", "Audio/Haqi/UI/Button04.ogg"},
        {"按钮音5", "Audio/Haqi/UI/Button05.ogg"},
        {"按钮音7", "Audio/Haqi/UI/Button07.ogg"},
        {"接受任务", "Audio/Haqi/UI/AcceptQuest_teen.ogg"},
        {"结束任务", "Audio/Haqi/UI/FinishQuest_teen.ogg"},
        {"点击", "Audio/Haqi/UI/Click_teen.ogg"},
        {"收集", "Audio/Haqi/UI/Gather_teen.ogg"},
        {"背包", "Audio/Haqi/UI/Bag_teen.ogg"},
        {"默认音乐", "Audio/Haqi/Homeland/MusicBox_FromDancer.ogg"},
        {"刺杀", "Audio/Haqi/Combat/Common/AndThorn.ogg"},
        {"死亡", "Audio/Haqi/Combat/Common/Dead.ogg"},
        {"失败", "Audio/Haqi/Combat/Common/Fizzle.ogg"},
        {"通过", "Audio/Haqi/Combat/Common/Pass.ogg"},
        {"死亡吟唱2", "Audio/Haqi/Combat/Death/Death_Casting.ogg"},
        {"死亡_发射", "Audio/Haqi/Combat/Death/DoT_Death_Missile.ogg"},
        {"死亡_结束", "Audio/Haqi/Combat/Death/DoT_Death_End.ogg"},
        {"10级单次攻击发射", "Audio/Haqi/Combat/Death/Death_SingleAttack_Level0_1_20_Missile.ogg"},
        {"暗灵之咒2", "Audio/Haqi/Combat/Death/Death_SingleAttack_Level1_Missile.ogg"},
        {"暗灵之咒3", "Audio/Haqi/Combat/Death/Death_SingleAttack_Level1_End.ogg"},
        {"吸血幽灵2", "Audio/Haqi/Combat/Death/Death_SingleAttackWithLifeTap_Level2_Missile.ogg"},
        {"幽灵突袭2", "Audio/Haqi/Combat/Death/Death_SingleAttack_Level3_Missile.ogg"},
        {"幽灵突袭3", "Audio/Haqi/Combat/Death/Death_SingleAttack_Level3_End.ogg"},
        {"回光返照2", "Audio/Haqi/Combat/Death/Death_SingleAttackWithLifeTap_Level4_Missile.ogg"},
        {"回光返照3", "Audio/Haqi/Combat/Death/Death_SingleAttackWithLifeTap_Level4_End.ogg"},
        {"墓地莽石2", "Audio/Haqi/Combat/Death/Death_SingleAttack_Level5_Missile.ogg"},
        {"献祭2", "Audio/Haqi/Combat/Death/Death_SingleHealWithImmolate_Level3_Missile.ogg"},
        {"献祭3", "Audio/Haqi/Combat/Death/Death_SingleHealWithImmolate_Level3_End.ogg"},
        {"死亡毒2", "Audio/Haqi/Combat/Death/Death_SingleAttackWithDOT_Level4_Missile.ogg"},
        {"死亡毒3", "Audio/Haqi/Combat/Death/Death_SingleAttackWithDOT_Level4_End.ogg"},
        {"烈火吟唱2", "Audio/Haqi/Combat/Fire/Fire_Casting.ogg"},
        {"火攻", "Audio/Haqi/Combat/Fire/DoT_Fire_Missile.ogg"},
        {"烈火魔光2", "Audio/Haqi/Combat/Fire/Fire_SingleAttack_Level0_1_20_Missile.ogg"},
        {"火焰爆2", "Audio/Haqi/Combat/Fire/Fire_SingleAttack_Level1_Missile.ogg"},
        {"火焰爆3", "Audio/Haqi/Combat/Fire/Fire_SingleAttack_Level1_End.ogg"},
        {"烈焰之轮2", "Audio/Haqi/Combat/Fire/Fire_DOTAttackWithHOT_Level2_Misssile.ogg"},
        {"烈焰之轮3", "Audio/Haqi/Combat/Fire/Fire_DOTAttackWithHOT_Level2_End.ogg"},
        {"火鸟冲击2", "Audio/Haqi/Combat/Fire/Fire_SingleAttack_Level3_Missile.ogg"},
        {"火鸟冲击3", "Audio/Haqi/Combat/Fire/Fire_SingleAttack_Level3_End.ogg"},
        {"星火袭空2", "Audio/Haqi/Combat/Fire/Fire_SingleAttackWithImmolate_Level4_Missile.ogg"},
        {"火狼咆哮2", "Audio/Haqi/Combat/Fire/Fire_DOTAttack_LevelX_Missile.ogg"},
        {"火狼咆哮3", "Audio/Haqi/Combat/Fire/Fire_DOTAttack_LevelX_End.ogg"},
        {"寒冰吟唱2", "Audio/Haqi/Combat/Ice/Ice_Casting.ogg"},
        {"寒冰魔光2", "Audio/Haqi/Combat/Ice/Ice_SingleAttack_Level0_1_20_Missile.ogg"},
        {"冰霜破2", "Audio/Haqi/Combat/Ice/Ice_SingleAttack_Level1_Missile.ogg"},
        {"陨落冰石2", "Audio/Haqi/Combat/Ice/Ice_SingleAttack_Level1_End.ogg"},
        {"冰剑凛空3", "Audio/Haqi/Combat/Ice/Ice_SingleAttack_Level2_End.ogg"},
        {"破地冰钻4", "Audio/Haqi/Combat/Ice/Ice_SingleAttack_Level3_End.ogg"},
        {"冰魄漫天5", "Audio/Haqi/Combat/Ice/Ice_SingleAttack_Level4_End.ogg"},
        {"海狮冰剑6", "Audio/Haqi/Combat/Ice/Ice_AreaAttack_Level4_End.ogg"},
        {"冰盾防御1", "Audio/Haqi/Combat/Ice/Ice_DefensiveStance_Missile.ogg"},
        {"冰盾防御2", "Audio/Haqi/Combat/Ice/Ice_DefensiveStance_End.ogg"},
        {"生命吟唱2", "Audio/Haqi/Combat/Life/Life_Casting.ogg"},
        {"生命魔光2", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level0_1_20_Missile.ogg"},
        {"生灵光弧2", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level1_Missile.ogg"},
        {"灵木刺阵2", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level2_Missile.ogg"},
        {"灵木刺阵3", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level2_End.ogg"},
        {"莽林狂舞2", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level3_Missile.ogg"},
        {"噬草召唤2", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level4_Missile.ogg"},
        {"噬草召唤3", "Audio/Haqi/Combat/Life/Life_SingleAttack_Level4_End.ogg"},
        {"生命复苏1", "Audio/Haqi/Combat/Life/Life_SingleHeal_Level0_Missile.ogg"},
        {"生命复苏2", "Audio/Haqi/Combat/Life/Life_SingleHealWithHOT_Level1_End.ogg"},
        {"生命复苏3", "Audio/Haqi/Combat/Life/Life_SingleHeal_ForLife_Level2_Missile.ogg"},
        {"生命复苏4", "Audio/Haqi/Combat/Life/Life_SingleHeal_Level4_End.ogg"},
        {"生命复苏5", "Audio/Haqi/Combat/Life/Life_AreaHeal_Level3_End.ogg"},
        {"雨露均沾1", "Audio/Haqi/Combat/Life/Life_AreaHealWithHOT_Level8_Missile.ogg"},
        {"雨露均沾2", "Audio/Haqi/Combat/Life/Life_AreaHealWithHOT_Level8_Missile02.ogg"},
        {"风暴吟唱2", "Audio/Haqi/Combat/Storm/Storm_Casting.ogg"},
        {"风暴魔光2", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level0_1_20_Missile.ogg"},
        {"金灵遁空2", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level1_Missile.ogg"},
        {"金灵遁空3", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level1_End.ogg"},
        {"疾电术2", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level2_End.ogg"},
        {"暗夜雷动2", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level3_End.ogg"},
        {"雷神之剑2", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level4_Missile.ogg"},
        {"雷神之剑3", "Audio/Haqi/Combat/Storm/Storm_SingleAttack_Level4_End.ogg"},
        {"暴风隐遁", "Audio/Haqi/Combat/Storm/Storm_SingleStealth_Missile.ogg"},
        {"战斗死亡", "Audio/Haqi/Combat/Dead.ogg"},
        {"战斗刺杀", "Audio/Haqi/Combat/AndThorn.ogg"},
        {"战斗铸件01", "Audio/Haqi/Combat/Casting01.ogg"},
        {"战斗铸件02", "Audio/Haqi/Combat/Casting02.ogg"},
        {"战斗土地", "Audio/Haqi/Combat/Earth01.ogg"},
        {"战斗增强刀片", "Audio/Haqi/Combat/EnhanceBlade.ogg"},
        {"战斗火器02", "Audio/Haqi/Combat/Fire02.ogg"},
        {"战斗火器04", "Audio/Haqi/Combat/Fire04.ogg"},
        {"战斗火点", "Audio/Haqi/Combat/Fire_Dot.ogg"},
        {"战斗失败", "Audio/Haqi/Combat/Fizzle.ogg"},
        {"战斗受伤的怪物声", "Audio/Haqi/Combat/InjuredSound_Monster.ogg"},
        {"战斗金属01", "Audio/Haqi/Combat/Matel05.ogg"},
        {"战斗金属02", "Audio/Haqi/Combat/Metal02.ogg"},
        {"战斗金属03", "Audio/Haqi/Combat/Metal03.ogg"},
        {"战斗金属工艺01", "Audio/Haqi/Combat/Metal_Process01.ogg"},
        {"战斗通过01", "Audio/Haqi/Combat/Pass01.ogg"},
        {"战斗水治疗", "Audio/Haqi/Combat/Water_Heal.ogg"},
        {"战斗水工艺01", "Audio/Haqi/Combat/Water_Process01.ogg"},
        {"战斗木头01", "Audio/Haqi/Combat/Wood01.ogg"},
        {"行动挂载", "Audio/Haqi/Ordinary/Action_OnMount.ogg"},
        {"行动_在下一个级别", "Audio/Haqi/Ordinary/Action_OnNextInstanceLevel.ogg"},
        {"行动_在上一个级别", "Audio/Haqi/Ordinary/Action_OnPreviousInstanceLevel.ogg"},
        {"行动_获取", "Audio/Haqi/Ordinary/Action_QuestAcquire.ogg"},
        {"行动_完成", "Audio/Haqi/Ordinary/Action_QuestFinish.ogg"},
        {"使用战斗药丸", "Audio/Haqi/Ordinary/Action_UseCombatPill.ogg"},
        {"使用实验包", "Audio/Haqi/Ordinary/Action_UseExpBag.ogg"},
        {"升级", "Audio/Haqi/Ordinary/Action_OnLevelUp.ogg"},
        {"传送", "Audio/Haqi/Ordinary/Action_OnTeleport.ogg"},
        {"完成任务", "Audio/Haqi/UI/FinishQuest_teen.ogg"},
        {"寒冰魔光1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttack_Level0_1_20_teen.ogg"},
        {"冰霜破1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttack_Level1_teen.ogg"},
        {"陨落冰石1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttack_Level2_teen.ogg"},
        {"冰剑凛空1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttack_Level3_teen.ogg"},
        {"破地冰钻1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttack_Level4_teen.ogg"},
        {"冰魄漫天1", "Audio/Haqi/Combat_teen/Ice/Ice_AreaAttack_Level4_teen.ogg"},
        {"海狮冰剑1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttack_Level6_teen.ogg"},
        {"冰雹来袭1", "Audio/Haqi/Combat_teen/Ice/Ice_SingleAttackWithDOT_Level5_teen.ogg"},
        {"冰镜破碎1", "Audio/Haqi/Combat_teen/Ice/Ice_ReflectionShield_shieldbreak_teen.ogg"},
        {"寒冰群击1", "Audio/Haqi/Combat_teen/Ice/Ice_Rune_AreaAttack_Level2_teen.ogg"},
        {"生命魔光1", "Audio/Haqi/Combat_teen/Life/Life_SingleAttack_Level0_1_20_teen.ogg"},
        {"生灵光弧1", "Audio/Haqi/Combat_teen/Life/Life_SingleAttack_Level1_teen.ogg"},
        {"灵木刺阵1", "Audio/Haqi/Combat_teen/Life/Life_SingleAttack_Level2_teen.ogg"},
        {"莽林狂舞1", "Audio/Haqi/Combat_teen/Life/Life_SingleAttack_Level3_teen.ogg"},
        {"噬草召唤1", "Audio/Haqi/Combat_teen/Life/Life_SingleAttack_Level4_teen.ogg"},
        {"生命之怒", "Audio/Haqi/Combat_teen/Life/Life_SingleAttack_Level6_teen.ogg"},
        {"生命群击", "Audio/Haqi/Combat_teen/Life/Life_Rune_AreaAttack_Level2_teen.ogg"},
        {"死亡魔光1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttack_Level0_1_20_teen.ogg"},
        {"暗灵之咒1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttack_Level1_teen.ogg"},
        {"吸血幽灵1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttackWithLifeTap_Level2_teen.ogg"},
        {"幽灵突袭1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttack_Level3_teen.ogg"},
        {"回光返照1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttackWithLifeTap_Level4_teen.ogg"},
        {"墓地莽石1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttack_Level5_teen.ogg"},
        {"死亡毒1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttackWithDOT_Level4_teen.ogg"},
        {"蝠王吸魂1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttackWithLifeTap_Level6_teen.ogg"},
        {"祭献1", "Audio/Haqi/Combat_teen/Death/Death_SingleHealWithImmolate_Level3_teen.ogg"},
        {"天魔杀星1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttackWithDisabledHeal_teen.ogg"},
        {"死神契约1", "Audio/Haqi/Combat_teen/Death/Death_SingleAttackWithPercent_teen.ogg"},
        {"死亡群击1", "Audio/Haqi/Combat_teen/Death/Death_Rune_AreaAttack_Level2_teen.ogg"},
        {"烈火魔光1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttack_Level0_1_20_teen.ogg"},
        {"火焰爆1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttack_Level1_teen.ogg"},
        {"火鸟冲击1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttack_Level3_teen.ogg"},
        {"烈焰之轮1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttackWithDOT_Level2_teen.ogg"},
        {"星火袭空1", "Audio/Haqi/Combat_teen/Fire/Fire_AreaAttack_Level4_teen.ogg"},
        {"火神之握1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttackWithImmolate_Level4_teen.ogg"},
        {"烈火怒吼1", "Audio/Haqi/Combat_teen/Fire/Fire_AreaDOTAttack_Level5_teen.ogg"},
        {"凤翼天翔1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttack_Level5_teen.ogg"},
        {"火狼咆哮1", "Audio/Haqi/Combat_teen/Fire/Fire_DOTAttack_LevelX_teen.ogg"},
        {"火魔掷石1", "Audio/Haqi/Combat_teen/Fire/Fire_SingleAttack_Level6_teen.ogg"},
        {"熔岩炸弹1", "Audio/Haqi/Combat_teen/Fire/Fire_DOTAttackWithSplash_Level6_teen.ogg"},
        {"烈火群击1", "Audio/Haqi/Combat_teen/Fire/Fire_Rune_AreaAttack_Level2_teen.ogg"},
        {"风暴魔光1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level0_1_20_teen.ogg"},
        {"金灵遁空1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level1_teen.ogg"},
        {"疾电术1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level2_teen.ogg"},
        {"暗夜雷动1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level3_teen.ogg"},
        {"雷神之剑1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level4_teen.ogg"},
        {"雷鸟之怒1", "Audio/Haqi/Combat_teen/Storm/Storm_AreaAttack_LevelX_teen.ogg"},
        {"蛇女雷暴1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level5_teen.ogg"},
        {"极限暴熊1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_WildBolt_Level2_teen.ogg"},
        {"雷猴神兵1", "Audio/Haqi/Combat_teen/Storm/Storm_SingleAttack_Level6_teen.ogg"},
        {"风暴群击1", "Audio/Haqi/Combat_teen/Storm/Storm_Rune_AreaAttack_Level2_teen.ogg"},
        {"发招失败", "Audio/Haqi/Combat_teen/Common/Fizzle_teen.ogg"},
        {"捉宠成功", "Audio/Haqi/Combat_teen/Storm/Balance_Catchpet_success_teen.ogg"},
        {"捉宠失败", "Audio/Haqi/Combat_teen/Storm/Balance_Catchpet_failed_teen.ogg"},
        {"风暴吟唱1", "Audio/Haqi/Combat_teen/Storm/Storm_Casting_teen.ogg"},
        {"寒冰吟唱1", "Audio/Haqi/Combat_teen/Ice/Ice_Casting_teen.ogg"},
        {"烈火吟唱1", "Audio/Haqi/Combat_teen/Fire/Fire_Casting_teen.ogg"},
        {"生命吟唱1", "Audio/Haqi/Combat_teen/Life/Life_Casting_teen.ogg"},
        {"死亡吟唱1", "Audio/Haqi/Combat_teen/Death/Death_Casting_teen.ogg"},
        {"上BUFF1", "Audio/Haqi/Combat_teen/Common/AndThorn_teen.ogg"},
        {"上BUFF2", "Audio/Haqi/Combat_teen/Common/Stun_teen.ogg"},
    }
end

Options.isKeyPressedOptions = function()
    return {
        { L"空格", "space" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" },{ "ESC", "escape" },
        {"a","a"},{"b","b"},{"c","c"},{"d","d"},{"e","e"},{"f","f"},{"g","g"},{"h","h"},
        {"i","i"},{"j","j"},{"k","k"},{"l","l"},{"m","m"},{"n","n"},{"o","o"},{"p","p"},
        {"q","q"},{"r","r"},{"s","s"},{"t","t"},{"u","u"},{"v","v"},{"w","w"},{"x","x"},
        {"y","y"},{"z","z"},
        {"1","1"},{"2","2"},{"3","3"},{"4","4"},{"5","5"},{"6","6"},{"7","7"},{"8","8"},{"9","9"},{"0","0"},
        {"f1","f1"},{"f2","f2"},{"f3","f3"},{"f4","f4"},{"f5","f5"},{"f6","f6"},{"f7","f7"},{"f8","f8"},{"f9","f9"},{"f10","f10"},{"f11","f11"},{"f12","f12"},
        { L"回车", "return" },{ "-", "minus" },{ "+", "equal" },{ "back", "back" },{ "tab", "tab" },
        { "lctrl", "lcontrol" },{ "lshift", "lshift" },{ "lalt", "lmenu" },
        {"num0","numpad0"},{"num1","numpad1"},{"num2","numpad2"},{"num3","numpad3"},{"num4","numpad4"},{"num5","numpad5"},{"num6","numpad6"},{"num7","numpad7"},{"num8","numpad8"},{"num9","numpad9"},
    }
end

Options.gameModeOptions = function()
    return {
        { L"游戏模式", "game" },{ L"编辑模式", "edit" },
    }
end


Options.voiceNarratorOption = function()
    return {
        {L"无", "-1"},
        {L"女声", "0"},
        {L"男声", "1"},
        {L"逍遥", "3"},
        {L"丫丫", "4"},        
        {L"逍遥2", "5003"},
        {L"小鹿", "5118"},
        {L"博文", "106"},
        {L"小童", "110"},
        {L"小萌", "111"},
        {L"米朵", "103"},
        {L"小娇", "5"},
        {L"晓萱", "10001"},
        {L"云希", "10002"},
        {L"晓墨", "10003"},
        {L"晓涵", "10004"},
        {L"云哲", "10005"},
        {L"云野", "10006"},
        {L"晓颜", "10007"},
        {L"晓辰", "10008"},
        {L"晓曼(粤语)", "10010"},
        {L"晓秋", "10011"},
        {L"晓悠", "10012"},
        {L"晓晓", "10013"},
        {L"云扬", "10015"},
        {L"晓睿", "20007"},
        {L"晓双", "20008"},
        {L"晓佳(粤语)", "20015"},
        {L"云龍(粤语)", "20016"},
        {L"晓臻", "20017"},
        {L"晓雨", "20018"},
    }
end