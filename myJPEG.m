% clear all variables
clear;
%% 4 Image preparation
% 4a&b: read the image file
RGB = imread('Cpeppers.png');
f = im2gray(RGB); %change it to a grayscale image
imshow(f);
[m, n] = size(f);
whos f; %An efficient way to view information
%4c, working from left to right, top to bottom, split the image into 8x8 blocks of pixels
m1 = 8 - mod(m, 8); %Figure out how many pixels away from the width is divisible by 8
n1 = 8 - mod(n, 8); %so as height

f_m = (zeros(m1, n));
f = [f; f_m]; %add the number of rows to an integer multiple of 8
f_n = zeros(m + m1, n1);
f = [f f_n]; %add the number of columns to an integer multiple of 8

[m, n] = size(f); %The size of the completed image matrix is obtained
num = 1;

for i = 8:8:m %Divide the matrix into 8 * 8 submatrices and store them in subim

    for j = 8:8:n
        %4e subtract 128 from each pixel values so they range from -128 to 127
        subim(:, :, num) = int16(f(i - 7:i, j - 7:j) - 128); %#ok<*SAGROW>
        num = num + 1;
    end

end

% 4d&f: Print (disp) again the first two 8x8 matrices of pixel values
fprintf('subim:  \n');
fprintf('subim(:, :, 1)\n');
disp(subim(:, :, 1))
fprintf('subim(:, :, 2)\n');
disp(subim(:, :, 2))

%% 5 Applying 2D DCT to each block
%5a using dct to subim
for i = 1:(num - 1)
    subnew(:, :, i) = dct2(subim(:, :, i));
end

%5b print
fprintf('subnew:  \n');
fprintf('subnew(:, :, 1)\n');
disp(subnew(:, :, 1))
fprintf('subnew(:, :, 2)\n');
disp(subnew(:, :, 2)) %Print (disp) the first two 8x8 matrices of DCT factors values

%% 6 Quantisation
%6a quantisation matrix
Qstd = [16 11 10 16 24 40 51 61
    12 12 14 19 26 58 60 55
    14 13 16 24 40 57 69 56
    14 17 22 29 51 87 80 62
    18 22 37 56 68 109 103 77
    24 35 55 64 81 104 113 92
    49 64 78 87 103 121 120 101
    72 92 95 98 112 100 103 99];
%6b
Qlow = round(0.3 * Qstd); %Qlow, Smaller factors, higher quantization accuracy
Qhigh = 2 * Qstd; %The opposite of Qlow
%6c - print them
fprintf('Qlow:\n');
disp(Qlow);
fprintf('Qhigh:\n');
disp(Qhigh);
%6d - apply quantisation to all the 8x8 matrices of DCT coefficients, using Qstd, Qlow and Qhigh.
for i = 1:(num - 1) %using Qstd
    std(:, :, i) = round(subnew(:, :, i) ./ Qstd); %Dot Divide, sounds like dot product?
end

for i = 1:(num - 1) %using Qlow
    low(:, :, i) = round((subnew(:, :, i)) ./ Qlow);
end

for i = 1:(num - 1) %using Qhigh
    high(:, :, i) = round((subnew(:, :, i)) ./ Qhigh);
end

%6e - print
fprintf('apply quantisation to the first two matrix using Qstd:\n');
disp(std(:, :, 1));
disp(std(:, :, 2));
fprintf('Using Qlow:\n');
disp(low(:, :, 1));
disp(low(:, :, 2));
fprintf('Using Qhigh:\n');
disp(high(:, :, 1));
disp(high(:, :, 2));

%% 7. Decompression
%7a - multiply the quantised DCT values by the corresponding element of the quantisation matrix originally used
%standard
for i = 1:(num - 1)
    std2(:, :, i) = std(:, :, i) .* Qstd; %notice: dot product
end

%low quantisation
for i = 1:(num - 1)
    low2(:, :, i) = low(:, :, i) .* Qlow;
end

%high quantisation
for i = 1:(num - 1)
    high2(:, :, i) = high(:, :, i) .* Qhigh;
end

%7b - print
fprintf('the standard one: \n');
disp(std2(:, :, 1));
disp(std2(:, :, 2));
fprintf('the low quantisd one:\n');
disp(low2(:, :, 1));
disp(low2(:, :, 2));
fprintf('the high quantisd one:\n');
disp(high2(:, :, 1));
disp(high2(:, :, 2));
%7c - inverse DCT & restore the range to (0,255)
%apply the inverse DCT (idct2) to all 8x8 matrices of DCT coefficients.
%add 128 to each matrix element and round the values.
for i = 1:(num - 1)
    stdRestore(:, :, i) = round(idct2(std2(:, :, i)) + 128); % for standard quantised
end

for i = 1:(num - 1)
    lowRestore(:, :, i) = round(idct2(low2(:, :, i)) + 128); % for low quantised
end

for i = 1:(num - 1)
    highRestore(:, :, i) = round(idct2(high2(:, :, i)) + 128); % for high quantised
end

%7d - print
fprintf('the standard one after restoring\n');
disp(stdRestore(:, :, 1));
disp(stdRestore(:, :, 2));
fprintf('the low quantisd one after restoring:\n');
disp(lowRestore(:, :, 1));
disp(lowRestore(:, :, 2));
fprintf('the high quantisd one after restoring:\n');
disp(highRestore(:, :, 1));
disp(highRestore(:, :, 2));

%% 8. Image reconstruction
%f = [f f_n]

%首先以standard为例
f_std = [];
x_new = [];
index_element = 1; %用来遍历8*8矩阵

for y = 1:(208/8) %一共这么多行

    for x = 1:(288/8) %每一行先往右叠加

        x_new = [x_new stdRestore(:, :, index_element)];
        index_element = index_element + 1;
    end

    f_std = cat(1, f_std, x_new); %向后叠加
    x_new = [];
end

figure,

subplot(1,3,1);
imshow((uint8(f_std)));
title('standard');

% low
f_low = [];
x_new = [];
index_element = 1; %用来遍历8*8矩阵

for y = 1:(208/8) %一共这么多行

    for x = 1:(288/8) %每一行先往右叠加

        x_new = [x_new lowRestore(:, :, index_element)];
        index_element = index_element + 1;
    end

    f_low = cat(1, f_low, x_new); %向后叠加
    x_new = [];
end

subplot(1,3,2);
imshow((uint8(f_low)));
title('low');

%high
f_high = [];
x_new = [];
index_element = 1; %用来遍历8*8矩阵

for y = 1:(208/8) %一共这么多行

    for x = 1:(288/8) %每一行先往右叠加

        x_new = [x_new stdRestore(:, :, index_element)];
        index_element = index_element + 1;
    end

    f_high = cat(1, f_high, x_new); %向后叠加
    x_new = [];
end

subplot(1,3,3);
imshow((uint8(f_high)));
title('high');