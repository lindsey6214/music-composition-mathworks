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

