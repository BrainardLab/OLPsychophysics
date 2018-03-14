function protocolNames = DefineProtocolNames()
% Defines the protocol used by this approach
%
% This gets called by OLApproach_PsychophysicsLocalHook to set up the
% preferences for datapaths.
protocolNames = { ...
    'Demo' ...
    'MaxMelPulsePsychophysics' ...
    };

end