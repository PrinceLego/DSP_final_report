clc; clear; close all;

if ~isfile('1.wav')
    warning('找不到 1.wav，將使用隨機訊號模擬。');
    fs = 10000;
    clean_sig = randn(80000, 1);
else
    [clean_sig, fs] = audioread('1.wav');
end

%% Figure 1A, 1B, 1C: 多種雜訊之 Wiener Filter 降噪結果 (含原始訊號對照)
% 定義要測試的三種雜訊類型
noise_files = {'/Users/prince_lego/Documents/program/MATLAB/DSP_final_report/horn.wav', ...
               '/Users/prince_lego/Documents/program/MATLAB/DSP_final_report/mouse.wav', ...
               '/Users/prince_lego/Documents/program/MATLAB/DSP_final_report/whitenoise.wav'};
noise_names = {'Horn Noise (喇叭聲)', 'Mouse Noise (滑鼠聲)', 'White Noise (白雜訊)'};
fig_titles = {'Figure 1A', 'Figure 1B', 'Figure 1C'};

for k = 1:3
    curr_noise_file = noise_files{k};
    curr_noise_name = noise_names{k};
    curr_fig_title = fig_titles{k};
    
    disp(['正在生成 ' curr_fig_title ' (' curr_noise_name ')...']);
    

    figure('Name', [curr_fig_title ': ' curr_noise_name ' 降噪分析'], 'NumberTitle', 'off', 'Color', 'w');
    set(gcf, 'Position', [50+k*30, 50, 1000, 900]); 
    
    % 1. 混合雜訊 (SNR = 5dB)
    try
        [noisy_sig, ~] = audio_SNR(clean_sig, curr_noise_file, 5, fs);
        has_noise_file = true;
    catch
        warning(['缺少 ' curr_noise_file '，使用模擬雜訊代替。']);
        has_noise_file = false;
        % 簡單模擬雜訊 (Fallback)
        t = (0:length(clean_sig)-1)'/fs;
        if k==1 % Horn
            noise = 0.1 * sin(2*pi*400*t);
        elseif k==2 % Mouse
            noise = zeros(size(clean_sig)); idx = randperm(length(noise), 50); noise(idx) = 0.5;
        else % White
            noise = 0.05 * randn(size(clean_sig));
        end
        % 簡單疊加 (若 audio_SNR 失敗)
        noisy_sig = clean_sig + noise;
    end
    
    % 2. 執行 Wiener Filter
    if exist('WienerScalart96', 'file')
        enhanced_sig = WienerScalart96(noisy_sig(:,1), fs, 0.5);
    else
        enhanced_sig = noisy_sig; % Fallback
    end
    
    % --- 繪圖區 (改為 4x2 版面) ---
    
    % 第一排：原始乾淨訊號 (Clean)
    subplot(4, 2, 1);
    plot((0:length(clean_sig)-1)/fs, clean_sig(:,1), 'g'); % 綠色代表乾淨
    title('原始乾淨語音波形 (Clean)'); grid on; axis tight;
    xlabel('Time (s)'); ylabel('Amplitude');
    
    subplot(4, 2, 2);
    spectrogram(clean_sig(:,1), 1024, 512, [], fs, 'yaxis');
    title('原始乾淨語音頻譜');
    
    % 第二排：含雜訊訊號 (Noisy)
    subplot(4, 2, 3);
    plot((0:length(noisy_sig)-1)/fs, noisy_sig(:,1), 'k'); % 黑色代表雜訊
    title(['含雜訊波形: ' curr_noise_name]); grid on; axis tight;
    xlabel('Time (s)'); ylabel('Amplitude');
    
    subplot(4, 2, 4);
    spectrogram(noisy_sig(:,1), 1024, 512, [], fs, 'yaxis');
    title(['含雜訊頻譜: ' curr_noise_name]);
    
    % 第三排：降噪後訊號 (Enhanced)
    subplot(4, 2, 5);
    plot((0:length(enhanced_sig)-1)/fs, enhanced_sig, 'b'); % 藍色代表處理後
    title('Wiener Filter降噪後波形'); grid on; axis tight;
    xlabel('Time (s)'); ylabel('Amplitude');
    
    subplot(4, 2, 6);
    spectrogram(enhanced_sig, 1024, 512, [], fs, 'yaxis');
    title('Wiener Filter降噪後頻譜');
    
end


%% Figure 2: 房間聲學模型與 Z 轉換特性 (含相位頻譜)

disp('正在生成 Figure 2 (RIR 系統特性)...');
figure('Name', 'Figure 2: RIR 系統特性 (含相位)', 'NumberTitle', 'off', 'Color', 'w');
set(gcf, 'Position', [100, 100, 1500, 800]);

% 參數設定
mic = [1 2 2]; nn = 5; src = [2 3 1]; rm = [5 5 4]; a = 0.8;
h = rir(fs, mic, nn, a, rm, src);

