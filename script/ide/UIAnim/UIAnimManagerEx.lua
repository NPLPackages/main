--[[
Title: UI Animation
Author(s): chenjinxian
Date: 2020/8/8
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/UIAnim/UIAnimManagerEx.lua");
-------------------------------------------------------
]]
local format = format;
local type = type;
local pairs = pairs;
local UIAnimManagerEx = commonlib.gettable("UIAnimManagerEx");
local math_floor = math.floor;

local AllFiles = {};

local UIAnimationPool = {};

local AllUIElements = {};

local UI_timer;
-- start the animation framework and start the timer
function UIAnimManagerEx.Init()
	if(UIAnimManagerEx.inited) then
		return
	end
	UIAnimManagerEx.inited = true;
	NPL.load("(gl)script/ide/timer.lua");
	UI_timer = UI_timer or commonlib.Timer:new({callbackFunc = UIAnimManagerEx.DoAnimation});
	-- call every frame move
	UI_timer:Change(0, 1);
end

function UIAnimManagerEx.AddFile(FileName, file)
	if(not AllFiles[FileName]) then
		AllFiles[FileName] = file;
		file.FileName = FileName;
	else
		log("warning: file :"..FileName.." already exists in animation manager.\r\n");
	end
end

function UIAnimManagerEx.DeleteFile(FileName)
	local obj = AllFiles[FileName];
	if(obj ~= nil) then
		AllFiles[FileName] = nil;
	else
		log("error: file :"..FileName.." doesn't exist or not yet opened.\r\n");
	end
end

-- load the UI animation file
function UIAnimManagerEx.LoadUIAnimationFile(fileName)
	local NewTable = commonlib.LoadTableFromFile(fileName);
	
	NPL.load("(gl)script/ide/UIAnim/UIAnimFile.lua");
	
	if(not NewTable) then
		log("error loading animation file: "..fileName.."\n");
		return nil;
	end

	local ctl = UIAnimFile:new(NewTable);
	UIAnimManagerEx.AddFile(fileName, ctl);
	
	
	--Map3DSystem.Misc.SaveTableToFile(ctl, "TestTable/file.ini");

	return ctl;
end

---- play UI animation according to the filename and the animation ID and range ID
--function UIAnimManagerEx.PlayUIAnimationSingle(obj, fileName, AnimID, RangeID)
	---- TODO: load the UI animation file
--end

-- play UI animation according to the filename and the sequence ID 
function UIAnimManagerEx.PlayUIAnimationSequence(obj, fileName, ID, bLooping)
	UIAnimManagerEx.LoadUIAnimationFile(fileName);
	if(obj == nil) then
		return;
	end

	local file = AllFiles[fileName];
	if(file == nil) then
		log("warning: animation file is not yet opened: "..fileName.."\n");
		return;
	end
	local anim_seq = file.UIAnimSeq[ID];
	if(not anim_seq)  then
		LOG.std(nil, "warn", "UIAnimManagerEx",  "warning: %s sub animation sequence not found in %s: ", tostring(ID), fileName);
		return;
	end

	UIAnimManagerEx.Init();

	local animationID = anim_seq.AnimationID;
	local seq = anim_seq.Seq;
	if(not UIAnimationPool) then
		UIAnimationPool = {};
	end
	
	local _objectNameString;
	_objectNameString = UIAnimManagerEx.GetPathStringFromUIObject(obj)
	
	local children = obj:GetChildren();
	local child = children:first();
	while (child) do
		if (child:isVisible()) then
			UIAnimManagerEx.PlayUIAnimationSequence(child, fileName, ID, bLooping);
		end
		child = self.children:next(child);
	end
	
	-- record the object name and parent
	local objIndex = _objectNameString;
	
	UIAnimationPool[objIndex] = UIAnimationPool[objIndex] or {};
	
	if(UIAnimationPool[objIndex].IsAnimating ~= true) then
		-- set up new animation
		UIAnimationPool[objIndex].File = file; -- e.g "Test_UIAnimFile.lua.table"
		UIAnimationPool[objIndex].Seq = ID; -- e.g "Bounce"
		
		UIAnimationPool[objIndex].currentSeqID = 1; -- "Bounce": 1
		UIAnimationPool[objIndex].animationID = animationID;
		UIAnimationPool[objIndex].isLooping = bLooping;
		UIAnimationPool[objIndex].nCurrentFrame = file.UIAnimation[animationID]:GetStartFrame(file.UIAnimSeq[ID].Seq[1]);
		UIAnimationPool[objIndex].nStartFrame = file.UIAnimation[animationID]:GetStartFrame(file.UIAnimSeq[ID].Seq[1]);
		UIAnimationPool[objIndex].nEndFrame = file.UIAnimation[animationID]:GetEndFrame(file.UIAnimSeq[ID].Seq[1]);
		
		UIAnimationPool[objIndex].IsAnimating = true;
		
		UIAnimationPool[objIndex].SetBackVisible = obj:isVisible();
		UIAnimationPool[objIndex].SetBackEnable = obj:isEnabled();
		
		-- set the UI object visible during the animation and setback when finished
		obj:setVisible(true);
	else
		-- blending the animation to the new one
		
		--UIAnimationPool[objIndex].BlendingFactor = 1;
		----fileName, ID, bLooping
		--if(UIAnimationPool[objIndex].isLooping == true) then
			--if( UIAnimationPool[objIndex].File.FileName == fileName
					--and UIAnimationPool[objIndex].Seq == ID) then
				--UIAnimationPool[objIndex].isLooping = false;
			--end
		--end
	end
	
