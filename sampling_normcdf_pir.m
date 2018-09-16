function [ probability ] = sampling_normcdf_pir( observations, mean, std, islog )
    
    if observations == mean 
        observations = observations;
    end

    if islog
        probability = log(normcdf_try(observations+0.001, mean, std) - normcdf_try(observations-0.001, mean, std));
    else
        probability = normcdf_try(observations + 3, mean, std) - normcdf_try(observations - 3, mean, std);
    end
    
end

