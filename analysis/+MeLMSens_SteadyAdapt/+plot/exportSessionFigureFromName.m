function outputFile = exportSessionFigureFromName(participant, sessionName)
%SESSIONFIGUREFROMNAME Summary of this function goes here
%   Detailed explanation goes here

% History:
%    2019.02.26  jv   copied and adapted for MeLMSens_Pulse. Extracted
%                     plot.export, plot.sessionFigureFromName

% Get figure
fig = MeLMSens_SteadyAdapt.plot.sessionFigureFromName(participant, sessionName);

% Export
sessionPath = MeLMSens_SteadyAdapt.dataManagement.sessionProcessedPathFromName(participant, sessionName);
outputPath = strrep(sessionPath,'raw','processed');
if ~isfolder(outputPath)
    mkdir(outputPath);
end
outputFile = fullfile(outputPath,sprintf('%s_%s.trials.pdf',participant,sessionName));
MeLMSens_SteadyAdapt.plot.export(fig,outputFile);
end