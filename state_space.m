classdef state_space
   properties
       
      number_of_aps;
      number_of_states;
      number_of_oracles;
      propagation_method;
      
      emission_matrix;
      emission_matrix_noisy;
      emission_matrix_baum_welch;
      
      transition_matrix;
      transition_matrix_noisy;
      transition_matrix_baum_welch;
      
      Q_adjusted_emission_matrix;
      Q_adjusted_transition_matrix;
      
      prior_vector;
      
      Q_matrix;
      reward_matrix;
      reward_boost;
      
      epsilon_payout_matrix;
      
      distance_matrix;
      grid_coordinates;
      
      oracle_emissions_conditional;
      oracle_emissions;
      oracle_matrix;
      gamma;
      alpha;
      
      energy_usage;
      oracling_method;
      
      converged;
      previous_error;
      
      action_selection_method;
      
      current_state;
      next_state;
      
      epsilon;
      
      current_action;
      next_action;
      
   end
   methods
   end
end