--[[
Title: Quaternion
Author(s): LiXizhi
Date: 2015/9/2, ported from C++ ParaEngine
Desc: Class encapsulating a standard quaternion {x,y,z,w}.

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/math/Quaternion.lua");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
echo({Quaternion:new():FromEulerAngles(1.57, 1.1, 1.1):ToEulerAngles()});
echo({Quaternion:new():FromEulerAnglesSequence(1.57, 1.1, 1.1, "zxy"):ToEulerAnglesSequence("zxy")});
local q1 = Quaternion:new():identity();
local q2 = Quaternion:new():identity();
local q = q1 * q2;
echo(q);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/math3d.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local math3d = commonlib.gettable("mathlib.math3d");
local type = type;
local Quaternion = commonlib.gettable("mathlib.Quaternion");
Quaternion.__index = Quaternion;

-- create a new matrix
function Quaternion:new(o)
	o = o or {0,0,0,1};
	setmetatable(o, self);
	return o;
end

function Quaternion:clone()
	return Quaternion:new({unpack(self)});
end

function Quaternion:set(q)
	self[1] = q[1]; self[2] = q[2]; self[3] = q[3]; self[4] = q[4];
	return self;
end

-- make this identity
function Quaternion:identity()
	return self:set(Quaternion.IDENTITY);
end

function Quaternion:equals(v)
	return (self[1] == v[1] and self[2] == v[2] and self[3] == v[3] and self[4] == v[4]);
end

function Quaternion.__add(a,b)
	return Quaternion:new({a[1]+b[1], a[2]+b[2], a[3]+b[3], a[4]+b[4]})
end

function Quaternion.__sub(a,b)
	return Quaternion:new({a[1]-b[1], a[2]-b[2], a[3]-b[3], a[4]-b[4]})
end

-- rotate quaternion or a vector3
-- q3*(q2*q1) = rotate q1 and then q2, then q3
-- @param b: can be vector3d or Quaternion
-- @return quaternion or a vector3 depending on what b is. 
function Quaternion.__mul(a,b)
	if(b[4]) then
		return Quaternion:new({
			a[4] * b[1] + a[1] * b[4] + a[2] * b[3] - a[3] * b[2],
			a[4] * b[2] + a[2] * b[4] + a[3] * b[1] - a[1] * b[3],
			a[4] * b[3] + a[3] * b[4] + a[1] * b[2] - a[2] * b[1],
			a[4] * b[4] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3]
		});
	else
		return { Quaternion.RotateVector3(a, b[1], b[2], b[3]) }
	end
end

-- use this if one do not want to create additional vector3 table
function Quaternion:RotateVector3(vx, vy, vz)
	local x = self[1] * 2;
	local y = self[2] * 2;
	local z = self[3] * 2;
	local xx = self[1] * x;
	local yy = self[2] * y;
	local zz = self[3] * z;
	local xy = self[1] * y;
	local xz = self[1] * z;
	local yz = self[2] * z;
	local wx = self[4] * x;
	local wy = self[4] * y;
	local wz = self[4] * z;
	local rx = (1.0 - (yy + zz)) * vx + (xy - wz) * vy + (xz + wy) * vz;
	local ry = (xy + wz) * vx + (1.0 - (xx + zz)) * vy + (yz - wx) * vz;
	local rz = (xz - wy) * vx + (yz + wx) * vy + (1.0 - (xx + yy)) * vz;
	return rx, ry, rz;
end

-- multiplay in place without creating a new quaternion
-- -- q3*(q2*q1) = rotate q1 and then q2, then q3
function Quaternion:multiplyInplace(b)
	local a = self;
	self[1], self[2], self[3], self[4] = a[4] * b[1] + a[1] * b[4] + a[2] * b[3] - a[3] * b[2],
		a[4] * b[2] + a[2] * b[4] + a[3] * b[1] - a[1] * b[3],
		a[4] * b[3] + a[3] * b[4] + a[1] * b[2] - a[2] * b[1],
		a[4] * b[4] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3]
	return self;
end

