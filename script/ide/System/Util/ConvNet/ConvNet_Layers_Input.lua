--[[
Title: ConvNet Input layer
Author(s): LiXizhi
Date: 2022/8/20
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.InputLayer:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local InputLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.InputLayer"));

function InputLayer:ctor()
end

function InputLayer:Init(opt)
	opt = opt or {};
	self.out_depth = ConvNet.getopt(opt, {"out_depth", "depth"}, 2);
	self.out_sx = ConvNet.getopt(opt, {'out_sx', 'sx', 'width'}, 1);
    self.out_sy = ConvNet.getopt(opt, {'out_sy', 'sy', 'height'}, 1);
	self.layer_type = "input";
	return self;
end

-- simply identity function for now
function InputLayer:forward(V, is_training)
	self["in_act"] = V;
	self["out_act"] = V;
	return self["out_act"];
end

function InputLayer:backward()
end

function InputLayer:getParamsAndGrads()
	return {};
end

function InputLayer:toJSON()
	local json = {};
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	return json;
end

function InputLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
end