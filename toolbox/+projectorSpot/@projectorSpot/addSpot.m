function addSpot(obj,varargin)
% Add central white spot and black annulus to a GLWindow
%
% Syntax:
%   projectorWindow = projectSpot;
%
% Description:
%
%
% Inputs:
%    projectorSpot - 
% 
% Outputs:
%    None.             projectorWindow now has objects defining a white
%                      (RGB: [1 1 1]) field, a black (RGB: [0 0 0])
%                      annulus, and a white central spot.
%
% Optional key/value arguments:
%    None.
%
% See also:
%    GLWindow, makeProjectorSpot, toggleProjectorSpot

% History:
%    07/16/18  jv  wrote addProjectorSpot;
%    09/01/18  jv  turn into projectorSpot.addSpot method.        


%% Parse input
parser = inputParser;
parser.addRequired('obj');

% Colors
parser.addParameter('backgroundRGB',[0 0 0],@isnumeric);
parser.addParameter('annulusRGB',[0 0 0],@isnumeric);
parser.addParameter('fieldRGB',[1 1 1],@isnumeric);
parser.addParameter('spotRGB',[1 1 1],@isnumeric);

% Sizes
parser.addParameter('spotDiameter',160,@isnumeric);
parser.addParameter('annulusDiameter',530,@isnumeric);
parser.addParameter('centerPosition',[0 0],@isnumeric);

parser.parse(obj, varargin{:});

%% Set params
% Find parameters for which we're not using the defaults:
overwrites = setdiff(parser.Parameters,['obj',parser.UsingDefaults]);

% Assign to obj.properties
for p = overwrites
    obj.(p{:}) = parser.Results.(p{:});
end

%% Create child-elements
annulus = projectorSpot.circle('RGB',obj.annulusRGB,...
                               'center',obj.centerPosition,...
                               'diameter',obj.annulusDiameter,...
                               'name','annulus');
spot = projectorSpot.circle('RGB',obj.spotRGB,...
                            'center',obj.centerPosition,...
                            'diameter',obj.spotDiameter,...
                            'name','spot');    
obj.children = {annulus};%, spot};

%% Get GLWindow
projectorWindow = obj.projectorWindow;

%% Add objects
projectorWindow.addRectangle(obj.centerPosition, projectorWindow.SceneDimensions, obj.fieldRGB);
annulus.add(projectorWindow);
spot.add(projectorWindow);
end