--This constructor creates a new quaternion that will rotate vector
-- a into vector b about their mutually perpendicular axis. (if one exists)
function Quaternion:FromVectorToVector(a, b)
	local factor = a:length() * b:length();

	if (math.abs(factor) > 0.000001) then
		-- Vectors have length > 0
		local dot = a:dot(b) / factor;
		local theta = math.acos(mathlib.clamp(dot, -1.0, 1.0));

		local pivotVector = a*b;
		if (dot < 0.0 and pivotVector:length() < 0.000001) then
			-- Vectors parallel and opposite direction, therefore a rotation
			-- of 180 degrees about any vector perpendicular to this vector
			-- will rotate vector a onto vector b.
			-- The following guarantees the dot-product will be 0.0.
			local dominantIndex = a:dominantAxis();
			pivotVector[dominantIndex] = -a[(dominantIndex) % 3+1];
			pivotVector[(dominantIndex) % 3 + 1] = a[dominantIndex];
			pivotVector[(dominantIndex + 1) % 3 + 1] = 0.0;
		end
		self:FromAngleAxis(theta, pivotVector);
	else
		self[1], self[2], self[3], self[4] = 0,0,0,1;
	end
	return self;
end

-- @param rkAxis: may not be normalized
function Quaternion:FromAngleAxis(rfAngle, rkAxis)
    -- The quaternion representing the rotation is
    --   q = cos(A/2)+sin(A/2)*(x*i+y*j+z*k)
	local sumOfSquares = rkAxis:length2();
	if(sumOfSquares <= 0.00001) then
		-- Axis too small.
		self[1], self[2], self[3], self[4] = 0,0,0,1;
	else
		local fHalfAngle = (rfAngle * 0.5);
		local fSin = math.sin(fHalfAngle);
		if(sumOfSquares ~= 1.0) then
			fSin = fSin / (sumOfSquares^0.5);
		end
		self[1] = fSin*rkAxis[1];
		self[2] = fSin*rkAxis[2];
		self[3] = fSin*rkAxis[3];
		self[4] = math.cos(fHalfAngle);
	end
	return self;
end

-- @return angle, axis: float, vector3d
function Quaternion:ToAngleAxis()
	local rfAngle;
	local rkAxis = vector3d:new();
    --The quaternion representing the rotation is
    --   q = cos(A/2)+sin(A/2)*(x*i+y*j+z*k)
	local x,y,z = self[1], self[2], self[3];
    local fSqrLength = x*x+y*y+z*z;
    if ( fSqrLength > 0.0 ) then
        rfAngle = math.acos(self[4])*2;
        local fInvLength = 1 / (fSqrLength ^ 0.5);
        rkAxis[1] = x*fInvLength;
        rkAxis[2] = y*fInvLength;
        rkAxis[3] = z*fInvLength;
    else
        -- angle is 0 (mod 2*pi), so any axis will do
        rfAngle = 0.0;
        rkAxis[1] = 1.0;
        rkAxis[2] = 0.0;
        rkAxis[3] = 0.0;
    end
	return rfAngle, rkAxis;
end

function Quaternion:tostring()
    return format("%f %f %f %f",self[1],self[2],self[3], self[4])
end

function Quaternion:tostringAngleAxis()
	local angle, axis = self:ToAngleAxis()
	return format("%f: %f %f %f",angle,axis[1],axis[2], axis[3])
end

-- transform to another coordinate system. 
function Quaternion:TransformAxisByMatrix(mat)
	local angle, axis = self:ToAngleAxis();
	axis:normalize();
	axis = axis*mat;
	return self:FromAngleAxis(angle, axis);
end

-- Conversion Euler(pitch first) to Quaternion, see also self:FromEulerAnglesSequence(a1,a2,a2, "xzy")
-- @param heading(yaw), attitude(roll), bank(pitch)
-- @returns: self
function Quaternion:FromEulerAngles(heading, attitude, bank) 
    -- Assuming the angles are in radians.    
    local c1 = math.cos(heading/2);    
    local s1 = math.sin(heading/2);    
    local c2 = math.cos(attitude/2);    
    local s2 = math.sin(attitude/2);    
    local c3 = math.cos(bank/2);    
    local s3 = math.sin(bank/2);
    local c1c2 = c1*c2;    
    local s1s2 = s1*s2;
    w =c1c2*c3 - s1s2*s3;
  	x =c1c2*s3 + s1s2*c3;
	y =s1*c2*c3 + c1*s2*s3;
	z =c1*s2*c3 - s1*c2*s3;
	self[1], self[2], self[3], self[4] =  x,y,z,w;
	return self;
end
local q1 = Quaternion:new();
local q2 = Quaternion:new();
local q3 = Quaternion:new();

