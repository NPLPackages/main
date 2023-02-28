--[[
Title: 4x4 homogeneous matrix
Author(s): LiXizhi
Date: 2015/8/19, ported from C++ ParaEngine
Desc: Class encapsulating a standard 4x4 homogeneous matrix.
@remarks
    ParaEngine uses row vectors when applying matrix multiplications,
    This means a vector is represented as a single row, 4-column
    matrix. This has the effect that the transformations implemented
    by the matrices happens left-to-right e.g. if vector V is to be
    transformed by M1 then M2 then M3, the calculation would be
    V * M1 * M2 * M3 . The order that matrices are concatenated is
    vital since matrix multiplication is not commutative, i.e. you
    can get a different result if you concatenate in the wrong order.
	But it is fine to use this class in a column-major math, the math are the same.
@par
    ParaEngine deals with the differences between D3D and OpenGL etc.
    internally when operating through different render systems. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local m1 = Matrix4:new():identity();
local m2 = m1:clone():makeTrans(3, 3, 3);
local v = mathlib.vector3d:new(1,2,3);
v = v * (m1 * m2);
echo(v);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local math3d = commonlib.gettable("mathlib.math3d");
local vector3d = commonlib.gettable("mathlib.vector3d");
local type = type;
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
Matrix4.__index = Matrix4;

-- create a new matrix
function Matrix4:new(o)
	o = o or {};
	setmetatable(o, self);
	return o;
end

function Matrix4:clone()
	return Matrix4:new({unpack(self)});
end

function Matrix4:set(mat)
	for i=1,16 do
		self[i] = mat[i];
	end
	return self;
end

-- make this identity
function Matrix4:identity()
	return self:set(Matrix4.IDENTITY);
end

-- @return true if this is an identity matrix.
function Matrix4:isIdentity()
	return self:equals(Matrix4.IDENTITY);
end

function Matrix4:equals(mat)
	for i=1,16 do
		if(self[i] ~= mat[i]) then
			return false
		end
	end
	return true;
end

function Matrix4.__add(a,b)
	local mat = {};
	for i=1,16 do
		mat[i] = a[i] + b[i];
	end
	return Matrix4:new(mat);
end

function Matrix4.__sub(a,b)
	local mat = {};
	for i=1,16 do
		mat[i] = a[i] - b[i];
	end
	return Matrix4:new(mat);
end

-- @param b: can be vector3d or Matrix4
function Matrix4.__mul(a,b)
	local nSizeB = #b;
	if(nSizeB == 16) then
		return math3d.MatrixMultiply(nil, a, b);
	elseif(nSizeB == 3) then
		return math3d.MatrixMultiplyVector(nil, a, b)
	end
end

-- @param row: 0-3
-- @param col: 0-3
function Matrix4:get(row, col)
	return self[row*4+col+1];
end

-- Builds a translation matrix
function Matrix4:makeTrans(tx, ty, tz)
	self:set(Matrix4.IDENTITY);
	self[13] = tx;  self[14] = ty;  self[15] = tz;
	return self;
end

function Matrix4:offsetTrans(tx, ty, tz)
	self[13] = self[13]+tx;  self[14] = self[14]+ty;  self[15] = self[15]+tz;
	return self;
end

function Matrix4:addTranslation(tx, ty, tz)
	self[13] = self[13]+tx;  self[14] = self[14]+ty;  self[15] = self[15]+tz;
	return self;
end

function Matrix4:addScaling(sx, sy, sz)
	local m = Matrix4:new():identity()
	m:setScale(sx, sy, sz);
	return self:multiply(m);
end

function Matrix4:setScale(sx, sy, sz)
	self[1] = sx or 1;  	self[6] = sy or 1;  self[11] = sz or 1;
end

function Matrix4:setTrans(tx, ty, tz)
	self[13] = tx or 0;  self[14] = ty or 0;  self[15] = tz or 0;
end

function Matrix4:ApplyScaling(sx, sy, sz)
	self[1] = self[1] * sx;		self[2] = self[2] * sx;		self[3] = self[3] * sx;
	self[5] = self[5] * sy;		self[6] = self[6] * sy;		self[7] = self[7] * sy;
	self[9] = self[9] * sz;		self[10] = self[10] * sz;	self[11] = self[11] * sz;
	return self;
end

function Matrix4:RemoveScaling(Tolerance)
	Tolerance = Tolerance or 0.000001;
	-- For each row, find magnitude, and if its non-zero re-scale so its unit length.
	local SquareSum0 = (self[1] * self[1]) + (self[2] * self[2]) + (self[3] * self[3]);
	local SquareSum1 = (self[5] * self[5]) + (self[6] * self[6]) + (self[7] * self[7]);
	local SquareSum2 = (self[9] * self[9]) + (self[10] * self[10]) + (self[11] * self[11]);
	local Scale0 = (SquareSum0 - Tolerance) > 0 and 1/math.sqrt(SquareSum0) or 1;
	local Scale1 = (SquareSum1 - Tolerance) > 0 and 1/math.sqrt(SquareSum1) or 1;
	local Scale2 = (SquareSum2 - Tolerance) > 0 and 1/math.sqrt(SquareSum2) or 1;

	self[1] = self[1] * Scale0;		self[2] = self[2] * Scale0;		self[3] = self[3] * Scale0;
	self[5] = self[5] * Scale1;		self[6] = self[6] * Scale1;		self[7] = self[7] * Scale1;
	self[9] = self[9] * Scale2;		self[10] = self[10] * Scale2;	self[11] = self[11] * Scale2;
	return self;
end

-- return the inverse of this matrix
function Matrix4:inverse()
	local m00, m01, m02, m03 = self[1], self[2], self[3], self[4];
    local m10, m11, m12, m13 = self[5], self[6], self[7], self[8];
    local m20, m21, m22, m23 = self[9], self[10],self[11],self[12];
    local m30, m31, m32, m33 = self[13],self[14],self[15],self[16];

    local v0 = m20 * m31 - m21 * m30;
    local v1 = m20 * m32 - m22 * m30;
    local v2 = m20 * m33 - m23 * m30;
    local v3 = m21 * m32 - m22 * m31;
    local v4 = m21 * m33 - m23 * m31;
    local v5 = m22 * m33 - m23 * m32;

    local t00 = (v5 * m11 - v4 * m12 + v3 * m13);
    local t10 = - (v5 * m10 - v2 * m12 + v1 * m13);
    local t20 = (v4 * m10 - v2 * m11 + v0 * m13);
    local t30 = - (v3 * m10 - v1 * m11 + v0 * m12);

    local invDet = 1 / (t00 * m00 + t10 * m01 + t20 * m02 + t30 * m03);

    local d00 = t00 * invDet;
    local d10 = t10 * invDet;
    local d20 = t20 * invDet;
    local d30 = t30 * invDet;

    local d01 = - (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
    local d11 = (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
    local d21 = - (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
    local d31 = (v3 * m00 - v1 * m01 + v0 * m02) * invDet;

    v0 = m10 * m31 - m11 * m30;
    v1 = m10 * m32 - m12 * m30;
    v2 = m10 * m33 - m13 * m30;
    v3 = m11 * m32 - m12 * m31;
    v4 = m11 * m33 - m13 * m31;
    v5 = m12 * m33 - m13 * m32;

    local d02 = (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
    local d12 = - (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
    local d22 = (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
    local d32 = - (v3 * m00 - v1 * m01 + v0 * m02) * invDet;

    v0 = m21 * m10 - m20 * m11;
    v1 = m22 * m10 - m20 * m12;
    v2 = m23 * m10 - m20 * m13;
    v3 = m22 * m11 - m21 * m12;
    v4 = m23 * m11 - m21 * m13;
    v5 = m23 * m12 - m22 * m13;

    local d03 = - (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
    local d13 = (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
    local d23 = - (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
    local d33 = (v3 * m00 - v1 * m01 + v0 * m02) * invDet;

    return Matrix4:new({
        d00, d01, d02, d03,
        d10, d11, d12, d13,
        d20, d21, d22, d23,
        d30, d31, d32, d33});
end

-- determine whether self matrix is a mirroring transformation
function Matrix4:isMirroring()
    local u = vector3d:new(self[1], self[5], self[9]);
    local v = vector3d:new(self[2], self[6], self[10]);
    local w = vector3d:new(self[3], self[7], self[11]);

    -- for a true orthogonal, non-mirrored base, u:cross(v) == w
    -- If they have an opposite direction then we are mirroring
    local mirrorvalue = u:cross(v):dot(w);
    local ismirror = (mirrorvalue < 0);
    return ismirror;
end

-- Create an affine matrix for mirroring into an arbitrary plane:
function Matrix4.mirroring(plane)
    local nx,ny,nz,w = plane[1],plane[2],plane[3],plane[4];
    return Matrix4:new({
        (1.0 - 2.0 * nx * nx), (-2.0 * ny * nx), (-2.0 * nz * nx), 0,
        (-2.0 * nx * ny), (1.0 - 2.0 * ny * ny), (-2.0 * nz * ny), 0,
        (-2.0 * nx * nz), (-2.0 * ny * nz), (1.0 - 2.0 * nz * nz), 0,
        (2.0 * nx * w), (2.0 * ny * w), (2.0 * nz * w), 1
    });
end

-- Create a rotation matrix for rotating around the x axis
function Matrix4.rotationX(degrees)
    local radians = degrees * math.pi * (1.0 / 180.0);
    local cos = math.cos(radians);
    local sin = math.sin(radians);
    return Matrix4:new( {
        1, 0, 0, 0, 0, cos, sin, 0, 0, -sin, cos, 0, 0, 0, 0, 1
    });
end

-- Create a rotation matrix for rotating around the y axis
function Matrix4.rotationY(degrees)
    local radians = degrees * math.pi * (1.0 / 180.0);
    local cos = math.cos(radians);
    local sin = math.sin(radians);
    return Matrix4:new({
        cos, 0, -sin, 0, 0, 1, 0, 0, sin, 0, cos, 0, 0, 0, 0, 1
    });
end

-- Create a rotation matrix for rotating around the z axis
function Matrix4.rotationZ(degrees)
    local radians = degrees * math.pi * (1.0 / 180.0);
    local cos = math.cos(radians);
    local sin = math.sin(radians);
    return Matrix4:new({
        cos, sin, 0, 0, -sin, cos, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1
    });
end
-- Create an affine matrix for translation:
function Matrix4.translation(v)
    return Matrix4:new({1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, v[1], v[2], v[3], 1});
end
-- Create an affine matrix for scaling:
function Matrix4.scaling(v)
    return Matrix4:new({v[1], 0, 0, 0, 0, v[2], 0, 0, 0, 0, v[3], 0, 0, 0, 0, 1});
end

-- decompose affine matrix into scale, rotation and translation
-- @param outscale, outrotation, outtranslation: can be nil or output table objects 
-- @return outscale, outrotation, outtranslation: may return nil, if input m is not affine. 
function Matrix4:Decompose(outscale, outrotation, outtranslation)
	local m = self;
	outscale = outscale or mathlib.vector3d:new();
	outrotation = outrotation or mathlib.Quaternion:new();
	outtranslation = outtranslation or mathlib.vector3d:new();
	local normalized = Matrix4:new():identity();
	local vec = mathlib.vector3d:new();
	
	-- Compute the scaling part.
	vec[1]=m[1];
	vec[2]=m[2];
	vec[3]=m[3];
	outscale[1]=vec:length();
	
	vec[1]=m[5];
	vec[2]=m[6];
	vec[3]=m[7];
	outscale[2] = vec:length();
	
	vec[1]=m[9];
	vec[2]=m[10];
	vec[3]=m[11];
	outscale[3]=vec:length();
	
	-- Compute the translation part.
	outtranslation[1]=m[13];
	outtranslation[2]=m[14];
	outtranslation[3]=m[15];
	
	-- Let's calculate the rotation now
	if ( (outscale[1] == 0) or (outscale[2] == 0) or (outscale[3] == 0) ) then
		return
	end
	
	normalized[1]=m[1]/outscale[1];
	normalized[2]=m[2]/outscale[1];
	normalized[3]=m[3]/outscale[1];
	normalized[5]=m[5]/outscale[2];
	normalized[6]=m[6]/outscale[2];
	normalized[7]=m[7]/outscale[2];
	normalized[9]=m[9]/outscale[3];
	normalized[10]=m[10]/outscale[3];
	normalized[11]=m[11]/outscale[3];
	
	outrotation:FromRotationMatrix(normalized);
	return outscale, outrotation, outtranslation;
end

-- right multiply by another 4x4 matrix:
function Matrix4:multiply(m)
	local m1 = self;
	local m2 = m;
	local r11,r12,r13,r14 =
		m1[ 1] * m2[ 1] + m1[ 2] * m2[ 5] + m1[ 3] * m2[ 9] + m1[ 4] * m2[13],
		m1[ 1] * m2[ 2] + m1[ 2] * m2[ 6] + m1[ 3] * m2[10] + m1[ 4] * m2[14],
		m1[ 1] * m2[ 3] + m1[ 2] * m2[ 7] + m1[ 3] * m2[11] + m1[ 4] * m2[15],
		m1[ 1] * m2[ 4] + m1[ 2] * m2[ 8] + m1[ 3] * m2[12] + m1[ 4] * m2[16];
	local r21,r22,r23,r24 =								  
		m1[ 5] * m2[ 1] + m1[ 6] * m2[ 5] + m1[ 7] * m2[ 9] + m1[ 8] * m2[13],
		m1[ 5] * m2[ 2] + m1[ 6] * m2[ 6] + m1[ 7] * m2[10] + m1[ 8] * m2[14],
		m1[ 5] * m2[ 3] + m1[ 6] * m2[ 7] + m1[ 7] * m2[11] + m1[ 8] * m2[15],
		m1[ 5] * m2[ 4] + m1[ 6] * m2[ 8] + m1[ 7] * m2[12] + m1[ 8] * m2[16];
	local r31,r32,r33,r34 =											  
		m1[ 9] * m2[ 1] + m1[10] * m2[ 5] + m1[11] * m2[ 9] + m1[12] * m2[13],
		m1[ 9] * m2[ 2] + m1[10] * m2[ 6] + m1[11] * m2[10] + m1[12] * m2[14],
		m1[ 9] * m2[ 3] + m1[10] * m2[ 7] + m1[11] * m2[11] + m1[12] * m2[15],
		m1[ 9] * m2[ 4] + m1[10] * m2[ 8] + m1[11] * m2[12] + m1[12] * m2[16];
	local r41,r42,r43,r44 =											  
		m1[13] * m2[ 1] + m1[14] * m2[ 5] + m1[15] * m2[ 9] + m1[16] * m2[13],
		m1[13] * m2[ 2] + m1[14] * m2[ 6] + m1[15] * m2[10] + m1[16] * m2[14],
		m1[13] * m2[ 3] + m1[14] * m2[ 7] + m1[15] * m2[11] + m1[16] * m2[15],
		m1[13] * m2[ 4] + m1[14] * m2[ 8] + m1[15] * m2[12] + m1[16] * m2[16];
	self[ 1], self[ 2], self[ 3], self[ 4] = r11,r12,r13,r14;
	self[ 5], self[ 6], self[ 7], self[ 8] = r21,r22,r23,r24;
	self[ 9], self[10], self[11], self[12] = r31,r32,r33,r34;
	self[13], self[14], self[15], self[16] = r41,r42,r43,r44;
	return self;
end
function Matrix4:transpose( )
	local m00, m01, m02, m03 = self[1], self[2], self[3], self[4];
    local m10, m11, m12, m13 = self[5], self[6], self[7], self[8];
    local m20, m21, m22, m23 = self[9], self[10],self[11],self[12];
    local m30, m31, m32, m33 = self[13],self[14],self[15],self[16];
	self[ 1], self[ 2], self[ 3], self[ 4] = m00,m10,m20,m30;
	self[ 5], self[ 6], self[ 7], self[ 8] = m01,m11,m21,m31;
	self[ 9], self[10], self[11], self[12] = m02,m12,m22,m32;
	self[13], self[14], self[15], self[16] = m03,m13,m23,m33;
	return self;
end

-- string is a commar separated numbers like "1, 0, 0, ..."
function Matrix4:toString()
	return table.concat(self, ",");
end

-- return self;
function Matrix4:fromString(str)
	self:identity();
	if(str) then
		local index = 1;
		for v in str:gmatch("[^, ]+") do
			self[index] = tonumber(v);
			index = index + 1;
		end
	end
	return self;
end

function Matrix4:MatrixOrthoLH(Width, Height, zNearPlane, zFarPlane)
	self:identity();
    self[1] = 1.0 / Width;
	self[6] = 1.0 / Height;
	self[11] = 1.0 / (zFarPlane - zNearPlane);
	self[15] = -zNearPlane / (zFarPlane - zNearPlane);
	return self;
end

function Matrix4:MakeOrthoOffCenter(left, right, bottom, top, zNearPlane, zFarPlane)
	if(System.os.GetPlatform()=="win32") then
		return self:MakeOrthoOffCenterLH(left, right, bottom, top, zNearPlane, zFarPlane)
	else
		return self:MatrixOrthoOffCenterOpenGL(left, right, bottom, top, zNearPlane, zFarPlane)
	end
end

function Matrix4:MakeOrthoOffCenterLH(left, right, bottom, top, zNearPlane, zFarPlane)
	self:identity();
    self[1] = 2.0 / (right - left);
    self[6] = 2.0 / (top - bottom);
    self[11] = 1.0 / (zFarPlane - zNearPlane);
    self[13] = -1.0 -2.0 * left / (right - left);
    self[14] = 1.0 + 2.0 * top / (bottom - top);
    self[15] = zNearPlane / (zNearPlane - zFarPlane);
    return self;
end

function Matrix4:MatrixOrthoOffCenterOpenGL(left, right, bottom, top, zNearPlane, zFarPlane)
	self:identity();
	self[1] = 2 / (right - left);
	self[6] = 2 / (top - bottom);
	self[11] = 2 / (zNearPlane - zFarPlane);
	self[13] = (left + right) / (left - right);
	self[14] = (top + bottom) / (bottom - top);
	self[15] = (zNearPlane + zFarPlane) / (zNearPlane - zFarPlane);
	return self;
end


-- const static identity matrix. 
Matrix4.IDENTITY = Matrix4:new({1, 0, 0, 0,        0, 1, 0, 0,        0, 0, 1, 0,        0, 0, 0, 1 });
