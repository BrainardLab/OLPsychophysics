%% Demo protocol in the Psychophysics approach
% This script demonstrates the workflow of running a protocol in the
% psychophysics approach.

%% Set the parameter structure here
% We want to start with a clean slate, and set a number of parameters
% before doing anything else.
clear all; close all; clc;
protocolParams.approach = 'OLApproach_Psychophysics';
protocolParams.protocol = 'Demo';
protocolParams.observerAge = 32;
protocolParams.simulate.oneLight = true;
protocolParams.simulate.radiometer = true;
radiometerPauseDuration = 0;

%% Get calibration
% Specify which box and calibration to use, check that everything is set up
% correctly, and retrieve the calibration structure.
protocolParams.boxName = 'BoxC';  
protocolParams.calibrationType = 'BoxCRandomizedLongCableBEyePiece2_ND01';
if (~strcmp(getpref('OneLightToolbox','OneLightCalData'),getpref(protocolParams.approach,'OneLightCalDataPath')))
    error('Calibration file prefs not set up as expected for an approach');
end
calibration = OLGetCalibrationStructure('CalibrationType',protocolParams.calibrationType,'CalibrationDate','latest');

%% Open the OneLight
% Open up a OneLight device
oneLight = OneLight('simulate',protocolParams.simulate.oneLight); drawnow;

%% Get radiometer
% Open up a radiometer, which we will need later on.
if ~protocolParams.simulate.radiometer
    oneLight.setAll(true);
    commandwindow;
    input(sprintf('<strong>Focus the radiometer and press enter to pause %d seconds and start measuring.</strong>\n', radiometerPauseDuration));
    oneLight.setAll(false);
    pause(radiometerPauseDuration);
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end

%% Create the melanopsin direction with maximal bipolar contrast
% A direction of modulation is stored in a directionStruct. This structure
% has the following fields:
%  - backgroundPrimary   : the primary values for the background.
%  - differentialPositive: the difference in primary values to be added to
%                          the background primary to create the positive
%                          direction
%  - differentialNegative: the difference in primary values to be added to
%                          the background primary to create the negative
%                          direction
%  - calibration         : the calibration structure used to generate the
%                          directionStruct. No code relies on this being in
%                          the struct, but it's good to store it.
%  - describe            : structure with additional metadata
%
% There are several ways to construct a directionStruct:
%  - from scratch; as long as you have the three primary fields in your
%    struct, it is a valid directionStruct
%  - from parameters; objects of OLDirectionParams-subclasses can define
%    parameter sets, and use the OLDirectionNominalStructFromParams to
%    generate a directionStruct that nominally corresponds to those
%    parameters
%  - from a name; the OLDirectionParamsDictionary defines several commonly
%    used sets of parameters and stores those under names. The names can be
%    retrieved using OLGetDirectionNames. The corresponding (nominal)
%    direction structs can be generated used
%    OLDirectionNominalStructFromName(directionName). The parameters can be
%    retrieved using OLDirectionParamsFromName(directionName).
%
% Here, we demonstrate getting a set of parameters from the directions
% dictionary, adjusting some of those parameters, and then generating the
% direction.
directionParams = OLDirectionParamsFromName('MaxMel_bipolar_275_80_667');
directionParams.primaryHeadRoom = .01;
directionStruct = OLDirectionNominalStructFromParams(directionParams, calibration, 'observerAge', protocolParams.observerAge);

%% Correct and validate the direction
% The nominal primary values often do not generate the exact spectral power
% distributions that we expect. We iteratively correct the primary values
% to get closer to the desired SPDs, and then validate that these primary
% values produce a direction that we can live with.
%
% The corrections code overwrites the primaries in the directionStruct
% (although it saves the nominal ones under the .describe field). This
% means that the same field(names) form the 'business end' of the direction
% struct, before and after correction. Thus, subsequent code does not have
% to know whether the direction was corrected or not. It also stores a lot
% of data in under .describe.correction, for debugging purposes.
directionStruct = OLCorrectDirection(directionStruct, calibration, oneLight, radiometer);

