% =========================================================================
% Practical 2: Mandelbrot-Set Serial vs Parallel Analysis
% =========================================================================
%
% GROUP NUMBER:3
%
% MEMBERS:
%   - Member 1 Khaarendiwe, MLDKHA010
%   - Member 2 Name, Student Number

function run_analysis()

image_sizes = [
800,600;
];

% SETTING UP FOR BENCHMARKING
max_iterations = 1000;
max_workers = 4;

num_sizes = size(image_sizes,1); %number of rows in image_sizes

serial_times = zeros(num_sizes,1);%Creates a column vector filled with zeros
parallel_times = zeros(num_sizes,max_workers);
speedups = zeros(num_sizes,max_workers);%Stores calculated speedup values
efficiencies = zeros(num_sizes,max_workers);

% SERIAL BENCHMARK

fprintf("Running Sequential Benchmark\n");

for i = 1:num_sizes
    
    %read values from the matrix
    width = image_sizes(i,1);
    height = image_sizes(i,2);
    % Start execution timer
    tic
    serial_img = mandelbrot_serial(width,height,max_iterations);
    % End timer 
    serial_times(i) = toc; %Stores time for comparison later
    %plot image
    filename = sprintf("mandelbrot_serial_%dx%d.png",width,height);
    mandelbrot_plot(serial_img, filename);
    

end

% PARALLEL BENCHMARK

for workers = 2:max_workers %The serial case already represents 1 worker, so parallel starts at 2

    fprintf("\nRunning Parallel Benchmark with %d workers\n",workers);

    delete(gcp('nocreate')); % Close Any Existing Parallel Pool, dont create one if none already exists
    parpool(workers); % Create Parallel Pool with specified number of workers (4)

    for i = 1:num_sizes

        width = image_sizes(i,1);
        height = image_sizes(i,2);
        % Start execution timer
        tic
        parallel_img = mandelbrot_parallel(width,height,max_iterations);
        % End timer
        parallel_times(i,workers) = toc;
        % Plot image
        filename = sprintf("mandelbrot_parallel_%dx%d_%dworkers.png",width,height,workers);
        mandelbrot_plot(parallel_img, filename);

        % Calculate speedup and efficency
        speedups(i,workers) = serial_times(i) / parallel_times(i,workers);

        efficiencies(i,workers) = ...
            (speedups(i,workers) / workers) * 100;

    end

end
% Close Parallel Pool
delete(gcp('nocreate'));

% DISPLAY RESULTS

fprintf("\nPerformance Results\n");

for i = 1:num_sizes

    width = image_sizes(i,1);
    height = image_sizes(i,2);

    fprintf("\nResolution %dx%d\n",width,height);
    fprintf("Serial Time: %.3f s\n",serial_times(i)); %print the serial time

    for workers = 2:max_workers %loop over worker threads and print each of their execution times, speedups and efficiencies

        fprintf("Workers %d | Parallel: %.3f s | Speedup: %.2f | Efficiency: %.2f%%\n", ...
        workers, ...
        parallel_times(i,workers), ...
        speedups(i,workers), ...
        efficiencies(i,workers));

    end

end

% PLOT SPEEDUP GRAPH
figure
hold on
% All resolution speedups are plotted on the same figure

for i = 1:num_sizes
    plot(2:max_workers, speedups(i,2:max_workers),'o-')
end

xlabel("Number of Workers")
ylabel("Speedup")
title("Parallel Speedup vs Workers")
legend("SVGA","HD","FullHD","2K","QHD","4K","5K","8K")

grid on

% PLOT EFFICIENCY GRAPH

figure
hold on
% All resolution speedups are plotted on the same figure
for i = 1:num_sizes
    plot(2:max_workers, efficiencies(i,2:max_workers),'o-')
end

xlabel("Number of Workers")
ylabel("Efficiency (%)")
title("Parallel Efficiency vs Workers")

grid on

end

%% ========================================================================
%  PART 1: Mandelbrot Set Image Plotting and Saving
% ========================================================================

function mandelbrot_plot(iter_matrix, filename)

figure
imagesc(iter_matrix)
axis equal
axis off
colormap(hot)

saveas(gcf, filename)

end


%% ========================================================================
%  PART 2: Serial Mandelbrot Set Computation
% ========================================================================


% Helper function
function iter = mandelbrot_pixel(x0, y0, max_iterations)
    x = 0;
    y = 0;
    iter = 0;

    while (iter < max_iterations) && (x*x + y*y <= 4)
        x_next = x*x - y*y + x0;
        y_next = 2*x*y + y0;

        x = x_next;
        y = y_next;

        iter = iter + 1;
    end
end


function iter_matrix = mandelbrot_serial(width, height, max_iterations)
x_min = -2.0;
x_max = 0.5;
y_min = -1.2;
y_max = 1.2;
iter_matrix = zeros(height,width);

for px = 1:width
    for py = 1:height

        x0 = x_min + (px-1)*(x_max-x_min)/(width-1);
        y0 = y_min + (py-1)*(y_max-y_min)/(height-1);

        iter_matrix(py,px) = mandelbrot_pixel(x0,y0,max_iterations);
    end
end

end


%% ========================================================================
%  PART 3: Parallel Mandelbrot Set Computation
% ========================================================================

function iter_matrix = mandelbrot_parallel(width, height, max_iterations)
x_min = -2.0;
x_max = 0.5;
y_min = -1.2;
y_max = 1.2;
iter_matrix = zeros(height, width);

% Parallel outer loop
parfor px = 1:width

    for py = 1:height

        x0 = x_min + (px-1) * (x_max - x_min) / (width-1);
        y0 = y_min + (py-1) * (y_max - y_min) / (height-1);

        iter_matrix(py,px) = mandelbrot_pixel(x0,y0,max_iterations);

    end

end

end
