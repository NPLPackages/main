--[[
Title: QR Code reader
Author(s): LiXizhi
Date: 2024/3/12
Desc: based on https://github.com/zxing/zxing/blob/master/core/src/main/java/com/google/zxing/qrcode/detector/FinderPatternFinder.java
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/QRCode.lua");
local QRCode = commonlib.gettable("System.Util.ConvNet.QRCode")
-- better pre-process the image as black and white
local image = System.Util.ImageProc.Image:new():LoadFromFile("temp/qrcode.jpg")
image:Show("original");
local finder = QRCode.FinderPatternFinder:new():Init(image);
local result = finder:find();
for i = 1, #result do
	echo(result[i]);
	image:drawBox(result[i].posX, result[i].posY, result[i].estimatedModuleSize, 255, 0, 0);
end
image:Show("result");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;
local bxor = mathlib.bit.bxor;

-- Encapsulates a finder pattern, which are the three square patterns found in
-- the corners of QR Codes. It also encapsulates a count of similar finder patterns,
-- as a convenience to the finder's bookkeeping.
local QRCode = commonlib.gettable("System.Util.ConvNet.QRCode");
local FinderPattern = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.QRCode.FinderPattern"));
local FinderPatternFinder = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.QRCode.FinderPatternFinder"));

function FinderPattern:ctor()
	self.estimatedModuleSize = 0;
	self.posX = 0;
	self.posY = 0;
	self.count = 0;
end

function FinderPattern:getX()
	return self.posX;
end

function FinderPattern:getY()
	return self.posY;
end

function FinderPattern:getCount()
	return self.count;
end

function FinderPattern:getEstimatedModuleSize()
	return self.estimatedModuleSize;
end

function FinderPattern:Init(posX, posY, estimatedModuleSize, count)
	self.posX = posX;
	self.posY = posY;
	self.estimatedModuleSize = estimatedModuleSize;
	self.count = count or 1;
	return self;
end

-- Determines if this finder pattern "about equals" a finder pattern at the stated
-- position and size -- meaning, it is at nearly the same center with nearly the same size.</p>
function FinderPattern:aboutEquals(moduleSize, i, j)
	if (math.abs(i - self.posY) <= moduleSize and math.abs(j - self.posX) <= moduleSize) then
		local moduleSizeDiff = math.abs(moduleSize - self.estimatedModuleSize);
		return moduleSizeDiff <= 1 or moduleSizeDiff / self.estimatedModuleSize <= 1;
	end
	return false;
end

function FinderPattern:__tostring()
	return string.format("posX:%d, posY:%d, estimatedModuleSize:%d, count:%d", self.posX, self.posY, self.estimatedModuleSize, self.count);
end

-- Combines this object's current estimate of a finder pattern position and module size
-- with a new estimate. It returns a new FinderPattern containing a weighted average based on count.
function FinderPattern:combineEstimate(i, j, newModuleSize)
	local combinedCount = self.count + 1;
	local combinedX = (self.count * self.posX + j) / combinedCount;
	local combinedY = (self.count * self.posY + i) / combinedCount;
	local combinedModuleSize = (self.count * self.estimatedModuleSize + newModuleSize) / combinedCount;
	local result = FinderPattern:new():Init(combinedX, combinedY, combinedModuleSize, combinedCount);
	return result;
end

-- This class attempts to find finder patterns in a QR Code. Finder patterns are the square
-- markers at three corners of a QR Code
FinderPatternFinder.CENTER_QUORUM = 2;
FinderPatternFinder.MIN_SKIP = 3; -- 1 pixel/module times 3 modules/center
FinderPatternFinder.MAX_MODULES = 97; -- support up to version 20 for mobile clients

function FinderPatternFinder:ctor()
	self.image = nil;
	self.possibleCenters = {};
	self.possibleDots = {};
	self.possibleOptionDots = {};
	self.hasSkipped = false;
	self.crossCheckStateCount = {0, 0, 0, 0, 0};
	self.resultPointCallback = nil;
	self.isStrictMode = true;
end

-- @param image: should be grey scale and sharpened
function FinderPatternFinder:Init(image, resultPointCallback)
	self.image = image;
	self.possibleCenters = {};
	self.crossCheckStateCount = {0, 0, 0, 0, 0};
	self.resultPointCallback = resultPointCallback;
	return self;
end

function FinderPatternFinder:SetStrictMode(strict_mode)
	self.isStrictMode = strict_mode;
end

function FinderPatternFinder:getImage()
	return self.image;
end

function FinderPatternFinder:getPossibleCenters()
	return self.possibleCenters;
end

local function doClearCounts(stateCount)
	for i = 1, #stateCount do
		stateCount[i] = 0;
	end
end

local function doShiftCounts2(stateCount) 
	stateCount[1] = stateCount[3];
	stateCount[2] = stateCount[4];
	stateCount[3] = stateCount[5];
	stateCount[4] = 1;
	stateCount[5] = 0;
end

local function shiftCounts2(stateCount)
	doShiftCounts2(stateCount);
end

--  Get square of distance between a and b.
local function squaredDistance(a, b)
	local x = a:getX() - b:getX();
	local y = a:getY() - b:getY();
	return x * x + y * y;
end

function FinderPatternFinder:getCrossCheckStateCount()
	doClearCounts(self.crossCheckStateCount)
	return self.crossCheckStateCount;
end

function FinderPatternFinder:CloneStateCount(stateCount)
	return {stateCount[1], stateCount[2], stateCount[3], stateCount[4], stateCount[5]};
end

function FinderPatternFinder:isBlack(x, y)
	local r,g,b = self.image:getPixel(x, y);
	-- if (not r) then
	-- 	print(x, y)
	-- 	print(commonlib.debugstack());
	-- end
	-- return r < 128 or g < 128 or b < 128;
	return r < 128;
end

function FinderPatternFinder:find(info)
	self:scan(info);
	local patternInfo = self:selectBestPatterns();
	if (not patternInfo) then self:scan_cross(info) end
	local patternInfo = self:selectBestPatterns();
	return patternInfo;
end

function FinderPatternFinder:scan(info)
	local tryHarder = info and info.tryHarder;
	local maxI = self.image.height;
	local maxJ = self.image.width;

	-- We are looking for black/white/black/white/black modules in
    -- 1:1:3:1:1 ratio; this tracks the number of such modules seen so far

	-- Let's assume that the maximum version QR Code we support takes up 1/4 the height of the
    -- image, and then account for the center being 3 modules in size. This gives the smallest
    -- number of pixels the center could be, so skip this often. When trying harder, look for all
    -- QR versions regardless of how dense they are.

	local iSkip = math.floor((3 * maxI) / (4 * FinderPatternFinder.MAX_MODULES));
	if (iSkip < FinderPatternFinder.MIN_SKIP or tryHarder) then
		iSkip = FinderPatternFinder.MIN_SKIP;
	end
	local done = false;
	local stateCount = {0, 0, 0, 0, 0};
	for i = iSkip, maxI, iSkip do
		-- Get a row of black/white values
		doClearCounts(stateCount);
		local currentState = 1;
		for j = 1, maxJ do
			if (self:isBlack(j, i)) then
				if (band(currentState, 1)) == 0 then   -- switch to black if counting on white
					currentState = currentState + 1;
				end
				stateCount[currentState] = stateCount[currentState] + 1;
			else
				if (band(currentState, 1) == 1) then -- switch to white if counting on black
					if (currentState == 5) then
						if (self:foundPatternCross(stateCount)) then -- yes, find black/white/black/white/black
							local confirmed = self:handlePossibleCenter(stateCount, i, j);
							if (confirmed and self.isStrictMode) then
								-- Start examining every other line. Checking each line turned out to be too
								-- expensive and didn't improve performance.
								iSkip = 2;
								if (self.hasSkipped) then
									done = self:haveMultiplyConfirmedCenters();
								else
									local rowSkip = math.floor(self:findRowSkip());
									if (rowSkip > stateCount[3]) then
										-- Skip rows between row of lower confirmed center
										-- and top of presumed third confirmed center
										-- but back up a bit to get a full chance of detecting
										-- it, entire width of center of finder pattern
										--
										-- Skip by rowSkip, but back off by stateCount[2] (size of last center
										-- of pattern we saw) to be conservative, and also back off by iSkip which
										-- is about to be re-added
										i = i + rowSkip - stateCount[3] - iSkip;
										j = maxJ;
									end
								end
								-- Clear state to start looking again
								currentState = 1;
								doClearCounts(stateCount);
							else
								doShiftCounts2(stateCount);
								currentState = 4;
							end
						else
							--  No, shift counts back by two
							shiftCounts2(stateCount);
							currentState = 4;
						end
					else
						currentState = currentState + 1;
						stateCount[currentState] = stateCount[currentState] + 1;
					end
				else
					-- Counting white pixels
					stateCount[currentState] = stateCount[currentState] + 1;
				end
			end
		end
		if (currentState == 5 and self:foundPatternCross(stateCount)) then
			local confirmed = self:handlePossibleCenter(stateCount, i, maxJ);
			if (confirmed and self.isStrictMode) then
				iSkip = stateCount[1];
				if (self.hasSkipped) then
					done = self:haveMultiplyConfirmedCenters();
				end
			end
		end
		if(done) then
			break;
		end
	end
end

function FinderPatternFinder:scan_cross(info)
	local tryHarder = info and info.tryHarder;
	local maxI = self.image.height;
	local maxJ = self.image.width;

	-- We are looking for black/white/black/white/black modules in
    -- 1:1:3:1:1 ratio; this tracks the number of such modules seen so far

	-- Let's assume that the maximum version QR Code we support takes up 1/4 the height of the
    -- image, and then account for the center being 3 modules in size. This gives the smallest
    -- number of pixels the center could be, so skip this often. When trying harder, look for all
    -- QR versions regardless of how dense they are.

	local iSkip = math.floor((3 * maxJ) / (4 * FinderPatternFinder.MAX_MODULES));
	if (iSkip < FinderPatternFinder.MIN_SKIP or tryHarder) then
		iSkip = FinderPatternFinder.MIN_SKIP;
	end

	local done = false;
	local stateCount = {0, 0, 0, 0, 0};
	for j = iSkip, maxJ, iSkip do
		-- Get a row of black/white values
		doClearCounts(stateCount);
		local currentState = 1;
		for i = 1, maxI do
			if (self:isBlack(j, i)) then
				if (band(currentState, 1)) == 0 then   -- switch to black if counting on white
					currentState = currentState + 1;
				end
				stateCount[currentState] = stateCount[currentState] + 1;
			else
				if (band(currentState, 1) == 1) then -- switch to white if counting on black
					if (currentState == 5) then
						if (self:foundPatternCross(stateCount)) then -- yes, find black/white/black/white/black
							local confirmed = self:handlePossibleCenterCross(stateCount, i, j);
							if (confirmed and self.isStrictMode) then
								-- Start examining every other line. Checking each line turned out to be too
								-- expensive and didn't improve performance.
								iSkip = 2;
								if (self.hasSkipped) then
									done = self:haveMultiplyConfirmedCenters();
								else
									local rowSkip = math.floor(self:findRowSkip());
									if (rowSkip > stateCount[3]) then
										-- Skip rows between row of lower confirmed center
										-- and top of presumed third confirmed center
										-- but back up a bit to get a full chance of detecting
										-- it, entire width of center of finder pattern
										--
										-- Skip by rowSkip, but back off by stateCount[2] (size of last center
										-- of pattern we saw) to be conservative, and also back off by iSkip which
										-- is about to be re-added
										i = i + rowSkip - stateCount[3] - iSkip;
										j = maxJ;
									end
								end
								-- Clear state to start looking again
								currentState = 1;
								doClearCounts(stateCount);
							else
								doShiftCounts2(stateCount);
								currentState = 4;
							end
						else
							--  No, shift counts back by two
							shiftCounts2(stateCount);
							currentState = 4;
						end
					else
						currentState = currentState + 1;
						stateCount[currentState] = stateCount[currentState] + 1;
					end
				else
					-- Counting white pixels
					stateCount[currentState] = stateCount[currentState] + 1;
				end
			end
		end
		if (currentState == 5 and self:foundPatternCross(stateCount)) then
			local confirmed = self:handlePossibleCenter(stateCount, maxI, j);
			if (confirmed and self.isStrictMode) then
				iSkip = stateCount[1];
				if (self.hasSkipped) then
					done = self:haveMultiplyConfirmedCenters();
				end
			end
		end
		if(done) then
			break;
		end
	end
end
-- Given a count of black/white/black/white/black pixels just seen and an end position,
-- figures the location of the center of this run.
function FinderPatternFinder:centerFromEnd(stateCount, endPos)
	return endPos - stateCount[4] - stateCount[5] - stateCount[3] / 2.0;
end

-- @param stateCount count of black/white/black/white/black pixels just read
-- @return true iff the proportions of the counts is close enough to the 1/1/3/1/1 ratios
--  used by finder patterns to be considered a match
function FinderPatternFinder:foundPatternCross(stateCount)
	local totalModuleSize = 0;
	for i = 1, 5 do
		local count = stateCount[i];
		if (count == 0) then
			return false;
		end
		totalModuleSize = totalModuleSize + count;
	end
	if (totalModuleSize < 7) then
		return false;
	end
	local moduleSize = totalModuleSize / 7.0;
	local maxVariance = moduleSize > 2 and (moduleSize / 2.0) or (moduleSize / 1);
	if (not self.isStrictMode) then
		-- maxVariance = moduleSize > 2 and (moduleSize / 1.5) or (moduleSize * 1.5);
		maxVariance = moduleSize > 2 and (moduleSize / 1.8) or (moduleSize * 1.2);
	end
	-- Allow less than 50% variance from 1-1-3-1-1 proportions
	-- for really small moduleSize(1-2 pixels), we use 100% variance
	return math.abs(moduleSize - stateCount[1]) < maxVariance and 
		math.abs(moduleSize - stateCount[2]) < maxVariance and 
		math.abs(3.0 * moduleSize - stateCount[3]) < 3 * maxVariance and 
		math.abs(moduleSize - stateCount[4]) < maxVariance and 
		math.abs(moduleSize - stateCount[5]) < maxVariance;
end

-- @param stateCount count of black/white/black/white/black pixels just read
-- @return true iff the proportions of the counts is close enough to the 1/1/3/1/1 ratios
--         used by finder patterns to be considered a match
  function FinderPatternFinder:foundPatternDiagonal(stateCount)
	local totalModuleSize = 0;
	for i = 1, 5 do
	  local count = stateCount[i];
	  if (count == 0) then
		return false;
	  end
	  totalModuleSize = totalModuleSize + count;
	end
	if (totalModuleSize < 7) then
	  return false;
	end
	local moduleSize = totalModuleSize / 7.0;
	local maxVariance = moduleSize > 2 and (moduleSize / 1.333) or (moduleSize / 1);
	-- Allow less than 75% variance from 1-1-3-1-1 proportions
	-- for really small moduleSize(1-2 pixels), we use 100% variance
	return math.abs(moduleSize - stateCount[1]) < maxVariance and 
	  math.abs(moduleSize - stateCount[2]) < maxVariance and 
	  math.abs(3.0 * moduleSize - stateCount[3]) < 3 * maxVariance and 
	  math.abs(moduleSize - stateCount[4]) < maxVariance and 
	  math.abs(moduleSize - stateCount[5]) < maxVariance;
  end


-- After a vertical and horizontal scan finds a potential finder pattern, this method
-- "cross-cross-cross-checks" by scanning down diagonally through the center of the possible
-- finder pattern to see if the same proportion is detected.
--
-- @param centerI row where a finder pattern was detected
-- @param centerJ center of the section that appears to cross a finder pattern
-- @return true if proportions are withing expected limits
function FinderPatternFinder:crossCheckDiagonal(centerI, centerJ)
	local stateCount = self:getCrossCheckStateCount();
	-- Start counting up, left from center finding black center
	local i = 0;
	while (centerI - i >= 1 and centerJ - i >= 1 and self:isBlack(centerJ - i, centerI - i)) do
		stateCount[3] = stateCount[3] + 1;
		i = i + 1;
	end
	if (stateCount[3] == 0) then
		return false;
	end
	-- Continue up, left finding white space
	while (centerI - i >= 1 and centerJ - i >= 1 and not self:isBlack(centerJ - i, centerI - i) and stateCount[2] <= stateCount[3]) do
		stateCount[2] = stateCount[2] + 1;
		i = i + 1;
	end
	-- If already too many modules in this state or ran off the edge:
	if (stateCount[2] > stateCount[3]) then
		return false;
	end
	-- Continue up, left finding black border
	while (centerI - i >= 1 and centerJ - i >= 1 and self:isBlack(centerJ - i, centerI - i) and stateCount[1] <= stateCount[2]) do
		stateCount[1] = stateCount[1] + 1;
		i = i + 1;
	end
	if (stateCount[1] > stateCount[2]) then
		return false;
	end
	local maxI = self.image.height;
	local maxJ = self.image.width;
	-- Now also count down, right from center
	i = 1;
	while (centerI + i <= maxI and centerJ + i <= maxJ and self:isBlack(centerJ + i, centerI + i)) do
		stateCount[3] = stateCount[3] + 1;
		i = i + 1;
	end
	while (centerI + i <= maxI and centerJ + i <= maxJ and not self:isBlack(centerJ + i, centerI + i) and stateCount[4] < stateCount[3]) do
		stateCount[4] = stateCount[4] + 1;
		i = i + 1
	end
	if (stateCount[4] >= stateCount[3]) then
		return false;
	end
	while (centerI + i <= maxI and centerJ + i <= maxJ and self:isBlack(centerJ + i, centerI + i) and stateCount[5] < stateCount[4]) do
		stateCount[5] = stateCount[5] + 1;
		i = i + 1;
	end
	if (stateCount[5] >= stateCount[4]) then
		return false;
	end
	-- If we found a finder-pattern-like section, but its size is more than 40% different than
	-- the original, assume it's a false positive
	local totalModuleSize = stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4] + stateCount[5];
	if (5 * math.abs(totalModuleSize - stateCount[1]) >= 2 * totalModuleSize) then
		return false;
	end
	return self:foundPatternCross(stateCount);
end

-- After a horizontal scan finds a potential finder pattern, this method
-- "cross-checks" by scanning down vertically through the center of the possible
-- finder pattern to see if the same proportion is detected.</p>
--
-- @param startI row where a finder pattern was detected
-- @param centerJ center of the section that appears to cross a finder pattern
-- @param maxCount maximum reasonable number of modules that should be
-- observed in any reading state, based on the results of the horizontal scan
-- @return vertical center of finder pattern, or false if not found
function FinderPatternFinder:crossCheckVertical(startI, centerJ, maxCount, originalStateCountTotal)
	local maxI = self.image.height;
	local stateCount = self:getCrossCheckStateCount();
	-- Start counting up from center
	local i = startI;
	while (i >= 1 and self:isBlack(centerJ, i)) do
		stateCount[3] = stateCount[3] + 1;
		i = i - 1;
	end
	if (i < 1 or stateCount[3] == 0) then
		return false;
	end
	while (i >= 1 and not self:isBlack(centerJ, i) and stateCount[2] <= maxCount) do
		stateCount[2] = stateCount[2] + 1;
		i = i - 1;
	end
	-- If already too many modules in this state or ran off the edge:
	if (stateCount[2] > maxCount or i < 1) then
		return false;
	end
	while (i >= 1 and self:isBlack(centerJ, i) and stateCount[1] <= maxCount) do
		stateCount[1] = stateCount[1] + 1;
		i = i - 1;
	end
	if (stateCount[1] > maxCount) then
		return false;
	end
	-- Now also count down from center
	i = startI + 1;
	while (i <= maxI and self:isBlack(centerJ, i)) do
		stateCount[3] = stateCount[3] + 1;
		i = i + 1;
	end
	if (i > maxI) then
		return false;
	end
	while (i <= maxI and not self:isBlack(centerJ, i) and stateCount[4] < maxCount) do
		stateCount[4] = stateCount[4] + 1;
		i = i + 1;
	end
	if (i > maxI or stateCount[4] >= maxCount) then
		return false;
	end
	while (i <= maxI and self:isBlack(centerJ, i) and stateCount[5] < maxCount) do
		stateCount[5] = stateCount[5] + 1;
		i = i + 1;
	end
	if (stateCount[5] >= maxCount)
	then
		return false;
	end

	-- If we found a finder-pattern-like section, but its size is more than 40% different than
	-- the original, assume it's a false positive
	local stateCountTotal = stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4] + stateCount[5];
	if (5 * math.abs(stateCountTotal - originalStateCountTotal) >= 2 * originalStateCountTotal) then
		return false;
	end
	return self:foundPatternCross(stateCount) and self:centerFromEnd(stateCount, i);
