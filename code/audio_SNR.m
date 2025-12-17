function [x, fs] = audio_SNR(clean_sig, noise_file, SNR_target, fs_target)
    if ischar(clean_sig)
        [y, fs] = audioread(clean_sig);
    else
        y = clean_sig;
        fs = fs_target;
    end
    
    if ~isfile(noise_file)
        warning('找不到雜訊檔，回傳原訊號');
        x = y;
        return;
    end
    
    [noise, ~] = audioread(noise_file);
    
    % 取單聲道與長度對齊
    if size(y, 2) > 1, y = y(:, 1); end
    if size(noise, 2) > 1, noise = noise(:, 1); end
    
    L = length(y);
    % 循環雜訊
    noise = repmat(noise, ceil(L/length(noise)), 1);
    noise = noise(1:L);
    
    % 計算能量
    P_signal = sum(y.^2);
    P_noise = sum(noise.^2);
    
    % 修正後的公式
    scale_factor = sqrt((P_signal / (10^(SNR_target/10))) / (P_noise + 1e-10));
    
    noise = noise * scale_factor;
    x = y + noise;
    x = x / max(abs(x)); % Normalize
end