% 1. 時域脈衝響應
subplot(2, 3, 1);
plot(h);
title('房間脈衝響應 h[n] (Time Domain)');
xlabel('Sample n'); ylabel('Amplitude'); grid on;

% 2. Z 平面極零點圖
subplot(2, 3, 2);
zplane(h, 1); 
title('Z 平面極零點圖 (Z-Plane)');
text(-0.8, 0.8, 'Poles at Origin', 'FontSize', 8, 'BackgroundColor', 'w');

% 4. 振幅頻率響應
[H_freq, w_freq] = freqz(h, 1, 1024);
subplot(2, 3, 4);
plot(w_freq/pi, 20*log10(abs(H_freq)));
title('振幅頻譜 (Magnitude Response)');
xlabel('Normalized Frequency (\times\pi rad/sample)'); ylabel('dB'); grid on;

% 5. 相位頻率響應
subplot(2, 3, 5);
plot(w_freq/pi, angle(H_freq));
title('相位頻譜 (Phase Response)');
xlabel('Normalized Frequency'); ylabel('Radians'); grid on;

% 6. 群延遲
[gd, w_gd] = grpdelay(h, 1, 1024);
subplot(2, 3, 6);
plot(w_gd/pi, gd);
title('Group Delay');
xlabel('Frequency'); ylabel('Samples'); grid on;



%% 準備回音模擬資料 (用於 LMS/NLMS)

input_sim = randn(1, 40000); % 40k samples
d_sim = filter(h, 1, input_sim); % 期望訊號 (含回音)
N = 291; w0 = zeros(N, 1);
mu_values = [0.6, 0.06, 0.006, 0.0006]; % 注意：LMS 在 0.6 通常會發散


%% Figure 3A: LMS 不同步階值收斂比較

disp('正在生成 Figure 3A (LMS 收斂比較)...');
figure('Name', 'Figure 3A: LMS MSE 收斂比較', 'NumberTitle', 'off', 'Color', 'w');

for i = 1:4
    curr_mu = mu_values(i);
    [e_lms, ~] = full_lms(input_sim, d_sim, N, w0, curr_mu);
    mse_curve = 10 * log10(filter(ones(1,100)/100, 1, e_lms.^2));
    
    subplot(2, 2, i);
    plot(mse_curve);
    title(['LMS \mu = ' num2str(curr_mu)]);
    xlabel('Iterations'); ylabel('MSE (dB)'); grid on; axis tight;
    ylim([-100 50]);
end


%% Figure 3B: NLMS 不同步階值收斂比較

disp('正在生成 Figure 3B (NLMS 收斂比較)...');
figure('Name', 'Figure 3B: NLMS MSE 收斂比較', 'NumberTitle', 'off', 'Color', 'w');

for i = 1:4
    curr_mu = mu_values(i);
    % 使用 NLMS
    [e_nlms, ~] = full_nlms(input_sim, d_sim, N, w0, curr_mu);
    mse_curve = 10 * log10(filter(ones(1,100)/100, 1, e_nlms.^2));
    
    subplot(2, 2, i);
    plot(mse_curve, 'r'); % 使用紅色區別 NLMS
    title(['NLMS \mu = ' num2str(curr_mu)]);
    xlabel('Iterations'); ylabel('MSE (dB)'); grid on; axis tight;
    ylim([-100 50]);
    
end


%% Figure 4: LMS vs NLMS 與 系統識別

disp('正在生成 Figure 4 (NLMS 效能與系統識別)...');
figure('Name', 'Figure 4: NLMS 效能與系統識別', 'NumberTitle', 'off', 'Color', 'w');

% 比較參數: 取一個穩定的 LMS mu 和一個快速的 NLMS mu
mu_lms_safe = 0.006;
mu_nlms_fast = 0.6; % NLMS 可以用大步階

[e_lms, ~] = full_lms(input_sim, d_sim, N, w0, mu_lms_safe);
[e_nlms, w_final_nlms] = full_nlms(input_sim, d_sim, N, w0, mu_nlms_fast);

mse_lms = 10 * log10(filter(ones(1,100)/100, 1, e_lms.^2));
mse_nlms = 10 * log10(filter(ones(1,100)/100, 1, e_nlms.^2));

% 1. MSE 比較
subplot(2, 1, 1);
plot(mse_lms, 'b'); hold on;
plot(mse_nlms, 'r');
legend(['LMS (\mu=' num2str(mu_lms_safe) ')'], ['NLMS (\mu=' num2str(mu_nlms_fast) ')']);
title('LMS vs NLMS 收斂速度比較');
xlabel('Iterations'); ylabel('MSE (dB)'); grid on;

% 2. 系統識別結果
subplot(2, 1, 2);
stem(h(1:N), 'b', 'filled'); hold on;
stem(w_final_nlms(end, :), 'r--');
legend('真實 RIR (True h)', 'NLMS 估測權重 (Estimated w)');
title('系統識別結果 (System Identification)');
xlabel('Tap Index'); ylabel('Coefficient'); grid on;

disp('所有圖表生成完畢！');