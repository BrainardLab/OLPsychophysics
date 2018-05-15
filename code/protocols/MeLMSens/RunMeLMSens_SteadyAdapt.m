%% Run MeLMSens protocol

%% Set overall parameters
% We want to start with a clean slate, and set a number of parameters
% before doing anything else.
if exist('radiometer','var')
    try radiometer.shutDown
    end
end
clear all; close all; clc;

approach = 'OLApproach_Psychophysics';
protocol = 'MeLMSens';
simulate = getpref(approach,'simulate'); % localhook defines what devices to simulate

%% Set output path
participantID = GetWithDefault('>> Enter <strong>participant ID</strong>', 'HERO_xxxx');
participantAge = GetWithDefault('>> Enter <strong>participant age</strong>', 32);
sessionName = GetWithDefault('>> Enter <strong>session number</strong>:', 'session_1');
todayDate = datestr(now, 'yyyy-mm-dd');
protocolDataPath = getpref(protocol,'DataFilesBasePath');
participantDataPath = fullfile(protocolDataPath,participantID);
sessionDataPath = fullfile(participantDataPath,[todayDate '_' sessionName]);
mkdir(sessionDataPath);

%% Get calibration
% Specify which box and calibration to use, check that everything is set up
% correctly, and retrieve the calibration structure.
boxName = 'BoxB';
calibrationType = 'BoxBRandomizedLongCableBEyePiece2_ND01';
calibration = OLGetCalibrationStructure('CalibrationType',calibrationType,'CalibrationDate','latest');

%% Open the OneLight
% Open up a OneLight device
oneLight = OneLight('simulate',simulate.oneLight); drawnow;

%% Get radiometer
% Open up a radiometer, which we will need later on.
if ~simulate.radiometer
    oneLight.setAll(true);
    commandwindow;
    input('<strong>Focus the radiometer and press enter to pause 3 seconds and start measuring.</strong>\n');
    oneLight.setAll(false);
    pause(3);
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end

%% Create directions
% Melanopsin directed direction, background
Null = OLDirection_unipolar.Null(calibration);
MelDirectionParams = OLDirectionParamsFromName('MaxMel_unipolar_275_60_667','alternateDictionaryFunc','OLDirectionParamsDictionary_Psychophysics');
MelDirectionParams.primaryHeadRoom = 0;
MelDirectionParams.modulationContrast = OLUnipolarToBipolarContrast(3.5);
[MelStep, Mel_low] = OLDirectionNominalFromParams(MelDirectionParams, calibration, 'observerAge', participantAge);
Mel_high = Mel_low + MelStep;
receptors = MelStep.describe.directionParams.T_receptors;

% LMS-step directed direction, background
LMSDirectionParams = OLDirectionParamsFromName('MaxLMS_unipolar_275_60_667','alternateDictionaryFunc','OLDirectionParamsDictionary_Psychophysics');
LMSDirectionParams.primaryHeadRoom = 0;
LMSDirectionParams.modulationContrast = OLUnipolarToBipolarContrast([3.5 3.5 3.5]);
[LMSStep, LMS_low] = OLDirectionNominalFromParams(LMSDirectionParams, calibration, 'observerAge', participantAge);
LMS_high = LMS_low + LMSStep;

% LMS flicker directions
FlickerDirectionParams = OLDirectionParamsFromName('MaxLMS_bipolar_275_60_667','alternateDictionaryFunc','OLDirectionParamsDictionary_Psychophysics');
FlickerDirectionParams.primaryHeadRoom = 0;
FlickerDirectionParams.modulationContrast = [.05 .05 .05];
FlickerDirection_Mel_low = OLDirectionNominalFromParams(FlickerDirectionParams, calibration, 'background', Mel_low, 'observerAge', participantAge);
FlickerDirection_Mel_high = OLDirectionNominalFromParams(FlickerDirectionParams, calibration, 'background', Mel_high, 'observerAge', participantAge);
FlickerDirection_LMS_low = OLDirectionNominalFromParams(FlickerDirectionParams, calibration, 'background', LMS_low, 'observerAge', participantAge);
FlickerDirection_LMS_high = OLDirectionNominalFromParams(FlickerDirectionParams, calibration, 'background', LMS_high, 'observerAge', participantAge);

