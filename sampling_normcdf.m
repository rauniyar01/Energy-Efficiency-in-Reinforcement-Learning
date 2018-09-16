function [ probability ] = sampling_normcdf( observations, mean, std, islog )

    if islog
        probability = log((1/sqrt(2*pi*(std)^2))*exp(-(((observations - mean)^2)/(2*(std)^2))));
    else
        probability = (1/sqrt(2*pi*(std)^2))*exp(-(((observations - mean)^2)/(2*(std)^2)));
    end    

end

