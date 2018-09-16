function [ allow ] = check_coords( grid_member, x, y )

    allow = 0;

    for i = 1:size(grid_member, 1)    
        if grid_member(i, 1) == x && grid_member(i, 2) == y        
            allow = 0;   
            break;
        else
            allow = 1;
        end    
    end

end

