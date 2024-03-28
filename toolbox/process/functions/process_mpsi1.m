function varargout = process_mPSI1( varargin )

% PROCESS_MPSI1: Compute the multivariate Phase Slope Index between one signal and all the others, in one file.
%
% @=============================================================================
% Copyright (C) 2020-2022 - Methods and Models for Brain Oscillations
% (MAMBO) group, Dept. of Neuroscience, Imaging and Clinical Sciences, 
% G. d'Annunzio University Chieti-Pescara 
%
% You can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% The code is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% (<http://www.gnu.org/licenses/>)
% Comments, bug reports, etc are welcome.
% =============================================================================@
%
% Authors:  Alessio Basti (alessio.basti@unich.it)
%           Roberto Guidotti (r.guidotti@unich.it)
%           Giulia Pieramico (giulia.pieramico@unich.it)
%           Laura Marzetti (laura.marzetti@unich.it)
%           Vittorio Pizzella (vittorio.pizzella@unich.it) 
%
eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() 
    % Description the process
    sProcess.Comment     = 'Multivariate connectivity 1xN';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Connectivity';
    % sProcess.IsSeparator = 1; FIXME
    sProcess.Index       = 1000;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'results'};
    sProcess.OutputTypes = {'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % === CONNECT INPUT
    sProcess = process_corr1n('DefineConnectOptions', sProcess, 1);

    % === UNCONSTRAINED SOURCES ===
    sProcess.options.reduction.Comment    = 'Number of PCs to use';
    sProcess.options.reduction.Type       = 'value';
    sProcess.options.reduction.Group      = 'input';
    sProcess.options.reduction.Value      = {3, ' ', 0};

    % === UNCONSTRAINED SOURCES ===
    sProcess.options.segleng.Comment    = 'Segment Lenght (0=full)';
    sProcess.options.segleng.Type       = 'value';
    sProcess.options.segleng.Group      = 'input';
    sProcess.options.segleng.Value      = {0, ' pts.', 0};

    % === UNCONSTRAINED SOURCES ===
    sProcess.options.epleng.Comment    = 'Epoch lenght (0=full)';
    sProcess.options.epleng.Type       = 'value';
    sProcess.options.epleng.Group      = 'input';
    sProcess.options.epleng.Value      = {0, ' pts.', 0};

    % === FREQ BANDS
    sProcess.options.freqbands.Comment = 'Frequency bands for the Hilbert transform:';
    sProcess.options.freqbands.Type    = 'groupbands';
    sProcess.options.freqbands.Value   = bst_get('DefaultFreqBands');
    
    % === KEEP TIME
    sProcess.options.keeptime.Comment = 'Keep time information, and estimate mPSI across trials<BR>(requires the average of many trials)';
    sProcess.options.keeptime.Type    = 'checkbox';
    sProcess.options.keeptime.Value   = 0;  
    
    % === mPSI MEASURE
    sProcess.options.mpsimeasure.Comment = {'MIM', 'MPSI', 'Measure:'};
    sProcess.options.mpsimeasure.Type    = 'radio_line';
    sProcess.options.mpsimeasure.Value   = 2;

    % === OUTPUT MODE
    sProcess.options.outputmode.Comment = {'Save individual results (one file per input file)', 'Concatenate input files before processing (one file)', 'Save average connectivity matrix (one file)'};
    sProcess.options.outputmode.Type    = 'radio';
    sProcess.options.outputmode.Value   = 1;
    sProcess.options.outputmode.Group   = 'output';

    sProcess.options = rmfield(sProcess.options, 'pcaedit');
    sProcess.options = rmfield(sProcess.options, 'flatten');

end

%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) 
    Comment = sProcess.Comment;

    % if isempty(sProcess.options.window_length.Value{1})
    %     Comment = 'Window length: No window length set';
    % else
    %     strValue = sprintf('%1.0fs ', sProcess.options.window_length.Value{1});
    %     Comment = ['Window length: ' strValue(1:end-1)];
    % end
    % 
    % if isempty(sProcess.options.freq_span.Value{1})
    %     Comment = 'Window length: No Frequency band set';
    % else
    %     strValue = sprintf('%1.0fHz ', sProcess.options.window_length.Value{1});
    %     Comment = ['Frequency band: ' strValue(1:end-1)];
    % end

end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputA) 

% Input options common to all connectivity processes
    OPTIONS = process_corr1n('GetConnectOptions', sProcess, sInputA);
    if isempty(OPTIONS)
        OutputFiles = {};
        return
    end

    % Keep time or not: different methods   FIXME
    choice = sProcess.options.mpsimeasure.Value;
    OPTIONS.Method = sProcess.options.mpsimeasure.Comment(choice);
    OPTIONS.Method = char(lower(OPTIONS.Method));
    
    if sProcess.options.keeptime.Value
        % OPTIONS.Method = [OPTIONS.Method 't'];
    end
    
  % Hilbert and frequency bands options
    OPTIONS.Freqs = sProcess.options.freqbands.Value;
    OPTIONS.isMirror = 0;
 
  % mPSI measure
    if isfield(sProcess.options, 'plvmeasure') && isfield(sProcess.options.plvmeasure, 'Value') && ~isempty(sProcess.options.plvmeasure.Value) 
        switch (sProcess.options.plvmeasure.Value)
            case 1,  OPTIONS.PlvMeasure = 'none';
            case 2,  OPTIONS.PlvMeasure = 'magnitude';
        end
    else
        OPTIONS.PlvMeasure = 'magnitude';
    end
    
    % PCA
    if isfield(sProcess.options, 'reduction')
        OPTIONS.ReductionNComponents = sProcess.options.reduction.Value;
    end
        
    
    % Compute metric
    %OutputFiles = Compute(sInputA, sInputA, OPTIONS);
    OutputFiles = bst_connectivity(sInputA, sInputA, OPTIONS);
end


%% ===== COMPUTE =====
function OutputFiles = Compute(DataA, DataB, OPTIONS) 

% ===== INITIALIZATIONS =====
% Copy default options to OPTIONS structure (do not replace defined values)
% OPTIONS = struct_copy_fields(OPTIONS, Def_OPTIONS, 0);   FIXME commentato
% Initialize output variables

OutputFiles = {};
AllComments = {};
Ravg = [];
nAvg = 0;

% Do nothing
% size(DataA)
% size(DataB)
end