end

-- @param bForceStop: force the ui object animation to stop, unless the animation will be animated to endframe or blended with the next one
--						NOTE: if bForceStop is true, fileName and ID could be nil
function UIAnimManagerEx.StopLoopingUIAnimationSequence(obj, fileName, ID, bForceStop)
	if(not obj) then
		return;
	end
	if(not UIAnimationPool) then
		UIAnimationPool = {};
	end
	
	local _objectNameString;
	_objectNameString = UIAnimManagerEx.GetPathStringFromUIObject(obj)
	
	local objIndex = _objectNameString;
	
	UIAnimationPool[objIndex] = UIAnimationPool[objIndex] or {};
	
	if(bForceStop == true) then
		UIAnimationPool[objIndex] = nil;
		obj.TranslationX = 0;
		obj.TranslationY = 0;
		obj.ScalingX = 1;
		obj.ScalingY = 1;
		obj.Rotation = 0;
		obj.Color = "#ffffff";
		obj.Opacity = 1;
		return;
	end
	
	local file = AllFiles[fileName];
	if(file == nil) then
		log("warning: animation file is not yet opened: "..fileName.."\n");
		return;
	end
	local animationID = file.UIAnimSeq[ID].AnimationID;
	local seq = file.UIAnimSeq[ID].Seq;
	
	if(UIAnimationPool[objIndex].IsAnimating ~= true) then
		-- the ui object is not yet animating
	else
		-- NOTE: directly stop the ui animation in the stop function
		--		original version only set the isLooping to false and wait until the next DoAnimation call to stop animation
		-- stop the animating ui object
		if(UIAnimationPool[objIndex].isLooping == true) then
			if( UIAnimationPool[objIndex].File.FileName == fileName and UIAnimationPool[objIndex].Seq == ID) then
				UIAnimationPool[objIndex].IsAnimating = false;
				UIAnimationPool[objIndex].isLooping = false;
				local v = UIAnimationPool[objIndex];
				v.nCurrentFrame = v.nEndFrame;
				local _uiObject = UIAnimManagerEx.GetUIObjectFromPathString(objIndex);
				_uiObject:setVisible(v.SetBackVisible);
				_uiObject:SetEnabled(v.SetBackEnable);
				
				local animID = file.UIAnimSeq[v.Seq].Seq[v.currentSeqID];
				local _TX = file.UIAnimation[v.animationID]:GetTranslationXValue(animID, v.nCurrentFrame);
				local _TY = file.UIAnimation[v.animationID]:GetTranslationYValue(animID, v.nCurrentFrame);
				local _SX = file.UIAnimation[v.animationID]:GetScalingXValue(animID, v.nCurrentFrame);
				local _SY = file.UIAnimation[v.animationID]:GetScalingYValue(animID, v.nCurrentFrame);
				local _R = file.UIAnimation[v.animationID]:GetRotationValue(animID, v.nCurrentFrame);
				local _A = file.UIAnimation[v.animationID]:GetAlphaValue(animID, v.nCurrentFrame);
				local _CR = file.UIAnimation[v.animationID]:GetColorRValue(animID, v.nCurrentFrame);
				local _CG = file.UIAnimation[v.animationID]:GetColorGValue(animID, v.nCurrentFrame);
				local _CB = file.UIAnimation[v.animationID]:GetColorBValue(animID, v.nCurrentFrame);
				
				_uiObject.TranslationX = _TX;
				_uiObject.TranslationY = _TY;
				_uiObject.ScalingX = _SX;
				_uiObject.ScalingY = _SY;
				
				_uiObject.Rotation = _R;
				_uiObject.Color = string.format("#%x%x%x%x", _CR, _CG, _CB, _A);
			end
		end
	end
end

-- get the ui object from object path string
-- path string format: [@index][@index]..
-- @param path: object path string
-- @return nil if not found
function UIAnimManagerEx.GetUIObjectFromPathString(id)
	if(id) then
		local obj = AllUIElements[id];
		return obj;
	end	
