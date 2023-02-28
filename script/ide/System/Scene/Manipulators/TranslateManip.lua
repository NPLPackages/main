--[[
Title: TranslateManip Base 
Author(s): LiXizhi@yeah.net
Date: 2015/8/10
Desc: TranslateManip is manipulator for 3D rotation. 

Virtual functions:
	mousePressEvent(event)
	mouseMoveEvent
	mouseReleaseEvent
	draw
	connectToDependNode(node);

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Manipulators/TranslateManip.lua");
local TranslateManip = commonlib.gettable("System.Scene.Manipulators.TranslateManip");
local manip = TranslateManip:new():init();
manip:SetPosition(x,y,z);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/Manipulator.lua");
NPL.load("(gl)script/ide/math/Plane.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local Color = commonlib.gettable("System.Core.Color");
local Plane = commonlib.gettable("mathlib.Plane");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local TranslateManip = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.Manipulator"), commonlib.gettable("System.Scene.Manipulators.TranslateManip"));

TranslateManip:Property({"Name", "TranslateManip", auto=true});
TranslateManip:Property({"radius", 1});
TranslateManip:Property({"showArrowHead", true});
TranslateManip:Property({"showGroundSnap", false, "IsShowGroundSnap", "SetShowGroundSnap", auto=true});
TranslateManip:Property({"groundSnapColor", "#00ffff"});
TranslateManip:Property({"showGrid", false, "IsShowGrid", "SetShowGrid", auto=true});
TranslateManip:Property({"snapToGrid", false, "IsSnapToGrid", "SetSnapToGrid", auto=true});

TranslateManip:Property({"gridSize", 0.1, "GetGridSize", "SetGridSize", auto=true});
TranslateManip:Property({"gridOffset", {0,0,0}, "GetGridOffset", "SetGridOffset", auto=true});
-- whether to update values during dragging
TranslateManip:Property({"RealTimeUpdate", true, "IsRealTimeUpdate", "SetRealTimeUpdate", auto=true});
-- whether to update the manipulator's real position according to "position" variable.
TranslateManip:Property({"UpdatePosition", true, "IsUpdatePosition", "SetUpdatePosition", auto=true});
-- when rendering, the axis is fixed at "origin" (default to 0,0,0)
TranslateManip:Property({"FixOrigin", false, "IsFixOrigin", "SetFixOrigin", auto=true});
TranslateManip:Property({"origin", {0,0,0}, "GetOrigin", "SetOrigin", auto=true});

-- private: "x|y|z" current selected axis
TranslateManip:Property({"selectedAxis", nil});

function TranslateManip:ctor()
	self.names = {};
	self.gridOffset = {0,0,0};
	self:AddValue("position", {0,0,0});
end

function TranslateManip:OnValueChange(name, value)
	TranslateManip._super.OnValueChange(self);
	if(self.UpdatePosition and not self:IsDragging() and name == "position") then
		local x, y, z = unpack(value);
		self:SetPosition(x, y, z);
	end
end

function TranslateManip:IsDragging()
	return self.drag_offset ~= nil;
end

function TranslateManip:init(parent)
	TranslateManip._super.init(self, parent);
	return self;
end

local axis_dirs = {
	x = vector3d:new({1,0,0}),
	y = vector3d:new({0,1,0}),
	z = vector3d:new({0,0,1}),
}
-- @param axis: "x|y|z". default to current
-- @return vector3d
function TranslateManip:GetMoveDirByAxis(axis)
	return axis_dirs[axis or self.selectedAxis];
end

-- virtual: 
function TranslateManip:mousePressEvent(event)
	if(event:button() ~= "left") then
		return
	end
	event:accept();
	local name = self:GetActivePickingName();
	if(name == self.names.x) then
		self.selectedAxis = "x"
	elseif(name == self.names.y) then
		self.selectedAxis = "y"
	elseif(name == self.names.z) then
		self.selectedAxis = "z"
	elseif(name == self.names.xyz) then
		self.selectedAxis = "xyz";
	else
		self.selectedAxis = nil;
		self.drag_offset = nil;
		return;
	end
	local moveDir = self:GetMoveDirByAxis();
	self.last_mouse_x = event.x;
	self.last_mouse_y = event.y;
	self.old_position = self:GetField("position");
	if(self.old_position and not self.old_position[1])then
		local x, y, z = self:GetPosition();
		self.old_position[1] = x;
		self.old_position[2] = y;
		self.old_position[3] = z;
	end
	self.from_worldPosition = self:CalculateWorldOrigin();
	
	self.drag_offset = {x=0,y=0,z=0};

	-- calculate everything in view space. 
	if(moveDir) then
		local vecList = self:TransformVectorsInViewSpace({vector3d:new(0,0,0), moveDir:clone()});
		self.moveDir = vecList[2] - vecList[1];
		self.moveOrigin = vecList[1];
		-- final a virtual plane, containing the selected axis. 
		local planeVec;
		if(math.abs(self.moveDir[2]) < 0.6) then
			planeVec = vector3d:new(0,1,0);
		else
			planeVec = vector3d:new(1,0,0);
		end
		self.virtualPlane = Plane:new():redefine(self.moveDir*planeVec, self.moveOrigin);
		-- screenSpaceDir
		local vecList = self:TransformVectorsInScreenSpace({vector3d:new(0,0,0), moveDir:clone()});
		self.screenSpaceDir = vecList[2] - vecList[1];
		self.screenSpaceDir:normalize();
	else
		self.moveDir = nil;
		self.moveOrigin = nil;
	end
end

-- virtual: 
function TranslateManip:mouseMoveEvent(event)
	if(self.selectedAxis) then
		event:accept();
		if(self.selectedAxis == "xyz") then
			-- ray cast on ground based on mouse position. 
			if(self.from_worldPosition and SelectionManager.MousePickBlock) then
				local result = SelectionManager:MousePickBlock(nil, nil, nil, nil, event.x, event.y);
				if(result and result.x) then
					local x, y, z = result:GetPhysicalPos()
					if(x) then
						self.drag_offset.x = x - self.from_worldPosition[1]
						self.drag_offset.y = y - self.from_worldPosition[2]
						self.drag_offset.z = z - self.from_worldPosition[3]
						if(not self.pressDist) then
							self.pressDist = 1;
							self:BeginModify();
						else
							if(self:IsRealTimeUpdate()) then
								self:GrabValues();
							end
						end
					end
				end
			end
		else
			-- get the mouse position for mouse ray casting. 
			local mouseMoveDir = vector3d:new(event.x - self.last_mouse_x, event.y-self.last_mouse_y, 0);
			local dist = mouseMoveDir:dot(self.screenSpaceDir);
			local mouse_x = self.last_mouse_x + self.screenSpaceDir[1] * dist;
			local mouse_y = self.last_mouse_y + self.screenSpaceDir[2] * dist;
			if(not self.pressPoint) then
				mouse_x = self.last_mouse_x;
				mouse_y = self.last_mouse_y;
			end
			-- ray cast to virtual plane to obtain the mouse picking point. 
			local point = vector3d:new();
			local result, dist = self:MouseRayIntersectPlane(mouse_x, mouse_y, self.virtualPlane, point);
			if(result == 1) then
				if(not self.pressPoint) then
					self.pressPoint = point;
					self.pressDist = dist;
					self:BeginModify();
				else
					local dist = (point - self.pressPoint):dot(self.moveDir);
					self.drag_offset[self.selectedAxis] = dist;
					if(self:IsRealTimeUpdate()) then
						self:GrabValues();
					end
				end
			end
		end
	end
end

-- virtual: 
function TranslateManip:mouseReleaseEvent(event)
	if(event:button() ~= "left") then
		return
	end
	event:accept();
	self:GrabValues();
	self.selectedAxis = nil;
	self.drag_offset = nil;
	self.pressPoint = nil;
	self.pressDist = nil;
	self.old_position = nil;
	self.from_worldPosition = nil;
	if(self:IsUpdatePosition()) then
		local x, y, z = unpack(self:GetField("position", {0,0,0}));
		if(x) then
			self:SetPosition(x, y, z);
		end
	end
	self:EndModify();
end

function TranslateManip:GrabValues()
	if(self.drag_offset and self.old_position) then
		local x, y, z = unpack(self.old_position);
		if(x) then
			local new_x, new_y, new_z = x + self.drag_offset.x, y + self.drag_offset.y, z + self.drag_offset.z;
			self:SetNewPosition(new_x, new_y, new_z)
		end
	end
end

function TranslateManip:SetNewPosition(new_x, new_y, new_z)
	if(new_x) then
		if(self:IsSnapToGrid()) then
			new_x, new_y, new_z = self:SnapToGrid(new_x, new_y, new_z);
		end
		self:SetField("position", {new_x, new_y, new_z});
	end
end

function TranslateManip:SnapToGrid(new_x, new_y, new_z)
	local gridSize = self:GetGridSize();
	local offset = self:GetGridOffset();
	new_x = math.floor((new_x-offset[1])/gridSize + 0.5)*gridSize + offset[1];
	new_y = math.floor((new_y-offset[2])/gridSize + 0.5)*gridSize + offset[2];
	new_z = math.floor((new_z-offset[3])/gridSize + 0.5)*gridSize + offset[3];
	return new_x, new_y, new_z;
end

-- virtual: actually means key stroke. 
function TranslateManip:keyPressEvent(key_event)
end

-- @param axis: "x", "y", "z", "xyz"
-- @param name: current active name. if nil, it will load current active name
function TranslateManip:IsAxisHighlighted(axis, name)
	if(self.selectedAxis) then
		return self.selectedAxis == axis;
	else
		name = name or self:GetActivePickingName();
		return (self.names[axis] == name);
	end
end

function TranslateManip:HasPickingName(pickingName)
	return self.names.x == pickingName
		or self.names.y == pickingName
		or self.names.z == pickingName
		or self.names.xyz == pickingName;
end

function TranslateManip:paintEvent(painter)
	self.pen.width = self.PenWidth;
	local arrow_radius = self.PenWidth*5;
	painter:SetPen(self.pen);

	local isDrawingPickable = self:IsPickingPass();


	if(self.drag_offset) then
		if(self:IsFixOrigin()) then
			painter:TranslateMatrix(unpack(self:GetOrigin()));
		else
			if(not self:IsUpdatePosition()) then
				local old_x, old_y, old_z = unpack(self.old_position);
				if(old_x) then
					painter:TranslateMatrix(old_x, old_y, old_z);
				end
			end
		end
		
		if(not isDrawingPickable) then
			self:SetColorAndName(painter, Color.ChangeOpacity(self.lineColor,196));
			-- draw dragging path
			ShapesDrawer.DrawCube(painter, 0,0,0, self.pen.width);
			ShapesDrawer.DrawLine(painter, 0,0,0, self.drag_offset.x, self.drag_offset.y, self.drag_offset.z);
			ShapesDrawer.DrawCube(painter, self.drag_offset.x, self.drag_offset.y, self.drag_offset.z, self.pen.width);

			if(self.virtualPlane and self:IsShowGrid() and self.old_position) then
				self:SetColorAndName(painter, self.gridColor);
				-- draw grid
				local x, y, z = unpack(self:GetField("position"));
				if(x) then
					local new_x, new_y, new_z = self:SnapToGrid(x, y, z);
					local old_x, old_y, old_z = unpack(self.old_position);
				
					local offset_x, offset_y, offset_z = new_x-old_x, new_y-old_y, new_z-old_z;
					local gridSize = self:GetGridSize();
					local moveDir = self:GetMoveDirByAxis();
					if(moveDir) then
						for i=-5, 5 do
							local x, y, z = moveDir[1]*(i*gridSize) + offset_x, moveDir[2]*(i*gridSize) + offset_y, moveDir[3]*(i*gridSize) + offset_z;
							ShapesDrawer.DrawCube(painter, x, y, z, 0.02);
						end
					end
				end
			end
		end
		painter:TranslateMatrix(self.drag_offset.x, self.drag_offset.y, self.drag_offset.z);
	else
		if(self:IsFixOrigin()) then
			painter:TranslateMatrix(unpack(self:GetOrigin()));
		else
			if(not self:IsUpdatePosition()) then
				local x,y,z = unpack(self:GetField("position", {0,0,0}));
				if(x) then
					painter:TranslateMatrix(x, y, z);
				end
			end
		end
	end

	self:paintPlanes(painter);

	local x_name, y_name, z_name, xyz_name;
	if(isDrawingPickable) then
		x_name = self:GetNextPickingName();
		y_name = self:GetNextPickingName();
		z_name = self:GetNextPickingName();
		xyz_name = self:GetNextPickingName();
	end
	

	local name = self:GetActivePickingName();
	local radius = self.radius;
	local from_length = self.showGroundSnap and (radius / 5) or 0;

	if(self:IsAxisHighlighted("x", name)) then 
		self:SetColorAndName(painter, self.selectedColor, x_name);
	else
		if(not self.selectedAxis) then
			self:SetColorAndName(painter, self.xColor, x_name);
		else
			self:SetColorAndName(painter, Color.ChangeOpacity(self.xColor, 32), x_name);
		end
	end
	ShapesDrawer.DrawLine(painter, from_length,0,0, radius,0,0);
	if(self.showArrowHead) then
		ShapesDrawer.DrawArrowHead(painter, radius,0,0, "x", arrow_radius, nil, 8);
	end
	if(self:IsAxisHighlighted("y", name)) then 
		self:SetColorAndName(painter, self.selectedColor, y_name);
	else
		if(not self.selectedAxis) then
			self:SetColorAndName(painter, self.yColor, y_name);
		else
			self:SetColorAndName(painter, Color.ChangeOpacity(self.yColor, 32), y_name);
		end
	end
	ShapesDrawer.DrawLine(painter, 0,from_length,0, 0,radius,0);
	if(self.showArrowHead) then
		ShapesDrawer.DrawArrowHead(painter, 0,radius,0, "y", arrow_radius, nil, 8);
	end
	if(self:IsAxisHighlighted("z", name)) then 
		self:SetColorAndName(painter, self.selectedColor, z_name);
	else
		if(not self.selectedAxis) then
			self:SetColorAndName(painter, self.zColor, z_name);
		else
			self:SetColorAndName(painter, Color.ChangeOpacity(self.zColor, 32), y_name);
		end
	end
	ShapesDrawer.DrawLine(painter, 0,0,from_length, 0,0,radius);
	if(self.showArrowHead) then
		ShapesDrawer.DrawArrowHead(painter, 0,0,radius, "z", arrow_radius, nil, 8);
	end

	if(self.showGroundSnap) then
		-- center cross line
		if(self:IsAxisHighlighted("xyz", name)) then 
			self:SetColorAndName(painter, self.selectedColor, xyz_name);
		else
			self:SetColorAndName(painter, self.groundSnapColor, xyz_name);
		end
		ShapesDrawer.DrawLine(painter, 0,0,0, from_length,0,0);
		ShapesDrawer.DrawLine(painter, 0,0,0, 0,from_length,0);
		ShapesDrawer.DrawLine(painter, 0,0,0, 0,0,from_length);
	end

	if(isDrawingPickable) then
		self.names.x = x_name;
		self.names.y = y_name;
		self.names.z = z_name;
		self.names.xyz = xyz_name;
	end
end


