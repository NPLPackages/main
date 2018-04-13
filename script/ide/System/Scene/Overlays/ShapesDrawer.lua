--[[
Title: ShapesDrawer
Author(s): LiXizhi@yeah.net
Date: 2015/8/12
Desc: ShapesDrawer provides static functions to help drawing standard shapes like cube, circle, etc, 
inside Overlay's paintEvent. 
Note: Performance is optimized by caching triangle tables. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
------------------------------------------------------------
]]

local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local ffi = ParaEngine.hasFFI and require('ffi');

if(ParaEngine.hasFFI) then
	local cube_template = ffi.new('struct Vector3[9]');
	cube_template[1].x, cube_template[1].y, cube_template[1].z = -1, -1, -1;
	cube_template[2].x, cube_template[2].y, cube_template[2].z = -1, 1, -1;
	cube_template[3].x, cube_template[3].y, cube_template[3].z = 1, 1, -1;
	cube_template[4].x, cube_template[4].y, cube_template[4].z = 1, -1, -1;
	cube_template[5].x, cube_template[5].y, cube_template[5].z = -1, -1, 1;
	cube_template[6].x, cube_template[6].y, cube_template[6].z = -1, 1, 1;
	cube_template[7].x, cube_template[7].y, cube_template[7].z = 1, 1, 1;
	cube_template[8].x, cube_template[8].y, cube_template[8].z = 1, -1, 1;
	
	local cube_vertices = ffi.new('struct Vector3[9]');
	-- 8 triangles
	local fake_cube_triangles = ffi.new('struct Vector3[24]');
	function FillFakeCubeTriangles_()
		fake_cube_triangles[0],fake_cube_triangles[1], fake_cube_triangles[2], fake_cube_triangles[3], fake_cube_triangles[4], fake_cube_triangles[5] =  cube_vertices[1],cube_vertices[2],cube_vertices[3],	cube_vertices[1],cube_vertices[3],cube_vertices[4];
		fake_cube_triangles[6],fake_cube_triangles[7], fake_cube_triangles[8], fake_cube_triangles[9], fake_cube_triangles[10], fake_cube_triangles[11] =  cube_vertices[5],cube_vertices[6],cube_vertices[7],	cube_vertices[5],cube_vertices[7],cube_vertices[8];
		fake_cube_triangles[12],fake_cube_triangles[13], fake_cube_triangles[14], fake_cube_triangles[15], fake_cube_triangles[16], fake_cube_triangles[17] =  cube_vertices[2],cube_vertices[6],cube_vertices[8],	cube_vertices[2],cube_vertices[8],cube_vertices[4];
		fake_cube_triangles[18],fake_cube_triangles[19], fake_cube_triangles[20], fake_cube_triangles[21], fake_cube_triangles[22], fake_cube_triangles[23] =  cube_vertices[1],cube_vertices[5],cube_vertices[7],	cube_vertices[1],cube_vertices[7],cube_vertices[3];
	end
	-- 12 triangles
	local cube_triangles =  ffi.new('struct Vector3[36]');
	function FillCubeTriangles_()
		cube_triangles[0],cube_triangles[1], cube_triangles[2], cube_triangles[3], cube_triangles[4], cube_triangles[5] =  cube_vertices[1],cube_vertices[2],cube_vertices[3],	cube_vertices[1],cube_vertices[3],cube_vertices[4];
		cube_triangles[6],cube_triangles[7], cube_triangles[8], cube_triangles[9], cube_triangles[10], cube_triangles[11] =  cube_vertices[5],cube_vertices[6],cube_vertices[7],	cube_vertices[5],cube_vertices[7],cube_vertices[8];
		cube_triangles[12],cube_triangles[13], cube_triangles[14], cube_triangles[15], cube_triangles[16], cube_triangles[17] =  cube_vertices[1],cube_vertices[2],cube_vertices[6],	cube_vertices[1],cube_vertices[6],cube_vertices[5];
		cube_triangles[18],cube_triangles[19], cube_triangles[20], cube_triangles[21], cube_triangles[22], cube_triangles[23] =  cube_vertices[4],cube_vertices[3],cube_vertices[7],	cube_vertices[4],cube_vertices[7],cube_vertices[8];
		cube_triangles[24],cube_triangles[25], cube_triangles[26], cube_triangles[27], cube_triangles[28], cube_triangles[29] =  cube_vertices[2],cube_vertices[6],cube_vertices[7],	cube_vertices[2],cube_vertices[7],cube_vertices[3];
		cube_triangles[30],cube_triangles[31], cube_triangles[32], cube_triangles[33], cube_triangles[34], cube_triangles[35] =  cube_vertices[1],cube_vertices[5],cube_vertices[8],	cube_vertices[1],cube_vertices[8],cube_vertices[4];
	end
	-- draw a cube by specifying its center and radius(half length)
	-- @param bFakeCube: if true (default), we will emulate a cube by drawing only 8 triangles, instead of 12. when no shading
	function ShapesDrawer.DrawCube(painter, x,y,z, radius, bFakeCube)
		for i=1,8 do
			local to = cube_vertices[i] 
			local from = cube_template[i] 
			to.x, to.y, to.z = x+from.x*radius, y+from.y*radius, z+from.z*radius;
		end	
		if(bFakeCube~=false) then
			FillFakeCubeTriangles_();
			painter:DrawTriangleList(fake_cube_triangles, 8);
		else
			FillCubeTriangles_();
			painter:DrawTriangleList(cube_triangles, 12);
		end
	end
	local lineList = ffi.new('struct Vector3[24]');

	-- draw a line
	function ShapesDrawer.DrawLine(painter, from_x,from_y,from_z, to_x, to_y, to_z)
		local from = lineList[0];
		from.x, from.y, from.z = from_x,from_y,from_z or 0;
		local to = lineList[1];
		to.x, to.y, to.z = to_x, to_y, to_z or 0;
		painter:DrawLineList(lineList, 1);
	end


	-- draw AABB
	-- @param bFill: if true, we will render box instead of boader lines. 
	function ShapesDrawer.DrawAABB(painter, min_x, min_y, min_z, max_x, max_y, max_z, bFill)
		if(bFill) then
			local cx, cy, cz = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5;
			local ex, ey,ez = math.abs(min_x - max_x)*0.5, math.abs(min_y - max_y) * 0.5, math.abs(min_z - max_z) * 0.5;
			for i=1,8 do
				local to = cube_vertices[i] 
				local from = cube_template[i] 
				to.x, to.y, to.z = cx+from.x*ex, cy+from.y*ey, cz+from.z*ez;
			end	
			painter:DrawTriangleList(cube_triangles, 12);
		else
			local pt;
			pt = lineList[0];
			pt.x, pt.y,pt.z = min_x, min_y, min_z;
			pt = lineList[1];
			pt.x, pt.y,pt.z = max_x, min_y, min_z;
			pt = lineList[2];
			pt.x, pt.y,pt.z = min_x, min_y, min_z;
			pt = lineList[3];
			pt.x, pt.y,pt.z = min_x, min_y, max_z;
			pt = lineList[4];
			pt.x, pt.y,pt.z = max_x, min_y, min_z;
			pt = lineList[5];
			pt.x, pt.y,pt.z = max_x, min_y, max_z;
			pt = lineList[6];
			pt.x, pt.y,pt.z = min_x, min_y, max_z;
			pt = lineList[7];
			pt.x, pt.y,pt.z = max_x, min_y, max_z;

			pt = lineList[8];
			pt.x, pt.y,pt.z = min_x, max_y, min_z;
			pt = lineList[9];
			pt.x, pt.y,pt.z = max_x, max_y, min_z;
			pt = lineList[10];
			pt.x, pt.y,pt.z = min_x, max_y, min_z;
			pt = lineList[11];
			pt.x, pt.y,pt.z = min_x, max_y, max_z;
			pt = lineList[12];			  
			pt.x, pt.y,pt.z = max_x, max_y, min_z;
			pt = lineList[13];
			pt.x, pt.y,pt.z = max_x, max_y, max_z;
			pt = lineList[14];
			pt.x, pt.y,pt.z = min_x, max_y, max_z;
			pt = lineList[15];
			pt.x, pt.y,pt.z = max_x, max_y, max_z;

			pt = lineList[16];
			pt.x, pt.y,pt.z = min_x, min_y, min_z;
			pt = lineList[17];
			pt.x, pt.y,pt.z = min_x, max_y, min_z;
			pt = lineList[18];
			pt.x, pt.y,pt.z = min_x, min_y, max_z;
			pt = lineList[19];
			pt.x, pt.y,pt.z = min_x, max_y, max_z;
			pt = lineList[20];			  
			pt.x, pt.y,pt.z = max_x, min_y, min_z;
			pt = lineList[21];
			pt.x, pt.y,pt.z = max_x, max_y, min_z;
			pt = lineList[22];
			pt.x, pt.y,pt.z = max_x, min_y, max_z;
			pt = lineList[23];
			pt.x, pt.y,pt.z = max_x, max_y, max_z;
		
			painter:DrawLineList(lineList, 12);
		end
	end

	local triangles_count = 256;
	local triangles_cache = ffi.new('struct Vector3[?]', triangles_count);
	

	local function GetVertice(nIndex)
		if(nIndex >= triangles_count) then
			local old_data = triangles_cache;
			triangles_cache = ffi.new('struct Vector3[?]', nIndex+256);
			for i=0, triangles_count - 1 do
				triangles_cache[i] = old_data[i];
			end
			triangles_count = nIndex+256;
		end
		return triangles_cache[nIndex];
	end

	local two_pi = 3.14159265359 * 2;
	local axis_index = {x=1, y=2, z=3};
	-- draw a circle perpendicular to a specified axis with center and radius
	-- @param axis: "x", "y", "z". perpendicular to which axis
	-- @param bFill: if true (default to nil), we will fill the circle with current brush 
	-- @param segment: if nil, we will automatically determine segment by radius. 
	-- @param fromAngle: default to 0;
	-- @param toAngle: default to 2*math.pi;
	-- @param center_offset: default to 0.
	function ShapesDrawer.DrawCircle(painter, cx,cy,cz, radius, axis, bFill, segment, fromAngle, toAngle, center_offset)
		fromAngle = fromAngle or 0;
		toAngle = toAngle or two_pi;
		if(toAngle<fromAngle) then
			toAngle = toAngle + two_pi;
		end
		if(not segment) then
			segment = math.max(5, math.min(100, radius*(toAngle - fromAngle)/0.05));
		end
		segment = math.floor(segment);
		local delta_angle = (toAngle - fromAngle) / segment;

		local last_x, last_y = math.cos(fromAngle)*radius, math.sin(fromAngle)*radius;
		local nIndex = 0;
		local triangles = triangles_cache;
		for i=1, segment do
			local angle = fromAngle+delta_angle*i;	
			local x, y = math.cos(angle)*radius, math.sin(angle)*radius;
			local v1 = GetVertice(nIndex);
			local v2 = GetVertice(nIndex+1);
			if(axis == "x") then
				v1.x, v1.y, v1.z = cx, cy + last_x, cz + last_y;
				v2.x, v2.y, v2.z = cx, cy + x, cz + y;
			elseif(axis == "y") then
				v1.x, v1.y, v1.z = cx + last_y, cy, cz + last_x;
				v2.x, v2.y, v2.z = cx + y, cy, cz + x;
			else -- "z"
				v1.x, v1.y, v1.z = cx + last_x, cy + last_y, cz;
				v2.x, v2.y, v2.z = cx + x, cy + y, cz;
			end
			if(bFill) then
				local v3 = GetVertice(nIndex+2);
				v3.x, v3.y, v3.z = cx, cy, cz; 
				if(center_offset and center_offset~=0) then
					if(axis == "x") then
						v3.x = v3.x + center_offset;
					elseif(axis == "y") then
						v3.y = v3.y + center_offset;
					else
						v3.z = v3.z + center_offset;
					end
				end
				nIndex = nIndex + 3;
			else
				nIndex = nIndex + 2;
			end
			last_x, last_y = x, y;
		end
		
		if(bFill) then
			painter:DrawTriangleList(triangles, segment);
		else
			painter:DrawLineList(triangles, segment);
		end
	end
