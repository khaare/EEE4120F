function img = mandelbrot_sequential(width, height, max_iterations)
    % Define the coordinate ranges
    x_coords = linspace(-2.0, 0.5, width);
    y_coords = linspace(-1.2, 1.2, height);
    
    % Preallocate image array
    img = zeros(height, width);
    
    % Nested for-loops for sequential execution
    for row = 1:height
        for col = 1:width
            x0 = x_coords(col);
            y0 = y_coords(row);
            x = 0;
            y = 0;
            iteration = 0;
            
            % Escape time algorithm (Pseudocode Implementation)
            while (iteration < max_iterations && (x^2 + y^2) <= 4)
                x_next = x^2 - y^2 + x0;
                y_next = 2*x*y + y0;
                x = x_next;
                y = y_next;
                iteration = iteration + 1;
            end
            img(row, col) = iteration;
        end
    end
end