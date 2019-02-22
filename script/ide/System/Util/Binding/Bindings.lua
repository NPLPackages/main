--[[
Title: all kinds of bindings
Author(s): LiXizhi, 
Date: 2019/2/20
Desc: This static class is used for one-way or two-way databinding between two nodes. 
only update when value is changed. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/Binding/Bindings.lua");
local Binding = commonlib.gettable("System.Util.Binding");
------------------------------------------------------------
]]
local Binding = commonlib.gettable("System.Util.Binding");

function Binding.GetValue(node, propertyName, defaultValue)
	local v = (node.GetValue or node.GetField)(node, propertyName, defaultValue);
	return v;
end

function Binding.SetValue(node, propertyName, value)
	local result = (node.SetValue or node.SetField)(node, propertyName, value);
	return result;
end
local GetValue = Binding.GetValue;
local SetValue = Binding.SetValue;

-- return true if modified
function Binding.CheckSetValue(node, propertyName, value)
	if(GetValue(node, propertyName) ~= value) then
		SetValue(node, propertyName, value)
		return true;
	end
end

-- please note fromNode and toNode should have either GetValue or GetField method to get its property by name
-- @param fromDefaultValue: can be nil. then toDefaultValue will be used
-- @param toDefaultValue: can be nil. 
-- @param tolerance: if not nil, it will be used to compare number type values. smaller than this will be regarded as equal.
-- @param valueType: nil or "number" or "int" or "radian" or "angle"
-- @param minValue: nil
-- @param maxValue: nil
-- @return true if value is set
function Binding.NumberToString(fromNode, fromPropertyName, fromDefaultValue, toNode, toPropertyName, toDefaultValue, tolerance, valueType, minValue, maxValue)
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end

	local fromValue = GetValue(fromNode, fromPropertyName, fromDefaultValue);
	local newToValue;
	if(fromValue) then
		if(valueType == "int") then
			newToValue = format("%d", fromValue);
		elseif(tolerance and tolerance>=0.01) then
			newToValue = format("%f", fromValue);
		else	
			newToValue = tostring(fromValue);
		end
	end
	local oldToValue = GetValue(toNode, toPropertyName);
	if(fromValue == fromDefaultValue and not oldToValue and not toDefaultValue) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(newToValue and newToValue ~= oldToValue) then
		if(tolerance and tolerance~=0 and oldToValue and fromValue) then
			local oldValue = tonumber(oldToValue);
			if(oldValue and math.abs(oldValue-fromValue) < tolerance) then
				return
			end
		end
		SetValue(toNode, toPropertyName, newToValue);
		return true;
	elseif(not newToValue and oldToValue and oldToValue ~= toDefaultValue) then
		SetValue(toNode, toPropertyName, toDefaultValue);
		return true;
	end
end

function Binding.StringToNumber(fromNode, fromPropertyName, fromDefaultValue, toNode, toPropertyName, toDefaultValue, tolerance, valueType, minValue, maxValue)
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end

	local fromValue = GetValue(fromNode, fromPropertyName, fromDefaultValue);
	local newToValue;
	if(fromValue) then
		newToValue = tonumber(fromValue);
	end
	local oldToValue = GetValue(toNode, toPropertyName);
	if(fromValue == fromDefaultValue and not oldToValue and not toDefaultValue) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(newToValue and newToValue ~= oldToValue) then
		if(valueType == "int") then
			newToValue = math.floor(newToValue);
		end
		if( (minValue and minValue>newToValue) or (maxValue and maxValue<newToValue) ) then
			return
		end
		if(tolerance and tolerance~=0 and oldToValue and newToValue) then
			if(oldToValue and math.abs(oldToValue-newToValue) < tolerance) then
				return
			end
		end
		SetValue(toNode, toPropertyName, newToValue);
		return true;
	elseif(not newToValue and oldToValue and oldToValue~=toDefaultValue) then
		SetValue(toNode, toPropertyName, toDefaultValue);
		return true;
	end
end

