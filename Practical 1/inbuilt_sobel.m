function [magnitude, Gx_out, Gy_out, time_taken] = inbuilt_sobel(input_image)
    % INBUILT_SOBEL Performs Sobel edge detection using MATLAB's conv2.

    % 1. Convert image to double for high-precision calculation 
    img = double(input_image);
    
    % 2. Define the Sobel Kernels [cite: 8]
    Gx_kernel = [-1 0 1; -2 0 2; -1 0 1];
    Gy_kernel = [1 2 1; 0 0 0; -1 -2 -1];

    % 3. Measure execution time using tic/toc 
    tic;
    
    % Perform 2D Convolution using built-in function 
    % 'same' ensures output size matches input size 
    Gx_out = conv2(img, Gx_kernel, 'same');
    Gy_out = conv2(img, Gy_kernel, 'same');
    
    % 4. Calculate Approximate Gradient Magnitude 
    % |G| = |Gx| + |Gy| (Computationally efficient version) 
    magnitude = abs(Gx_out) + abs(Gy_out);
    
    time_taken = toc; % Stop timer 
    
    fprintf('Built-in execution time: %.6f seconds\n', time_taken);
end