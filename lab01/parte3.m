%% GRABADORA SIMPLE DE VOZ
% Crea el archivo voz_prueba.wav desde el micrófono [cite: 221]
clear; close all; clc;

%% Configuración
fs = 8000;                      % Frecuencia de muestreo (8 kHz) [cite: 224, 226]
duracion = 5;                   % Duración de la grabación en segundos [cite: 225, 227]
nombre_archivo = 'voz_prueba.wav';

fprintf('=== GRABADORA DE VOZ ===\n');
fprintf('Frecuencia: %d Hz\n', fs);
fprintf('Duración: %d segundos\n', duracion);
fprintf('Archivo: %s\n\n', nombre_archivo);

%% Grabación desde micrófono
fprintf('Preparando grabación...\n');
try
    % Crear objeto de grabación
    grabadora = audiorecorder(fs, 16, 1); % 16 bits, mono [cite: 237]
    fprintf('Grabando durante %d segundos...\n', duracion);
    fprintf('HABLE AHORA...\n');
    
    % Iniciar grabación
    recordblocking(grabadora, duracion);
    
    % Obtener los datos de audio
    audio_data = getaudiodata(grabadora);
    fprintf('Grabación completada.\n');
catch error
    fprintf('Error: No se pudo acceder al micrófono.\n');
    fprintf('Mensaje: %s\n', error.message);
    return;
end

%% Normalizar audio
audio_data = audio_data / max(abs(audio_data)) * 0.99; 

%% Guardar archivo WAV
try
    audiowrite(nombre_archivo, audio_data, fs);
    fprintf('Archivo guardado: %s\n', nombre_archivo);
    
    % Mostrar información del archivo
    info = audioinfo(nombre_archivo);
    fprintf('Duración: %.2f segundos\n', info.Duration);
    fprintf('Muestras: %d\n', info.TotalSamples);
    fprintf('Tamaño: %.2f KB\n', info.FileSize/1024);
catch error
    fprintf('Error al guardar el archivo: %s\n', error.message);
    return;
end

%% Reproducir grabación
fprintf('\n¿Reproducir grabación? (s/n): ');
respuesta = input('', 's');
if lower(respuesta) == 's'
    fprintf('Reproduciendo...\n');
    sound(audio_data, fs);
    pause(duracion + 1);
end

fprintf('\n=== PROCESO COMPLETADO ===\n');
fprintf('El archivo %s está listo para usar.\n', nombre_archivo);