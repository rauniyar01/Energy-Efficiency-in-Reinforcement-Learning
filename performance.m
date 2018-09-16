function [ perfect_error, perfect_distance, perfect_path, nominal_error, nominal_distance, nominal_path, reinforced_error, reinforced_distance, reinforced_path, state_space ] = performance( state_space )

    sequence_length = 100;
    sequence_length_baum_welch = 10000;
    number_of_aps = state_space.number_of_aps;
    number_of_states = state_space.number_of_states;
    oracle_states = find(state_space.oracle_matrix == 1);
    number_of_oracles = state_space.number_of_oracles;
    
    for ap_index = 1:number_of_aps
        for state_index = 1:number_of_states         
            means(ap_index, state_index) = state_space.emission_matrix{ap_index, state_index}(1);
            variances(ap_index, state_index) = (state_space.emission_matrix{ap_index, state_index}(2))^2;        
        end   
    end
    oracle_result = zeros(1, sequence_length);
    sequence_sample = sample_state_sequence(state_space.prior_vector, state_space.transition_matrix, sequence_length, 1);
    if strcmp(state_space.oracling_method, 'single')
        oracle_reading = [];
        oracle_reading_states = [];
        for oracle = 1:number_of_oracles
            oracle_reading_ = sequence_sample;
            oracle_reading_(~ismember(oracle_reading_, oracle_states(oracle))) = 0;
            oracle_to_compute = oracle_reading_;
            oracle_reading_states(:, oracle) = oracle_reading_;
            oracle_reading_(ismember(oracle_reading_, oracle_states(oracle))) = 1;
            oracle_reading(:, oracle) = oracle_reading_;
        end

        for observation = 1:sequence_length        
            [~, i] = find(oracle_reading(observation, :) ~=0);
            if ~isempty(i)
                oracle_result(observation) = i; 
            else
                oracle_result(observation) = 0;
            end
        end
    elseif strcmp(state_space.oracling_method, 'sporadic')
        oracle_indecies_ = [];
        oracle_states = state_space.oracle_matrix;
        oracle_reading = zeros(sequence_length, number_of_states);
        oracle_reading_states = [];
        for oracle = 1:length(oracle_states)
            oracle_reading_ = find(sequence_sample == oracle);
            oracle_reading_ = oracle_reading_(randperm(length(oracle_reading_)));
            oracle_indecies_ = [ oracle_reading_(1:round(oracle_states(oracle)*length(oracle_reading_)))];
            oracle_reading((sequence_sample == oracle), oracle) = 1;
            oracle_result(oracle_indecies_) = oracle;
        end            
    end

    for state_index = 1:sequence_length
        for ap_index = 1:number_of_aps  
            data_point = sample_gaussian(means(ap_index, sequence_sample(state_index)), sqrt(variances(ap_index, sequence_sample(state_index))), 1);
            data(state_index, ap_index) = round(data_point); 
            data_point = [];
        end
    end
    
    % Nominal performance      
    bayesian_posterior = bayesian_node( {data}, state_space, 'rssi', state_space.emission_matrix' );
    [~, ~, perfect, ~] = fb( bayesian_posterior, log(state_space.transition_matrix), log(state_space.prior_vector));      
    
    perfect_result = get_predictions( perfect, sequence_sample );
    perfect_error = error_computation( perfect_result, sequence_sample ); 
    perfect_distance = distance_error( perfect_result, sequence_sample, state_space );    
    perfect_path = distance_error_path( perfect_result, sequence_sample, state_space );    
        
    bayesian_posterior = bayesian_node( {data}, state_space, 'rssi', state_space.emission_matrix_noisy' );
    [~, ~, nominal, ~] = fb( bayesian_posterior, log(state_space.transition_matrix_noisy), log(state_space.prior_vector));

    nominal_result = get_predictions( nominal, sequence_sample );
    nominal_error = error_computation( nominal_result, sequence_sample );
    nominal_distance = distance_error( nominal_result, sequence_sample, state_space );
    nominal_path = distance_error_path( nominal_result, sequence_sample, state_space ); 
          
    if state_space.current_state == 1
        [~, ~, reinforced, ~] = forward_backward_variable({oracle_reading, data}, state_space, log(state_space.Q_adjusted_transition_matrix), log(state_space.prior_vector), 'pir', state_space.oracle_emissions, 'rssi', state_space.Q_adjusted_emission_matrix');
        reinforced_result = get_predictions( reinforced, sequence_sample);
        reinforced_error = error_computation_oracle( reinforced_result, oracle_to_compute );
        reinforced_distance = distance_error( reinforced_result, sequence_sample, state_space );
        reinforced_path = distance_error_path( reinforced_result, sequence_sample, state_space ); 
        [state_space.Q_adjusted_transition_matrix, state_space.Q_adjusted_emission_matrix] = remix_parameters(state_space.Q_adjusted_transition_matrix, state_space.Q_adjusted_emission_matrix, data, oracle_reading_states);
    elseif state_space.current_state == 2
        [~, ~, reinforced, ~] = forward_backward_variable({data}, state_space, log(state_space.Q_adjusted_transition_matrix), log(state_space.prior_vector), 'rssi', state_space.Q_adjusted_emission_matrix');
        reinforced_result = get_predictions( reinforced, sequence_sample);
        reinforced_error = state_space.previous_error(end);
        reinforced_distance = distance_error( reinforced_result, sequence_sample, state_space );
        reinforced_path = distance_error_path( reinforced_result, sequence_sample, state_space ); 
    elseif state_space.current_state == 3
        state_space.converged = 1;
        [~, ~, reinforced, ~] = forward_backward_variable({data}, state_space, log(state_space.Q_adjusted_transition_matrix), log(state_space.prior_vector), 'rssi', state_space.Q_adjusted_emission_matrix');
        reinforced_result = get_predictions( reinforced, sequence_sample);
        reinforced_error = state_space.previous_error(end);
        reinforced_distance = distance_error( reinforced_result, sequence_sample, state_space );
        reinforced_path = distance_error_path( reinforced_result, sequence_sample, state_space ); 
    end           

    if state_space.converged ~= 1
        state_space.previous_error = [state_space.previous_error, reinforced_error];    
        if state_space.action_selection_method == 1
            state_space = Q_learning( state_space );
        elseif state_space.action_selection_method == 2
            state_space = Q_learning_random( state_space );
        elseif state_space.action_selection_method == 3
            state_space = Q_learning_greedy( state_space );
        end
    end
    
end

