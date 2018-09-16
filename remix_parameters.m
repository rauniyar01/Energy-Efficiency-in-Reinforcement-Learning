function [Q_adjusted_transition_matrix, Q_adjusted_emission_matrix] = remix_parameters(Q_adjusted_transition_matrix, Q_adjusted_emission_matrix, data, oracle_reading)

    number_of_aps = size(Q_adjusted_emission_matrix, 1);
    number_of_states = size(Q_adjusted_emission_matrix, 2);
    number_of_observations = size(oracle_reading, 1);
    number_of_oracles = size(oracle_reading, 2);
    proportion = 0.7;

    %% Transitions
    for observations = 1:number_of_observations - 1
        for oracle = 1:number_of_oracles
            if oracle_reading(observations, oracle) ~= 0 && oracle_reading(observations+1, oracle) ~= 0
                Q_adjusted_transition_matrix(oracle_reading(observations, oracle), oracle_reading(observations+1, oracle)) = Q_adjusted_transition_matrix(oracle_reading(observations, oracle), oracle_reading(observations+1, oracle)) + 0.01;    
                [ Q_adjusted_transition_matrix ] = normalise_matrix( Q_adjusted_transition_matrix );
            elseif (oracle_reading(observations, oracle) == 0 && oracle_reading(observations+1, oracle) ~= 0)
                possible = Q_adjusted_transition_matrix(:, oracle_reading(observations+1, oracle));
                possible(possible ~= 0) = 0.01; 
                possible(oracle_reading(observations+1, oracle)) = 0;
                Q_adjusted_transition_matrix(:, oracle_reading(observations+1, oracle)) = Q_adjusted_transition_matrix(:, oracle_reading(observations+1, oracle)) + possible;
                [ Q_adjusted_transition_matrix ] = normalise_matrix( Q_adjusted_transition_matrix );
            elseif (oracle_reading(observations, oracle) ~= 0 && oracle_reading(observations+1, oracle) == 0)
                possible = Q_adjusted_transition_matrix(oracle_reading(observations, oracle), :);
                possible(possible ~= 0) = 0.01; 
                possible(oracle_reading(observations, oracle)) = 0;
                Q_adjusted_transition_matrix(oracle_reading(observations, oracle), :) = Q_adjusted_transition_matrix(oracle_reading(observations, oracle), :) + possible;
                [ Q_adjusted_transition_matrix ] = normalise_matrix( Q_adjusted_transition_matrix );
            end
        end
    end

    %% Emissions
    for ap_index = 1:number_of_aps
        for state_index = 1:number_of_states         
            means(ap_index, state_index) = Q_adjusted_emission_matrix{ap_index, state_index}(1);
            variances(ap_index, state_index) = (Q_adjusted_emission_matrix{ap_index, state_index}(2))^2;        
        end   
    end
    
    iter_total = 100;
    rssi_holder = [];
    
    for ap_index = 1:number_of_aps
        for state_index = 1:number_of_states
            for observation_index = 1:number_of_observations
                for oracle = 1:number_of_oracles
                    if oracle_reading(observation_index, oracle) ~= 0 && oracle_reading(observation_index, oracle) == state_index
                        mu_loader = data(observation_index, ap_index);

                        mean_nominal = mean([mu_loader, means(ap_index, state_index)]);
                        var_nominal = var([mu_loader, means(ap_index, state_index)]);

                        mu_loader_final = proportion * mean_nominal + (1-proportion) * means(ap_index, state_index);

                        sigma_first = proportion * var_nominal + (1-proportion) * variances(ap_index, state_index);
                        sigma_second = proportion * mu_loader^2 + (1-proportion) * means(ap_index, state_index)^2;
                        sigma_third = (proportion * mu_loader + (1-proportion) * means(ap_index, state_index))^2; 

                        sigma_loader_final = sigma_first + (sigma_second - sigma_third);

                        if mu_loader ~= 0
    %                         means(ap_index, state_index)
    %                         sqrt(variances(ap_index, state_index))
    %                         mu_loader_final
    %                         sqrt(sigma_loader_final)
                            Q_adjusted_emission_matrix{ap_index, state_index} = [mu_loader_final, sqrt(sigma_loader_final)];
                            mu_loader = [];
                            sigma_loader = [];
                            rssi_holder = [];
                        end

                    end
                end
            end
        end
    end
                       
end

