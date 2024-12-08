midiData = readmidi("A., Jag, Je t'aime Juliette, OXC7Fd0ZN8o.mid");

trackMessages = midiData.track(2).messages;

% Initialize arrays to store deltatime, noteNumber, and velocity
deltatimes = [trackMessages.deltatime]';  % Extract all deltatime values
noteNumbers = NaN(length(trackMessages), 1);  % Use NaN to handle potential missing values
velocities = NaN(length(trackMessages), 1); 


% Loop through each message to extract noteNumber and velocity
for i = 1:length(trackMessages)
    data = trackMessages(i).data;  % Get the [note number; velocity] pair
    
    % Check if data is non-empty and has at least 2 elements
    if numel(data) >= 2
        noteNumbers(i) = data(1);   % Extract note number
        velocities(i) = data(2);    % Extract velocity
    end
end

% Create a table with deltatime, noteNumber, and velocity columns
oneMidiData = table(deltatimes, noteNumbers, velocities, ...
                         'VariableNames', {'DeltaTime', 'NoteNumber', ...
                                           'Velocity'});
% Remove rows with NaNs in NoteNumber or Velocity
validRows = ~isnan(oneMidiData.NoteNumber) & ~isnan(oneMidiData.Velocity);
oneMidiData = oneMidiData(validRows, :);

% Normalize NoteNumber and Velocity to [0, 1] range for the LSTM
noteNumbersNorm = (oneMidiData.NoteNumber - min(oneMidiData.NoteNumber)) / ...
                  (max(oneMidiData.NoteNumber) - min(oneMidiData.NoteNumber));
velocitiesNorm = (oneMidiData.Velocity - min(oneMidiData.Velocity)) / ...
                 (max(oneMidiData.Velocity) - min(oneMidiData.Velocity));

% Combine into a sequence matrix [NoteNumber; Velocity] for each time step
sequenceData = [noteNumbersNorm, velocitiesNorm]';

% Define LSTM network architecture
inputSize = 2;  % We have two input features: NoteNumber and Velocity
numHiddenUnits = 50;  % Number of hidden units in the LSTM
outputSize = 2;  % Output two values (NoteNumber, Velocity) for the next time step

layers = [
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits, 'OutputMode', 'sequence')
    fullyConnectedLayer(outputSize)
    regressionLayer
];

% Prepare input (X) and target (Y) sequences
X = sequenceData(:, 1:end-1);  % Input sequence
Y = sequenceData(:, 2:end);    % Target sequence (shifted by one time step)

% Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 1, ...
    'Shuffle', 'never', ...
    'Verbose', 0, ...
    'Plots', 'training-progress');

% Train the LSTM model
net = trainNetwork(X, Y, layers, options);

% Initialize parameters for generation
numGeneratedSteps = 500;  % Number of notes to generate
generatedSequence = zeros(2, numGeneratedSteps);  % Initialize with zeros
generatedSequence(:, 1) = sequenceData(:, 1);  % Start with the first timestep of the original sequence

% Generate new notes using the LSTM model
for t = 2:numGeneratedSteps
    % Reshape the last generated note for prediction
    YPred = predict(net, reshape(generatedSequence(:, t-1), [2, 1]), 'MiniBatchSize', 1);
    generatedSequence(:, t) = YPred;  % Store predicted note
end

% Denormalize the generated notes back to the original scale
noteNumbersGen = (generatedSequence(1, :) * (max(oneMidiData.NoteNumber) - min(oneMidiData.NoteNumber))) + min(oneMidiData.NoteNumber);
velocitiesGen = (generatedSequence(2, :) * (max(oneMidiData.Velocity) - min(oneMidiData.Velocity))) + min(oneMidiData.Velocity);

% Prepare MIDI structure
midi = struct();
midi.format = 1;  % Format 1: Multiple tracks, synchronized
midi.ticks_per_quarter_note = 480;  % Example value, adjust as needed
midi.track = {};  % Initialize as a cell array

% Create a track for the generated MIDI
trackMessages = struct('type', {}, 'chan', {}, 'deltatime', {}, 'data', {});  % Initialize track messages

% Create MIDI messages from generated notes
for i = 1:numGeneratedSteps
    % Create note-on message
    noteOnMsg = struct('type', 144, 'chan', 1, ...
                       'deltatime', 0, ...
                       'data', [round(noteNumbersGen(i)), round(velocitiesGen(i))]);
    trackMessages(end + 1) = noteOnMsg;  % Add note-on message

    % Add a note-off message after a certain duration (e.g., 480 ticks)
    noteOffMsg = struct('type', 128, 'chan', 1, ...
                        'deltatime', 480, ...
                        'data', [round(noteNumbersGen(i)), 0]);
    trackMessages(end + 1) = noteOffMsg;  % Add note-off message
end

% Store messages in the first track
midi.track{1}.messages = trackMessages;  % Store messages in the first track

filename = 'generated_song.mid';  % Specify the filename
%writemidi(midi, filename); % Call the function to write MIDI data to file

write_midi_from_struct('generated_song.mid',midi)
