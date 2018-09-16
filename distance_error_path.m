function [ distance ] = distance_error_path( predicted_labels, actual_labels, state_space )

    error = 0;
    number_of_instances = length(predicted_labels);
    internal = 1;
    for i = 1:number_of_instances
        if predicted_labels(i) ~= 0 && actual_labels(i) ~= 0 
            dist(internal) =  dijkstra_custom(state_space.distance_matrix, predicted_labels(i), actual_labels(i));
            if isinf(dist(internal))            
                dist(internal) =  dijkstra_custom(state_space.distance_matrix, actual_labels(i), predicted_labels(i));            
            end
            internal = internal + 1;
        end
    end
    dist(isinf(dist)) = [];
    distance = mean(dist);

end

