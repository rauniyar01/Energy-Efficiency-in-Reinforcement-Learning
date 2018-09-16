function [ state_space_ ] = create_state_space( number_of_aps_, number_of_states_, number_of_oracles_, propagation_method_, oracling_method_, action_selection_method_, gamma, alpha )

    state_space_ = state_space;
    state_space_.number_of_aps = number_of_aps_;
    state_space_.number_of_states = number_of_states_;
    state_space_.number_of_oracles = number_of_oracles_;
    state_space_.propagation_method = propagation_method_;
    
    rssi_max = 40;
    rssi_min = 100;
    rssi_range = rssi_min - rssi_max;
    rssi_interval = rssi_max:rssi_min;
    
    var_max = 20;
    var_min = 1;
    
    space_size = number_of_aps_ * number_of_states_;
    mu_loader = zeros(space_size, 1);  
    sigma_loader = zeros(space_size, 1); 
    mu_loader_noisy = zeros(space_size, 1);  
    sigma_loader_noisy = zeros(space_size, 1); 
    
    [ transition, transition_noisy, grids, distance_ ] = create_measurement_space(number_of_states_);
    [ oracle_matrix, oracle_emissions, oracle_emissions_conditional ] = create_oracles(number_of_oracles_, grids, oracling_method_);
    
    if strcmp(propagation_method_, 'optimal')      
        mu_jumps = rssi_range/space_size;       
        internal = 1;
        for index = rssi_max:mu_jumps:rssi_min - 1       
            mu_loader(internal) = index;
            internal = internal + 1;        
        end          
        for index = 1:space_size      
            sigma_loader(index) = 0.1;       
        end  
        mu_loader = mu_loader(randperm(length(mu_loader)));
        sigma_loader = sigma_loader(randperm(length(sigma_loader)));
    elseif strcmp(propagation_method_, 'random')    
        for index = 1:space_size           
            mu_loader(index) = (rssi_min-rssi_max)*rand(1,1) + rssi_max;            
        end        
        for index = 1:space_size      
            sigma_loader(index) = (var_min-var_max)*rand(1,1) + var_max;       
        end 
        mu_loader = mu_loader(randperm(length(mu_loader)));
        sigma_loader = sigma_loader(randperm(length(sigma_loader)));
    elseif strcmp(propagation_method_, 'select')
        internal = 1;
        for ap_index = 1:number_of_aps_
            for state_index = 1:number_of_states_
                prompt1 = ['Input mean for AP ', num2str(ap_index), ' for state ', num2str(state_index), ': '];
                mu_loader(internal) = input(prompt1);
                prompt2 = ['Input variance for AP ', num2str(ap_index), ' for state ', num2str(state_index), ': '];
                sigma_loader(internal) = input(prompt2);
                internal = internal + 1;
            end
        end 
    elseif strcmp(propagation_method_, 'pathloss')
        internal = 1;
        iteration = 10;
        ap_grid = create_aps(number_of_aps_, number_of_states_, 2); 
        for ap_index = 1:number_of_aps_
            for state_index = 1:number_of_states_
                receiver = ap_grid(ap_index, :);
                transmitter = grids(state_index, :);
                X = [receiver; transmitter];               
                distance = pdist(X,'euclidean');
                for iter = 1:iteration                
                    rssi_holder(iter) = abs(pathloss_rssi(distance));                    
                end                
                mu_loader(internal) = mean(rssi_holder);
                sigma_loader(internal) = std(rssi_holder); 
                rssi_holder = awgn(rssi_holder, 3, 'measured');
                mu_loader_noisy(internal) = mean(rssi_holder);
                sigma_loader_noisy(internal) = std(rssi_holder);
                rssi_holder = [];
                internal = internal + 1;
            end
        end       
    end
    
    emission_matrix_ = cell(number_of_aps_, number_of_states_);
    emission_matrix_noisy_ = cell(number_of_aps_, number_of_states_);
        
    internal = 1;
    for ap_index = 1:number_of_aps_    
        for state_index = 1:number_of_states_        
            emission_matrix_{ap_index, state_index} = [mu_loader(internal), sigma_loader(internal)];
            emission_matrix_noisy_{ap_index, state_index} = [mu_loader_noisy(internal), sigma_loader_noisy(internal)];           
            internal = internal + 1;        
        end   
    end
    
    prior = ones(number_of_states_, 1);
    prior = prior/sum(prior);
    
    Q_matrix = zeros(2, 2);
    epsilon_payout_matrix = zeros(2, 2);
    Q_matrix(1, 1) = 0.000001;
    Q_adjusted_transition_matrix = zeros(number_of_states_, number_of_states_);
    
    % Reward Matrix
    reward_matrix = zeros(2, 2);
    reward_matrix(1, 1) = -1;
    reward_matrix(1, 2) = 0; 
    reward_matrix(2, 1) = 0;
    reward_matrix(2, 2) = 1;
    
    Q_adjusted_emission_matrix = emission_matrix_noisy_;
    
    Q_adjusted_transition_matrix = Q_adjusted_transition_matrix .* transition;
    Q_adjusted_transition_matrix(transition ~= 0) = 1;
    Q_adjusted_transition_matrix = normalise_matrix(Q_adjusted_transition_matrix);
    
    state_space_.distance_matrix = distance_;
    state_space_.grid_coordinates = grids;
    state_space_.prior_vector = prior;
    
    state_space_.epsilon = 0.1;
    
    state_space_.epsilon_payout_matrix = epsilon_payout_matrix;
    
    state_space_.emission_matrix = emission_matrix_;
    state_space_.emission_matrix_noisy = emission_matrix_noisy_;
    state_space_.emission_matrix_baum_welch = emission_matrix_noisy_;
    
    state_space_.transition_matrix = transition;
    state_space_.transition_matrix_noisy = transition_noisy;
    state_space_.transition_matrix_baum_welch = transition_noisy;
    
    state_space_.Q_adjusted_transition_matrix = Q_adjusted_transition_matrix;
    state_space_.Q_adjusted_emission_matrix = Q_adjusted_emission_matrix;
    
    state_space_.oracle_emissions_conditional = oracle_emissions_conditional;
    state_space_.oracle_emissions = oracle_emissions;
    state_space_.oracle_matrix = oracle_matrix;
    
    state_space_.oracling_method = oracling_method_;
    state_space_.Q_matrix = Q_matrix;
    state_space_.reward_matrix = reward_matrix;
    state_space_.gamma = gamma;
    state_space_.alpha = alpha;
    state_space_.previous_error = [110, 100];
    state_space_.current_state = 1;
    state_space_.next_state = 1;
    state_space_.current_action = 1;
    state_space_.next_action = 1;
    state_space_.converged = 0;
    
    state_space_.action_selection_method = action_selection_method_;
    

end

