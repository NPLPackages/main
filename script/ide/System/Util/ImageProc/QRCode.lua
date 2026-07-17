--[[
Title: QR Code reader
Author(s): LiXizhi
Date: 2024/3/12
Desc: based on https://github.com/zxing/zxing/blob/master/core/src/main/java/com/google/zxing/qrcode/detector/FinderPatternFinder.java
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ImageProc/QRCode.lua");
local QRCode = commonlib.gettable("System.Util.ImageProc.QRCode")
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
local QRCode = commonlib.gettable("System.Util.ImageProc.QRCode");
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;
local bxor = mathlib.bit.bxor;

-- Encapsulates a finder pattern, which are the three square patterns found in
-- the corners of QR Codes. It also encapsulates a count of similar finder patterns,
-- as a convenience to the finder's bookkeeping.
local FinderPattern = commonlib.inherit(nil, commonlib.gettable("System.Util.ImageProc.QRCode.FinderPattern"));
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
local FinderPatternFinder = commonlib.inherit(nil, commonlib.gettable("System.Util.ImageProc.QRCode.FinderPatternFinder"));
FinderPatternFinder.CENTER_QUORUM = 2;
FinderPatternFinder.MIN_SKIP = 3; -- 1 pixel/module times 3 modules/center
FinderPatternFinder.MAX_MODULES = 97; -- support up to version 20 for mobile clients

function FinderPatternFinder:ctor()
	self.image = nil;
	self.possibleCenters = {};
	self.hasSkipped = false;
	self.crossCheckStateCount = {0, 0, 0, 0, 0};
	self.resultPointCallback = nil;
end

-- @param image: should be grey scale and sharpened
function FinderPatternFinder:Init(image, resultPointCallback)
	self.image = image;
	self.possibleCenters = {};
	self.crossCheckStateCount = {0, 0, 0, 0, 0};
	self.resultPointCallback = resultPointCallback;
	return self;
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

function FinderPatternFinder:isBlack(x, y)
	local r,g,b = self.image:getPixel(x, y);
	return r < 128;
end

function FinderPatternFinder:find(info)
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
							if (confirmed) then
								-- Start examining every other line. Checking each line turned out to be too
								-- expensive and didn't improve performance.
								iSkip = 2;
								if (self.hasSkipped) then
									done = self:haveMultiplyConfirmedCenters();
								else
									local rowSkip = self:findRowSkip();
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
		if (self:foundPatternCross(stateCount)) then
			local confirmed = self:handlePossibleCenter(stateCount, i, maxJ);
			if (confirmed) then
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
	local patternInfo = self:selectBestPatterns();
	return patternInfo;
end

-- Given a count of black/white/black/white/black pixels just seen and an end position,
-- figures the location of the center of this run.
function FinderPatternFinder:centerFromEnd(stateCount, endPos)
	return (endPos - stateCount[4] - stateCount[5]) - stateCount[3] / 2.0;
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
	if (i < 1) then
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
	local stateCountTotal = stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4] + stateCount[5];
	local centerJ = self:centerFromEnd(stateCount, j);
	local centerI = self:crossCheckVertical(i, math.floor(centerJ), stateCount[3], stateCountTotal);
	if (type(centerI) == "number") then
		centerJ = self:crossCheckHorizontal(math.floor(centerJ), math.floor(centerI), stateCount[3], stateCountTotal);
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
				self.possibleCenters[#self.possibleCenters + 1] = point;
				if (self.resultPointCallback ~= nil) then
					self.resultPointCallback(point);
				end
			end
			return true;
		end
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
function FinderPatternFinder:selectBestPatterns()
	local startSize = #self.possibleCenters;
	if (startSize < 3) then
		-- Couldn't find enough finder patterns
		return nil;
	end
	-- Filter outlier possibilities
	local totalModuleSize = 0;
	for i = 1, startSize do
		totalModuleSize = totalModuleSize + self.possibleCenters[i]:getEstimatedModuleSize();
	end
	local average = totalModuleSize / startSize;
	local totalDeviation = 0;
	for i = 1, startSize do
		local pattern = self.possibleCenters[i];
		totalDeviation = totalDeviation + math.abs(pattern:getEstimatedModuleSize() - average);
	end
	local result = {};
	for i = 1, startSize do
		local pattern = self.possibleCenters[i];
		if (math.abs(pattern:getEstimatedModuleSize() - average) <= 0.2 * average) then
			result[#result + 1] = pattern;
		end
	end
	if (#result < 3) then
		-- Couldn't find enough finder patterns
		return nil;
	end
	-- Look for at least 3 modules in a row, which can be assumed to be the alignment pattern
	return result;
end