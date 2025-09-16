%% 2.1. CARGA DE SEÑAL DE VOZ DE PRUEBA
try
    [voz_original, fs_voz] = audioread('voz_prueba.wav');
catch
    % Generar señal de voz sintética si no hay archivo
    fs_voz = 8000;
    t_voz = 0:1/fs_voz:2;
    voz_original = 0.5*sin(2*pi*500*t_voz) + 0.3*sin(2*pi*1200*t_voz);
end
voz_original = voz_original(:);

% Normalizar y recortar
voz_original = voz_original(1:min(16000, length(voz_original)));
voz_original = voz_original / max(abs(voz_original));

%% 2.2. MODULACIÓN PCM CON CUANTIZACIÓN UNIFORME
function [voz_cuantizada, niveles] = pcm_uniforme(senal, bits)
    niveles = 2^bits;
    paso = 2 / (niveles - 1);
    voz_cuantizada = round(senal / paso) * paso;
end

% Aplicar PCM uniforme con diferentes resoluciones
bits = [4, 8, 12];
voz_pcm = cell(length(bits), 1);
for i = 1:length(bits)
    [voz_pcm{i}, niveles] = pcm_uniforme(voz_original, bits(i));
    subplot(3,2,2+i);
    plot((1:500)/fs_voz, voz_original(1:500), 'b', 'LineWidth', 1);
    hold on;
    plot((1:500)/fs_voz, voz_pcm{i}(1:500), 'r', 'LineWidth', 1.5);
    title(['PCM Uniforme ', num2str(bits(i)), ' bits']);
    xlabel('Tiempo (s)'); ylabel('Amplitud');
    legend('Original', 'Cuantizada'); grid on;
end

%% 2.3. COMPANDING LEY A
function senal_compandida = companding_leyA(senal, A)
    senal_compandida = zeros(size(senal));
    for n = 1:length(senal)
        if abs(senal(n)) < 1/A
            senal_compandida(n) = A*abs(senal(n))/(1+log(A));
        else
            senal_compandida(n) = (1+log(A*abs(senal(n))))/(1+log(A));
        end
        senal_compandida(n) = sign(senal(n)) * senal_compandida(n);
    end
end
A = 87.6;
voz_compandida = companding_leyA(voz_original, A);

% Aplicar PCM después de companding
[voz_pcm_compandida, ~] = pcm_uniforme(voz_compandida, 8);

%% 2.4. CÁLCULO DE SNQ (Señal a Ruido de Cuantización)
function snq = calcular_snq(original, cuantizada)
    error = original - cuantizada;
    potencia_senal = mean(original.^2);
    potencia_error = mean(error.^2);
    snq = 10*log10(potencia_senal / potencia_error);
end

% Comparar SNQ para diferentes configuraciones
snq_uniforme_8bit = calcular_snq(voz_original, voz_pcm{2});
snq_compand_8bit = calcular_snq(voz_original, voz_pcm_compandida);

fprintf('SNQ PCM Uniforme 8-bit: %.2f dB\n', snq_uniforme_8bit);
fprintf('SNQ PCM + Companding A-law 8-bit: %.2f dB\n', snq_compand_8bit);

%% 2.5. REPRODUCCIÓN COMPARATIVA
disp('Reproduciendo voz original...');
sound(voz_original, fs_voz);
pause(3);
disp('Reproduciendo voz con PCM uniforme 8-bit...');
sound(voz_pcm{2}, fs_voz);
pause(3);
disp('Reproduciendo voz con companding A-law...');
sound(voz_pcm_compandida, fs_voz);

%% 2.6. ANÁLISIS ESPECTROCOMPARATIVO
figure('Position', [100, 100, 1200, 600]);
N = length(voz_original);
f = (0:N-1)*(fs_voz/N);

% Espectro original
subplot(2,2,1);
espectro_orig = 20*log10(abs(fft(voz_original)));
plot(f(1:N/2), espectro_orig(1:N/2));
title('Espectro Voz Original');
xlabel('Frecuencia (Hz)'); ylabel('Amplitud (dB)'); grid on;

% Espectro PCM uniforme
subplot(2,2,2);
espectro_pcm = 20*log10(abs(fft(voz_pcm{2})));
plot(f(1:N/2), espectro_pcm(1:N/2));
title('Espectro PCM Uniforme 8-bit');
xlabel('Frecuencia (Hz)'); ylabel('Amplitud (dB)'); grid on;

% Espectro error de cuantización
subplot(2,2,3);
error = voz_original - voz_pcm{2};
espectro_error = 20*log10(abs(fft(error)));
plot(f(1:N/2), espectro_error(1:N/2));
title('Espectro Error de Cuantización');
xlabel('Frecuencia (Hz)'); ylabel('Amplitud (dB)'); grid on;

% Espectro con companding
subplot(2,2,4);
espectro_comp = 20*log10(abs(fft(voz_pcm_compandida)));
plot(f(1:N/2), espectro_comp(1:N/2));
title('Espectro PCM + Companding A-law');
xlabel('Frecuencia (Hz)'); ylabel('Amplitud (dB)'); grid on;

%% 2.7. ESTIMACIÓN DE MOS (MODELO SIMPLIFICADO)
function mos = estimar_mos(snq)
    % Modelo E-model simplificado para estimar MOS
    if snq > 35
        mos = 4.5;
    elseif snq > 30
        mos = 4.0;
    elseif snq > 25
        mos = 3.5;
    elseif snq > 20
        mos = 3.0;
    else
        mos = 2.5;
    end
end

mos_uniforme = estimar_mos(snq_uniforme_8bit);
mos_compand = estimar_mos(snq_compand_8bit);
fprintf('\n--- CALIDAD DE VOZ ESTIMADA ---\n');
fprintf('PCM Uniforme 8-bit: MOS = %.1f\n', mos_uniforme);
fprintf('PCM + Companding: MOS = %.1f\n', mos_compand);