end

-- get the object path string from the ui object
-- path string format: [name@][name@]..
-- @param obj: ui object
-- @return nil if not found
function UIAnimManagerEx.GetPathStringFromUIObject(obj)
	if(obj) then
		local id = obj:GetID();
		AllUIElements[id] = obj;
		return id;
	end	
end

-- animate the ui objects in the UIAnimationPool
function UIAnimManagerEx.DoAnimation(timer)
	local dTimeDelta = timer.delta;
	
	local k, v;
	if(not UIAnimationPool) then
		UIAnimationPool = {};
	end
	local delete_pool;
	for k, v in pairs(UIAnimationPool) do
			
		local _uiObject = UIAnimManagerEx.GetUIObjectFromPathString(k);
		if(not _uiObject) then
			-- remove from the pool. 
			delete_pool = delete_pool or {};
			delete_pool[k] = true;
		else
			if(v.IsAnimating == true) then
				--local animID = v.AnimID;
				local file = v.File; -- e.g "Test_UIAnimFile.lua.table"
				local seq = v.Seq; -- -- e.g "Bounce"
				
				local nToDoFrame = v.nCurrentFrame + dTimeDelta;
				
				if(nToDoFrame > v.nEndFrame) then
					
					nToDoFrame = nToDoFrame - (v.nEndFrame - v.nStartFrame); -- wrap to the beginning
					
					if(file.UIAnimSeq[seq].Seq[v.currentSeqID + 1] == nil) then
						-- end of animation
						if(v.isLooping) then
							-- loop to the front of animation sequence
							v.currentSeqID = 1;
							local animationID = file.UIAnimSeq[seq].AnimationID;
							v.nCurrentFrame = file.UIAnimation[animationID]:GetStartFrame(file.UIAnimSeq[seq].Seq[1]);
							v.nStartFrame = file.UIAnimation[animationID]:GetStartFrame(file.UIAnimSeq[seq].Seq[1]);
							v.nEndFrame = file.UIAnimation[animationID]:GetEndFrame(file.UIAnimSeq[seq].Seq[1]);
						else
							-- NOTE: original implementation
							--	Animaiton logic fails in the following code:
							--		UIAnimManagerEx.StopLoopingUIAnimationSequence(_waiting, fileName, "WaitingSpin");
							--		_waiting.visible = false;
							--
							---- end of animation
							--v.nCurrentFrame = v.nEndFrame;
							--v.IsAnimating = false;
							--_uiObject.visible = v.SetBackVisible;
							--_uiObject.enable = v.SetBackEnable;
						end
					else
						-- continue with sequence
						v.currentSeqID = v.currentSeqID + 1;
						local animID = file.UIAnimSeq[seq].Seq[v.currentSeqID];
						v.animationID = file.UIAnimSeq[seq].AnimationID;
						v.nCurrentFrame = nToDoFrame - v.nStartFrame;
						v.nStartFrame = file.UIAnimation[v.animationID]:GetStartFrame(animID);
						v.nEndFrame = file.UIAnimation[v.animationID]:GetEndFrame(animID);
						v.nCurrentFrame = v.nCurrentFrame + v.nStartFrame;
					end
				else
					-- continue with current animation
					v.nCurrentFrame = nToDoFrame;
				end
				
				local animID = file.UIAnimSeq[seq].Seq[v.currentSeqID];
				local anim_data = file.UIAnimation[v.animationID];
				local nCurFrame = v.nCurrentFrame;
				local _TX = anim_data:GetTranslationXValue(animID, nCurFrame);
				local _TY = anim_data:GetTranslationYValue(animID, nCurFrame);
				local _SX = anim_data:GetScalingXValue(animID, nCurFrame);
				local _SY = anim_data:GetScalingYValue(animID, nCurFrame);
				local _R = anim_data:GetRotationValue(animID, nCurFrame);
				local _A = anim_data:GetAlphaValue(animID, nCurFrame);
				local _CR = anim_data:GetColorRValue(animID, nCurFrame);
				local _CG = anim_data:GetColorGValue(animID, nCurFrame);
				local _CB = anim_data:GetColorBValue(animID, nCurFrame);
				
				_uiObject.TranslationX = _TX;
				_uiObject.TranslationY = _TY;
				_uiObject.ScalingX = _SX;
				_uiObject.ScalingY = _SY;
				
				_uiObject.Rotation = _R;
				_uiObject.Color = string.format("#%x%x%x%x", _CR, _CG, _CB, _A);
			
			end -- if(v.IsAnimating = true) then
		end 
	end -- for k, v in pairs(UIAnimationPool) do
	
	if(delete_pool) then
		local id, _
		for id, _ in pairs(delete_pool) do
			UIAnimationPool[id] = nil;
		end
	end	
end
