--[[
Title: Animation
Author(s): wxa
Date: 2020/6/30
Desc: Animation
use the lib:
-------------------------------------------------------
local Animation = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Animation.lua");
-------------------------------------------------------
]]

local Animation = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local AnimationDebug = GGS.Debug.GetModuleDebug("AnimationDebug");

Animation:Property("Element");     -- 元素
Animation:Property("KeyFrames");   -- 关键帧

function Animation:ctor()
    self.startTime = 0;                                   -- 开始时间
    self.index = 0;                                       -- 动画索引
    self.times = {};                                      -- 正向时间表
    self.reverseTimes = {};                               -- 逆向时间表
    self.totalTime = 0;                                   -- 总时间
    self.name = "";                                       -- 动画名称
    -- self.keyframes = {};                               -- 关键帧
end

function Animation:Init(el)
    
    self:SetElement(el);

    return self;
end

function Animation:ApplyAnimationStyle()
    local el = self:GetElement();
    if (not el) then return end
    local style, keyframes = el:GetStyle(), self:GetKeyFrames();
    if (not keyframes or #keyframes == 0 or self.name == style["animation-name"]) then return end 

    self.name = style["animation-name"];
    self.totalTime = (style["animation-duration"] or 0) * 1000;
    self.delayTime = (style["animation-delay"] or 0) * 1000;
    self.count = style["animation-iteration-count"];                        -- nil表示无限次数
    self.direction = style["animation-direction"];                          -- normal|reverse|alternate|alternate-reverse|initial|inherit;
    self.keyframes = keyframes;                                             -- 关键帧
    self.frameSize = #keyframes;                                            -- 帧数量
    self.curDirection = (self.direction == "reverse" or self.direction == "alternate-reverse") and "reverse" or "normal";
    
    if (self.direction == "alternate" or self.alternate == "alternate-reverse") then self.totalTime = math.floor(self.totalTime / 2) end
    
    local last_percentage, reverse_last_percentage, size = 0, 100, #keyframes;
    for i = 1, size do 
        local index = i;
        self.times[index] = math.floor(self.totalTime * (keyframes[index].percentage - last_percentage) / 100);
        last_percentage = keyframes[index].percentage;

        index = size - i + 1;
        self.reverseTimes[index] = math.floor(self.totalTime * (reverse_last_percentage - keyframes[index].percentage) / 100);
        reverse_last_percentage = keyframes[index].percentage;
    end

    -- 无效动画
    if (keyframes[1].percentage ~= 0 or keyframes[size].percentage ~= 100) then self.totalTime = 0 end

    -- AnimationDebug(#keyframes, self.totalTime, self.count, self.times, self.reverseTimes);
end

function Animation:NextFrame()
    self.index = self:GetNextIndex();
    self.lastNextTime = self.nextTime;
    self.nextTime = self.lastNextTime + self:GetFrameTime();
end

function Animation:GetNextIndex()
    if (self.index == 0) then 
        return self.curDirection == "reverse" and self.frameSize or 1;
    else
        return self.curDirection == "reverse" and self.index - 1 or self.index + 1;
    end
end

function Animation:GetPrevIndex()
    return self.curDirection == "reverse" and self.index + 1 or self.index - 1;
end

function Animation:GetFrameStyle()
    local prevIndex = self.curDirection == "reverse" and self.index + 1 or self.index - 1;

    return self.keyframes[self.index], self.keyframes[prevIndex];
end

function Animation:GetFrameTime()
    return (self.curDirection == "reverse" and self.reverseTimes[self.index] or self.times[self.index]) or 0;
end

function Animation:SetAnimationStyle()
    local curtime = ParaGlobal.timeGetTime();
    local frameStyle, prevFrameStyle = self:GetFrameStyle();
    local style = self:GetElement():GetStyle();

    if (type(frameStyle) ~= "table") then return end

    local timePercentage = (self.nextTime > self.lastNextTime and curtime < self.nextTime) and ((curtime - self.lastNextTime) / (self.nextTime - self.lastNextTime)) or 1;
    local function GetCurValue(startValue, endValue)
        if (not startValue or not endValue) then return startValue or endValue end
        return math.floor(startValue + (endValue - startValue) * timePercentage)
    end
    for key, val in pairs(frameStyle) do
        local value = val;
        if (key == "width" or key == "height") then
            value = GetCurValue(prevFrameStyle and prevFrameStyle[key], frameStyle[key]);
        elseif (key == "transform") then
            local lastTF, TF, curTF = prevFrameStyle and prevFrameStyle[key], frameStyle[key], style[key];
            if (not curTF) then 
                style[key] = commonlib.deepcopy(TF);
                curTF = style[key];
            end
            for i = 1, #TF do
                local lasttf, tf, curtf = lastTF and lastTF[i], TF[i], curTF[i];
                if (tf.action == "rotate") then
                    curtf.rotate = GetCurValue(lasttf and lasttf.rotate, tf.rotate);
                elseif (tf.action == "translate") then
                    curtf.translateX = GetCurValue(lasttf and lasttf.translateX, tf.translateX);
                    curtf.translateY = GetCurValue(lasttf and lasttf.translateY, tf.translateY);
                end
            end
        end

        if (key ~= "transform") then style[key] = value end
        if (key == "width") then self:GetElement():SetWidth(value) end
        if (key == "height") then self:GetElement():SetHeight(value) end
    end
end

-- local lastCurTime = 0;
function Animation:FrameMove()
    local keyframes = self:GetKeyFrames();
    if (not keyframes or #keyframes == 0 or self.totalTime == 0 or self.count == 0) then return end

    local curtime = ParaGlobal.timeGetTime();
    
    -- 开始动画
    if (self.index == 0) then
        self.startTime = curtime + self.delayTime;
        self.nextTime = self.startTime;
        self:NextFrame();
    end

    if (curtime < self.startTime) then return end

    self:SetAnimationStyle();

    -- if (curtime - lastCurTime > 1000) then
    --     AnimationDebug(curtime, self.index, self.curDirection, 
    --         {self:GetFrameStyle()},
    --         self:GetElement():GetStyle():GetCurStyle(), 
    --         (self.nextTime > self.lastNextTime) and ((curtime - self.lastNextTime) / (self.nextTime - self.lastNextTime)) or 1);
    --     lastCurTime = curtime;
    -- end

    if (curtime < self.nextTime) then return end
    -- self.nextTime = curtime;
    self:NextFrame();

    if (self:IsFinish()) then
        self.count = self.count and (self.count - 1);
        self.index = 0;
    end
end

function Animation:IsFinish()
    if (1 <= self.index and self.index <= self.frameSize) then return false end

    if (self.direction == "alternate") then
        if (self.curDirection == "normal") then 
            self.curDirection = "reverse";
            return false;
        else
            self.curDirection = "normal";
            return true;
        end
    end

    if (self.direction == "alternate-reverse") then
        if (self.curDirection == "normal") then 
            self.curDirection = "reverse";
            return true;
        else
            self.curDirection = "normal";
            return false;
        end
    end

    return true;
end