else
	local cube_template = {
		{-1, -1, -1},	{-1, 1, -1},	{1, 1, -1},	{1, -1, -1},
		{-1, -1, 1},	{-1, 1, 1},		{1, 1, 1},	{1, -1, 1},
	};
	local cube_vertices = {	{},{},{},{},{},{},{},{},{},};
	-- 8 triangles
	local fake_cube_triangles = {
		cube_vertices[1],cube_vertices[2],cube_vertices[3],	cube_vertices[1],cube_vertices[3],cube_vertices[4],
		cube_vertices[5],cube_vertices[6],cube_vertices[7],	cube_vertices[5],cube_vertices[7],cube_vertices[8],
		cube_vertices[2],cube_vertices[6],cube_vertices[8],	cube_vertices[2],cube_vertices[8],cube_vertices[4],
		cube_vertices[1],cube_vertices[5],cube_vertices[7],	cube_vertices[1],cube_vertices[7],cube_vertices[3],
	};
	-- 12 triangles
	local cube_triangles = {
		cube_vertices[1],cube_vertices[2],cube_vertices[3],	cube_vertices[1],cube_vertices[3],cube_vertices[4],
		cube_vertices[5],cube_vertices[6],cube_vertices[7],	cube_vertices[5],cube_vertices[7],cube_vertices[8],
		cube_vertices[1],cube_vertices[2],cube_vertices[6],	cube_vertices[1],cube_vertices[6],cube_vertices[5],
		cube_vertices[4],cube_vertices[3],cube_vertices[7],	cube_vertices[4],cube_vertices[7],cube_vertices[8],
		cube_vertices[2],cube_vertices[6],cube_vertices[7],	cube_vertices[2],cube_vertices[7],cube_vertices[3],
		cube_vertices[1],cube_vertices[5],cube_vertices[8],	cube_vertices[1],cube_vertices[8],cube_vertices[4],
	}
	-- draw a cube by specifying its center and radius(half length)
	-- @param bFakeCube: if true (default), we will emulate a cube by drawing only 8 triangles, instead of 12. when no shading
	function ShapesDrawer.DrawCube(painter, x,y,z, radius, bFakeCube)
		for i=1,8 do
			local to = cube_vertices[i] 
			local from = cube_template[i] 
			to[1], to[2], to[3] = x+from[1]*radius, y+from[2]*radius, z+from[3]*radius;
		end	
		if(bFakeCube~=false) then
			painter:DrawTriangleList(fake_cube_triangles);
		else
			painter:DrawTriangleList(cube_triangles);
		end
	end

	local lineList = {
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
		{0,0,0}, {1,0,0},
	};

	-- draw a line
	function ShapesDrawer.DrawLine(painter, from_x,from_y,from_z, to_x, to_y, to_z)
		local from = lineList[1];
		from[1], from[2], from[3] = from_x,from_y,from_z or 0;
		local to = lineList[2];
		to[1], to[2], to[3] = to_x, to_y, to_z or 0;
		painter:DrawLineList(lineList, 1);
	end


	-- draw AABB
	-- @param bFill: if true, we will render box instead of boader lines. 
	function ShapesDrawer.DrawAABB(painter, min_x, min_y, min_z, max_x, max_y, max_z, bFill)
		if(bFill) then
			local cx, cy, cz = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5;
			local ex, ey,ez = math.abs(min_x - max_x)*0.5, math.abs(min_y - max_y) * 0.5, math.abs(min_z - max_z) * 0.5;
			for i=1,8 do
				local to = cube_vertices[i] 
				local from = cube_template[i] 
				to[1], to[2], to[3] = cx+from[1]*ex, cy+from[2]*ey, cz+from[3]*ez;
			end	
			painter:DrawTriangleList(cube_triangles);
		else
			local pt;
			pt = lineList[1];
			pt[1], pt[2], pt[3] = min_x, min_y, min_z;
			pt = lineList[2];
			pt[1], pt[2], pt[3] = max_x, min_y, min_z;
			pt = lineList[3];
			pt[1], pt[2], pt[3] = min_x, min_y, min_z;
			pt = lineList[4];
			pt[1], pt[2], pt[3] = min_x, min_y, max_z;
			pt = lineList[5];
			pt[1], pt[2], pt[3] = max_x, min_y, min_z;
			pt = lineList[6];
			pt[1], pt[2], pt[3] = max_x, min_y, max_z;
			pt = lineList[7];
			pt[1], pt[2], pt[3] = min_x, min_y, max_z;
			pt = lineList[8];
			pt[1], pt[2], pt[3] = max_x, min_y, max_z;

			pt = lineList[9];
			pt[1], pt[2], pt[3] = min_x, max_y, min_z;
			pt = lineList[10];
			pt[1], pt[2], pt[3] = max_x, max_y, min_z;
			pt = lineList[11];
			pt[1], pt[2], pt[3] = min_x, max_y, min_z;
			pt = lineList[12];
			pt[1], pt[2], pt[3] = min_x, max_y, max_z;
			pt = lineList[13];			  
			pt[1], pt[2], pt[3] = max_x, max_y, min_z;
			pt = lineList[14];
			pt[1], pt[2], pt[3] = max_x, max_y, max_z;
			pt = lineList[15];
			pt[1], pt[2], pt[3] = min_x, max_y, max_z;
			pt = lineList[16];
			pt[1], pt[2], pt[3] = max_x, max_y, max_z;

			pt = lineList[17];
			pt[1], pt[2], pt[3] = min_x, min_y, min_z;
			pt = lineList[18];
			pt[1], pt[2], pt[3] = min_x, max_y, min_z;
			pt = lineList[19];
			pt[1], pt[2], pt[3] = min_x, min_y, max_z;
			pt = lineList[20];
			pt[1], pt[2], pt[3] = min_x, max_y, max_z;
			pt = lineList[21];			  
			pt[1], pt[2], pt[3] = max_x, min_y, min_z;
			pt = lineList[22];
			pt[1], pt[2], pt[3] = max_x, max_y, min_z;
			pt = lineList[23];
			pt[1], pt[2], pt[3] = max_x, min_y, max_z;
			pt = lineList[24];
			pt[1], pt[2], pt[3] = max_x, max_y, max_z;
		
			painter:DrawLineList(lineList, 12);
		end
	end

	local ring_triangles = {};
	local circle_triangles = {};

	local function GetVertice(triangles, nIndex)
		local v = triangles[nIndex]
		if(not v) then
			v = {}
			triangles[nIndex] = v;
		end
		return v;
	end

	local two_pi = 3.14159265359 * 2;
	local axis_index = {x=1, y=2, z=3};
	-- draw a circle perpendicular to a specified axis with center and radius
	-- @param axis: "x", "y", "z". perpendicular to which axis
	-- @param bFill: if true (default to nil), we will fill the circle with current brush 
	-- @param segment: if nil, we will automatically determine segment by radius. 
	-- @param fromAngle: default to 0;
	-- @param toAngle: default to 2*math.pi;
	-- @param center_offset: default to 0.
	function ShapesDrawer.DrawCircle(painter, cx,cy,cz, radius, axis, bFill, segment, fromAngle, toAngle, center_offset)
		fromAngle = fromAngle or 0;
		toAngle = toAngle or two_pi;
		if(toAngle<fromAngle) then
			toAngle = toAngle + two_pi;
		end
		if(not segment) then
			segment = math.max(5, math.min(100, radius*(toAngle - fromAngle)/0.05));
		end
		segment = math.floor(segment);
		local delta_angle = (toAngle - fromAngle) / segment;

		local last_x, last_y = math.cos(fromAngle)*radius, math.sin(fromAngle)*radius;
		local nIndex = 1;
		local triangles = if_else(bFill, circle_triangles, ring_triangles);
		for i=1, segment do
			local angle = fromAngle+delta_angle*i;	
			local x, y = math.cos(angle)*radius, math.sin(angle)*radius;
			local v1 = GetVertice(triangles, nIndex);
			local v2 = GetVertice(triangles, nIndex+1);
			if(axis == "x") then
				v1[1], v1[2], v1[3] = cx, cy + last_x, cz + last_y;
				v2[1], v2[2], v2[3] = cx, cy + x, cz + y;
			elseif(axis == "y") then
				v1[1], v1[2], v1[3] = cx + last_y, cy, cz + last_x;
				v2[1], v2[2], v2[3] = cx + y, cy, cz + x;
			else -- "z"
				v1[1], v1[2], v1[3] = cx + last_x, cy + last_y, cz;
				v2[1], v2[2], v2[3] = cx + x, cy + y, cz;
			end
			if(bFill) then
				local v3 = GetVertice(triangles, nIndex+2);
				v3[1], v3[2], v3[3] = cx, cy, cz; 
				if(center_offset and center_offset~=0) then
					v3[axis_index[axis]] = v3[axis_index[axis]] + center_offset;
				end
				nIndex = nIndex + 3;
			else
				nIndex = nIndex + 2;
			end
			last_x, last_y = x, y;
		end
		if(bFill) then
			painter:DrawTriangleList(triangles, segment);
		else
			painter:DrawLineList(triangles, segment);
		end
	end
end



-- draw arrow head 
function ShapesDrawer.DrawArrowHead(painter, cx,cy,cz, axis, radius, length, segment)
	if(not segment) then
		segment = math.max(3, math.min(100, radius*(two_pi)/0.03));
	end
	segment = math.floor(segment);
	length = length or radius*2.5;
	ShapesDrawer.DrawCircle(painter, cx,cy,cz, radius, axis, true, segment, 0, two_pi);
	ShapesDrawer.DrawCircle(painter, cx,cy,cz, radius, axis, true, segment, 0, two_pi, length);
end