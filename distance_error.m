function [ distance ] = distance_error( predicted_labels, actual_labels, state_space )

    error = 0;
    number_of_instances = length(predicted_labels);
    internal = 1;
    for i = 1:number_of_instances
        if predicted_labels(i) ~= 0 && actual_labels(i) ~= 0 
            pred = state_space.grid_coordinates( predicted_labels(i), : );
            actu = state_space.grid_coordinates( actual_labels(i), : );
            X = [pred; actu];
            dist(internal) = pdist(X,'euclidean');
            internal = internal + 1;
        end
    end
    distance = mean(dist);
    
end

