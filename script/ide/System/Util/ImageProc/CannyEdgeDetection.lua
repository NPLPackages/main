--[[
Title: Canny edge detection
Author(s): LiXizhi
Date: 2024/2/8
Desc: https://en.wikipedia.org/wiki/Canny_edge_detector
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ImageProc/CannyEdgeDetection.lua");
local CannyEdgeDetection = commonlib.gettable("System.Util.ImageProc.CannyEdgeDetection")
-------------------------------------------------------
]]

local CannyEdgeDetection = commonlib.inherit(nil, commonlib.gettable("System.Util.ImageProc.CannyEdgeDetection"));

function CannyEdgeDetection:ctor()
end

-- @param img: the input image. {width, height, data = {r,g,b,...}}
-- @param sigma: the standard deviation of the Gaussian filter. default to 1.4
-- @param lowThreshold: default to 20
-- @param highThreshold: default to 50
-- @param useL2Gradient: default to false. If true, it will use L2 norm for gradient magnitude, otherwise L1 norm.
function CannyEdgeDetection:Init(img, sigma, lowThreshold, highThreshold, useL2Gradient)
	self.img = img;
	self.sigma = sigma or 1.4;
	self.lowThreshold = lowThreshold or 20;
	self.highThreshold = highThreshold or 50;
	self.useL2Gradient = useL2Gradient or false;
	return self;
end

--[[
@param data - input pixels data
@param idx - the index of the central pixel
@param w - image width (width*4 in case of RGBA)
@param m - the gradient mask (for Sobel=[1, 2, 1])
]]
local function conv3x(data, idx, w, m)
  return (m[1]*data[idx - w - 4] + m[2]*data[idx - 4] + m[3]*data[idx + w - 4]
      -m[1]*data[idx - w + 4] - m[2]*data[idx + 4] - m[3]*data[idx + 4 + 4])
end

local function conv3y(data, idx, w, m)
  return (m[1]*data[idx - w - 4] + m[2]*data[idx - w] + m[3]*data[idx - w + 4]
      -(m[1]*data[idx + w - 4] + m[2]*data[idx + w] + m[3]*data[idx + w + 4]))
end

function CannyEdgeDetection:Convert(imagePath) 
	-- Load the image 
	local img = image.load(imagePath, 1, 'byte')

	-- Convert the image to grayscale
	local gray = image.rgb2y(img)

	-- Apply Gaussian blur
	local blur = image.gaussian(3)

	-- Apply Sobel operator to get the gradient magnitude and direction
	local gx = image.convolve(gray, image.gaussian1D(3):resize(1,3):t())
	local gy = image.convolve(gray, image.gaussian1D(3):resize(1,3))
	local mag = image.sqrt(image.add(image.cmul(gx, gx), image.cmul(gy, gy)))

	-- Apply non-maximum suppression
	local suppressed = image.convolve(mag, image.gaussian1D(3):resize(1,3):t())

	-- Apply double thresholding
	local highThreshold = 75
	local lowThreshold = 25
	local strongEdges = image.gt(suppressed, highThreshold)
	local weakEdges = image.cmul(image.gt(suppressed, lowThreshold), image.lt(suppressed, highThreshold))

	-- Apply edge tracking by hysteresis
	local edges = image.add(strongEdges, weakEdges)

	return edges
end