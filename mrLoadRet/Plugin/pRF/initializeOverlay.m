function [ o ] = initializeOverlay(v,params,varargin)
%initializeOverlay - create a overlay struct for use in pRF code
%
%      usage: [ o ] = initializeOverlay(v, params, varargin  )
%         by: lpzds1, Denis Schluppeck
%       date: Feb 13, 2017
%        $Id$
%     inputs: v - a view; params - the params from the GUI, 
%             varargin - per evalargs convention...
%    
%    outputs: o - an overlay
%
%    purpose: create a overlay with some default settings. this takes the
%    hard-coded parts out of pRF code to make it more flexible for other
%    stimulus domains  
%
%        e.g: 

eval(evalargs(varargin))

% by default we want the r2 overlay
if ieNotDefined('name'), name = 'r2'; end % this sets a default name if none was speficified
if ieNotDefined('func'), func = 'pRF'; end
if ieNotDefined('range'), range = [0 1]; end
if ieNotDefined('clip'), clip = [0 1]; end
if ieNotDefined('colormap'), colormap =  hot(312); end
if ieNotDefined('colormapType'), colormapType = 'normal'; end
if ieNotDefined('interrogator'), interrogator = 'myOverlayStats'; end
if ieNotDefined('mergeFunction'), mergeFunction = 'pRFMergeParams'; end


% fill everything else.
dateString = datestr(now);
o.name = name;
o.groupName = params.groupName;
o.function = func;  %% 
o.reconcileFunction = 'defaultReconcileParams';
o.data = cell(1,viewGet(v,'nScans'));
o.date = dateString;
o.params = cell(1,viewGet(v,'nScans'));
o.range = range; %%
o.clip = clip; %%
% colormap is made with a little bit less on the dark end
o.colormap = colormap; %%
o.colormap = o.colormap(end-255:end,:); 
o.alpha = 1;
o.colormapType = colormapType; %%
o.interrogator = interrogator; %% 
o.mergeFunction = mergeFunction; %%

% assert(isoverlay(o),'uhoh = also no good')

end