function mrSetFigLoc(figname,pos)
%
% mrSetFigLoc(figname,[pos])
%
% Sets a field in the global variable mrDEFAULTS.figloc, which is a
% structure with fields for each figure name.
%
% figname is a string that specifies each type of figure window
% pos is a 4-vector specifying lowerleft corner and size
%     default: [100 100 560 420]
%
% Examples:
%   mrSetFigLoc('mrLoadRetGUI',[100 100 560 420]);
%
% djh, 5/2007

global mrDEFAULTS

if ieNotDefined('pos')
    pos = [100 100 560 420];
end

mrDEFAULTS.figloc = setfield(mrDEFAULTS.figloc,figname,pos);