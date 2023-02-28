--[[
Title: Local Transform Manipulator
Author(s): LiXizhi@yeah.net
Date: 2022/5/11
Desc: this is for entities that support LocalTransform, such as live model entity. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Manipulators/LocalTransformManipContainer.lua");
local LocalTransformManipContainer = commonlib.gettable("System.Scene.Manipulators.LocalTransformManipContainer");
	
function XXXSceneContext:UpdateManipulators()
	self:DeleteManipulators();
	local manipCont = LocalTransformManipContainer:new():init();
	self:AddManipulator(manipCont);
	manipCont:connectToDependNode(self:GetSelectedObject());
end
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local LocalTransformManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("System.Scene.Manipulators.LocalTransformManipContainer"));
LocalTransformManipContainer:Property({"Name", "LocalTransformManipContainer", auto=true});
-- this is max translation offset that is allowed in the local transform, so that we do not move too far from world position. 
LocalTransformManipContainer:Property({"MaxTranslateDistance", 3,});
LocalTransformManipContainer:Property({"textColor", 0x20ffffff, "GetTextColor", "SetTextColor", auto=true});
LocalTransformManipContainer:Property({"PositionPlugName", "position", auto=true});
LocalTransformManipContainer:Property({"SupportUndo", true, "IsSupportUndo", "SetSupportUndo", auto=true});
LocalTransformManipContainer:Property({"LocalTransformPlugName", "LocalTransform", auto=true});
LocalTransformManipContainer:Property({"AngleGridStep", nil, "GetAngleGridStep", "SetAngleGridStep", auto=true}); -- this can be math.pi / 12

function LocalTransformManipContainer:ctor()
	self:SetShowPos(true);
	self:SetShowYPlane(true);	
	self:SetPlaneSize(4);
end

function LocalTransformManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip.radius = self.radius;
	self.translateManip:SetFixOrigin(true);
	self.translateManip:SetRealTimeUpdate(false);
	self.translateManip:SetUpdatePosition(false);
	
	self.scaleManip = self:AddScaleManip();
	self.scaleManip.radius = 0.5;
	self.scaleManip:SetRealTimeUpdate(false)
	self.scaleManip:SetUpdatePosition(false);

	self.rotateManip = self:AddRotateManip();
	self.rotateManip:SetYawPitchRollMode(true);
	self.rotateManip:SetRealTimeUpdate(false)
	self.rotateManip:SetUpdatePosition(false);
	self.rotateManip:SetGridStep(self:GetAngleGridStep());
end

-- TODO: shall we use 2,3,4 key to toggle between manipulator mode?
-- @param name: "translate|scale|rotate"
function LocalTransformManipContainer:UpdateManipMode(name)
	if(self.translateManip) then
		self.translateManip:SetVisible(name == "translate")
		self.translateManip.enabled = name == "translate"
	end
	if(self.scaleManip and self:IsShowScaling()) then
		self.scaleManip:SetVisible(name == "scale")
		self.scaleManip.enabled = name == "scale"
	end
	if(self.rotateManip and self:IsShowRotation()) then
		self.rotateManip:SetVisible(name == "rotate")
		self.rotateManip.enabled = name == "rotate"
	end
end


-- update plug transform to all manipulators' local tranforms. 
function LocalTransformManipContainer:UpdateManipTransforms()
	local node = self.node;
	if(node) then
		local plugTransform = node:findPlug(self:GetLocalTransformPlugName());
		local matLocal = plugTransform:GetValue()
		if(matLocal) then
			matLocal = matLocal:clone();
		else
			matLocal = mathlib.Matrix4:new():identity();
		end
		self:SetLocalTransform(node:GetWorldRotationTransform());

		local vPos = mathlib.vector3d:new({0,0,0})
		vPos:multiplyInPlace(matLocal);

		local outscale, outrotation, outtranslation = matLocal:Decompose()
		if(outrotation) then
			matLocal = outrotation:ToRotationMatrix(matLocal)
			-- we need to remove scaling from local transform when drawing manipulators
			matLocal:setTrans(vPos[1], vPos[2], vPos[3]);
		end

		self.translateManip:SetLocalTransform(matLocal);
		self.scaleManip:SetLocalTransform(matLocal);
		self.rotateManip:SetLocalTransform(matLocal);
	end
end

function LocalTransformManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug(self.PositionPlugName);
	local plugTransform = node:findPlug(self:GetLocalTransformPlugName());

	self.node = node;

	-- for one way position conversion for manip container
	local manipContainerPosPlug = self:findPlug("position");
	self:addPlugToManipConversionCallback(manipContainerPosPlug, function(self, manipPlug)
		return plugPos:GetValue();
	end);

	if(plugTransform) then
		node:Connect("facingChanged", function()
			self:UpdateManipTransforms()
		end);
		node:Connect("valueChanged", function()
			self:UpdateManipTransforms()
		end);
		
		-- translate
		local manipTranslatePlug = self.translateManip:findPlug("position");
		self:addPlugToManipConversionCallback(manipTranslatePlug, function(self, manipPlug)
			return {0, 0, 0};
		end);

		-- scale
		local manipScalePlug = self.scaleManip:findPlug("scaling");
		self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
			return {1, 1, 1};
		end);

		-- rotate
		local manipYawPlug = self.rotateManip:findPlug("yaw");
		self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
			return 0;
		end);
		local manipPitchPlug = self.rotateManip:findPlug("pitch");
		self:addPlugToManipConversionCallback(manipPitchPlug, function(self, manipPlug)
			return 0;
		end);
		local manipRollPlug = self.rotateManip:findPlug("roll");
		self:addPlugToManipConversionCallback(manipRollPlug, function(self, manipPlug)
			return 0;
		end);

		-- from manipulator's delta values to node's local transform. 
		self:addManipToPlugConversionCallback(plugTransform, function(self, plug)
			local pos = manipTranslatePlug:GetValue();
			local lastTransform = plugTransform:GetValue();
			if(not lastTransform) then
				lastTransform = mathlib.Matrix4:new():identity();
			end
			-- first decompose matrix
			local outscale, outrotation, outtranslation = lastTransform:Decompose()
			if(outscale) then
				local mScale = mathlib.Matrix4:new():identity();
				local scale = manipScalePlug:GetValue();
				outscale[1] = outscale[1] * scale[1]
				outscale[2] = outscale[2] * scale[2]
				outscale[3] = outscale[3] * scale[3]
				mScale:setScale(outscale[1], outscale[2], outscale[3]);
				
				local yaw = manipYawPlug:GetValue()
				local roll = manipRollPlug:GetValue()
				local pitch = manipPitchPlug:GetValue()
				if(yaw~=0 or roll~=0 or pitch~=0) then
					local quat = mathlib.Quaternion:new():FromEulerAnglesSequence(roll, pitch, yaw, "zxy");
					outrotation = outrotation * quat;
				end
				local mRot = outrotation:ToRotationMatrix();

				if(pos[1]~=0 or pos[2]~=0 or pos[3]~=0) then
					pos = mathlib.vector3d:new({pos[1], pos[2], pos[3]})
					local offset = pos*mRot
					outtranslation:add(offset);
				end

				-- Compose back to affine matrix
				lastTransform = mScale:multiply(mRot)
				lastTransform:setTrans(outtranslation[1], outtranslation[2], outtranslation[3])
				self:SnapshotToHistory(lastTransform)
			end
			return lastTransform;
		end);

		self:SnapshotToHistory(plugTransform:GetValue())
	end
	
	self:ShowWithObject(node);
	self:UpdateManipTransforms();

	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	LocalTransformManipContainer._super.connectToDependNode(self, node);
