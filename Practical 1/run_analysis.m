% =========================================================================
% Practical 1: 2D Convolution Analysis
% =========================================================================
%
% GROUP NUMBER:
%
% MEMBERS:
%   - Member 1 Khaarendiwe Mulaudzi, MLDKHA010
%   - Member 2 Name, Student Number


%% ========================================================================
%  PART 1: Manual 2D Convolution Implementation
%  ========================================================================
%
% REQUIREMENT: You may NOT use built-in convolution functions (conv2, imfilter, etc.)

% TODO: Implement manual 2D convolution using Sobel Operator(Gx and Gy)
% output - Convolved image result (grayscale)
%--------------------------------------------------------------------------
% Define edge detection kernels (Sobel kernel)

function output = my_conv2(img, kernel,type) %Add necessary input arguments

    % Convert to double to prevent overflow (important for Sobel)
    img = double(img);
    kernel = double(kernel);

    % Flip kernel for true convolution 180 degrees
    kernel = rot90(kernel, 2);

    % Get sizes of the image and the kernel
    [h, w] = size(img);
    [kh, kw] = size(kernel);

    % -----------------------------------
    % Step 1: Create padded image (FULL)
    % -----------------------------------
    pad_h = kh - 1;
    pad_w = kw - 1;
    
    % Pad the image with zeros to avoid getting errors 
    padded_zeros = zeros(h + 2*pad_h, w + 2*pad_w);

    for i = 1:h
        for j = 1:w
            padded_zeros(i + pad_h, j + pad_w) = img(i, j);
        end
    end

    % Compute full convolution
    full_h = h + kh - 1;
    full_w = w + kw - 1;

    full_output = zeros(full_h, full_w);

    for i = 1:full_h
        for j = 1:full_w

            sum_val = 0;

            for m = 1:kh
                for n = 1:kw
                    sum_val = sum_val + ...
                        padded_zeros(i + m - 1, j + n - 1) * kernel(m, n);
                end
            end

            full_output(i, j) = sum_val;

        end
    end
    % -----------------------------------
    % Step 1: Create padded image (FULL)
    % -----------------------------------
    pad_h = kh - 1;
    pad_w = kw - 1;
    
    % Pad the image with zeros to avoid getting errors 
    padded_zeros = zeros(h + 2*pad_h, w + 2*pad_w);

    for i = 1:h
        for j = 1:w
            padded_zeros(i + pad_h, j + pad_w) = img(i, j);
        end
    end

    % Compute full convolution
    full_h = h + kh - 1;
    full_w = w + kw - 1;

    full_output = zeros(full_h, full_w);

    for i = 1:full_h
        for j = 1:full_w

            sum_val = 0;

            for m = 1:kh
                for n = 1:kw
                    sum_val = sum_val + ...
                        padded_zeros(i + m - 1, j + n - 1) * kernel(m, n);
                end
            end

            full_output(i, j) = sum_val;

        end
    end
%'full': Returns the complete convolution.
%'same': Returns the central part, matching the input image size
%'valid': Returns only the parts computed without zero-padded edge

    switch lower(type)

        case 'full'
            output = full_output;

        case 'same'
            start_i = floor(kh/2) + 1;
            start_j = floor(kw/2) + 1;

            output = zeros(h, w);

            for i = 1:h
                for j = 1:w
                    output(i, j) = ...
                        full_output(start_i + i - 1, start_j + j - 1);
                end
            end

        case 'valid'
            valid_h = h - kh + 1;
            valid_w = w - kw + 1;

            output = zeros(valid_h, valid_w);

            for i = 1:valid_h
                for j = 1:valid_w
                    output(i, j) = ...
                        full_output(i + kh - 1, j + kw - 1);
                end
            end

        otherwise
            error('Shape must be ''full'', ''same'', or ''valid''');

    end
end


%% ========================================================================
%  PART 2: Built-in 2D Convolution Implementation
%  ========================================================================
%   
% REQUIREMENT: You MUST use the built-in conv2 function

% TODO: Use conv2 to perform 2D convolution
% output - Convolved image result (grayscale)

function output = inbuilt_conv2(img, kernel,type) %Add necessary input arguments
    image = double(img);
    output = conv2(image, kernel, type);
end


%% ========================================================================
%  PART 3: Testing and Analysis
%  ========================================================================
%
% Compare the performance of manual 2D convolution (my_conv2) with MATLAB's
% built-in conv2 function (inbuilt_conv2).

function runAnalysis()
    % TODO1:
    % Load all the sample images from the 'sample_images' folder
    
    % TODO2:
    % Define edge detection kernels (Sobel kernel)
    
    % TODO3:
    % For each image, perform the following:
    %   a. Measure execution time of my_conv2
    %   b. Measure execution time of inbuilt_conv2
    %   c. Compute speedup ratio
    %   d. Verify output correctness (compare results)
    %   e. Store results (image name, time_manual, time_builtin, speedup)
    %   f. Plot and compare results
    %   g. Visualise the edge detection results(Optional)
    
    % Get all images in the folder
    imageFiles = dir('*.png');  
    Gx = [-1 0 1; -2 0 2; -1 0 1];
    Gy = [1 2 1; 0 0 0; -1 -2 -1];
    % Loop over all images
    for k = 1:length(imageFiles)
    
        % Read image
        filename = fullfile(imageFiles(k).folder, imageFiles(k).name);
        image = imread(filename);
        
        % Convert to grayscale if needed
        if size(image,3) == 3
            image = rgb2gray(image);
        end
    
        % ---- START TIMING ----
        tic
        
        % Apply Sobel operators
        edges_x = my_conv2(image, Gx, 'valid');
        edges_y = my_conv2(image, Gy, 'valid');
    
        % Combine gradients
        convolvedImage = mat2gray(sqrt(edges_x.^2 + edges_y.^2));
        
        % ---- END TIMING ----
        elapsedTime = toc;
        % ---- START TIMING ----
        tic
        % Apply Sobel operators
        edges_x1 = inbuilt_conv2(image, Gx, 'valid');
        edges_y1 = inbuilt_conv2(image, Gy, 'valid');
    
        % Combine gradients
        convolvedImage1 = mat2gray(sqrt(edges_x1.^2 + edges_y1.^2));
        
        % ---- END TIMING ----
        elapsedTime1 = toc;
        % Display result
        speedup = elapsedTime/elapsedTime1;
        figure;
        subplot(1,3,1);
        imshow(image);
        title('Original Image');
    
        subplot(1,3,2);
        imshow(convolvedImage);
        title(['(manual)' imageFiles(k).name]);
    
        subplot(1,3,3)
        imshow(convolvedImage1)
        title(['(inbuilt) - Time: ' num2str(elapsedTime1) ' s']);

        % Print time in Command Window
        fprintf('Image: %s - Execution Time (manual): %.6f seconds - Execution Time (inbuilt): %.6f seconds -  Speedup : %.6f \n', ...
                imageFiles(k).name, elapsedTime, elapsedTime1, speedup);
        
    end
    
end

runAnalysis();