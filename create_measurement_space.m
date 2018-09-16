function [ transition_matrix, transition_matrix_noisy, grid_member, distance_matrix ] = create_measurement_space( number_of_states )

    transition_matrix = eye(number_of_states);
    transition_matrix_noisy = eye(number_of_states);
    distance_matrix = zeros(number_of_states, number_of_states);
    
    coordinate_limits_x = [1, number_of_states];
    coordinate_limits_y = [1, number_of_states];

    % Initialise first coordinate
    x_ = (coordinate_limits_x(2)-coordinate_limits_x(1)).*rand(1,1) + coordinate_limits_x(1);
    y_ = (coordinate_limits_y(2)-coordinate_limits_y(1)).*rand(1,1) + coordinate_limits_y(1);
    
    grid_member(1, 1) = round(x_);
    grid_member(1, 2) = round(y_);
    
    x_ = round((-1-1).*rand(1,1) + 1);
    y_ = round((-1-1).*rand(1,1) + 1);
    
    safety = 1;

    for i = 2:number_of_states
        no_of_members = size(grid_member, 1);
%         selected = round((no_of_members-1).*rand(1,1) + 1);
        selected = no_of_members;
        
        x_ = grid_member(selected, 1) - x_;
        y_ = grid_member(selected, 2) - y_;
        
        while ~check_coords(grid_member, x_, y_) || ~check_bounds(coordinate_limits_x, coordinate_limits_y, x_, y_)
            x_ = round((-1-1).*rand(1,1) + 1);
            y_ = round((-1-1).*rand(1,1) + 1);
            
            x_ = grid_member(selected, 1) - x_;
            y_ = grid_member(selected, 2) - y_;
            if safety > 100
                selected = round((no_of_members-1).*rand(1,1) + 1);       
                safety = 1;
            else
                safety = safety + 1;
            end
        end

        grid_member(i, 1) = x_;
        grid_member(i, 2) = y_;
        
        transition_matrix(selected, i) = 1;
        
        x_ = 0;
        y_ = 0;
    
    end
    
    for i = 1:number_of_states
        for j = 1:number_of_states       
            if transition_matrix(i, j) == 1                 
                transition_matrix(j, i) = 1; 
                distance_matrix(i, j) = pdist([grid_member(i, :); grid_member(j, :)],'euclidean');
            end                            
        end
    end
    
    transition_matrix = transition_matrix + eye(number_of_states)*2;
    
    for i = 1:number_of_states 
        transition_matrix(i, :) = transition_matrix(i, :) / sum(transition_matrix(i, :));  
    end
    
    transition_matrix_noisy = abs((awgn(transition_matrix, 3, 'measured')));
    transition_matrix_noisy(transition_matrix == 0) = 0;
    
    for i = 1:number_of_states 
        transition_matrix_noisy(i, :) = transition_matrix_noisy(i, :) / sum(transition_matrix_noisy(i, :));  
    end
    
%     for i = 1:number_of_states
%     
%         hold on;
%         plot(grid_member(i, 1), grid_member(i, 2), '*');
%         text(grid_member(i, 1)+0.1, grid_member(i, 2), num2str(i));
%         xlim([coordinate_limits_x(1) coordinate_limits_x(2)+5]);
%         ylim([coordinate_limits_y(1) coordinate_limits_y(2)+5]);
%         
%     end      

end

