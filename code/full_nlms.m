function [e, w] = full_nlms(x, d, N, w0, mu)
    x = x(:); d = d(:); w0 = w0(:);
    L = length(x);
    w = zeros(L, N);
    w(1, :) = w0';
    e = zeros(L, 1);
    
    % Pad x with zeros
    x_pad = [zeros(N-1, 1); x];
    eps = 1e-10; % 防止除以零
    
    for i = 1:L
        x_vec = x_pad(i+N-1 : -1 : i);
        y = w(i, :) * x_vec;
        e(i) = d(i) - y;
        
        % NLMS Update
        norm_factor = x_vec' * x_vec + eps;
        if i < L
            w(i+1, :) = w(i, :) + (mu / norm_factor) * e(i) * x_vec';
        end
    end
end