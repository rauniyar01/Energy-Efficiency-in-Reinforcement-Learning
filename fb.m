function [ fwd, bkw, posterior, loglik ] = fb( bayes_posterior, trans_prob, prior_prob )

    % Grab the amount of states and observations from Bayesian posterior
    number_of_states = size(bayes_posterior, 1);
    number_of_observations = size(bayes_posterior, 2);    
    
    % Allocate for the forward and backward sweeps
    fwd = zeros(number_of_observations + 1, number_of_states);
    f_prev = zeros(1, number_of_states);    
    bkw = zeros(number_of_observations + 1, number_of_states);
    b_prev = [];
    
    % Internal variables
    summand = zeros(1, number_of_states);
    backward_posterior = zeros(1, number_of_states);
    
    % Returns
    posterior = zeros(number_of_observations+1, number_of_states);
    res = zeros(1, number_of_observations+1);
    
    % Housekeeping
    trans_prob(isinf(trans_prob)) = -100;

    % Forward part of the algorithm
    for observation = 1:number_of_observations    
        f_curr = [];
        for state = 1:number_of_states
            if observation == 1
               prev_f_sum = prior_prob(state);
               fwd(observation, state) = prior_prob(state);  
            else
                for state_ = 1:number_of_states
                    summand(state_) = f_prev(state_) + trans_prob(state_, state); 
                end
                prev_f_sum = sum_logs(summand);
            end           
            f_curr(state) = bayes_posterior(state, observation) + prev_f_sum;
        end
        f_curr = f_curr - sum_logs(f_curr); 
        fwd(observation + 1, :) = f_curr;
        f_prev = f_curr;    
    end

    % Backward part of the algorithm   
    for observation = number_of_observations+1:-1:1    
        b_curr = zeros(1, number_of_states);
        for state = 1:number_of_states
            if observation == number_of_observations+1
                b_curr(state) = 0;
            else
                for state_ = 1:number_of_states
                    summand(state_) = trans_prob(state, state_) + bayes_posterior(state, observation) + b_prev(state_); 
                end
                b_curr(state) = sum_logs(summand);
            end
        end
        if observation ~= number_of_observations+1            
            b_curr = b_curr-sum_logs(b_curr);
            b_curr(isinf(abs(b_curr))) = -realmin;
            bkw(observation, :) = b_curr;
        end
        b_prev = b_curr;    
    end
    for state = 1:number_of_states
        backward_posterior(state) = prior_prob(state) + sum(bayes_posterior(:, state, 1)) + b_curr(state);
    end
    
    backward_posterior = sum_logs(backward_posterior);
    
    % Merging
    for observation = 1:number_of_observations
        posterior_per_state = zeros(number_of_states, 1);
        for state = 1:number_of_states
            posterior_per_state(state) = (fwd(observation, state) + bkw(observation, state)) - backward_posterior;
        end
        posterior_per_state = posterior_per_state-sum_logs(posterior_per_state);
        posterior_per_state(isinf(abs(posterior_per_state))) = -1e8;
        posterior(observation, :) = posterior_per_state;
    end 
    
    for result = 1:size(posterior, 1)   
        [optimal_probability, optimal_state] = max(posterior(result, :));
        res(result) = optimal_state;
        prob(result) = optimal_probability;
    end
           
    loglik = sum(prob);

end