function Binding.StringToString(fromNode, fromPropertyName, fromDefaultValue, toNode, toPropertyName, toDefaultValue)
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end	
	local fromValue = GetValue(fromNode, fromPropertyName, fromDefaultValue);
	local oldToValue = GetValue(toNode, toPropertyName);
	if(fromValue == fromDefaultValue and not oldToValue and not toDefaultValue) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(fromValue and fromValue ~= oldToValue) then
		SetValue(toNode, toPropertyName, fromValue);
		return true;
	elseif(not fromValue and oldToValue and oldToValue~=toDefaultValue) then
		SetValue(toNode, toPropertyName, toDefaultValue);
		return true;
	end
end

-- {0,0,0} to "0,0,0"
-- @param tolerance: default to 0.01
function Binding.PosVec3ToString(fromNode, fromPropertyName, fromDefaultValue, toNode, toPropertyName, toDefaultValue, tolerance, valueType)
	tolerance = tolerance or 0.01
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end	
	local fromValue = GetValue(fromNode, fromPropertyName, fromDefaultValue);
	local newToValue;
	if(fromValue) then
		if(valueType == "int") then
			newToValue = format("%d,%d,%d", fromValue[1], fromValue[2], fromValue[3]);
		elseif(tolerance and tolerance>=0.01) then
			newToValue = format("%f,%f,%f", fromValue[1], fromValue[2], fromValue[3]);
		else
			newToValue = string.format("%f,%f,%f", fromValue[1], fromValue[2], fromValue[3]);
		end
	end

	local oldToValue = GetValue(toNode, toPropertyName);
	if(not oldToValue and not toDefaultValue and commonlib.partialcompare(fromValue, fromDefaultValue, tolerance)) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(newToValue and newToValue~=oldToValue) then
		if(oldToValue) then
			local x, y, z = oldToValue:match("^([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)$");
			if(x and y and z) then
				x = tonumber(x);
				y = tonumber(y);
				z = tonumber(z);
				if(valueType == "int") then
					x = math.floor(x);
					y = math.floor(y);
					z = math.floor(z);
				end
				if(commonlib.partialcompare({x,y,z}, fromValue, tolerance)) then
					return
				end
			end
		end
		SetValue(toNode, toPropertyName, newToValue);
		return true;
	elseif(not fromValue and oldToValue and oldToValue~=toDefaultValue) then
		SetValue(toNode, toPropertyName, toDefaultValue);
		return true;
	end
end

-- "0,0,0" to {0,0,0}
-- @param tolerance: default to 0.01
function Binding.StringToPosVec3(fromNode, fromPropertyName, fromDefaultValue, toNode, toPropertyName, toDefaultValue, tolerance, valueType)
	tolerance = tolerance or 0.01
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end

	local fromValue = GetValue(fromNode, fromPropertyName, fromDefaultValue);
	local newToValue;
	if(fromValue) then
		local x, y, z = fromValue:match("^([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)$");
		if(x and y and z) then
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
			if(valueType == "int") then
				x = math.floor(x);
				y = math.floor(y);
				z = math.floor(z);
			end
			newToValue = {x,y,z};
		else
			return
		end
	end
	local oldToValue = GetValue(toNode, toPropertyName);
	if(fromValue == fromDefaultValue and not oldToValue and not toDefaultValue) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(newToValue and not commonlib.partialcompare(newToValue, oldToValue, tolerance)) then
		SetValue(toNode, toPropertyName, newToValue);
		return true;
	elseif(not newToValue and oldToValue and toDefaultValue and not commonlib.partialcompare(oldToValue, toDefaultValue, tolerance)) then
		SetValue(toNode, toPropertyName, toDefaultValue);
		return true;
	end
end

