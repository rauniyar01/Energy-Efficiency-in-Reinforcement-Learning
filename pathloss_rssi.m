function [ rssi ] = pathloss_rssi( distance )

    rssi_0 = -49.4; %As per Mellios et al
    d_0 = 1.2;
    sigma = 2.5;
    X_g = sample_gaussian(0, sigma, 1);
    n = 3; %As per Salas
    
    rssi = rssi_0 - 10*n*log(distance/d_0) - X_g;

end

