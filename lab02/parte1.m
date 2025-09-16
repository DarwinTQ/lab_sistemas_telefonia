%% LABORATORIO 3-4: CONMUTACIÓN Y TRÁFICO TELEFÓNICO
clear all; close all; clc;

%% 1.1. PARÁMETROS DEL SISTEMA
num_lineas = 8; % Número total de líneas 
prob_llamada = 0.3; % Probabilidad de generar llamada en un segundo 
duracion_promedio = 180; % Duración promedio de una llamada en segundos 
tiempo_simulacion = 3600; % Tiempo total de la simulación en segundos (1 hora) 

fprintf('=== SIMULACIÓN DE CONMUTADOR TELEFÓNICO ===\n'); 
fprintf('Líneas disponibles: %d\n', num_lineas); 
fprintf('Tiempo de simulación: %d segundos (1 hora)\n', tiempo_simulacion); 

%% 1.2. INICIALIZACIÓN DE ESTADOS
% Matriz de estados: 0=libre, >0=ocupado (el valor es el tiempo restante)
estado_lineas = zeros(1, num_lineas); 
% Estructura para registrar la información de cada llamada
llamadas = struct('inicio', [], 'duracion', [], 'linea', [], 'estado', []); 

%% 1.3. SIMULACIÓN POR EVENTOS DISCRETOS
num_llamadas = 0; 
llamadas_bloqueadas = 0; 

for tiempo = 1:tiempo_simulacion 
    % Liberar líneas que terminan su llamada 
    for i = 1:num_lineas 
        if estado_lineas(i) > 0 
            estado_lineas(i) = estado_lineas(i) - 1; 
            if estado_lineas(i) == 0 
                fprintf('T=%-4d: Línea %d liberada\n', tiempo, i); 
            end
        end
    end

    % Generar nueva llamada (basado en la probabilidad) 
    if rand() < prob_llamada 
        num_llamadas = num_llamadas + 1; 
        
        % Buscar una línea libre 
        linea_libre = find(estado_lineas == 0, 1); 
        
        if ~isempty(linea_libre) 
            % Asignar la llamada a una línea libre 
            duracion = exprnd(duracion_promedio); 
            estado_lineas(linea_libre) = ceil(duracion); 
            
            % Guardar información de la llamada completada
            llamadas(num_llamadas).inicio = tiempo; 
            llamadas(num_llamadas).duracion = ceil(duracion); 
            llamadas(num_llamadas).linea = linea_libre; 
            llamadas(num_llamadas).estado = 'COMPLETADA'; 
            
            fprintf('T=%-4d: Llamada %d asignada a línea %d (dura: %d s)\n', ...
                    tiempo, num_llamadas, linea_libre, ceil(duracion)); 
        else
            % Bloquear la llamada si no hay líneas libres 
            llamadas_bloqueadas = llamadas_bloqueadas + 1; 
            
            % Guardar información de la llamada bloqueada
            llamadas(num_llamadas).inicio = tiempo; 
            llamadas(num_llamadas).duracion = 0; 
            llamadas(num_llamadas).linea = 0; 
            llamadas(num_llamadas).estado = 'BLOQUEADA'; 
            
            fprintf('T=%-4d: Llamada %d BLOQUEADA (todas las líneas ocupadas)\n', ...
                    tiempo, num_llamadas); 
        end
    end
end

%% 1.4. ESTADÍSTICAS DE LA SIMULACIÓN
fprintf('\n=== ESTADÍSTICAS DE SIMULACIÓN ===\n'); 
fprintf('Total de llamadas generadas: %d\n', num_llamadas); 
fprintf('Llamadas completadas: %d\n', num_llamadas - llamadas_bloqueadas); 
fprintf('Llamadas bloqueadas: %d\n', llamadas_bloqueadas); 
prob_bloqueo_sim = llamadas_bloqueadas / num_llamadas;
fprintf('Probabilidad de bloqueo: %.4f (%.2f%%)\n', ...
        prob_bloqueo_sim, prob_bloqueo_sim * 100); 
        
% Calcular tráfico ofrecido y cursado 
trafico_ofrecido = (num_llamadas * duracion_promedio) / tiempo_simulacion; 
trafico_cursado = ((num_llamadas - llamadas_bloqueadas) * duracion_promedio) / tiempo_simulacion; 
fprintf('Tráfico ofrecido: %.3f Erlangs\n', trafico_ofrecido); 
fprintf('Tráfico cursado: %.3f Erlangs\n', trafico_cursado); 
fprintf('Utilización del sistema: %.2f%%\n', (trafico_cursado / num_lineas) * 100); 

%% 1.5. VISUALIZACIÓN DE RESULTADOS
figure('Position', [100, 100, 1000, 800]);

% Gráfico de líneas ocupadas en el tiempo
subplot(2, 2, 1); 
% (Para una visualización más eficiente, se pre-calcula el estado en cada instante)
ocupacion_hist = zeros(num_lineas, tiempo_simulacion);
for i = 1:num_llamadas
    if strcmp(llamadas(i).estado, 'COMPLETADA')
        inicio = llamadas(i).inicio;
        fin = min(inicio + llamadas(i).duracion, tiempo_simulacion);
        linea = llamadas(i).linea;
        ocupacion_hist(linea, inicio:fin) = 1;
    end
end
plot(1:tiempo_simulacion, sum(ocupacion_hist), 'b', 'LineWidth', 1.5);
title('Ocupación del Sistema en el Tiempo'); 
xlabel('Tiempo (segundos)'); 
ylabel('Líneas ocupadas'); 
grid on; 
ylim([0, num_lineas]); 

% Histograma de duración de llamadas 
subplot(2, 2, 2); 
duraciones = [llamadas.duracion]; 
histogram(duraciones(duraciones > 0), 20, 'FaceColor', 'green'); 
title('Distribución de Duración de Llamadas'); 
xlabel('Duración (segundos)'); 
ylabel('Frecuencia'); 
grid on; 

% Probabilidad de bloqueo vs tiempo 
subplot(2, 2, 3); 
pb_acumulativo = zeros(1, tiempo_simulacion); 
llamadas_hasta_t_vec = 1:num_llamadas;
bloqueadas_hasta_t_vec = cumsum(strcmp({llamadas.estado}, 'BLOQUEADA'));
for t = 1:tiempo_simulacion 
    llamadas_hasta_t = sum([llamadas.inicio] <= t); 
    if llamadas_hasta_t > 0 
        bloqueadas_hasta_t = sum([llamadas([1:llamadas_hasta_t]).inicio] <= t & strcmp({llamadas([1:llamadas_hasta_t]).estado}, 'BLOQUEADA')); 
        pb_acumulativo(t) = bloqueadas_hasta_t / llamadas_hasta_t; 
    end
end
plot(1:tiempo_simulacion, pb_acumulativo, 'r', 'LineWidth', 1.5); 
title('Probabilidad de Bloqueo Acumulativa'); 
xlabel('Tiempo (segundos)'); 
ylabel('Probabilidad de bloqueo'); 
grid on; 

% Utilización de cada línea 
subplot(2, 2, 4); 
utilizacion_lineas = zeros(1, num_lineas); 
for i = 1:num_lineas 
    tiempo_ocupada = sum([llamadas([llamadas.linea] == i).duracion]); 
    utilizacion_lineas(i) = tiempo_ocupada / tiempo_simulacion; 
end
bar(1:num_lineas, utilizacion_lineas * 100, 'FaceColor', 'cyan'); 
title('Utilización por Línea');
xlabel('Número de Línea'); 
ylabel('Porcentaje de utilización (%)'); 
grid on; 
ylim([0, 100]);