% Sequential Baseline
clear; clc;

% Define the Standard Testing Resolutions 
res_names = {'SVGA', 'HD', 'Full_HD', '2K', 'QHD', '4K_UHD', '5K', '8K_UHD'};
widths    = [800, 1280, 1920, 2048, 2560, 3840, 5120, 7680];
heights   = [600, 720, 1080, 1080, 1440, 2160, 2880, 4320];
max_iter  = 1000; % 

% Initialize a table to store results
results_table = table('Size', [length(res_names), 3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Resolution', 'Megapixels', 'ExecutionTime_s'});

fprintf('Starting Sequential Mandelbrot Generation...\n');
fprintf('--------------------------------------------------\n');

for i = 1:length(res_names)
    % Calculate Megapixels for record keeping 
    mp = (widths(i) * heights(i)) / 1e6;
    
    fprintf('Processing %s (%dx%d, %.2f MP)...\n', res_names{i}, widths(i), heights(i), mp);
    
    % Measure execution time using tic/toc
    tic;
    img_data = mandelbrot_sequential(widths(i), heights(i), max_iter);
    exec_time = toc;
    
    % Store results
    results_table.Resolution(i) = res_names{i};
    results_table.Megapixels(i) = mp;
    results_table.ExecutionTime_s(i) = exec_time;
    
    % Task 0: Plot and Save the image 
    filename = sprintf('Mandelbrot_%s_Sequential.png', res_names{i});
    mandelbrot_plot(img_data, filename);
    
    fprintf('Completed %s in %.4f seconds.\n\n', res_names{i}, exec_time);
    
    % Warning check: Execution times for resolutions higher than Full HD
    % might become very long.
    if widths(i) >= 1920
        fprintf('Warning: Large resolution detected. Execution may take significant time.\n');
    end
end

% Display final benchmarking table
disp('Final Sequential Benchmarking Results:');
disp(results_table);

% Save the results table for Task 3 comparison

save('sequential_results.mat', 'results_table');
