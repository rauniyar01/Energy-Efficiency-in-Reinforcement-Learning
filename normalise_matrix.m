function [ matrix ] = normalise_matrix( matrix )

    for i = 1:size(matrix, 1) 
        matrix(i, :) = matrix(i, :) / sum(matrix(i, :));  
    end

end

