% pRF.m
%
%        $Id:$ 
%      usage: pRF(v,params,varargin)
%         by: justin gardner
%       date: 11/20/11
%    purpose: compute pRF analysis on MLR data
%
%             if you just want a default parameter structure you
%             can do:
% 
%             v = newView;
%             [v params] = pRF(v,[],'justGetParams=1','defaultParams=1','scanList=1')
%
%             Note that justGetParams,defualtParams and scanList are independent parameters, so
%             if you want, say to bring up the GUI to set the params, but not run the analysis, you
%             can do:
%             [v params] = pRF(v,[],'justGetParams=1');
%
function [v d] = pRF(v,params,varargin)

% check arguments
if nargin < 1
  help pRF
  return
end

d = [];
% a version number in case we make major changes
pRFVersion = 1;

% params defaults to empty
if nargin < 2,params =[];end

% other arguments
justGetParams=[];defaultParams=[];scanList=[];
groupNum=[];
getArgs(varargin,{'justGetParams=0','defaultParams=0','scanList=[]','groupNum=[]',  'hrfprf=[]'});

% first get parameters
if isempty(params)
  % get group
  if isempty(groupNum),groupNum = viewGet(v,'curGroup');end
  % put up the gui
  params = pRFGUI('v',v,'groupNum',groupNum,'defaultParams',defaultParams,'scanList',scanList);
end

% just return parameters
if justGetParams,d = params;return,end

% Reconcile params with current status of group and ensure that it has
% the required fields. 
params = defaultReconcileParams([],params);

% Abort if params empty
if isempty(params),return,end

% check the params
params = checkPRFparams(params);

% set the group
v = viewSet(v,'curGroup',params.groupName);

% create the parameters for the polarAngle overlay

mod = 'vision'; % this variable should be set in the GUI - the user can choose the stimulus / modality

overlayNames = getMetaData(v,params,mod,'overlayNames');

theOverlays = getMetaData(v,params,mod,'theOverlays');

% overlaySpec = {
%     {'name','r2'}, ...
%     {'name','polarAngle','range',[-pi pi],'clip',[-pi pi], 'colormapType', 'normal', 'colormap' ,hsv(256)}, ...
%     {'name','eccentricity','range',[0 15],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,copper(256)}, ...
%     {'name','rfHalfWidth','range',[0 15],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,pink(256)}, ...
% };
% 
% % somato - e.g.
% overlaySpec = {
%     {'name','r2'}, ...
%     {'name','prefDigit','range',[0 6],'clip',[ 0 6], 'colormapType', 'normal', 'colormap' ,hsv(256)}, ...
%     {'name','prefPD','range',[0 15],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,copper(256)}, ...
%     {'name','rfHalfWidth','range',[0 15],'clip',[0 inf], 'colormapType', 'normal', 'colormap' ,pink(256)}, ...
% }
% 
% % auditory - e.g.
% overlaySpec = {
%     {'name','r2'}, ...
%     {'name','pcf','range',[0.02 20],'clip',[0.02 20], 'colormapType', 'normal', 'colormap' ,jet(256)}, ...
%     {'name','ptw','range',[0.02 20],'clip',[0.02 20], 'colormapType', 'normal', 'colormap' ,jet(256)} ...
% }

