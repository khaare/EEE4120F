% =========================================================================
% Practical 2: Mandelbrot-Set Serial vs Parallel Analysis
% =========================================================================
%
% GROUP NUMBER: 3
%
% MEMBERS:
%   - Member 1 Name, Student Number
%   - Member 2 Name, Student Number

%% ========================================================================
%  PART 1: Mandelbrot Set Image Plotting and Saving
%  ========================================================================
%
% TODO: Implement Mandelbrot set plotting and saving function
function run_analysis()

image_sizes = [
800,600;
];

max_iterations = 1000;
max_workers = 4;

num_sizes = size(image_sizes,1);

serial_times = zeros(num_sizes,1);
parallel_times = zeros(num_sizes,max_workers);
speedups = zeros(num_sizes,max_workers);
efficiencies = zeros(num_sizes,max_workers);

%% =============================
% SERIAL BENCHMARK
%% =============================

fprintf("Running Sequential Benchmark\n");

for i = 1:num_sizes

    width = image_sizes(i,1);
    height = image_sizes(i,2);

    tic
    mandelbrot_serial(width,height,max_iterations);
    serial_times(i) = toc;

end

%% =============================
% PARALLEL BENCHMARK
%% =============================

for workers = 2:max_workers

    fprintf("\nRunning Parallel Benchmark with %d workers\n",workers);

    delete(gcp('nocreate'));
    parpool(workers);

    for i = 1:num_sizes

        width = image_sizes(i,1);
        height = image_sizes(i,2);

        tic
        mandelbrot_parallel(width,height,max_iterations);
        parallel_times(i,workers) = toc;

        speedups(i,workers) = serial_times(i) / parallel_times(i,workers);

        efficiencies(i,workers) = ...
            (speedups(i,workers) / workers) * 100;

    end

end

delete(gcp('nocreate'));

%% =============================
% DISPLAY RESULTS TABLE
%% =============================

fprintf("\nPerformance Results\n");

for i = 1:num_sizes

    width = image_sizes(i,1);
    height = image_sizes(i,2);

    fprintf("\nResolution %dx%d\n",width,height);
    fprintf("Serial Time: %.3f s\n",serial_times(i));

    for workers = 2:max_workers

        fprintf("Workers %d | Parallel: %.3f s | Speedup: %.2f | Efficiency: %.2f%%\n", ...
        workers, ...
        parallel_times(i,workers), ...
        speedups(i,workers), ...
        efficiencies(i,workers));

    end

end

%% =============================
% PLOT SPEEDUP GRAPH
%% =============================

figure
hold on

for i = 1:num_sizes
    plot(2:max_workers, speedups(i,2:max_workers),'o-')
end

xlabel("Number of Workers")
ylabel("Speedup")
title("Parallel Speedup vs Workers")
legend("SVGA","HD","FullHD","2K","QHD","4K","5K","8K")

grid on

%% =============================
% PLOT EFFICIENCY GRAPH
%% =============================

figure
hold on

for i = 1:num_sizes
    plot(2:max_workers, efficiencies(i,2:max_workers),'o-')
end

xlabel("Number of Workers")
ylabel("Efficiency (%)")
title("Parallel Efficiency vs Workers")

grid on

end
%% ========================================================================
%  PART 2: Serial Mandelbrot Set Computation
%  ========================================================================`
%
%TODO: Implement serial Mandelbrot set computation function
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

        x = 0;
        y = 0;
        iteration = 0;

        while (iteration < max_iterations) && (x*x + y*y <= 4)

            x_next = x*x - y*y + x0;
            y_next = 2*x*y + y0;

            x = x_next;
            y = y_next;

            iteration = iteration + 1;
        end

        iter_matrix(py,px) = iteration;

    end
end

end
%% ========================================================================
%  PART 3: Parallel Mandelbrot Set Computation
%  ========================================================================
%
%TODO: Implement parallel Mandelbrot set computation function
function iter_matrix = mandelbrot_parallel(width, height, max_iterations)

% Standard Mandelbrot region
x_min = -2.0;
x_max = 0.5;
y_min = -1.2;
y_max = 1.2;

iter_matrix = zeros(height, width);

% Parallel outer loop
parfor px = 1:width

    for py = 1:height

        % Map pixel to complex plane
        x0 = x_min + (px-1) * (x_max - x_min) / (width-1);
        y0 = y_min + (py-1) * (y_max - y_min) / (height-1);

        x = 0;
        y = 0;
        iteration = 0;

        while (iteration < max_iterations) && (x*x + y*y <= 4)

            x_next = x*x - y*y + x0;
            y_next = 2*x*y + y0;

            x = x_next;
            y = y_next;

            iteration = iteration + 1;

        end

        iter_matrix(py,px) = iteration;

    end

end

end

%% ========================================================================
%  PART 4: Testing and Analysis
%  ========================================================================
% Compare the performance of serial Mandelbrot set computation
% with parallel Mandelbrot set computation.

