
function writemidiPoly(midi, filename)
    % WRITEMIDI Writes a MIDI structure to a file
    %   midi: Structure containing MIDI data
    %   filename: Name of the output MIDI file

    fid = fopen(filename, 'wb');  % Open file for writing in binary mode
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end

    try
        % Write MIDI header chunk
        fwrite(fid, 'MThd', 'char');                     % Chunk type "MThd"
        fwrite(fid, uint32(6), 'uint32', 'b');           % Header length (6 bytes)
        fwrite(fid, uint16(midi.format), 'uint16', 'b'); % MIDI format (0, 1, or 2)
        fwrite(fid, uint16(length(midi.track)), 'uint16', 'b');  % Number of tracks
        fwrite(fid, uint16(midi.ticks_per_quarter_note), 'uint16', 'b');  % Time division

        % Write each track
        for t = 1:length(midi.track)
            trackData = createTrackChunk(midi.track{t});
            fwrite(fid, trackData, 'uint8');
        end
    catch ME
        fclose(fid);  % Close the file on error
        rethrow(ME);
    end

    fclose(fid);  % Close the file after writing
end

function trackData = createTrackChunk(track)
    % CREATETRACKCHUNK Creates a MIDI track chunk from track messages
    %   track: Structure containing track messages

    % Initialize the track data with a header
    trackBytes = [];
    trackBytes = [trackBytes, uint8('MTrk')];  % Chunk type "MTrk"
    lengthPosition = length(trackBytes) + 1;  % Placeholder for length
    trackBytes = [trackBytes, zeros(1, 4)];   % Reserve space for length field

    % Process each message
    lastDeltaTime = 0;
    for i = 1:length(track.messages)
        msg = track.messages(i);

        % Encode delta time as a variable-length quantity
        deltaTime = int32(msg.deltatime);  % Ensure deltaTime is an integer
        deltaTimeBytes = encodeVariableLength(deltaTime - lastDeltaTime);
        lastDeltaTime = deltaTime;
        trackBytes = [trackBytes, deltaTimeBytes];

        % Encode the message
        if msg.type == 144 || msg.type == 128  % Note On or Note Off
            trackBytes = [trackBytes, uint8(msg.type + (msg.chan - 1)), ...
                          uint8(msg.data(1)), uint8(msg.data(2))];
        else
            error('Unsupported message type: %d', msg.type);
        end
    end

    % Add end-of-track meta-event
    trackBytes = [trackBytes, uint8([0, 255, 47, 0])];  % DeltaTime=0, MetaEvent, End of Track

    % Update the chunk length
    trackLength = length(trackBytes) - lengthPosition - 4;
    trackBytes(lengthPosition:(lengthPosition + 3)) = uint8([...
        bitshift(trackLength, -24), ...
        bitshift(bitand(trackLength, 16711680), -16), ...
        bitshift(bitand(trackLength, 65280), -8), ...
        bitand(trackLength, 255)]);

    trackData = trackBytes;
end

function bytes = encodeVariableLength(value)
    % ENCODEVARIABLELENGTH Encodes a value as a MIDI variable-length quantity
    %   value: Integer to encode
    %   bytes: Encoded variable-length quantity as a vector of uint8

    value = uint32(value);  % Ensure value is an integer
    bytes = [];
    while true
        byte = bitand(value, 127);  % Extract the lower 7 bits
        value = bitshift(value, -7);  % Shift value to the right by 7 bits
        if ~isempty(bytes)
            byte = bitor(byte, 128);  % Set the continuation bit for all but the last byte
        end
        bytes = [byte, bytes];
        if value == 0
            break;
        end
    end
    bytes = uint8(bytes);  % Ensure bytes are in uint8 format
end
