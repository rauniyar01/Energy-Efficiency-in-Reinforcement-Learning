function [ ap_grids ] = create_aps( number_of_aps, number_of_states, buffer )

    total_random = number_of_states + buffer;
    x_ = (total_random-1).*rand(1,1) + 1;
    y_ = (total_random-1).*rand(1,1) + 1;    
    
    hold_grids = [];
    
    ap_grids(1, 1) = x_;
    ap_grids(1, 2) = y_;
    
    x_ = (total_random-1).*rand(1,1) + 1;
    y_ = (total_random-1).*rand(1,1) + 1;   
    
    safety = 1;

    for i = 2:number_of_aps
        
        x_ = (total_random-1).*rand(1,1) + 1;
        y_ = (total_random-1).*rand(1,1) + 1;
        
        while ~check_coords(ap_grids, x_, y_)
            
            x_ = (total_random-1).*rand(1,1) + 1;
            y_ = (total_random-1).*rand(1,1) + 1;
            if safety > 100
                selected = round((no_of_members-1).*rand(1,1) + 1);       
                safety = 1;
            else
                safety = safety + 1;
            end
        end

        ap_grids(i, 1) = x_;
        ap_grids(i, 2) = y_;        
        
        x_ = 0;
        y_ = 0;
    
    end


end