% We then validate the direction, by comparing the predicted and measured
% SPDs. Optionally, this can also calculate the actual and predicted
% contrasts. We store this information under the 'describe' field of the
% direction struct.
directionStruct.describe.validationPre = OLValidateDirection(directionStruct, calibration, oneLight, radiometer);

%% Create the temporal waveform
% Just like with directions, temporal waveforms can be constructed in
% several ways. Again, we demonstrate here getting a set of parameters from
% a dictionary, adjusting a parameter, and then constructing the waveform.
waveformParams = OLWaveformParamsFromName('MaxContrast3sSinusoid');
waveformParams.stimulusDuration = 5;
[waveform, timestep] = OLWaveformFromParams(waveformParams);

%% Assemble the modulation
% The modulation is the combination of background, direction and a temporal
% waveform. This is stored in a modulationStruct, with the following
% fields:
%   - primaryWaveform: the primary values for each device primary at each
%     timepoint. This is the actual stimulus presented on the OneLight. Can
%     be visualized using OLPlotPrimaryWaveform.
%   - starts, stops: the corresponding starts and stops for the OneLight
%     mirror matrix
%   - nominalSPDs: the nominal SPD at each timepoint, predicted from the
%     primaryWaveform.
%   - primaryValues: the full matrix of primary values used. For a single
%     direction, this consists of the background primary vector and the two
%     differential primary vectors
%   - waveformMatrix: matrix defining temporal waveforms for each primary
%     vector, one row per vector.
%
% OLAssembleModulation can assemble this from a directionStruct and a a
% single waveform, where negative values in the waveform are applied to the
% negative differential primary vector, and positive values in the waveform
% are applied to the positive differential primary vector.
modulationStruct = OLAssembleModulation(directionStruct,waveform,calibration);

%% Package trial for DemoEngine
% The Psychophysics engine (or at least this demo version) expects
% information to be packaged in a certain way, so thats what we do here.
trialList = struct([]);

trial.name = 'MaxMel_sinusoid_5s';
trial.modulationStarts = modulationStruct.starts;
trial.modulationStops = modulationStruct.stops;
[trial.backgroundStarts, trial.backgroundStops] = OLPrimaryToStartsStops(directionStruct.backgroundPrimary, calibration); 
trial.timestep = timestep;
trial.adaptTime = 1;
trial.repeats = 1;

trialList = [trialList, trial];

%% Close radiometer
% We don't need the radiometer for now, so let's make sure we close it
% properly. This allows the user to unhook the eyepiece from the
% radiometer, and set it up for viewing.
if ~protocolParams.simulate.radiometer
    shutDown(radiometer);
    oneLight.setAll(false);
    commandwindow;
    input(sprintf('<strong>Unhook the eyepiece from the radiometer and set up for viewing. Press enter to pause %d seconds and start experiment.</strong>\n', radiometerPauseDuration));
    pause(radiometerPauseDuration);
end
clear radiometer;

%% Run demo trial
% Call the DemoEngine to execute our trials
DemoEngine(trialList,oneLight,'speakRate',getpref(protocolParams.approach, 'SpeakRateDefault'));

%% Validate direction corrected primaries post experiment
% We often want to validate our directions after the experiment as well, so
% that we know that we had the correct SPDs throughout.

% Setup radiometer
if ~protocolParams.simulate.radiometer
    radiometerPauseDuration = 0;
    oneLight.setAll(true);
    commandwindow;
    input(sprintf('<strong>Focus the radiometer and press enter to pause %d seconds and start measuring.</strong>\n', radiometerPauseDuration));
    oneLight.setAll(false);
    pause(radiometerPauseDuration);
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end

% Validate direction corrected primaries post experiment
directionStruct.describe.validationPost = OLValidateDirection(directionStruct, calibration, oneLight, radiometer);

% Close radiometer
if ~protocolParams.simulate.radiometer
    shutDown(radiometer);
end
clear radiometer;