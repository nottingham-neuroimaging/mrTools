function data = getMetaData(v,params,mod,meta)
%      usage: data = getMetaData(vargin)
%         by: Ben Gurer
%       date: Feb 23, 2017
%     inputs: varargin - per evalargs convention...
%
%    outputs: o - an overlay
%    purpose: a function to get user defined and stimulus specific meta
%    data for pRF.m
switch mod
    case'vision'
        overlaySpec = {
            {'name','r2'}, ...
            {'name','polarAngle','range',[-pi pi],'clip',[-pi pi], 'colormapType', 'normal', 'colormap' ,hsv(256)}, ...
            {'name','eccentricity','range',[0 15],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,copper(256)}, ...
            {'name','rfHalfWidth','range',[0 15],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,pink(256)}, ...
            };
        switch meta
            case'overlayNames'
                data = cell(1,numel(overlaySpec));
                for i =1:numel(overlaySpec)
                    data{i} = overlaySpec{i}{2};
                end
            case'theOverlays'
                data = cell(1,numel(overlaySpec));
                for iOverlay = 1:numel(overlaySpec)
                    data{iOverlay} = initializeOverlay(v,params, overlaySpec{iOverlay}{:});
                end
        end
        
    case'somato'
        % somato - e.g.
        overlaySpec = {
            {'name','r2'}, ...
            {'name','prefDigit','range',[0 6.28],'clip',[ 0 6.28], 'colormapType', 'normal', 'colormap' ,hsv(256)}, ...
            {'name','prefPD','range',[0 6.28],'clip',[0 6.28], 'colormapType', 'normal', 'colormap' ,hsv(256)}, ...
            {'name','rfHalfWidth','range',[0 50],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,pink(256)}, ...
            };
        
        switch meta
            case'overlayNames'
                data = cell(1,numel(overlaySpec));
                for i =1:numel(overlaySpec)
                    data{i} = overlaySpec{i}{2};
                end
            case'theOverlays'
                data = cell(1,numel(overlaySpec));
                for iOverlay = 1:numel(overlaySpec)
                    data{iOverlay} = initializeOverlay(v,params, overlaySpec{iOverlay}{:});
                end
        end
        
    case'auditory'
        % % auditory - e.g.
        % overlaySpec = {
        %     {'name','r2'}, ...
        %     {'name','pcf','range',[0.02 20],'clip',[0.02 20], 'colormapType', 'normal', 'colormap' ,jet(256)}, ...
        %     {'name','ptw','range',[0.02 20],'clip',[0.02 20], 'colormapType', 'normal', 'colormap' ,jet(256)} ...
        % }
        
end
end