end

-- Like {@link #crossCheckVertical(int, int, int, int)}, and in fact is basically identical,
-- except it reads horizontally instead of vertically. This is used to cross-cross
-- check a vertical cross check and locate the real center of the alignment pattern.
function FinderPatternFinder:crossCheckHorizontal(startJ, centerI, maxCount, originalStateCountTotal)
	local maxJ = self.image.width;
	local stateCount = self:getCrossCheckStateCount();
	local j = startJ;
	while (j >= 1 and self:isBlack(j, centerI)) do
		stateCount[3] = stateCount[3] + 1;
		j = j - 1;
	end
	if (j < 1) then
		return false;
	end
	while (j >= 1 and not self:isBlack(j, centerI) and stateCount[2] <= maxCount) do
		stateCount[2] = stateCount[2] + 1;
		j = j - 1;
	end
	if (stateCount[2] > maxCount or j < 1) then
		return false;
	end
	while (j >= 1 and self:isBlack(j, centerI) and stateCount[1] <= maxCount) do
		stateCount[1] = stateCount[1] + 1;
		j = j - 1;
	end
	if (stateCount[1] > maxCount) then
		return false;
	end
	j = startJ + 1;
	while (j <= maxJ and self:isBlack(j, centerI)) do
		stateCount[3] = stateCount[3] + 1;
		j = j + 1;
	end
	if (j > maxJ) then
		return false;
	end
	while (j <= maxJ and not self:isBlack(j, centerI) and stateCount[4] < maxCount) do
		stateCount[4] = stateCount[4] + 1;
		j = j + 1;
	end
	if (j > maxJ or stateCount[4] >= maxCount) then
		return false;
	end
	while (j <= maxJ and self:isBlack(j, centerI) and stateCount[5] < maxCount) do
		stateCount[5] = stateCount[5] + 1;
		j = j + 1;
	end
	if (stateCount[5] >= maxCount) then
		return false;
	end

	-- If we found a finder-pattern-like section, but its size is significantly different than
	-- the original, assume it's a false positive
	local stateCountTotal = stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4] + stateCount[5];
	if (5 * math.abs(stateCountTotal - originalStateCountTotal) >= originalStateCountTotal) then
		return false;
	end
	return self:foundPatternCross(stateCount) and self:centerFromEnd(stateCount, j);