-- Conversion Euler to Quaternion, 
-- @param rotSeq: "zxy"(if nil, this is default), "yzx"
-- "zxy": roll pitch and yaw, which is the order used in BipedObject. 
function Quaternion:FromEulerAnglesSequence(angle1,angle2,angle3, rotSeq) 
	-- same as following code
	if(not rotSeq or rotSeq == "zxy") then
		-- roll(z), pitch(x), yaw(y),  first roll and then pitch and yaw
		q1:FromAngleAxis(angle1, vector3d.unit_z);
		q2:FromAngleAxis(angle2, vector3d.unit_x);
		q3:FromAngleAxis(angle3, vector3d.unit_y);
	elseif(rotSeq == "yzx") then
		q1:FromAngleAxis(angle1, vector3d.unit_y);
		q2:FromAngleAxis(angle2, vector3d.unit_z);
		q3:FromAngleAxis(angle3, vector3d.unit_x);
	elseif(rotSeq == "xzy") then
		q1:FromAngleAxis(angle1, vector3d.unit_x);
		q2:FromAngleAxis(angle2, vector3d.unit_z);
		q3:FromAngleAxis(angle3, vector3d.unit_y);
	elseif(rotSeq == "yxz") then
		q1:FromAngleAxis(angle1, vector3d.unit_y);
		q2:FromAngleAxis(angle2, vector3d.unit_x);
		q3:FromAngleAxis(angle3, vector3d.unit_z);
	elseif(rotSeq == "xyz") then
		q1:FromAngleAxis(angle1, vector3d.unit_x);
		q2:FromAngleAxis(angle2, vector3d.unit_y);
		q3:FromAngleAxis(angle3, vector3d.unit_z);
	elseif(rotSeq == "zyx") then
		q1:FromAngleAxis(angle1, vector3d.unit_z);
		q2:FromAngleAxis(angle2, vector3d.unit_y);
		q3:FromAngleAxis(angle3, vector3d.unit_x);
	end
	self:set(q3:multiplyInplace(q2:multiplyInplace(q1)));
	
	return self;
end

-- from quaternion to euler angle pitch first. 
-- see also: self:ToEulerAnglesSequence("xzy")
-- @return heading, attitude, bank (yaw(y), roll(z), pitch(x))
function Quaternion:ToEulerAngles() 
	local heading, attitude, bank;
	local test = self[1]*self[2] + self[3]*self[4];
	if (test > 0.499) then -- singularity at north pole
		heading = 2 * math.atan2(self[1],self[4]);
		attitude = math.pi/2;
		bank = 0;
		return heading, attitude, bank
	end	
	if (test < -0.499) then -- singularity at south pole
		heading = -2 * math.atan2(self[1],self[4]);
		attitude = - math.pi/2;
		bank = 0;
		return heading, attitude, bank
	end
	local sqx = self[1]*self[1];    
	local sqy = self[2]*self[2];
	local sqz = self[3]*self[3];
    heading = math.atan2(2*self[2]*self[4]-2*self[1]*self[3] , 1 - 2*sqy - 2*sqz);
	attitude = math.asin(2*test);
	bank = math.atan2(2*self[1]*self[4]-2*self[2]*self[3] , 1 - 2*sqx - 2*sqz)
	return heading, attitude, bank
end

local function threeaxisrot(r11, r12, r21, r31, r32)
	return math.atan2( r31, r32 ), math.asin( r21 ), math.atan2( r11, r12 );
end

