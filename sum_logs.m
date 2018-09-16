function [ out ] = sum_logs( array_to_sum )

    array_to_sum = squeeze(array_to_sum);

    array_to_sum(isinf(array_to_sum)) = -10000;
    array_to_sum(isnan(array_to_sum)) = -10000;

    out = 0;
    if size(array_to_sum, 1) == 1 && size(array_to_sum, 2) == 1 
        out = array_to_sum;
    elseif isempty(array_to_sum)
        out = -10000;
    else
        for i = 2:length(array_to_sum)   
            if i == 2
%                 out = add_lns(array_to_sum(i-1), array_to_sum(i));
                out = add_lns_c(array_to_sum(i-1), array_to_sum(i));
            else
%                 out = add_lns(out, array_to_sum(i));
                out = add_lns_c(out, array_to_sum(i));
            end   
        end
    end
end

