function [ fwd, bkw, posterior, loglik ] = forward_backward_variable( data_observations, state_space, transition_probability, prior_probability, varargin )

    number_of_supported_sensors = 3;
    number_of_sensors = (nargin - 4)/2;
    number_of_descriptors = zeros(number_of_sensors, 1);
    number_of_states = size(state_space.transition_matrix, 1);
    number_of_observations = size(data_observations{1}, 1);
    
    trans_prob = transition_probability;
    trans_prob(isinf(trans_prob)) = -100;
    
    prior_prob = prior_probability;
    
    binary_sensor_array = zeros(number_of_supported_sensors, 1);
    matrices = cell(number_of_sensors, 1);
    observations = cell(number_of_sensors, 1);
    summands = cell(number_of_sensors, 1);
    names_of_sensors = cell(number_of_sensors, 1);
    offset_parameter = 2;    
    
    current_iterator_nominal = 1;
    for sensor = 3:2:nargin - offset_parameter 
        
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
    
    emissions_per_epoch = zeros(number_of_states, number_of_observations);
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
        emissions_per_epoch(:, observation) = sum(bayes_summand, 1);               
    end   
   
    % forward part of the algorithm
    fwd = [];
    f_prev = [];
    
    for i = 1:number_of_observations    
        f_curr = [];
        for j = 1:number_of_states
            if i == 1
               prev_f_sum = prior_prob(j);
               fwd = [fwd, prior_prob(j)];  
            else
                for l = 1:number_of_states
                    summation(l) = f_prev(l) + trans_prob(l, j); 
                end
                prev_f_sum = sum_logs(summation);
            end           
            f_curr(j) = emissions_per_epoch(j, i) + prev_f_sum;
        end
        f_curr = f_curr-sum_logs(f_curr); 
        fwd = [fwd; f_curr];
        f_prev = f_curr;    
    end

    %backward part of the algorithm
    bkw = zeros(number_of_observations+1, number_of_states);
    b_prev = [];
    
    for i = number_of_observations+1:-1:1    
        b_curr = zeros(1, number_of_states);
        for j = 1:number_of_states
            if i == number_of_observations+1
                b_curr(j) = 0;
            else
                for l = 1:number_of_states
                    summation(l) = trans_prob(j, l) + emissions_per_epoch(j, i) + b_prev(l); 
                end
                b_curr(j) = sum_logs(summation);
            end
        end
        if i ~= number_of_observations+1            
            b_curr = b_curr-sum_logs(b_curr);
            b_curr(isinf(abs(b_curr))) = -realmin;
            bkw(i, :) = b_curr;
        end
        b_prev = b_curr;    
    end
    for l = 1:number_of_states
        summation_(l) = prior_prob(l) + sum(emissions_per_epoch(:, l, 1)) + b_curr(l);
    end
    
    p_bkw = sum_logs(summation_);
    
    %Merging
    posterior = [];
    for i = 1:number_of_observations
        summat = [];
        for l = 1:number_of_states
            summat(l) = (fwd(i, l) + bkw(i, l))-p_bkw;
        end
        summat = summat-sum_logs(summat);
        summat(isinf(abs(summat))) = -1e8;
        posterior = [posterior; summat];
    end 
    
    for result = 1:size(posterior, 1)   
        [m, i] = max(posterior(result, :));
        res(result) = m;
    end
    
    loglik = sum(res);
        
end

% for observation = 1:number_of_observations
%         num = 0;
%         den = 0;
%         iterator = 1;        
%         if binary_sensor_array(1) == 1
%             pir_boundary = number_of_descriptors(iterator);
%             pir_epoch = zeros(pir_boundary, number_of_states);
%             emissions_at_epoch_pir = summands{iterator}(:, :, observation)';       
%             for desc = 1:number_of_descriptors(iterator)           
%                 num = prior_prob + emissions_at_epoch_pir(:, desc);
%                 den = sum_logs(emissions_at_epoch_pir(:, desc));
%                 pir_epoch(desc, :) = num-den;        
%             end
%             iterator = iterator + 1;    
%         end
%         
%         if binary_sensor_array(2) == 1
%             rssi_boundary = number_of_descriptors(iterator);
%             rssi_epoch = zeros(rssi_boundary, number_of_states);
%             emissions_at_epoch_rssi = summands{iterator}(:, :, observation)';       
%             for desc = 1:number_of_descriptors(iterator)          
%                 num = prior_prob + emissions_at_epoch_rssi(:, desc);
%                 den = sum_logs(emissions_at_epoch_rssi(:, desc));
%                 rssi_epoch(desc, :) = num-den;        
%             end
%             iterator = iterator + 1;
%         end
%         
%         if binary_sensor_array(3) == 1
%             acc_boundary = number_of_descriptors(iterator);
%             acc_epoch = zeros(acc_boundary, number_of_states);
%             emissions_at_epoch_acc = summands{iterator}(:, :, observation)';       
%             for desc = 1:number_of_descriptors(iterator)            
%                 num = prior_prob + emissions_at_epoch_acc(:, desc);
%                 den = sum_logs(emissions_at_epoch_acc(:, desc));
%                 acc_epoch(desc, :) = num-den;        
%             end
%             iterator = iterator + 1;
%         end
% 
%         for state = 1:number_of_states
%             emissions_per_epoch(state, observation) = sum_logs(pir_epoch(:, state)) + sum_logs(rssi_epoch(:, state)) + sum_logs(acc_epoch(:, state));        
%         end
%         
%     end   

