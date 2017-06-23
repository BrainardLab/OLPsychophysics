% Class used to define modulation params. It includes the three predifined
% modulation params, but new ones can be generated by passing approrpiate
% value-key pairs.
%
% 6/23/17   npc         Wrote it.

classdef ModulationParams
    %ModulationParams Class used to define modulation params

    properties (SetAccess = private)
        pStruct;
    end
    
    properties (Access = private)
        
        % Modulation name
        modulationName;
        
        % Timing information
        trialDuration;                  % Number of seconds to show each trial
        timeStep;                       % Number ms of each sample time
        cosineWindowIn;                 % If true, have a cosine fade-in
        cosineWindowOut;                % If true, have a cosine fade-out
    	cosineWindowDurationSecs;       % Duration (in secs) of the cosine fade-in
        
        % Modulation information
    	nFrequencies;                   % Total number of frequencies
    	nPhases;                        % Total number of phases
    	modulationMode;
    	modulationWaveForm;
        
        % Modulation frequency parameters
    	modulationFrequencyTrials;      % Sequence of modulation frequencies
    	modulationPhase;

    	phaseRandSec;                   % Phase shifts in seconds
    	preStepTimeSec;                 % Time before step
    	stepTimeSec;                    % Step duration in seconds 
        
        % Carrier frequency parameters
        carrierFrequency;               % Sequence of carrier frequencies
        carrierPhase;
        
        % Contrast scaling
    	nContrastScalars;               % Number of different contrast scales
    	contrastScalars;                % Contrast scalars (as proportion of max.)
    	maxContrast;

    	coneNoise;                      % Do cone noise?
    	coneNoiseFrequency;             % Frequency in Hz
        
        % Direction identifiers
        direction;                      % Modulation direction
        directionCacheFile;             % Cache file to be used

        % Stimulation mode
        stimulationMode;

        % Default modulation names - these are using the default params
        defaultModulationNames = {...
            'Modulation-MaxMelPulsePsychophysics-PulseMaxLMS_3s_MaxContrast3sSegment.cfg' ...
            'Modulation-MaxMelPulsePsychophysics-PulseMaxMel_3s_MaxContrast3sSegment.cfg' ...
            'Modulation-MaxMelPulsePsychophysics-PulseMaxLightFlux_3s_MaxContrast3sSegment.cfg' ...
        };
    end
    
    methods
        % Constructor
        function obj = ModulationParams(varargin)  
           
            % Parse input to make sure it is valid
            p = inputParser;
            
            % Name of modulation
            p.addParameter('modulationName', '', @ischar);
            
            % Timing information
            p.addParameter('trialDuration', 3, @isnumeric);                 % Number of seconds to show each trial            
            p.addParameter('timeStep',1/64, @isnumeric);                    % Number ms of each sample time
            p.addParameter('cosineWindowIn',true, @islogical);              % If true, have a cosine fade-in
            p.addParameter('cosineWindowOut',true, @islogical);             % If true, have a cosine fade-out
            p.addParameter('cosineWindowDurationSecs',0.5, @isnumeric);     % Duration (in secs) of the cosine fade-in
        
            % Modulation information
            p.addParameter('nFrequencies',1, @isnumeric);                   % Total number of frequencies
            p.addParameter('nPhases',1, @isnumeric);                        % Total number of phases
            p.addParameter('modulationMode','pulse', @ischar);
            p.addParameter('modulationWaveForm','pulse', @ischar);
        
            % Modulation frequency parameters
            p.addParameter('modulationFrequencyTrials',[], @isnumeric);     % Sequence of modulation frequencies
            p.addParameter('modulationPhase',[], @isnumeric);

            p.addParameter('phaseRandSec',[0], @isnumeric);                 % Phase shifts in seconds
            p.addParameter('preStepTimeSec',0.5, @isnumeric);               % Time before step
            p.addParameter('stepTimeSec',2, @isnumeric);                    % Step duration in seconds 
        
            % Carrier frequency parameters
            p.addParameter('carrierFrequency',[-1], @isnumeric);            % Sequence of carrier frequencies
            p.addParameter('carrierPhase',[-1], @isnumeric);
        
            % Contrast scaling
            p.addParameter('nContrastScalars',1, @isnumeric);               % Number of different contrast scales
            p.addParameter('contrastScalars',[1], @isnumeric);              % Contrast scalars (as proportion of max.)
            p.addParameter('maxContrast',4, @isnumeric);

            p.addParameter('coneNoise',0, @isnumeric);                      % Do cone noise?
            p.addParameter('coneNoiseFrequency',8, @isnumeric);             % Frequency in Hz

            % Direction identifiers
            p.addParameter('direction', '', @ischar);                       % Modulation direction
            p.addParameter('directionCacheFile', '',@ischar);               % Cache file to be used
        
            % Stimulation mode
            p.addParameter('stimulationMode','maxmel', @ischar);
            p.parse(varargin{:});
            
            % Check that the user is not passing additional input params
            % for a predifined modulation name.
            if (ismember(p.Results.modulationName, obj.defaultModulationNames))
                % Ignore additional input params and let user we are doing so
                if (nargin > 2)
                    error('Since you passed a known modulation name, you may not pass additional modulation params!!\n');
                end
            end

            % Initialize our properties and get pStruct ready for the user
            fNames = fieldnames(p.Results);
            obj.pStruct = struct();
            for k = 1:numel(fNames)
               obj.(fNames{k}) = p.Results.(fNames{k});
               obj.pStruct.(fNames{k}) = [];
            end
            
            % Set appropriate direction and directionCacheFile for predefined modulations
            switch(p.Results.modulationName)
                case 'Modulation-MaxMelPulsePsychophysics-PulseMaxLMS_3s_MaxContrast3sSegment.cfg'
                    obj.direction = 'LMSDirectedSuperMaxLMS';
                    obj.directionCacheFile = 'Direction_LMSDirectedSuperMaxLMS.mat';
                case 'Modulation-MaxMelPulsePsychophysics-PulseMaxMel_3s_MaxContrast3sSegment.cfg'
                    obj.direction = 'MelanopsinDirectedSuperMaxMel';
                    obj.directionCacheFile = 'Direction_MelanopsinDirectedSuperMaxMel.mat';
                case 'Modulation-MaxMelPulsePsychophysics-PulseMaxLightFlux_3s_MaxContrast3sSegment.cfg'
                    obj.direction = 'LightFluxMaxPulse';
                    obj.directionCacheFile = 'Direction_LightFluxMaxPulse.mat';
            end % switch
                
            % Error if we have no direction name
            if (isempty(obj.direction))
                error('You must either specify a value for ''direction'' or pass a known modulationName.');
            end
            
            % Error if we have no direction cache file
            if (isempty(obj.directionCacheFile))
                error('You must either specify a value for ''directionCacheFile'' or pass a known modulationName.');
            end
        end
        
        % Return a struct from the class properties
        function pStruct = structFromClass(obj)
            pStruct = struct();
            fNames = fieldnames(obj.pStruct);
            for k = 1:numel(fNames)
               pStruct.(fNames{k}) = obj.(fNames{k});
            end
        end
    end  % methods
end

