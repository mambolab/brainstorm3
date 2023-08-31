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
% Authors: Alessio Basti (alessio.basti@unich.it)
%               Roberto Guidotti (r.guidotti@unich.it) 
%               Laura Marzetti (laura.marzetti@unich.it)
%               Vittorio Pizzella (vittorio.pizzella@unich.it) 
%
eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() 
    % Description the process
    sProcess.Comment     = 'multivariate Phase Slope Index 1xN';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Connectivity';
    % sProcess.IsSeparator = 1; FIXME
    sProcess.Index       = 1000;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % === CONNECT INPUT
    sProcess = process_corr1n('DefineConnectOptions', sProcess, 0);
    % === FREQ BANDS
    sProcess.options.freqbands.Comment = 'Frequency bands for the Hilbert transform:';
    sProcess.options.freqbands.Type    = 'groupbands';
    sProcess.options.freqbands.Value   = bst_get('DefaultFreqBands');
    % === KEEP TIME
    sProcess.options.keeptime.Comment = 'Keep time information, and estimate mPSI across trials<BR>(requires the average of many trials)';
    sProcess.options.keeptime.Type    = 'checkbox';
    sProcess.options.keeptime.Value   = 0;
    % === mPSI MEASURE
    sProcess.options.mpsimeasure.Comment = {'None (complex)', 'Magnitude', 'Measure:'};
    sProcess.options.mpsimeasure.Type    = 'radio_line';
    sProcess.options.mpsimeasure.Value   = 2;
    % === OUTPUT MODE
    sProcess.options.outputmode.Comment = {'Save individual results (one file per input file)', 'Concatenate input files before processing (one file)', 'Save average connectivity matrix (one file)'};
    sProcess.options.outputmode.Type    = 'radio';
    sProcess.options.outputmode.Value   = 1;
    sProcess.options.outputmode.Group   = 'output';
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
    OPTIONS.Method = sProcess.options.mpsimeasure.Value;
    OPTIONS.Method = 'mpsi';
    
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


%     cross_spectrum = signal1 .* conj(signal2);
% 
%     % Instantaneous phase difference: 
%     dphi    = angle( cross_spectrum );
% 
%     switch cfg.method
% 
%         case 'iplv' 
%             value    = abs(mean( imag(exp(sqrt(-1)*( dphi )))));
%         case 'plv' 
%             value    = abs(mean(exp(sqrt(-1)*( dphi ))));
%         case 'pli'
%             value    = abs(mean( sign(dphi) ));
%         case 'wpli'
%             value    = abs( mean( abs(imag(cross_spectrum )) .*  sign(dphi)  ) ./ mean( abs(imag( cross_spectrum )) ) );
%         case 'imcoh'
%             amplitude1 = abs(signal1);
%             amplitude2 = abs(signal2);
%             value    = imag( mean(cross_spectrum) ./ sqrt(mean(amplitude1.^2) .* mean(amplitude2.^2)));
%         case 'wplideb'
%             imcoh    = imag( cross_spectrum  );
%             numerator = sum(imcoh).^2 - sum(imcoh.^2);
%             denominator = sum(abs(imcoh)).^2 - sum(abs(imcoh).^2);
%             value = sqrt(abs(numerator ./ denominator));
% 
%         otherwise
%             value    = abs(mean( imag(exp(sqrt(-1)*( dphi )))));
