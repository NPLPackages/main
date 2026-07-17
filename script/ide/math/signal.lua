--[[
Title: signal (TODO not implemented yet)
Author(s): LiXizhi
Desc: like fast fourier transform, wavelet transform, etc.
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/math/signal.lua");
local signal = commonlib.gettable("mathlib.signal");
echo(signal.DiscreteCosineTransform(mathlib.matrix:new(8,8, 255)));
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/matrix.lua");
local signal = commonlib.gettable("mathlib.signal");


-- Fast Fourier transform
-- @param x: input array
function signal.fft(x)
	local N = #x;
	if (N <= 1) then
		return x;
	end
	local even = {};
	local odd = {};
	for i = 1, N, 2 do
		even[#even + 1] = x[i];
		odd[#odd + 1] = x[i + 1];
	end
	even = signal.fft(even);
	odd = signal.fft(odd);
	local T = {};
	local halfN = math.floor(N / 2)
	for k = 1, halfN do
		local t = math.exp(-2 * math.pi * (k - 1) / N) * odd[k];
		T[k] = even[k] + t;
		T[k + halfN] = even[k] - t;
	end
	return T;
end

-- create a signal window
-- @param window_type: "hann", "hamming", "blackman", "bartlett", "rectangular". default to "hann"
function signal.window(window_type, window_size)
	local window = {};
	if (not window_type or window_type == "hann") then
		for i = 1, window_size do
			window[i] = 0.5 * (1 - math.cos(2 * math.pi * (i - 1) / (window_size - 1)));
		end
	elseif (window_type == "hamming") then
		for i = 1, window_size do
			window[i] = 0.54 - 0.46 * math.cos(2 * math.pi * (i - 1) / (window_size - 1));
		end
	elseif (window_type == "blackman") then
		for i = 1, window_size do
			window[i] = 0.42 - 0.5 * math.cos(2 * math.pi * (i - 1) / (window_size - 1)) + 0.08 * math.cos(4 * math.pi * (i - 1) / (window_size - 1));
		end
	elseif (window_type == "bartlett") then
		for i = 1, window_size do
			window[i] = 2 / (window_size - 1) * ((window_size - 1) / 2 - math.abs((i - 1) - (window_size - 1) / 2));
		end
	elseif (window_type == "rectangular") then
		for i = 1, window_size do
			window[i] = 1;
		end
	end
	return window;
end

-- Computes the Short-time Fourier Transform of signals.
function signal.stft(x, window_size, hop_size, window_type)
	local window = signal.window(window_type, window_size);
	local N = #x;
	local M = math.floor((N - window_size) / hop_size + 1);
	local X = {};
	for m = 1, M do
		local start = (m - 1) * hop_size + 1;
		local stop = start + window_size - 1;
		local frame = {};
		for i = start, stop do
			frame[#frame + 1] = x[i] * window[i - start + 1];
		end
		frame = signal.fft(frame);
		X[m] = frame;
	end
	return X;
end

-- compute discrete cosine transform of a matrix, such as used in JPEG image procecssing. usually 8x8 matrix
function signal.DiscreteCosineTransform(matrix)
	local pi = math.pi;
	local m =  m or (#matrix)
	local n = n or (#(matrix[1]))
    
	-- dct will store the discrete cosine transform
	local dct = {}
    for i = 1, m do
        dct[i] = {}
    end

    local ci, cj, dct1, sum

    for i = 1, m do
        for j = 1, n do
            -- ci and cj depends on frequency as well as
            -- number of row and columns of specified matrix
            if i == 1 then
                ci = 1 / math.sqrt(m)
            else
                ci = math.sqrt(2) / math.sqrt(m)
            end
            if j == 1 then
                cj = 1 / math.sqrt(n)
            else
                cj = math.sqrt(2) / math.sqrt(n)
            end

            -- sum will temporarily store the sum of cosine signals
            sum = 0
            for k = 1, m do
                for l = 1, n do
                    dct1 = matrix[k][l] * 
                           math.cos((2 * (k-1) + 1) * (i - 1) * pi / (2 * m)) * 
                           math.cos((2 * (l-1) + 1) * (j - 1) * pi / (2 * n))
                    sum = sum + dct1
                end
            end
            dct[i][j] = ci * cj * sum
        end
    end
	return dct;
end
