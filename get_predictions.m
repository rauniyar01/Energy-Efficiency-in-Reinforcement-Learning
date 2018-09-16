function [ prediction ] = get_predictions( posterior, labels )

    for i = 1:length(labels)
    
        [M, I] = max(posterior(i, :));
        prediction(i) = I;
    
    end

end

