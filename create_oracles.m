function [ oracle_matrix, oracle_emissions, oracle_emissions_conditional ] = create_oracles(number_of_oracles_, grids, oracling_method_)

    number_of_states = size(grids, 1);
    oracle_matrix = zeros(number_of_states, 1);
    oracle_emissions = cell(number_of_states, number_of_oracles_);
    oracle_emissions_conditional = zeros(number_of_states, number_of_oracles_);
    
    for states = 1:number_of_states
        for oracle = 1:number_of_oracles_
            oracle_emissions{states, oracle} = [-100, 2];
            oracle_emissions_conditional(states, oracle) = 0;
        end
    end

    if strcmp(oracling_method_, 'total')
        oracle_matrix(1:number_of_states) = 1;
        
    elseif strcmp(oracling_method_, 'sporadic')
        oracle_matrix(:) = number_of_oracles_;  
        oracle_matrix = oracle_matrix / length(oracle_matrix);
        
    elseif strcmp(oracling_method_, 'single')
        grid_rands = 1:number_of_states;    
        grid_rands = grid_rands(randperm(numel(grid_rands)));    
        chosen_grids = grid_rands(1:number_of_oracles_);
        oracle_matrix(chosen_grids) = 1;  
        for grids = chosen_grids    
            oracle_emissions{grids, find(chosen_grids == grids)} = [1, 0.00001];
            oracle_emissions_conditional(grids, find(chosen_grids == grids)) = 1;
        end
        
    end   
end