function mandelbrot_plot(img, filename)
    % MANDELBROT_PLOT Plots the Mandelbrot set and saves it to a file.
    % img: The matrix of iteration counts from the Mandelbrot function.
    % filename: The string name for the saved file (e.g., 'mandelbrot_HD.png').

    % Create a new figure window (hidden to speed up batch processing)
    fig = figure('Visible', 'off'); 

    % Use imagesc to display the data with scaled colors
    imagesc(img);
    
    % Apply a colormap (e.g., 'jet', 'hot', or 'magma' for better contrast)
    colormap(jet); 
    
    % Add a colorbar to show iteration depth
    colorbar;
    
    % Ensure the aspect ratio matches the resolution
    axis image; 
    axis off; % Turn off axis labels for a clean fractal image
    
    % Set the title (optional, useful for identification)
    title(['Mandelbrot Set Generation: ', filename], 'Interpreter', 'none');

    % Save the image using the specified filename
    % 'print' or 'saveas' can be used; 'print' often yields higher DPI
    saveas(fig, filename);
    
    % Close the figure to free up memory
    close(fig);
    
    fprintf('Successfully saved: %s\n', filename);
end