% create the parameters for the r2 overlay
% theOverlays = {};
% 
% for iOverlay = 1:numel(overlaySpec)
%     theOverlays{iOverlay} = initializeOverlay(v,params, overlaySpec{iOverlay}{1:2});
%     % reality check (which doesn't work!)
%     % assert(isoverlay(theOverlays{iOverlay}),'oops - looks like a non-overlay was created')
% end

% r2 = initializeOverlay(v, params, 'name=r2'); % by default go with r2. 

% - at this point we can two ways:

% 1- make variables (structs from the cell array that contains all the info
% UNPACK
%
% 2- make changes further down the line to deal with the fact that all
% overlays are stuck together in a cell array 
% NOT UNPACK until last minute

% keyboard

% 
% % polarAngle = initializeOverlay(v, params, 'name=polarAngle','range=[-pi pi]', 
% polarAngle = r2;
% polarAngle.name = 'polarAngle';
% polarAngle.range = [-pi pi];
% polarAngle.clip = [-pi pi];
% polarAngle.colormapType = 'normal';
% polarAngle.colormap = hsv(256);
% 
% % create the parameters for the eccentricity overlay
% eccentricity = r2;
% eccentricity.name = 'eccentricity';
% eccentricity.range = [0 15];
% eccentricity.clip = [0 inf];
% eccentricity.colormapType = 'normal';
% eccentricity.colormap = copper(256);
% 
% % create the paramteres for the rfHalfWidth overlay
% rfHalfWidth = r2;
% rfHalfWidth.name = 'rfHalfWidth';
% rfHalfWidth.range = [0 15];
% rfHalfWidth.clip = [0 inf];
% rfHalfWidth.colormapType = 'normal';
% rfHalfWidth.colormap = pink(256);

% get number of workers 
nProcessors = mlrNumWorkers;

% code snippet for clearing precomputed prefit
%global gpRFFitStimImage;gpRFFitStimImage = [];

dispHeader
disp(sprintf('(pRF) Running on scans %s:%s (restrict %s)',params.groupName,num2str(params.scanNum,'%i '),params.restrict ));

for scanNum = params.scanNum
  % see how long it took
  tic;
  
  % get voxels that we are restricted to
  [x y z] = getVoxelRestriction(v,params,scanNum);
  if isempty(x)
    disp(sprintf('(pRF) No voxels to analyze with current restriction'));
    return
  end

  % get total number of voxels
  n = length(x);

  % get scan dims
  scanDims = viewGet(v,'scanDims',scanNum);
  
  % init overlays  
  for iOverlay = 1:numel(overlayNames)
%       theOverlays{iOverlay}.overlayNames{iOverlay}.data{scanNum} = nan(scanDims);
      theOverlays{iOverlay}.data{scanNum} = nan(scanDims);
  end

%   r2.data{scanNum} = nan(scanDims);
%   polarAngle.data{scanNum} = nan(scanDims);
%   eccentricity.data{scanNum} = nan(scanDims);
%   rfHalfWidth.data{scanNum} = nan(scanDims);

  % default all variables that will be returned
  % by pRFFIt, so that we can call it the
  % second time and save some time
  concatInfo = [];
  stim = [];
  
  % save pRF parameters
  pRFAnal.d{scanNum}.ver = pRFVersion;
  pRFAnal.d{scanNum}.linearCoords = [];
  pRFAnal.d{scanNum}.params = [];

  % get some information from pRFFit that will be used again in
  % the fits, including concatInfo, stim, prefit, etc.
  fit = pRFFit(v,scanNum,[],[],[],'fitTypeParams',params.pRFFit,'returnPrefit',true);
  if isempty(fit),return,end
  stim = fit.stim;
  pRFAnal.d{scanNum}.stim = cellArray(stim);
  pRFAnal.d{scanNum}.stimX = fit.stimX;
  pRFAnal.d{scanNum}.stimY = fit.stimY;
  pRFAnal.d{scanNum}.stimT = fit.stimT;
  concatInfo = fit.concatInfo;
  pRFAnal.d{scanNum}.concatInfo = fit.concatInfo;
  prefit = fit.prefit;
  paramsInfo = fit.paramsInfo;
  pRFAnal.d{scanNum}.paramsInfo = paramsInfo;
  % grab all these fields and stick them onto a structure called paramsInfo
  % preallocate some space
  rawParams = nan(fit.nParams,n);
  r = nan(n,fit.concatInfo.n);
  thisr2 = nan(1,n);
  thisRawParamsCoords = nan(3,n);

  
%   thisData = cell(1,numel(overlaySpec));
%   for iOverlay = 1:numel(overlaySpec)
%       thisData{iOverlay}{1} = ['this' overlaySpec{iOverlay}{2}];
%       thisData{iOverlay}{2} = nan(1,n);
%   end
  thisData = nan(numel(overlayNames),n);

%   thisr2 = nan(1,n);
%   thisPolarAngle = nan(1,n);
%   thisEccentricity = nan(1,n);
%   thisRfHalfWidth = nan(1,n);

  % get some info about the scan to pass in (which prevents
  % pRFFit from calling viewGet - which is problematic for distributed computing
  framePeriod = viewGet(v,'framePeriod');
  junkFrames = viewGet(v,'junkFrames',scanNum);

  % compute pRF for each voxel in the restriction
  if params.pRFFit.prefitOnly,algorithm='prefit-only';else,algorithm=params.pRFFit.algorithm;end

  % disp info about fitting
  dispHeader;
  disp(sprintf('(pRF) Scan %s:%i (restrict %s) running on %i processor(s)',params.groupName,scanNum,params.restrict,nProcessors));
  disp(sprintf('(pRF) Computing %s fits using %s for %i voxels',params.pRFFit.rfType,algorithm,n));
  dispHeader;

  % this is a bit arbitrary but is the number of voxels to read in at a time.
  % should probably be either calculated based on memory demands or a
  % user settings. The bigger the number the less overhead and will run faster
  % but consume more memory. The overhead is not terribly significant though
  % as tested on my machine - maybe a few percent faster with full n, but
  % on many machines without enough memory that will crash it so keeping
  % this preliminary value in for now.
  % blockSize = 240;
  blockSize = n;
  tic;
  % break into blocks of voxels to go easy on memory
  % if blockSize = n then this just does on block at a time.
  for blockStart = 1:blockSize:n

    % display information about what we are doing
    % get blockEnd
    blockEnd = min(blockStart + blockSize-1,n);
    blockSize = blockEnd-blockStart+1;
    
    % load ROI
    loadROI = makeEmptyROI(v,'scanNum',scanNum,'groupNum',params.groupName);
    loadROI.coords(1,1:blockSize) = x(blockStart:blockEnd);
    loadROI.coords(2,1:blockSize) = y(blockStart:blockEnd);
    loadROI.coords(3,1:blockSize) = z(blockStart:blockEnd);
    % load all time series for block, we do this to pass into pRFFit. Generally
    % the purpose here is that if we run on distributed computing, we
    % can't load each voxel's time series one at a time. If this is
    % too large for memory then you can comment this out and not
    % pass it into pRFFit and pRFFit will load the tSeries itself
    loadROI = loadROITSeries(v,loadROI,scanNum,params.groupName);
    % reorder x,y,z coordinates since they can get scrambled in loadROITSeries
    
    % testing!!!!

    
%     blockEnd = size(thehrfs.r,2);
%     blockSize = blockEnd;
%     n = blockEnd;
   
    
    % hack to stop nans
    blockEnd = size(loadROI.scanCoords,2); % HACK TO STOP NANS
    blockSize = blockEnd;
    n = blockEnd;
    
    x(blockStart:blockEnd) = loadROI.scanCoords(1,1:blockSize);
    y(blockStart:blockEnd) = loadROI.scanCoords(2,1:blockSize);
    z(blockStart:blockEnd) = loadROI.scanCoords(3,1:blockSize);
    % keep the linear coords
    pRFAnal.d{scanNum}.linearCoords = [pRFAnal.d{scanNum}.linearCoords sub2ind(scanDims,x(blockStart:blockEnd),y(blockStart:blockEnd),z(blockStart:blockEnd))];

    if blockStart ~= 1
      % display time update
      dispHeader(sprintf('(pRF) %0.1f%% done in %s (Estimated time remaining: %s)',100*blockStart/n,mlrDispElapsedTime(toc),mlrDispElapsedTime((toc*n/blockStart) - toc)));
    end
    
    % adding some code here to use pre-fitted params
%      keyboard
%      inp = input('Give me some hrf params', 's');
%      myVar = eval(inp);
     %thehrfs = load('rh_5s_gethrf_cothr.mat');
     thehrfs = load('wiener_deconv_prfhrfRefit.mat');
     myVar = thehrfs.hrf_struct.yf;
     
    %thehrfs = load('deconv1s_new.mat');
    %thehrfs = load('decah.mat');
    %myVar = thehrfs.r;
    %thehrfs.idx = thehrfs.idx(1:blockEnd); 
    % now loop over each voxel
    %tempStart = 1;
      
  % save the pRF's dodgy hrfs
    prfHRFudge = 13;
    myrawHrfs = nan(prfHRFudge, n);
    
    %warning('off', 'MATLAB:rankDeficientMatrix');
    parfor ii = blockStart:blockEnd
        
        myVoxel = find(thehrfs.hrf_struct.volumeIndices == sub2ind(scanDims,x(ii),y(ii),z(ii)));
        
        
        %myVoxel = find(thehrfs.idx == sub2ind(scanDims,x(ii),y(ii),z(ii)));
%         
        if isempty(myVoxel)
            fprintf('\ncaught an empty, x %d y %d z %d, idx %f\n', x(ii), y(ii), z(ii), myVoxel);
            
            fit = [];
        elseif myVoxel > length(thehrfs.hrf_struct.yf)
            disp('caught one')
            fit = [];
        else
            
            
            %fit = pRFFit(v,scanNum,x(ii),y(ii),z(ii),'stim',stim,'concatInfo',concatInfo,'prefit',prefit,'fitTypeParams',params.pRFFit,'dispIndex',ii,'dispN',n,'tSeries',loadROI.tSeries(ii-blockStart+1,:)','framePeriod',framePeriod,'junkFrames',junkFrames,'paramsInfo',paramsInfo);
            fit = pRFFit(v,scanNum,x(ii),y(ii),z(ii),'stim',stim,'concatInfo',concatInfo,'prefit',prefit,'fitTypeParams',params.pRFFit,'dispIndex',ii,'dispN',n,'tSeries',loadROI.tSeries(ii-blockStart+1,:)','framePeriod',framePeriod,'junkFrames',junkFrames,'paramsInfo',paramsInfo, 'hrfprf', myVar(:,myVoxel));
            
        end
        
        if ~isempty(fit)
            % keep data, note that we are keeping temporarily in
            % a vector here so that parfor won't complain
            % then afterwords we put it into the actual overlay struct
            % 	thisr2(i) = fit.r2;
            % 	thisPolarAngle(i) = fit.polarAngle;
            % 	thisEccentricity(i) = fit.eccentricity;
            % 	thisRfHalfWidth(i) = fit.std;
            
            % parfor can't classify thisData, because it doesn't do order
            % very well...
            % so let's make a tempVar which is overwritten each time, then
            % save this into thisData outside the nested forloop - Jim
            
            tempVar = zeros(length(overlayNames),1);
            
            for iOverlay = 1:numel(overlayNames)

                % eval doesn't work when using parfor!!! 
                %eval(sprintf('thisData(%d,%d) = fit.%s;',iOverlay,i,overlayNames{iOverlay}));
                
                % this gets around using eval
                % but leads to other parallel processing issues...
                test = strcmpi(fieldnames(fit), overlayNames(iOverlay) );
                %pos = find(test==1);
                bla = struct2cell(fit);
                val = cell2mat(bla(test==1));
                
                % this is temporary, gets overwritten each time
                tempVar(iOverlay,1) = val;
              
                
                %thisData(iOverlay, ii) = val;
            end
            % now put the values for this voxel into some sort of order :)
            thisData(:,ii) = tempVar;
            
            % keep parameters
            rawParams(:,ii) = fit.params(:);
            r(ii,:) = fit.r;
            thisr2(ii) = fit.r2;
            thisRawParamsCoords(:,ii) = [x(ii) y(ii) z(ii)];
            %myrawHrfs(:,ii) = fit.myhrf.hrf; %save out prfs hrfs
        end
    end
    
    % set overlays
    for ii = 1:n
        %       r2.data{scanNum}(x(i),y(i),z(i)) = thisr2(i);
        %       polarAngle.data{scanNum}(x(i),y(i),z(i)) = thisPolarAngle(i);
        %       eccentricity.data{scanNum}(x(i),y(i),z(i)) = thisEccentricity(i);
        %       rfHalfWidth.data{scanNum}(x(i),y(i),z(i)) = thisRfHalfWidth(i);
%         ff = cell2struct(overlaySpec, 'usefulInfo', length(overlaySpec));
        for iOverlay = 1:length(overlayNames)                     
            theOverlays{iOverlay}.data{scanNum}(x(ii),y(ii),z(ii)) = thisData(iOverlay,ii);
        end
    end
  end
  % display time update
  dispHeader;
  disp(sprintf('(pRF) Fitting %i voxels took %s.',n,mlrDispElapsedTime(toc)));
  dispHeader;
  
  pRFAnal.d{scanNum}.params = rawParams;
  pRFAnal.d{scanNum}.r = r;
  pRFAnal.d{scanNum}.r2 = thisr2;
  pRFAnal.d{scanNum}.rawCoords = thisRawParamsCoords;
  %pRFAnal.d{scanNum}.myrawHrfs = myrawHrfs; % save out prfs hrfs

  iScan = find(params.scanNum == scanNum);
  thisParams.scanNum = params.scanNum(iScan);
  for iOverlay = 1:length(overlayNames)
      theOverlays{iOverlay}.params{scanNum} = thisParams;
  end  
%   r2.params{scanNum} = thisParams;
%   polarAngle.params{scanNum} = thisParams;
%   eccentricity.params{scanNum} = thisParams;
%   rfHalfWidth.params{scanNum} = thisParams; 

  % display how long it took
  disp(sprintf('(pRF) Fitting for %s:%i took in total: %s',params.groupName,scanNum,mlrDispElapsedTime(toc)));
end

% install analysis
pRFAnal.name = params.saveName;
pRFAnal.type = 'pRFAnal';
pRFAnal.groupName = params.groupName;
pRFAnal.function = 'pRF';
pRFAnal.reconcileFunction = 'defaultReconcileParams';
pRFAnal.mergeFunction = 'pRFMergeParams';
pRFAnal.guiFunction = 'pRFGUI';
pRFAnal.params = params;
pRFAnal.overlays = [];
for iOverlay = 1:numel(theOverlays)
    eval(sprintf('%s = struct(theOverlays{iOverlay});',overlayNames{iOverlay}));    
    eval(sprintf('pRFAnal.overlays = [pRFAnal.overlays %s];',overlayNames{iOverlay}));
end
%pRFAnal.overlays = [r2 polarAngle eccentricity rfHalfWidth];
% pRFAnal.overlays = ff;


pRFAnal.curOverlay = 1;
pRFAnal.date = date;
v = viewSet(v,'newAnalysis',pRFAnal);

% if we are going to merge, temporarily set overwritePolicy
if isfield(params,'mergeAnalysis') && params.mergeAnalysis
  saveMethod = mrGetPref('overwritePolicy');
  mrSetPref('overwritePolicy','Merge');
end
% Save it
saveAnalysis(v,pRFAnal.name);
% now set policy back
if isfield(params,'mergeAnalysis') && params.mergeAnalysis
  mrSetPref('overwritePolicy',saveMethod);
end

if ~isempty(viewGet(v,'fignum'))
  refreshMLRDisplay(viewGet(v,'viewNum'));
end

%set(viewGet(v,'figNum'),'Pointer','arrow');drawnow

% for output
if nargout > 1
  for ii = 1:length(d)
    pRFAnal.d{ii}.r2 = r2.data{ii};
  end
  % make d strucutre
  if length(pRFAnal.d) == 1
    d = pRFAnal.d{1};
  else
    d = pRFAnal.d;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    getVoxelRestriction    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x y z] = getVoxelRestriction(v,params,scanNum)

x = [];y = [];z = [];

if strncmp(params.restrict,'Base: ',6)
  % get the base name
  baseName = params.restrict(7:end);
  baseNums = [];
  if strcmp(baseName,'ALL')
    for iBase = 1:viewGet(v,'numBase')
      % if the base is a surface or flat then add to the list
      if any(viewGet(v,'baseType',iBase) == [1 2])
	baseNums(end+1) = iBase;
      end
    end
  else
    baseNums = viewGet(v,'baseNum',baseName);
  end
  % cycle through all bases that we are going to run on
  scanCoords = [];
  for iBase = 1:length(baseNums)
    % get the baseNum
    baseNum = baseNums(iBase);
    if isempty(baseNum)
      disp(sprintf('(pRF) Could not find base to restrict to: %s',params.restrict));
      continue
    end
    % get the base
    base = viewGet(v,'base',baseNum);
    if isempty(base)
      disp(sprintf('(pRF) Could not find base to restrict to: %s',params.restrict));
      return;
    end
    % if flat or surface
    if any(base.type == [1 2])
      % get base coordinates from the coordMap
      for corticalDepth = 0:0.1:1
	if base.type == 1
	  % flat map
	  baseCoords = (base.coordMap.innerCoords + corticalDepth * (base.coordMap.outerCoords-base.coordMap.innerCoords));
	  baseCoords = reshape(baseCoords,prod(size(base.data)),3)';
	else
	  % surface
	  baseCoords = (base.coordMap.innerVtcs + corticalDepth * (base.coordMap.outerVtcs-base.coordMap.innerVtcs))';
	end
	% convert to 4xn array
	baseCoords(4,:) = 1;
	% and convert to scan coordinates
	base2scan = viewGet(v,'base2scan',scanNum,params.groupName,baseNum);
	scanCoords = [scanCoords round(base2scan*baseCoords)];
      end
    end
  end
  % check against scandims
  scanDims = viewGet(v,'scanDims',scanNum,params.groupName);
  scanCoords = mrSub2ind(scanDims,scanCoords(1,:),scanCoords(2,:),scanCoords(3,:));
  % remove duplicates and nans
  scanCoords = scanCoords(~isnan(scanCoords));
  scanCoords = unique(scanCoords);
  % convert back to x,y,z coordinates
  [x y z] = ind2sub(scanDims,scanCoords);
elseif strncmp(params.restrict,'ROI: ',5)
  % get the roi name
  roiName = params.restrict(6:end);
  scanCoords = getROICoordinates(v,roiName,scanNum,params.groupName,'straightXform=1');
  if isempty(scanCoords),return,end
  x = scanCoords(1,:);y = scanCoords(2,:);z = scanCoords(3,:);
elseif strncmp(params.restrict,'None',4)
  scanDims = viewGet(v,'scanDims',scanNum,params.groupName);
  [x y z]  = ndgrid(1:scanDims(1),1:scanDims(2),1:scanDims(3));
  x = x(:);y = y(:);z = z(:);
else
  keyboard
end

%check if we have already computed Voxels
if isfield(params,'computedVoxels') && (length(params.computedVoxels)>=scanNum) && ~isempty(params.computedVoxels{scanNum})
  % get scan dims
  scanDims = viewGet(v,'scanDims',scanNum,params.groupName);
  % convert x, y, z to linear coords
  linearCoords = sub2ind(scanDims,x,y,z);
  % get new ones
  newLinearCoords = setdiff(linearCoords,params.computedVoxels{scanNum});
  if length(newLinearCoords) ~= length(linearCoords)
    % show what we are doing
    disp(sprintf('(pRF) Dropping %i voxels that have been already computed',length(linearCoords)-length(newLinearCoords)));
    % convert back to x, y, z
    [x y z] = ind2sub(scanDims,newLinearCoords);
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%
%    checkPRFparams    %
%%%%%%%%%%%%%%%%%%%%%%%%
function params = checkPRFparams(params)


% check the pRFFit params
checkFields = {{'stimImageDiffTolerance',5}};
for iFit = 1:length(params.pRFFit)

  % set defaults
  for iField = 1:length(checkFields)
    if ~isfield(params.pRFFit(iFit),checkFields{iField}{1})
      params.pRFFit(iFit).(checkFields{iField}{1}) = checkFields{iField}{2};
    end
  end
end

