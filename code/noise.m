%% 產生三種純雜訊 (Pure Noise) 的波形與頻譜圖
% 用途：用於報告 "III. 實驗設置" 或 "IV. 結果 - 雜訊特性分析"
% 功能：讀取 horn, mouse, whitenoise 並繪製波形與頻譜

clc; clear; close all;

% 自動切換至當前路徑
currentFolder = fileparts(mfilename('fullpath'));
if ~isempty(currentFolder), cd(currentFolder); end

% 設定雜訊檔案 (請確認檔名與路徑)
noise_files = {'horn.wav', 'mouse.wav', 'whitenoise.wav'};
noise_names = {'Horn Noise (喇叭聲)', 'Mouse Noise (滑鼠聲)', 'White Noise (白雜訊)'};
fig_titles = {'Figure N1', 'Figure N2', 'Figure N3'}; % N代表Noise

% 模擬參數 (當讀不到檔案時使用)
fs_sim = 10000;
T_sim = 2; % 秒
t_sim = (0:T_sim*fs_sim-1)'/fs_sim;

for k = 1:3
    curr_file = noise_files{k};
    curr_name = noise_names{k};
    
    disp(['正在分析雜訊: ' curr_name '...']);
    
    % --- 1. 讀取或模擬雜訊 ---
    try
        if isfile(curr_file)
            [y, fs] = audioread(curr_file);
            % 若為雙聲道，轉單聲道
            if size(y, 2) > 1, y = mean(y, 2); end
        else
            error('File not found');
        end
    catch
        warning(['找不到 ' curr_file '，使用模擬訊號代替。']);
        fs = fs_sim;
        if k == 1 % Horn: 週期性方波/三角波混合
            y = 0.5 * square(2*pi*400*t_sim) + 0.3 * sin(2*pi*800*t_sim);
        elseif k == 2 % Mouse: 稀疏脈衝
            y = zeros(size(t_sim));
            idx = randperm(length(y), 10); % 隨機 10 個點擊
            y(idx) = 1.0;
            % 稍微平滑化模擬真實錄音
            y = filter([0.2 0.5 0.8 0.5 0.2], 1, y); 
        else % White: 高斯白雜訊
            y = 0.5 * randn(size(t_sim));
        end
    end
    
    % --- 2. 繪圖 (上：波形，下：頻譜) ---
    figure('Name', [fig_titles{k} ': ' curr_name ' 特性分析'], 'NumberTitle', 'off', 'Color', 'w');
    set(gcf, 'Position', [100+k*50, 100, 800, 600]);
    
    % 波形圖
    subplot(2, 1, 1);
    plot((0:length(y)-1)/fs, y, 'Color', [0.8500 0.3250 0.0980]); % 使用橘紅色區別雜訊
    title([curr_name ' - Time Domain Waveform']);
    xlabel('Time (s)'); ylabel('Amplitude'); 
    grid on; axis tight;
    ylim([-1.1 1.1]); % 固定範圍方便比較
    
    % 頻譜圖
    subplot(2, 1, 2);
    % 調整頻譜參數以獲得清晰解析度
    win_len = fix(0.03 * fs); % 30ms window
    spectrogram(y, win_len, fix(win_len/2), 1024, fs, 'yaxis');
    title([curr_name ' - Spectrogram']);
    colormap('jet');
end

disp('所有雜訊分析圖表生成完畢！');
