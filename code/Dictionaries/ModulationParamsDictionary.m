%ModulationParamsDictionary
%
% Description:
%   Generate dictionary with modulation params
%
% 6/23/17  npc  Wrote it.

function d = ModulationParamsDictionary()
    % Initialize dictionary
    d = containers.Map();
    
    %% Modulation-MaxMelPulsePsychophysics-PulseMaxLMS_3s_MaxContrast3sSegment
    modulationName = 'Modulation-PulseMaxLMS_3s_MaxContrast3sSegment';
    params = defaultParams();
    
    % Direction identifiers
    params.direction = 'LMSDirectedSuperMaxLMS';                        % Modulation direction
    params.directionCacheFile = 'Direction_LMSDirectedSuperMaxLMS.mat'; % Cache file to be used
    d(modulationName) = params;
        
    
    %% Modulation-MaxMelPulsePsychophysics-PulseMaxMel_3s_MaxContrast3sSegment
    modulationName = 'Modulation-PulseMaxMel_3s_MaxContrast3sSegment';
    params = defaultParams();
    
    % Direction identifiers
    params.direction = 'MelanopsinDirectedSuperMaxMel';                        % Modulation direction
    params.directionCacheFile = 'Direction_MelanopsinDirectedSuperMaxMel.mat'; % Cache file to be used
    d(modulationName) = params;

    
    %% Modulation-MaxMelPulsePsychophysics-PulseMaxLightFlux_3s_MaxContrast3sSegment
    modulationName = 'Modulation-PulseMaxLightFlux_3s_MaxContrast3sSegment';
    params = defaultParams();
    
    % Direction identifiers
    params.direction = 'LightFluxMaxPulse';                         % Modulation direction
    params.directionCacheFile = 'Direction_LightFluxMaxPulse.mat';  % Cache file to be used
    d(modulationName) = struct(params);
end

function params = defaultParams()

    params = struct();
    % Type - * * * do we need one ? we have  params.modulationMode = 'pulse' ????? * * * *
    params.type = 'pulse';
    
    % Timing information
    params.trialDuration = 3;                   % Number of seconds to show each trial            
    params.timeStep = 1/64;                     % Number ms of each sample time
    params.cosineWindowIn = true;               % If true, have a cosine fade-in
    params.cosineWindowOut = true;              % If true, have a cosine fade-out
    params.cosineWindowDurationSecs = 0.5;      % Duration (in secs) of the cosine fade-in
    
    % Modulation information
    params.nFrequencies = 1;                    % Total number of frequencies
    params.nPhases = 1;                         % Total number of phases
    params.modulationMode = 'pulse';
    params.modulationWaveForm = 'pulse';
            
    % Modulation frequency parameters
    params.modulationFrequencyTrials = [];     % Sequence of modulation frequencies
    params.modulationPhase = [];

    params.phaseRandSec = [0];                 % Phase shifts in seconds
    params.preStepTimeSec = 0.5;               % Time before step
    params.stepTimeSec = 2; 
            
    % Carrier frequency parameters
    params.carrierFrequency = [-1];            % Sequence of carrier frequencies
    params.carrierPhase = [-1];
            
    % Contrast scaling
    params.nContrastScalars = 1;               % Number of different contrast scales
    params.contrastScalars = [1];              % Contrast scalars (as proportion of max.)
    params.maxContrast = 4;

    params.coneNoise = 0;                      % Do cone noise?
    params.coneNoiseFrequency = 8;
       
    % Direction identifiers
    params.direction = '';                     % Modulation direction
    params.directionCacheFile = '';            % Cache file to be used
    
    % Stimulation mode
    params.stimulationMode = 'maxmel';
end
