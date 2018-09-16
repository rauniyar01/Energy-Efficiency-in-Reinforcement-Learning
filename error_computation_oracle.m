function [ error ] = error_computation_oracle( predicted_labels, actual_labels )

    error = 0;
    number_of_instances = length(predicted_labels);
    internal =0;
    for i = 1:number_of_instances  
        if (predicted_labels(i) ~= 0 && actual_labels(i) ~= 0)
            if predicted_labels(i) ~= actual_labels(i)
                error = error + 1; 
            end
            internal = internal + 1;
        end
    end
    error = (error/internal) * 100;
    if isnan(error)     
        error = 100;    
    end
end