end

function LocalTransformManipContainer:paintEvent(painter)
	painter:SetPen(self.pen);
	self:paintPlanes(painter);
	LocalTransformManipContainer._super.paintEvent(self, painter)
end


-- @return true if added to history
function LocalTransformManipContainer:SnapshotToHistory(transform)
	if(self:IsSupportUndo()) then
		self.history = self.history or {}
		local lastItem = self:GetHistoryItem()
		local newItem = {transform};
		-- remove duplicated calls
		if(not lastItem or not commonlib.compare(newItem[1], lastItem[1])) then
			self.history[#(self.history) + 1] = newItem;
			return true
		end
	end
end

-- @param offsetFromTop: default to 0, which is the top most one. this can be -1 to fetch the one before top most one
function LocalTransformManipContainer:GetHistoryItem(offsetFromTop)
	return self.history and self.history[#(self.history) + (offsetFromTop or 0)];
end

function LocalTransformManipContainer:Undo()
	local historyItem = self:GetHistoryItem()
	local lastItem = historyItem and historyItem[1];
	local plugTransform = self.node:findPlug(self:GetLocalTransformPlugName());
	if(self.node and plugTransform and historyItem) then
		local newItem = plugTransform:GetValue();
		local isLastOne;
		if(commonlib.compare(newItem, lastItem)) then
			if(#(self.history) > 1) then
				self.history[#(self.history)] = nil;
				historyItem = self:GetHistoryItem()
				lastItem = historyItem[1]
			else
				isLastOne = true;
			end
		end
		if(not isLastOne) then
			-- always preserve last one and pop others. 
			if(#(self.history) > 1) then
				self.history[#(self.history)] = nil;
			end
			plugTransform:SetValue(lastItem)
		end
	end
	return true
end

function LocalTransformManipContainer:Redo()
	return true
end

-- virtual: actually means key stroke. 
function LocalTransformManipContainer:keyPressEvent(key_event)
	if(self:IsSupportUndo()) then
		local keyseq = key_event:GetKeySequence();
		if(keyseq == "Undo") then
			if(self:Undo()) then
				key_event:accept()
			end
		elseif(keyseq == "Redo") then
			if(self:Redo()) then
				key_event:accept()
			end
		end
	end
end