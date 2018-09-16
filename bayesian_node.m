function [ bayesian_posterior ] = bayesian_node( data_observations, state_space, varargin )

    number_of_supported_sensors = 3;
    number_of_sensors = (nargin - 2)/2;
    number_of_descriptors = zeros(number_of_sensors, 1);
    number_of_states = size(state_space.transition_matrix, 1);
    number_of_observations = size(data_observations{1}, 1);
    
    binary_sensor_array = zeros(number_of_supported_sensors, 1);
    matrices = cell(number_of_sensors, 1);
    observations = cell(number_of_sensors, 1);
    summands = cell(number_of_sensors, 1);
    names_of_sensors = cell(number_of_sensors, 1);
    offset_parameter = 2;    

    prior_prob = log(state_space.prior_vector);
    
    current_iterator_nominal = 1;
    for sensor = 3:2:nargin 
        
        current_iterator_name = sensor - offset_parameter;
        current_iterator_emission = sensor - offset_parameter + 1;
        
        matrices{current_iterator_nominal} = varargin{current_iterator_emission};
        observations{current_iterator_nominal} = data_observations{current_iterator_nominal};
        number_of_descriptors(current_iterator_nominal) = size(varargin{current_iterator_emission}, 2);    
        names_of_sensors{current_iterator_nominal} = varargin{current_iterator_name};
        
        current_emission_matrix = matrices{current_iterator_nominal};
        current_observations = observations{current_iterator_nominal};
        current_summand = zeros(number_of_descriptors(current_iterator_nominal), number_of_states, number_of_observations);

        mean_discretised = zeros(number_of_states, number_of_descriptors(current_iterator_nominal));
        std_discretised = zeros(number_of_states, number_of_descriptors(current_iterator_nominal));

        for state = 1:number_of_states
            for descriptor = 1:number_of_descriptors(current_iterator_nominal)
                mean_discretised(state, descriptor) = current_emission_matrix{state, descriptor}(1);
                std_discretised(state, descriptor) = current_emission_matrix{state, descriptor}(2);
            end
        end
                   
        for observation = 1:number_of_observations
            sample = zeros(number_of_descriptors(current_iterator_nominal), number_of_states);
            for state = 1:number_of_states
                for descriptor = 1:number_of_descriptors(current_iterator_nominal)
                    % Here add additional sensors as required.
                    if strcmp(names_of_sensors{current_iterator_nominal}, 'pir')
                        binary_sensor_array(1) = 1;
                        sample(descriptor, state) = sampling_normcdf_pir(current_observations(observation, descriptor), mean_discretised(state, descriptor), std_discretised(state, descriptor), 1 );                    
                    elseif strcmp(names_of_sensors{current_iterator_nominal}, 'rssi')
                        binary_sensor_array(2) = 1;
                        sample(descriptor, state) = sampling_normcdf(current_observations(observation, descriptor), mean_discretised(state, descriptor), std_discretised(state, descriptor), 1 );
                    elseif strcmp(names_of_sensors{current_iterator_nominal}, 'acc')
                        binary_sensor_array(3) = 1;
                        sample(descriptor, state) = sampling_normcdf_acc(current_observations(observation, descriptor), mean_discretised(state, descriptor), std_discretised(state, descriptor), 1 ); 
                    end
                    
                    if isinf(sample(descriptor, state))
                        sample(descriptor, state) = -10;
                    end
                    if ~isreal(sample(descriptor, state))
                        sample(descriptor, state) = -abs(sample(descriptor, state));
                    end
                end
            end
            sample(sample > 0) = 0;
            current_summand(:, :, observation) = sample;
        end          
    
        if size(current_summand, 1) > 1
            for observation = 1:number_of_observations
                for state = 1:number_of_states
                    for descriptor = 1:number_of_descriptors(current_iterator_nominal)
                        current_summand(descriptor, state, observation) = current_summand(descriptor, state, observation) - sum_logs(current_summand(:, state, observation));    
                    end
                end
            end
        end            
        
        summands{current_iterator_nominal} = current_summand;
        
        current_iterator_nominal = current_iterator_nominal + 1;     
    end
    
    bayesian_posterior = zeros(number_of_states, number_of_observations);
    bayes_summand = zeros(number_of_sensors, number_of_states);
    boundary = 1;
    
    iterator = 1;
    for observation = 1:number_of_observations
        num = 0;
        den = 0;
        iterator = 1;
        for sensor = 1:number_of_supported_sensors
            if binary_sensor_array(sensor) == 1
                boundary = number_of_descriptors(iterator);
                epoch = zeros(boundary, number_of_states);
                emissions_at_epoch = summands{iterator}(:, :, observation)';       
                for desc = 1:number_of_descriptors(iterator)           
                    num = prior_prob + emissions_at_epoch(:, desc);
                    den = sum_logs(emissions_at_epoch(:, desc));
                    epoch(desc, :) = num-den;        
                end              
                for state = 1:number_of_states
                    bayes_summand(iterator, state) = sum_logs(epoch(:, state));
                end
                iterator = iterator + 1; 
            end              
        end        
        bayesian_posterior(:, observation) = sum(bayes_summand, 1);               
    end     

end

