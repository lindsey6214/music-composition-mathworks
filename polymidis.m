% Marie Elster, Group 22
% November 20 2024
% Mathworks Music Composition using 20 Polyphonic midis

% ---- Fetch input data, extract first n files from midi ---

% Create the datastore
midiDatastore = fileDatastore(sourceFolder, "ReadFcn", @readmidi);
len = length('/Users/mcelster/Desktop/Mathworks Music/matlab-music-comp/midis/');

n = 100 % number of input songs

%Iterate through mididatastore object, collect number of desired files
midiFiles = strings(n);
for i = 2:n+1 %length(midiDatastore.Files)
    name = midiDatastore.Files{i}(len+1:end);
    midiFiles(i-1) = name;
end

% ---- Prepare Data for Multiple Songs -----

% Initialize storage for all songs' data
allDeltaTimes = [];
allNoteNumbers = [];
allVelocities = [];

% Loop through each MIDI file and process
for fileIdx = 1:length(midiFiles)
    midiData = readmidi(midiFiles{fileIdx});
    trackMessages = midiData.track(2).messages;  % Adjust track selection as needed

    % Initialize arrays for current file
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

    % Remove invalid rows and concatenate
    validRows = ~isnan(noteNumbers) & ~isnan(velocities);
    allDeltaTimes = [allDeltaTimes; deltatimes(validRows)];
    allNoteNumbers = [allNoteNumbers; noteNumbers(validRows)];
    allVelocities = [allVelocities; velocities(validRows)];
end

% Normalize allNoteNumbers and allVelocities
noteNumbersNorm = (allNoteNumbers - min(allNoteNumbers)) / ...
                  (max(allNoteNumbers) - min(allNoteNumbers));
velocitiesNorm = (allVelocities - min(allVelocities)) / ...
                 (max(allVelocities) - min(allVelocities));

% ---- Adjust Input and Output for Polyphony -----

% Group notes by unique delta times
[uniqueTimes, ~, idx] = unique(allDeltaTimes);
maxNotesPerStep = 10;  % Adjust based on your dataset

groupedNotes = zeros(maxNotesPerStep, length(uniqueTimes));
groupedVelocities = zeros(maxNotesPerStep, length(uniqueTimes));

for t = 1:length(uniqueTimes)
    % Find all notes with the same delta time
    noteIdx = find(idx == t);
    notes = allNoteNumbers(noteIdx);
    velocities = allVelocities(noteIdx);

    % Truncate or pad notes and velocities
    numNotes = min(maxNotesPerStep, length(notes));
    groupedNotes(1:numNotes, t) = notes(1:numNotes);
    groupedVelocities(1:numNotes, t) = velocities(1:numNotes);
end

% Normalize groupedNotes and groupedVelocities
groupedNotesNorm = (groupedNotes - min(allNoteNumbers)) / ...
                   (max(allNoteNumbers) - min(allNoteNumbers));
groupedVelocitiesNorm = (groupedVelocities - min(allVelocities)) / ...
                        (max(allVelocities) - min(allVelocities));

sequenceData = [groupedNotesNorm; groupedVelocitiesNorm];

% ---- Define LSTM Network Architecture -----

% Define LSTM network architecture
numFeatures = 2 * maxNotesPerStep;  % Each note has NoteNumber and Velocity
inputSize = numFeatures;
numHiddenUnits = 100;
outputSize = numFeatures;

layers = [
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits, 'OutputMode', 'sequence')
    fullyConnectedLayer(outputSize)
    regressionLayer
];

% Prepare training data
X = sequenceData(:, 1:end-1);
Y = sequenceData(:, 2:end);

% Training options #1
options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 1, ...
    'Shuffle', 'never', ...
    'Verbose', 0, ...
    'Plots', 'training-progress');
% Training options #2
%{
trainingOptions( 'adam', ...
    'MiniBatchSize', 1, ...
    'GradientThreshold', 1, ...
    'MaxEpochs', 25, ...
    'Plots', 'training-progress');
%}

% Train the LSTM model
net = trainNetwork(X, Y, layers, options);

% ---- Generate Multiple Notes Per Step ----

% Initialize parameters for generation
numGeneratedSteps = 200;
generatedSequence = zeros(numFeatures, numGeneratedSteps);
generatedSequence(:, 1) = sequenceData(:, 1);  % Start with the first timestep

% Generate new notes
for t = 2:numGeneratedSteps
    YPred = predict(net, reshape(generatedSequence(:, t-1), [numFeatures, 1]), 'MiniBatchSize', 1);
    generatedSequence(:, t) = YPred;
end

% Split generatedSequence into notes and velocities
notesGen = (generatedSequence(1:maxNotesPerStep, :) * (max(allNoteNumbers) - min(allNoteNumbers))) + min(allNoteNumbers);
velocitiesGen = (generatedSequence(maxNotesPerStep+1:end, :) * (max(allVelocities) - min(allVelocities))) + min(allVelocities);

% ---- Prepare MIDI output -----

% Prepare MIDI structure
midi = struct();
midi.format = 1;  % MIDI format 1: Multiple tracks, synchronized
midi.ticks_per_quarter_note = 480;  % Common resolution, adjust as needed
midi.track = {};  % Initialize as a cell array to store track data

% Initialize the track messages
trackMessages = struct('type', {}, 'chan', {}, 'deltatime', {}, 'data', {});

% Parameters for timing
defaultDeltaTime = 240;  % Default time between events in ticks

% Loop through generated notes and velocities
for t = 1:numGeneratedSteps
    for n = 1:maxNotesPerStep
        note = round(notesGen(n, t));  % Rounded note number
        velocity = round(velocitiesGen(n, t));  % Rounded velocity

        % Skip if the note or velocity is 0 (padding or no note played)
        if note > 0 && velocity > 0
            % "Note On" message
            noteOnMsg = struct('type', 144, 'chan', 1, ...
                               'deltatime', defaultDeltaTime, ...
                               'data', [note, velocity]);
            trackMessages(end + 1) = noteOnMsg;  % Add note-on message

            % "Note Off" message (after a duration, e.g., 480 ticks)
            noteOffMsg = struct('type', 128, 'chan', 1, ...
                                'deltatime', 480, ...
                                'data', [note, 0]);
            trackMessages(end + 1) = noteOffMsg;  % Add note-off message
        end
    end
end

% Store messages in the first track
midi.track{1}.messages = trackMessages;

% Write the MIDI file
write_midi_from_struct('monoSong', midi);
writemidiPoly(midi, 'polySong.mid');

disp(['MIDI file generated.']);
