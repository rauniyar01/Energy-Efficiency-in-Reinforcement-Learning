function [ result ] = check_bounds( x_bound, y_bound, x, y )

    result = 0;
    if (x > x_bound(1) && x <= x_bound(2)) && (y > y_bound(1) && y <= y_bound(2))
        result = 1;
    else
        result = 0;
    end

end

