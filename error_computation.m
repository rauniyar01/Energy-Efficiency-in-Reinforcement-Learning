function [ error ] = error_computation( predicted_labels, actual_labels )

    error = 0;
    number_of_instances = length(predicted_labels);
    for i = 1:number_of_instances  
        if (predicted_labels(i) ~= 0 && actual_labels(i) ~= 0)
            if predicted_labels(i) ~= actual_labels(i)
                error = error + 1; 
            end
        else
            error = error + 1; 
        end
    end
    error = (error/number_of_instances) * 100;
end

