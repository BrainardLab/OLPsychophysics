function [validationsPre, corrections, validationsPost, directions] = testMeLMSens_SteadyAdapt
%% Test MeLMSens_SteadyAdapt protocol
approach = 'OLApproach_Psychophysics';
protocol = 'MeLMSens';
simulate = getpref(approach,'simulate'); % localhook defines what devices to simulate

%% Get calibration
% Specify which box and calibration to use, check that everything is set up
% correctly, and retrieve the calibration structure.
boxName = 'BoxB';
calibrationType = 'BoxBRandomizedShortCableAEyePiece3Beamsplitter';
calibration = OLGetCalibrationStructure('CalibrationType',calibrationType,'CalibrationDate','latest');

%% Open the OneLight
% Open up a OneLight device
oneLight = OneLight('simulate',simulate.oneLight); drawnow;

%% Get radiometer
% Open up a radiometer, which we will need later on.
if ~simulate.radiometer
    radiometer = OLOpenSpectroRadiometerObj('PR-670');
else
    radiometer = [];
end

%% Get projectorSpot
pSpot = projectorSpotMeLMSens_SteadyAdapt(simulate.projector);

%% Update OLCalibration with pSpot
pSpotMeasurements = projectorSpot.measure(pSpot,oneLight,radiometer);
[calibration, pSpotSPD, pSpotLum] = projectorSpot.UpdateOLCalibrationWithProjectorSpot(calibration, pSpotMeasurements);

%% Make directions
directions = makeNominalMeLMSens_SteadyAdapt(calibration,'observerAge',32);
receptors = directions('MelStep').describe.directionParams.T_receptors;

%% Test directions
t = testDirections;
t.directions = directions;
t.receptors = receptors;
results = run(t);

%% Validate directions pre-correction
validationsPre = validateMeLMSens_SteadyAdapt(directions,oneLight,radiometer,...
                                                'receptors',receptors,...
                                                'primaryTolerance',1e-4,...
                                                'nValidations',5);
                                            
%% Correct directions
corrections = correctMeLMSens_SteadyAdapt(directions,oneLight,calibration,radiometer,...
                            receptors,...
                            'primaryTolerance',1e-5,...
                            'smoothness',.001);
                        
%% Validate directions post-correction
validationsPost = validateMeLMSens_SteadyAdapt(directions,oneLight,radiometer,...
                                                'receptors',receptors,...
                                                'primaryTolerance',1e-5,...
                                                'nValidations',5);                                           
                                            
%% Compare validations

%% Setup acquisitions
acquisitions = makeAcquisitionsMeLMSens_SteadyAdapt(directions, receptors,...
                'adaptationDuration',seconds(10),...
                'NTrialsPerStaircase',1);

%% Set trial response system
trialKeyBindings = containers.Map();
trialKeyBindings('ESCAPE') = 'abort';
trialKeyBindings('Q') = [1 0];
trialKeyBindings('P') = [0 1];

if ~simulate.gamepad
    gamePad = GamePad();
    trialKeyBindings('GP:B') = 'abort';
    trialKeyBindings('GP:UPPERLEFTTRIGGER') = [1 0];
    trialKeyBindings('GP:UPPERRIGHTTRIGGER') = [0 1];    
    trialKeyBindings('GP:LOWERLEFTTRIGGER') = [1 0];
    trialKeyBindings('GP:LOWERRIGHTTRIGGER') = [0 1];
else
    gamePad = [];
end
trialResponseSys = responseSystem(trialKeyBindings,gamePad);

%% Adjust projectorSpot
projectorSpot.adjust(pSpot,gamePad);

%% Run
pSpot.show();
for acquisition = acquisitions
    fprintf('Running acquisition %s...\n',acquisition.name)
    acquisition.initializeStaircases();
    acquisition.runAcquisition(oneLight, trialResponseSys);
    fprintf('Acquisition complete.\n'); Speak('Acquisition complete.',[],230);
end

%% Close connections
fprintf('Closing devices...');
oneLight.close;
radiometer.shutDown;
gamePad.shutDown;
fprintf('done.\n');
end