-- 0,0,0 to "0,0,0"
-- @param fromDefaultValue: default to 0
-- @param tolerance: default to 0.01
function Binding.XYZToString(fromNode, fromXName, fromYName, fromZName, fromDefaultValue, toNode, toPropertyName, toDefaultValue, tolerance, valueType)
	tolerance = tolerance or 0.01
	fromDefaultValue = fromDefaultValue or 0;
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end	
	local fromValueX = GetValue(fromNode, fromXName, fromDefaultValue);
	local fromValueY = GetValue(fromNode, fromYName, fromDefaultValue);
	local fromValueZ = GetValue(fromNode, fromZName, fromDefaultValue);
	local newToValue;
	if(fromValueX or fromValueY or fromValueZ) then
		if(valueType == "int") then
			newToValue = format("%d,%d,%d", fromValueX, fromValueY, fromValueZ);
		elseif(tolerance and tolerance>=0.01) then
			newToValue = format("%f,%f,%f", fromValueX, fromValueY, fromValueZ);
		else
			newToValue = string.format("%f,%f,%f", fromValueX, fromValueY, fromValueZ);
		end
	end

	local oldToValue = GetValue(toNode, toPropertyName);
	if(not oldToValue and not toDefaultValue and fromValueX==fromDefaultValue and fromValueY==fromDefaultValue and fromValueZ==fromDefaultValue) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(newToValue and newToValue~=oldToValue) then
		if(oldToValue) then
			local x, y, z = oldToValue:match("^([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)$");
			if(x and y and z) then
				x = tonumber(x);
				y = tonumber(y);
				z = tonumber(z);
				if(valueType == "int") then
					x = math.floor(x);
					y = math.floor(y);
					z = math.floor(z);
				end
				if(math.abs(x-fromValueX)<=tolerance and math.abs(y-fromValueY)<=tolerance and math.abs(z-fromValueZ)<=tolerance) then
					return
				end
			end
		end
		SetValue(toNode, toPropertyName, newToValue);
		return true;
	elseif(not newToValue and oldToValue and oldToValue~=toDefaultValue) then
		SetValue(toNode, toPropertyName, toDefaultValue);
		return true;
	end
end

-- "0,0,0" to 0,0,0
-- @param tolerance: default to 0.01
function Binding.StringToXYZ(fromNode, fromPropertyName, fromDefaultValue, toNode, toXName, toYName, toZName, toDefaultValue, tolerance, valueType)
	tolerance = tolerance or 0.01
	if(not fromNode) then
		return Binding.CheckSetValue(toNode, toPropertyName, toDefaultValue);
	end

	local fromValue = GetValue(fromNode, fromPropertyName, fromDefaultValue);
	local newToValueX, newToValueY, newToValueZ;
	if(fromValue) then
		local x, y, z = fromValue:match("^([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)$");
		if(x and y and z) then
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
			if(valueType == "int") then
				x = math.floor(x);
				y = math.floor(y);
				z = math.floor(z);
			end
			newToValueX, newToValueY, newToValueZ = x, y, z;
		else
			return
		end
	end
	local oldToValueX = GetValue(toNode, toXName);
	local oldToValueY = GetValue(toNode, toYName);
	local oldToValueZ = GetValue(toNode, toZName);
	if(fromValue == fromDefaultValue and (not oldToValueX and not oldToValueT and not oldToValueZ) and not toDefaultValue) then
		-- preserve nil value if fromValue is not changed
		return
	elseif(newToValueX) then
		local result;
		if(not oldToValueX or math.abs(oldToValueX-newToValueX) > tolerance) then
			SetValue(toNode, toXName, newToValueX);
			result =true;
		end
		if(not oldToValueY or math.abs(oldToValueY-newToValueY) > tolerance) then
			SetValue(toNode, toYName, newToValueY);
			result =true;
		end
		if(not oldToValueZ or math.abs(oldToValueZ-newToValueZ) > tolerance) then
			SetValue(toNode, toZName, newToValueZ);
			result =true;
		end
		return result;
	elseif(not newToValueX and (oldToValueX or oldToValueY or oldToValueZ) and toDefaultValue and (oldToValueX~=toDefaultValue or oldToValueY~=toDefaultValue or oldToValueZ~=toDefaultValue)) then
		SetValue(toNode, toXName, toDefaultValue);
		SetValue(toNode, toYName, toDefaultValue);
		SetValue(toNode, toZName, toDefaultValue);
		return true
	end
end