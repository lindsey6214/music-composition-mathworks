% Read midi data from file
midiData = readmidi("A., Jag, Je t'aime Juliette, OXC7Fd0ZN8o.mid");

deltaTime = [midiData.track(2).messages.deltatime] 
data = [midiData.track(2).messages.data] 

% To be continued:
% Prepare input-output sequences (e.g., sequences of 50 notes)
sequenceLength = 50;
X = [];
Y = [];

for i = 1:(length(data) - sequenceLength)
    X = [X; normalizedPitches(i:i+sequenceLength-1)'];  % Input sequence
    Y = [Y; normalizedPitches(i+sequenceLength)];       % Next note to predict
end

% Loop through the data to create sequences
for i:
X = [deltaTime, data];  % Input sequence of deltaTime and notePitches
Y = [];  % Output is the next note to predict
end

inputSize = 2;  % Since we are using deltaTime and notePitch
numHiddenUnits = 100;
numResponses = 1;  % Predicting the next note pitch

layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits, 'OutputMode', 'last')
    fullyConnectedLayer(numResponses)
    regressionLayer];

% Define training options
options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'GradientThreshold', 1, ...
    'InitialLearnRate', 0.01, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 10, ...
    'LearnRateDropFactor', 0.2, ...
    'Verbose', 0, ...
    'Plots', 'training-progress');

% Train the LSTM model
net = trainNetwork(X, Y, layers, options);