%% Validations
input('<strong>Focus the radiometer and press any key to pause 3 seconds and start measuring.</strong>\n'); pause(3);
validations = containers.Map();
validations('Mel_lowhigh') = OLValidateDirection(Mel_high, Mel_low, oneLight, radiometer, 'receptors', receptors);
validations('LMS_lowhigh')  = OLValidateDirection(LMS_high, LMS_low, oneLight, radiometer, 'receptors', receptors);
validations('Flicker_Mel_low') = OLValidateDirection(FlickerDirection_Mel_low, Mel_low, oneLight, radiometer, 'receptors', receptors);
validations('Flicker_Mel_high') = OLValidateDirection(FlickerDirection_Mel_high, Mel_high, oneLight, radiometer, 'receptors', receptors);
validations('Flicker_LMS_low') = OLValidateDirection(FlickerDirection_LMS_low, LMS_low, oneLight, radiometer, 'receptors', receptors);
validations('Flicker_LMS_high') = OLValidateDirection(FlickerDirection_LMS_high, LMS_high, oneLight, radiometer, 'receptors', receptors);

%% Corrections, re-validations
% TODO

%% Setup acquisitions
% Low Mel
acquisitions(1) = Acquisition_FlickerSensitivity_2IFC(...
    Mel_low,...
    FlickerDirection_Mel_low,...
    receptors,...
    'name',"Mel_low");

% High Mel
acquisitions(2) = Acquisition_FlickerSensitivity_2IFC(...
    Mel_high,...
    FlickerDirection_Mel_high,...
    receptors,...
    'name',"Mel_high");

% Low LMS
acquisitions(3) = Acquisition_FlickerSensitivity_2IFC(...
    LMS_low,...
    FlickerDirection_LMS_low,...
    receptors,...
    'name',"LMS_low");

% High LMS
acquisitions(4) = Acquisition_FlickerSensitivity_2IFC(...
    LMS_high,...
    FlickerDirection_LMS_high,...
    receptors,...
    'name',"LMS_high");

%% Run acquisitions
sessionResults = table();

rngSettings = rng;
acquisitions = Shuffle(acquisitions);

for acquisition = acquisitions
    fprintf('Running acquisition %s...\n',acquisition.name)
    acquisition.initializeStaircases();
    acquisition.runAcquisition(oneLight);

    % Get threshold estimate
    for k = 1:acquisition.NInterleavedStaircases
        acquisition.thresholds(k) = getThresholdEstimate(acquisition.staircases{k});
    end
    
    % Validate contrast at threshold
    desiredContrast = [1 1 1 0]' * mean(acquisition.thresholds);
    scaledDirection = acquisition.direction.ScaleToReceptorContrast(acquisition.background, receptors, desiredContrast);
    [acquisition.validationAtThreshold, ~, ~, validationContrast] = OLValidateDirection(scaledDirection,acquisition.background, oneLight, 'receptors', receptors);
    acquisition.validatedContrastAtThreshold = validationContrast.actual;
    
    % Collect results
    acquisitionResults.condition = acquisition.name;
    acquisitionResults.contrast = acquisition.validatedContrastAtThreshold;
    save(fullfile(sessionDataPath,sprintf('data-%s-%s-%s',participantID,sessionName,acquisition.name)),'acquisition');
    
    sessionResults = [sessionResults struct2table(acquisitionResults)];
    writetable(sessionResults,fullfile(sessionDataPath,['results-' participantID '-' sessionName '.csv']));
end
    
%% Close radiometer
if exist('radiometer','var') && ~isempty(radiometer)
    radiometer.shutDown();
end

%% Close OneLight
shutdown = input('<strong>Shutdown OneLight? [Y/N]</strong>>> ','s');
if upper(shutdown) == 'Y'
    oneLight.shutdown();
end
oneLight.close();