end

-- This is called when a horizontal scan finds a possible alignment pattern. It will
-- cross check with a vertical scan, and if successful, will, ah, cross-cross-check
-- with another horizontal scan. This is needed primarily to locate the real horizontal
-- center of the pattern in cases of extreme skew.
-- And then we cross-cross-cross check with another diagonal scan.
--
-- If that succeeds the finder pattern location is added to a list that tracks
-- the number of times each location has been nearly-matched as a finder pattern.
-- Each additional find is more evidence that the location is in fact a finder
-- pattern center
--
-- @param stateCount reading state module counts from horizontal scan
-- @param i row where finder pattern may be found
-- @param j end of possible finder pattern in row
-- @return true if a finder pattern candidate was found this time
function FinderPatternFinder:handlePossibleCenter(stateCount, i, j)
	local initStateCount = self:CloneStateCount(stateCount);
	local stateCountTotal = stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4] + stateCount[5];
	local centerJ = self:centerFromEnd(stateCount, j);
	local centerI, verticalStateCount = self:crossCheckVertical(i, math.floor(centerJ), stateCount[3], stateCountTotal);
	if (type(centerI) == "number") then
		centerJ, horizontalStateCount = self:crossCheckHorizontal(math.floor(centerJ), math.floor(centerI), stateCount[3], stateCountTotal);
		if (type(centerJ) == "number") then
			local estimatedModuleSize = stateCountTotal / 7.0;
			local found = false;
			local max = #self.possibleCenters;
			for index = 1, max do
				local center = self.possibleCenters[index];
				-- Look for about the same center and module size:
				if (center:aboutEquals(estimatedModuleSize, centerI, centerJ)) then
					center = center:combineEstimate(centerI, centerJ, estimatedModuleSize);
					found = true;
					break;
				end
			end
			if (not found) then
				local point = FinderPattern:new():Init(centerJ, centerI, estimatedModuleSize, stateCountTotal);
				point.initStateCount = initStateCount;
				point.horizontalStateCount = horizontalStateCount;
				point.verticalStateCount = verticalStateCount;
				self.possibleCenters[#self.possibleCenters + 1] = point;
				if (self.resultPointCallback ~= nil) then
					self.resultPointCallback(point);
				end
			end
			return true;
		end
	end

	centerI = type(centerI) == "number" and centerI or i;
	centerJ = type(centerJ) == "number" and centerJ or j;
	if (self:foundDot(centerI, centerJ)) then
		self:AddDot(self.possibleDots, centerJ, centerI, stateCountTotal / 7.0, stateCountTotal)
	else
		self:AddDot(self.possibleOptionDots, centerJ, centerI, stateCountTotal / 7.0, stateCountTotal)
	end
	
	return false;
end

function FinderPatternFinder:AddDot(dots, x, y, estimatedModuleSize, stateCountTotal)
	for i = 1, #dots do
		local p = dots[i];
		if (self:EqualSize(y, p.posY) and self:EqualSize(x, p.posX)) then
			return ;
		end
	end
	dots[#dots + 1] = FinderPattern:new():Init(x, y, estimatedModuleSize, stateCountTotal);
end

function FinderPatternFinder:foundDot(centerI, centerJ)
	local i_size = 0;
	local j_size = 0;
	local maxI = self.image.height;
	local maxJ = self.image.width;

	centerI = math.floor(centerI);
	centerJ = math.floor(centerJ);

	local debug = false;
	-- if (180 < centerJ and centerJ < 250 and 150 < centerI and centerI < 230) then
	-- 	print("=============================1221212", centerJ, centerI)
	-- 	debug = centerJ == 195 and centerI == 164;
	-- end

	local i = centerI;
	while (i >= 1 and self:isBlack(centerJ, i)) do
		i_size = i_size + 1;
		i = i - 1;
	end
	if (i < 1) then
		return false;
	end
	local min_i = i + 1;

	i = centerI + 1;
	while (i <= maxI and self:isBlack(centerJ, i)) do
		i_size = i_size + 1;
		i = i + 1;
	end
	if (i > maxI) then
		return false;
	end
	local max_i = i - 1;

	local j = centerJ;
	while (j >= 1 and self:isBlack(j, centerI)) do
		j_size = j_size + 1;
		j = j - 1;
	end
	if (j < 1) then
		return false;
	end
	local min_j = j + 1;

	j = centerJ + 1;
	while (j <= maxJ and self:isBlack(j, centerI)) do
		j_size = j_size + 1;
		j = j + 1;
	end
	if (j > maxJ) then
		return false;
	end
	local max_j = j - 1;

	if (debug) then print("debug start=======size=====================", i_size, j_size) end
	if (i_size < 3 or j_size < 3) then return false end

	local i = math.floor((min_i + max_i) / 2);
	local j = math.floor((min_j + max_j) / 2);
	local r, g, b = self.image:getPixel(j, i);
	if (debug) then print("debug start========rgb====================", r, g, b) end
	if (r > 64 or g > 64 or b > 64) then return false end

	local dot_i = i;
	local dot_j = j;
	local dot_size = math.floor((i_size + j_size) / 2);
	if (not self:EqualSize(i_size, j_size, 3, 10, 1.0)) then return false, dot_size, dot_j, dot_i end

	local is_exist_full_white = false;
	local is_exist_full_black = false;
	local full_black_size = 0;
	local full_white_size = 0;
	local black_white_true_size = math.floor(dot_size / 3);
	for step = math.floor(dot_size / 2), math.floor(dot_size * 3 / 2) do
		if ((dot_i - step) < 1 or (dot_j - step) < 1 or (dot_i + step) > maxI or (dot_j + step) > maxJ) then return false end
		local p1 = self:isBlack(dot_j - step, dot_i - step);
		local p2 = self:isBlack(dot_j + step, dot_i - step);
		local p3 = self:isBlack(dot_j - step, dot_i + step);
		local p4 = self:isBlack(dot_j + step, dot_i + step);
		local is_full_white = not (p1 or p2 or p3 or p4);
		local is_full_blank = p1 and p2 and p3 and p4;
		if (is_exist_full_white) then
			if (is_exist_full_black) then
				if (is_full_blank) then
					full_black_size = full_black_size + 1;
				else
					-- print("=================dot true", dot_size, dot_j, dot_i, dot_size, black_white_true_size, full_white_size, full_black_size, self:EqualSize(black_white_true_size, full_white_size) and self:EqualSize(black_white_true_size, full_black_size));					
					return self:EqualSize(black_white_true_size, full_white_size) and self:EqualSize(black_white_true_size, full_black_size), dot_size, dot_j, dot_i;						
				end
			else
				if (is_full_blank) then
					is_exist_full_black = is_full_blank;
					full_black_size = full_black_size + 1;
				end
			end
		else
			if (is_full_white) then
				is_exist_full_white = is_full_white;
				full_white_size = full_white_size + 1;
			end
		end
	end
	-- print("=================dot false", dot_size, dot_j, dot_i, dot_size, black_white_true_size, full_white_size, full_black_size, self:EqualSize(black_white_true_size, full_white_size) and self:EqualSize(black_white_true_size, full_black_size));					
	return self:EqualSize(black_white_true_size, full_white_size) and self:EqualSize(black_white_true_size, full_black_size), dot_size, dot_j, dot_i;						
end

function FinderPatternFinder:handlePossibleCenterCross(stateCount, i, j)
	local stateCountTotal = stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4] + stateCount[5];
	local centerI = self:centerFromEnd(stateCount, i);
	local centerJ = self:crossCheckHorizontal(j, math.floor(centerI), stateCount[3], stateCountTotal);
	if (type(centerJ) == "number") then
		centerI = self:crossCheckVertical(math.floor(centerI), math.floor(centerJ), stateCount[3], stateCountTotal);
		if (type(centerI) == "number") then
			local estimatedModuleSize = stateCountTotal / 7.0;
			local found = false;
			local max = #self.possibleCenters;
			for index = 1, max do
				local center = self.possibleCenters[index];
				-- Look for about the same center and module size:
				if (center:aboutEquals(estimatedModuleSize, centerI, centerJ)) then
					center = center:combineEstimate(centerI, centerJ, estimatedModuleSize);
					found = true;
					break;
				end
			end
			if (not found) then
				local point = FinderPattern:new():Init(centerJ, centerI, estimatedModuleSize, stateCountTotal);
				self.possibleCenters[#self.possibleCenters + 1] = point;
				if (self.resultPointCallback ~= nil) then
					self.resultPointCallback(point);
				end
			end
			return true;
		end
	end

	centerI = type(centerI) == "number" and centerI or i;
	centerJ = type(centerJ) == "number" and centerJ or j;
	if (self:foundDot(centerI, centerJ)) then
		self:AddDot(self.possibleDots, centerJ, centerI, stateCountTotal / 7.0, stateCountTotal)
	else
		self:AddDot(self.possibleOptionDots, centerJ, centerI, stateCountTotal / 7.0, stateCountTotal)
	end

	return false;
end

-- @return number of rows we could safely skip during scanning, based on the first
--         two finder patterns that have been located. In some cases their position will
--         allow us to infer that the third pattern must lie below a certain point farther down in the image.
function FinderPatternFinder:findRowSkip()
	local max = #self.possibleCenters;
	if (max <= 1) then
		return 0;
	end
	local firstConfirmedCenter = nil;
	for i = 1, max do
		local center = self.possibleCenters[i];
		if (center:getCount() >= FinderPatternFinder.CENTER_QUORUM) then
			if (firstConfirmedCenter == nil) then
				firstConfirmedCenter = center;
			else
				-- We have two confirmed centers
				-- How far down can we skip before resuming looking for the next
				-- pattern? In the worst case, only the difference between the
				-- difference in the x / y coordinates of the two centers.
				-- This is the case where you find top right and bottom left, and
				-- you're looking for bottom right. We will use each center's
				-- latest x and y position, not the average, since we want to
				-- avoid bloating the skip unnecessarily
				self.hasSkipped = true;
				return math.floor(math.abs(firstConfirmedCenter:getX() - center:getX()) - math.abs(firstConfirmedCenter:getY() - center:getY())) / 2;
			end
		end
	end
	return 0;
end

-- @return true if we have found at least 3 finder patterns that have been detected
--         at least {@link #CENTER_QUORUM} times each, and, the estimated module size of the
--         candidates is "pretty similar"
function FinderPatternFinder:haveMultiplyConfirmedCenters()
	local confirmedCount = 0;
	local totalModuleSize = 0;
	local max = #self.possibleCenters;
	for i = 1, max do
		local pattern = self.possibleCenters[i];
		if (pattern:getCount() >= FinderPatternFinder.CENTER_QUORUM) then
			confirmedCount = confirmedCount + 1;
			totalModuleSize = totalModuleSize + pattern:getEstimatedModuleSize();
		end
	end
	if (confirmedCount < 3) then
		return false;
	end
	-- OK, we have at least 3 confirmed centers, but, it's possible that one is a "false positive"
	-- and that we need to keep looking. We detect this by asking if the estimated module sizes
	-- vary too much. We arbitrarily say that when the total deviation from average exceeds
	-- 5% of the total module size estimates, it's too much.
	local average = totalModuleSize / max;
	local totalDeviation = 0;
	for i = 1, max do
		local pattern = self.possibleCenters[i];
		totalDeviation = totalDeviation + math.abs(pattern:getEstimatedModuleSize() - average);
	end
	return totalDeviation <= 0.05 * totalModuleSize;
end

-- @return the 3 best {@link FinderPattern}s from our list of candidates. The "best" are
--         those that have been detected at least {@link #CENTER_QUORUM} times, and whose module
--         size differs from the average among those patterns the least
function FinderPatternFinder:selectBestPatterns(includeDots)
	local points = {}
	local point_size = #self.possibleCenters;

	for i = 1, point_size do
		local point = self.possibleCenters[i];
		point.rows = {};
		point.cols = {};

		local size = #points
		local found = false;
		for j = 1, size do
			local other = points[j];
			if (self:EqualSize(other.posX, point.posX) and self:EqualSize(other.posY, point.posY)) then
				found = true;
			end
		end
		if (not found) then
			points[#points + 1] = point;
		end
	end

	if (includeDots) then
		point_size = #self.possibleDots;
		for i = 1, point_size do
			local point = self.possibleDots[i];
			point.rows = {};
			point.cols = {};

			local size = #points
			local found = false;
			for j = 1, size do
				local other = points[j];
				if (self:EqualSize(other.posX, point.posX) and self:EqualSize(other.posY, point.posY)) then
					found = true;
				end
			end
			if (not found) then
				points[#points + 1] = point;
			end
		end 
	end

	point_size = #points
	if (point_size < 3 and not includeDots) then
		return self:selectBestPatterns(true);
	end

	for i = 1, point_size do
		local point = points[i];
		local point_dot_size = point:getEstimatedModuleSize();
		local point_x = point.posX;
		local point_y = point.posY;
		for j = i + 1, point_size do
			local other = points[j];
			local other_dot_size = other:getEstimatedModuleSize();
			local other_x = other.posX;
			local other_y = other.posY;
			if (self:EqualSize(other_dot_size, point_dot_size)) then
				local equal_x = self:EqualSize(other_x, point_x);
				local equal_y = self:EqualSize(other_y, point_y);
				if (equal_x ~= equal_y) then
					if (equal_y) then
						point.rows[#point.rows + 1] = other;
						other.rows[#other.rows + 1] = point;
					else
						point.cols[#point.cols + 1] = other;
						other.cols[#other.cols + 1] = point;
					end
				end
			end
		end
	end

	local found = false;
	local result = {}
	local result_exist_point = {};
	for i = 1, point_size do
		local point = points[i];
		local point_x = point.posX;
		local point_y = point.posY;
		local row_size = #point.rows;
		local col_size = #point.cols;
		if (row_size > 0 and col_size > 0) then
			for r = 1, row_size do
				for c = 1, col_size do
					local row = point.rows[r];
					local col = point.cols[c];
					local row_size = math.abs(row.posX - point_x);
					local col_size = math.abs(col.posY - point_y);
					if (self:EqualSize(row_size, col_size)) then
						if (not result_exist_point[point]) then
							result[#result + 1] = point;
							result_exist_point[point] = true;
						end
						if (not result_exist_point[row]) then
							result_exist_point[row] = true;
							result[#result + 1] = row;
						end
						if (not result_exist_point[col]) then
							result_exist_point[col] = true;
							result[#result + 1] = col;
						end
						found = true;
					end
				end
			end
		end
	end

	if (not found and includeDots) then
		for i = 1, point_size do
			local point = points[i];
			local point_dot_size = point:getEstimatedModuleSize();
			local point_x = point.posX;
			local point_y = point.posY;
			local rows = {};
			local cols = {};
			for j = 1, #point.rows do
				rows[#rows + 1] = point.rows[j];
			end
			for j = 1, #point.cols do 
				cols[#cols + 1] = point.cols[j];
			end
			local option_point_size = #self.possibleOptionDots;
			for j = 1, option_point_size do
				local other = self.possibleOptionDots[j];
				local other_dot_size = other:getEstimatedModuleSize();
				local other_x = other.posX;
				local other_y = other.posY;
				-- 借点要求精度提高
				if (self:EqualSize(other_dot_size, point_dot_size, 3, 5, 0.95)) then
					local equal_x = self:EqualSize(other_x, point_x, 3, 5, 0.95);
					local equal_y = self:EqualSize(other_y, point_y, 3, 5, 0.95);
					if (equal_x ~= equal_y) then
						if (equal_y) then
							rows[#rows + 1] = other;
						else
							cols[#cols + 1] = other;
						end
					end
				end
			end
			local row_size = #rows;
			local col_size = #cols;
			if (row_size > 0 and col_size > 0) then
				for r = 1, row_size do
					for c = 1, col_size do
						local row = rows[r];
						local col = cols[c];
						local row_size = math.abs(row.posX - point_x);
						local col_size = math.abs(col.posY - point_y);
						if (self:EqualSize(row_size, col_size)) then
							if (not result_exist_point[point]) then
								result[#result + 1] = point;
								result_exist_point[point] = true;
							end
							if (not result_exist_point[row]) then
								result_exist_point[row] = true;
								result[#result + 1] = row;
							end
							if (not result_exist_point[col]) then
								result_exist_point[col] = true;
								result[#result + 1] = col;
							end
							found = true;
						end
					end
				end
			end
		end		
	end

	if (not found and not includeDots) then return self:selectBestPatterns(true) end

	if (not found) then
		local point_size = #points;
		for i = 1, point_size do
			local point = points[i];
			local ok, point_dot_size, point_x, point_y = self:foundDot(point.posY, point.posX);
			if (point_dot_size and point_x and point_y) then
				local find_dot_result = self:FindBestDots(point_x, point_y, point_dot_size);
				if (find_dot_result) then
					return find_dot_result;
				end
			end
		end
		-- for i = 1, point_size do
		-- 	local point = points[i];
		-- 	local point_x = math.floor(point.posX);
		-- 	local point_y = math.floor(point.posY);
		-- 	print("point: " .. point_x .. ", " .. point_y, #point.rows, #point.cols);
		-- end
	end

	return found and result or nil;
end

function FinderPatternFinder:EqualSize(value1, value2, min_error_size, max_error_size, error_percentage)
	min_error_size = min_error_size or 3;
	max_error_size = max_error_size or 15;
	error_percentage = error_percentage or 0.8;

	-- if (not value1 or not value2) then
	-- 	print(commonlib.debugstack())
	-- end

	local abs_value = math.abs(value1 - value2);
	if (abs_value < min_error_size) then return true end
	if (abs_value > max_error_size) then return false end
	local percentage = value1 < value2 and (value1 / value2) or (value2 / value1);
	return percentage > error_percentage
end

function FinderPatternFinder:FindBestDots(dot_x, dot_y, dot_size)
	local min_size = 30;
	local max_size = 100;
	-- local min_size = 45;
	-- local max_size = 50;
	local max_x = self.image.width;
	local max_y = self.image.height;
	local estimatedModuleSize = dot_size * 7 / 3;
	local stateCountTotal = dot_size * 5 / 2;
	for step = min_size, max_size do
		local ps = {
			{x = dot_x - step, y = dot_y},
			{x = dot_x + step, y = dot_y},
			{x = dot_x, y = dot_y - step},
			{x = dot_x, y = dot_y + step}
		}
		-- if (dot_x == 194 and dot_y == 164 and step == 48) then
		-- 	print("debug");
		-- end
		for i = 1, 4 do
			local x = ps[i].x;
			local y = ps[i].y;
			if (x > 0 and x <= max_x and y > 0 and y <= max_y) then
				ps[i].ok, ps[i].size, ps[i].x, ps[i].y = self:foundDot(ps[i].y, ps[i].x);
				ps[i].ok = ps[i].size and math.abs(ps[i].size - dot_size) < 6;
			else 
				ps[i].ok, ps[i].size = false, 0;
			end
		end
		local x_ok = ps[1].ok or ps[2].ok 
		local y_ok = ps[3].ok or ps[4].ok;
		if (x_ok and y_ok) then
			local points = {FinderPattern:new():Init(dot_x, dot_y, estimatedModuleSize, stateCountTotal)};
			if (ps[1].ok) then 
				points[#points + 1] = FinderPattern:new():Init(ps[1].x, ps[1].y, estimatedModuleSize, stateCountTotal);
			else
				points[#points + 1] = FinderPattern:new():Init(ps[2].x, ps[2].y, estimatedModuleSize, stateCountTotal);
			end
			if (ps[3].ok) then
				points[#points + 1] = FinderPattern:new():Init(ps[3].x, ps[3].y, estimatedModuleSize, stateCountTotal);
			else 
				points[#points + 1] = FinderPattern:new():Init(ps[4].x, ps[4].y, estimatedModuleSize, stateCountTotal);
			end
			return points;
		end
	end
	return nil;
end

		-- Couldn't find enough finder patterns
		-- if (startSize == 2) then
		-- 	local point1 = self.possibleCenters[1];
		-- 	local point2 = self.possibleCenters[2];
		-- 	-- 纵向两个
		-- 	if (math.abs(point1.posX - point2.posX) <= 2) then
		-- 		local dist = math.floor(math.abs(point1.posY - point2.posY));
		-- 		local stateCount = point1.stateCount;
		-- 		local x = math.floor(point1.posX + stateCount[4] + stateCount[5] + stateCount[3] / 2);
		-- 		local y = math.floor(point1.posY); 
		-- 		if (x + dist < self.image.width) then 
		-- 			self:handlePossibleCenter(stateCount, y, x + dist);
		-- 		end
		-- 		if (x - dist > 0) then
		-- 			self:handlePossibleCenter(stateCount, y, x - dist);
		-- 		end
		-- 		local stateCount = point2.stateCount;
		-- 		local x = math.floor(point2.posX + stateCount[4] + stateCount[5] + stateCount[3] / 2);
		-- 		local y = math.floor(point2.posY); 
		-- 		if (x + dist < self.image.width) then 
		-- 			self:handlePossibleCenter(stateCount, y, x + dist);
		-- 		end
		-- 		if (x - dist > 0) then
		-- 			self:handlePossibleCenter(stateCount, y, x - dist);
		-- 		end
		-- 	end
		-- 	-- 横向两个
		-- 	if (math.abs(point1.posY - point2.posY) <= 2) then
		-- 		local dist = math.floor(math.abs(point1.posX - point2.posX))
		-- 		local stateCount = point1.stateCount;
		-- 		local x = math.floor(point1.posX + stateCount[4] + stateCount[5] + stateCount[3] / 2);
		-- 		local y = math.floor(point1.posY); 
		-- 		if (y + dist < self.image.height) then 
		-- 			self:handlePossibleCenter(point1.stateCount, y + dist, x);
		-- 		end
		-- 		if (y - dist > 0) then
		-- 			self:handlePossibleCenter(point1.stateCount, y - dist, x);
		-- 		end
		-- 		local stateCount = point2.stateCount;
		-- 		local x = math.floor(point2.posX + stateCount[4] + stateCount[5] + stateCount[3] / 2);
		-- 		local y = math.floor(point2.posY); 
		-- 		if (y + dist < self.image.height) then 
		-- 			self:handlePossibleCenter(stateCount, y + dist, x);
		-- 		end
		-- 		if (y - dist > 0) then
		-- 			self:handlePossibleCenter(stateCount, y - dist, x);
		-- 		end
		-- 	end
		-- end
		-- startSize = #self.possibleCenters;
		-- if (startSize < 3) then return nil end 

			-- -- Filter outlier possibilities
	-- local totalModuleSize = 0;
	-- for i = 1, startSize do
	-- 	totalModuleSize = totalModuleSize + self.possibleCenters[i]:getEstimatedModuleSize();
	-- end
	-- local average = totalModuleSize / startSize;
	-- local totalDeviation = 0;
	-- for i = 1, startSize do
	-- 	local pattern = self.possibleCenters[i];
	-- 	totalDeviation = totalDeviation + math.abs(pattern:getEstimatedModuleSize() - average);
	-- end
	-- local result = {};
	-- for i = 1, startSize do
	-- 	local pattern = self.possibleCenters[i];
	-- 	if (math.abs(pattern:getEstimatedModuleSize() - average) <= 0.2 * average) then
	-- 		result[#result + 1] = pattern;
	-- 	end
	-- end
	-- if (#result < 3) then
	-- 	-- Couldn't find enough finder patterns
	-- 	return nil;
	-- end
	-- -- Look for at least 3 modules in a row, which can be assumed to be the alignment pattern
	-- return result;