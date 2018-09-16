function [state_space] = Q_learning( state_space )

    epsilon = state_space.epsilon;
    reward_boost = 0;
    
    if state_space.previous_error(end) >= state_space.previous_error(end-1)
        reward_boost = -1;
    elseif state_space.previous_error(end) < state_space.previous_error(end-1)
        reward_boost = 1;
    end
    
    state_space.epsilon_payout_matrix(state_space.current_state, state_space.current_action) = state_space.epsilon_payout_matrix(state_space.current_state, state_space.current_action) + 1;
    
    epsilon_probs = state_space.Q_matrix(state_space.current_state, :) ./ state_space.epsilon_payout_matrix(state_space.current_state, state_space.current_action);
    [~, epsilon_max] = max(epsilon_probs);
    [~, epsilon_min] = min(epsilon_probs);
    r = (1-0).*rand(1,1) + 0;
    
    if epsilon < r   
        state_space.next_action = epsilon_max;        
    else        
        state_space.next_action = epsilon_min;    
    end
        
    state_space.next_state = state_space.current_action;
    
    state_space.Q_matrix(state_space.current_state, state_space.current_action) = state_space.Q_matrix(state_space.current_state, state_space.current_action) + state_space.alpha * (reward_boost + state_space.reward_matrix(state_space.current_state, state_space.current_action) + state_space.gamma * max(state_space.Q_matrix(state_space.next_state, :)) - state_space.Q_matrix(state_space.current_state, state_space.current_action));       
    
    state_space.current_state = state_space.next_state;
    state_space.current_action = state_space.next_action;
    
    state_space.epsilon = epsilon;
    
end

