midiFolder = "/Users/erynngutierrez/Desktop/bttai/mathworks/midis";
midiFiles = dir(fullfile(midiFolder, '*.mid'));

% Limit to 10 files (or less if there are fewer than 10 files)
numFiles = min(10, length(midiFiles));

% Initialize cell arrays to store data from all files
allNoteNumbers = cell(1, numFiles);
allVelocities = cell(1, numFiles);
allDeltatimes = cell(1, numFiles);

% Process each MIDI file
for fileIdx = 1:numFiles
    % Read the MIDI file
    midiData = readmidi(fullfile(midiFolder, midiFiles(fileIdx).name));
    
    % Check if the file has at least 2 tracks
    if length(midiData.track) < 2
        warning('File %s does not have a second track. Skipping.', midiFiles(fileIdx).name);
        continue;
    end
    
    trackMessages = midiData.track(2).messages;
    
    % Extract deltatime, noteNumber, and velocity
    deltatimes = [trackMessages.deltatime]';
    noteNumbers = NaN(length(trackMessages), 1);
    velocities = NaN(length(trackMessages), 1);
    
    for i = 1:length(trackMessages)
        data = trackMessages(i).data;
        if numel(data) >= 2
            noteNumbers(i) = data(1);
            velocities(i) = data(2);
        end
    end
    
    % Store the data for this file
    allNoteNumbers{fileIdx} = noteNumbers;
    allVelocities{fileIdx} = velocities;
    allDeltatimes{fileIdx} = deltatimes;
end

% Combine all data
noteNumbers = vertcat(allNoteNumbers{:});
velocities = vertcat(allVelocities{:});
deltatimes = vertcat(allDeltatimes{:});

% Create a table with deltatime, noteNumber, and velocity columns
oneMidiData = table(deltatimes, noteNumbers, velocities, ...
                    'VariableNames', {'DeltaTime', 'NoteNumber', 'Velocity'});

% Remove rows with NaNs in NoteNumber or Velocity
validRows = ~isnan(oneMidiData.NoteNumber) & ~isnan(oneMidiData.Velocity);
oneMidiData = oneMidiData(validRows, :);

% Normalize NoteNumber and Velocity to [0, 1] range
if ~isempty(oneMidiData)
    noteNumbersNorm = (oneMidiData.NoteNumber - min(oneMidiData.NoteNumber)) / ...
                      (max(oneMidiData.NoteNumber) - min(oneMidiData.NoteNumber));
    velocitiesNorm = (oneMidiData.Velocity - min(oneMidiData.Velocity)) / ...
                     (max(oneMidiData.Velocity) - min(oneMidiData.Velocity));
    
    % Combine into a sequence matrix [NoteNumber; Velocity] for each time step
    sequenceData = [noteNumbersNorm, velocitiesNorm]';
    
    % Define LSTM network architecture
    inputSize = 2;
    numHiddenUnits = 50;
    outputSize = 2;

    layers = [
        sequenceInputLayer(inputSize)
        lstmLayer(numHiddenUnits, 'OutputMode', 'sequence')
        fullyConnectedLayer(outputSize)
        regressionLayer
    ];

    % Prepare input (X) and target (Y) sequences
    X = sequenceData(:, 1:end-1);
    Y = sequenceData(:, 2:end);
    
    % Check dimensions
    disp('Size of X:');
    disp(size(X));
    disp('Size of Y:');
    disp(size(Y));

    % Validate that X and Y are nonempty
    if isempty(X) || isempty(Y)
        error('X or Y is empty after processing. Check the MIDI files and data processing steps.');
    elseif size(X, 2) ~= size(Y, 2)
        error('Mismatch between X and Y sequence lengths.');
    end

    % Training options
    options = trainingOptions('adam', ...
        'MaxEpochs', 100, ...
        'MiniBatchSize', 32, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', 0, ...
        'Plots', 'training-progress');

    % Train the LSTM model
    net = trainNetwork(X, Y, layers, options);
    
    % Predict using the trained LSTM network
    YPred = predict(net, X);
else
    error('No valid data found in MIDI files. Check the MIDI files for valid NoteNumber and Velocity values.');
end