-- ported from: http://bediyap.com/programming/convert-quaternion-to-euler-rotations/
-- similar to ToEulerAngles(), but the order can be specified.
-- @param rotSeq: "zxy"(if nil, this is default), "yzx"
-- "zxy": roll(first) pitch and yaw, which is the order used in BipedObject. 
-- @return the order is same as rotSeq
function Quaternion:ToEulerAnglesSequence(rotSeq)
	rotSeq = rotSeq or "yxz"
	local x, y, z, w = self[1], self[2], self[3], self[4];
	if(rotSeq == "yxz") then
		return threeaxisrot( -2*(x*y - w*z),
			w*w - x*x + y*y - z*z,
			2*(y*z + w*x),
			-2*(x*z - w*y),
			w*w - x*x - y*y + z*z);
	elseif(rotSeq == "xzy") then
		return threeaxisrot( -2*(x*z - w*y),
			w*w + x*x - y*y - z*z,
			2*(x*y + w*z),
			-2*(y*z - w*x),
			w*w - x*x + y*y - z*z);
	elseif(rotSeq == "zxy") then
		return threeaxisrot( 2*(x*z + w*y),
			w*w - x*x - y*y + z*z,
			-2*(y*z - w*x),
			2*(x*y + w*z),
			w*w - x*x + y*y - z*z);
	elseif(rotSeq == "xyz") then
		return threeaxisrot( 2*(x*y + w*z),
			w*w + x*x - y*y - z*z,
			-2*(x*z - w*y),
			2*(y*z + w*x),
			w*w - x*x - y*y + z*z);
	elseif(rotSeq == "zyx") then
		return threeaxisrot( -2*(y*z - w*x),
			w*w - x*x - y*y + z*z,
			2*(x*z + w*y),
			-2*(x*y - w*z),
			w*w + x*x - y*y - z*z);
	elseif(rotSeq == "yzx") then
		return threeaxisrot( 2*(y*z + w*x),
			w*w - x*x + y*y - z*z,
			-2*(x*y - w*z),
			2*(x*z + w*y),
			w*w + x*x - y*y - z*z);
	end
end

local s_iNext = { [0] = 1, 2, 0 };

-- @param kRot: Matrix4 object
function Quaternion:FromRotationMatrix(kRot)
	-- Algorithm in Ken Shoemake's article in 1987 SIGGRAPH course notes
	-- article "Quaternion Calculus and Fast Animation".

	local m00, m01, m02 = kRot[1], kRot[2], kRot[3];
    local m10, m11, m12 = kRot[5], kRot[6], kRot[7];
    local m20, m21, m22 = kRot[9], kRot[10],kRot[11];
    
	local fTrace = m00 + m11 + m22;
	local fRoot;

	if (fTrace > 0) then
		--  |w| > 1/2, may as well choose w > 1/2
		fRoot = math.sqrt(fTrace + 1.0);  -- 2w
		self[4] = 0.5*fRoot;
		fRoot = 0.5 / fRoot;  --  1/(4w)
		self[1] = (m12 - m21)*fRoot;
		self[2] = (m20 - m02)*fRoot;
		self[3] = (m01 - m10)*fRoot;
	else
		-- |w| <= 1/2
		local i = 0;
		if (m11 > m00) then
			i = 1;
		end
		if (m22 > kRot:get(i,i)) then
			i = 2;
		end
		local j = s_iNext[i];
		local k = s_iNext[j];

		fRoot = math.sqrt(kRot:get(i,i) - kRot:get(j,j) - kRot:get(k,k) + 1.0);
		self[i+1] = 0.5 * fRoot;
		fRoot = 0.5 / fRoot;
		self[4] = (kRot:get(j,k) - kRot:get(k,j))*fRoot;
		self[j+1] = (kRot:get(i,j) + kRot:get(j,i))*fRoot;
		self[k+1] = (kRot:get(i,k) + kRot:get(k,i))*fRoot;
	end
end

function Quaternion:ToRotationMatrix(kRot)
	kRot = kRot or mathlib.Matrix4:new():identity();
    local fTx = self[1] + self[1];
	local fTy = self[2] + self[2];
	local fTz = self[3] + self[3];
    local fTwx = fTx*self[4];
    local fTwy = fTy*self[4];
    local fTwz = fTz*self[4];
    local fTxx = fTx*self[1];
    local fTxy = fTy*self[1];
    local fTxz = fTz*self[1];
    local fTyy = fTy*self[2];
    local fTyz = fTz*self[2];
    local fTzz = fTz*self[3];

    kRot[1] = 1.0-(fTyy+fTzz);      kRot[5] = fTxy-fTwz;			kRot[9] = fTxz+fTwy;
    kRot[2] = fTxy+fTwz;			kRot[6] = 1.0-(fTxx+fTzz);      kRot[10] = fTyz-fTwx;
    kRot[3] = fTxz-fTwy;			kRot[7] = fTyz+fTwx;			kRot[11] = 1.0-(fTxx+fTyy);
	return kRot;
end 
   
function Quaternion:Inverse()
    self[1], self[2], self[3], self[4] = -self[1],-self[2],-self[3], self[4];
end


-- const static identity matrix. 
Quaternion.IDENTITY = Quaternion:new({0, 0, 0, 1});
