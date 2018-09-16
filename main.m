%% SIMULATOR MAIN
% Simulator for Q-Learning of Localisation

clear all;
close all;
clc;

% Learning Parameters
gamma = 0.9;
alpha = 0.4;
oracle_proportion = 10;

internal_aps = 1;
internal_states = 1;
internal_oracle = 1;
for act_increase = 1
    for aps_increase = 5:8
        for state_increase = 10:10:30    
            for oracle_increase = state_increase/oracle_proportion:state_increase/oracle_proportion:state_increase 

                disp(['Current APs: ', num2str(aps_increase), ' Current States: ', num2str(state_increase), ' Current Oracles: ', num2str(oracle_increase), ' Current method: ', num2str(act_increase)]);

                % Number of APs
                number_of_aps = aps_increase;

                % Number of States
                number_of_states = state_increase;

                % Number of Oracles
                number_of_oracles = oracle_increase;

                % Method of propagation (Optimal // Random // Select // Pathloss)
                propagation_method = 'pathloss';

                % Method of oracling (Total // Single // Sporadic)
                oracling_method = 'single';

                % Action selection method
                action_selection_method_ = act_increase;

                % Create State Space
                state_space_handle = create_state_space( number_of_aps, number_of_states, number_of_oracles, propagation_method, oracling_method, action_selection_method_, gamma, alpha );

                repeats = 1;
                condition = 101;
                toplot = [];
                toplot_1 = [];

                while repeats ~= condition

                    % Compare performance
                    [   perfect_error(internal_aps, internal_states, internal_oracle, repeats),...
                        perfect_distance(internal_aps, internal_states, internal_oracle, repeats),...
                        perfect_path(internal_aps, internal_states, internal_oracle, repeats),...
                        nominal_error(internal_aps, internal_states, internal_oracle, repeats),...
                        nominal_distance(internal_aps, internal_states, internal_oracle, repeats),...
                        nominal_path(internal_aps, internal_states, internal_oracle, repeats),...
                        reinforced_error(internal_aps, internal_states, internal_oracle, repeats),...
                        reinforced_distance(internal_aps, internal_states, internal_oracle, repeats),...
                        reinforced_path(internal_aps, internal_states, internal_oracle, repeats),...
                        state_space_handle] = performance(state_space_handle);

                    states(internal_aps, internal_states, internal_oracle, repeats) = state_space_handle.current_state;
%                     if state_space_handle.converged ~= 1
%                         clf;
%                                        
%                         subplot(2, 1, 1);
%                         hold on;
%                         plot(1:repeats, squeeze(perfect_distance), 'g');
%                         plot(1:repeats, squeeze(nominal_distance), 'r');
%                         plot(1:repeats, squeeze(reinforced_distance), 'b');
%                         xlim([0 repeats]);
%                         ylim([0 5]);
%                         
%                         subplot(2, 1, 2);
%                         hold on;
%                         plot(1:repeats, squeeze(states), 'k');
%                         
%                         pause(0.001);
%                     end
                      repeats = repeats + 1;
                end
                internal_oracle = internal_oracle + 1;

            end
            internal_oracle = 1;
            internal_states = internal_states + 1;

        end
        internal_states = 1;
        internal_aps = internal_aps + 1;

    end
    
    save(['final_active_error_output_', num2str(act_increase), '_act.mat'], 'states', 'perfect_error', 'perfect_distance', 'perfect_path', 'nominal_error', 'nominal_distance', 'nominal_path', 'reinforced_error', 'reinforced_distance', 'reinforced_path');
    
    perfect_error = [];
    perfect_distance = [];
    perfect_path = [];
    nominal_error = [];
    nominal_distance = [];
    nominal_path = [];
    reinforced_error = [];
    reinforced_distance = [];
    reinforced_path = [];
    states = [];
    
end


