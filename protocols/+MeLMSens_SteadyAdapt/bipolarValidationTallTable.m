function T = bipolarValidationTallTable(validation)
% Summary of this function goes here
%   Detailed explanation goes here
receptorStrings = {'L','M','S','Mel'}';
time = repmat(validation.time(1),[length(receptorStrings),1]);

% contrastDesired = validation.contrastDesired; % desired modulation, not differential, contrast
% contrastDesired = table(time, receptorStrings,round(contrastDesired*100,2),...
%                     'VariableNames',{'time','receptor','desired'}); % convert to table

contrastActual = validation.contrastActual; % measured modulation, not differential, contrast
contrastActual = table(time, receptorStrings, contrastActual,...
                    'VariableNames',{'time','receptor','contrast'});
contrastActual = splitvars(contrastActual, 'contrast','NewVariableNames',{'positive','negative'});
contrastActual = stack(contrastActual,{'positive','negative'},'IndexVariableName','component','NewDataVariableName','contrast');

%T = join(contrastDesired, contrastActual);
T = contrastActual;
T.receptor = categorical(T.receptor);
end