% Original function to generate midi file from onemidi LSTM output.
function write_midi_from_struct(filename, midi)
    % Open the file in write mode
    fid = fopen(filename, 'w', 'b');  % 'b' for binary mode
    
    % Write the MIDI Header Chunk
    % Header starts with 'MThd' + 6 bytes for length + format (1) + tracks (1) + ticks per quarter note (480)
    fwrite(fid, 'MThd', 'char');     % Chunk type
    fwrite(fid, 6, 'uint32');        % Header length (6 bytes for MIDI header)
    fwrite(fid, 1, 'uint16');        % Format type 1 (single track)
    fwrite(fid, 1, 'uint16');        % Number of tracks (1 track)
    fwrite(fid, 480, 'uint16');      % Ticks per quarter note (adjustable, here 480)
    
    % Write the Track Chunk
    fwrite(fid, 'MTrk', 'char');     % Track chunk type
    trackData = [];                  % Initialize empty array to hold track data

    % Process each message in midi.track{1}.messages
    for i = 1:length(midi.track{1}.messages)
        msg = midi.track{1}.messages(i);
        
        % Add delta time (variable length)
        trackData = [trackData, var_len_encode(msg.deltatime)];
        
        % Add the event type + channel (e.g., 0x90 for Note On, channel 1)
        trackData = [trackData, msg.type + (msg.chan - 1)];
        
        % Add the data bytes (e.g., [note number, velocity])
        trackData = [trackData, msg.data];
    end
    
    % End of Track meta event
    trackData = [trackData, 0x00, 0xFF, 0x2F, 0x00];

    % Write the length of the track data
    fwrite(fid, length(trackData), 'uint32');
    % Write the track data itself
    fwrite(fid, trackData, 'uint8');
    
    % Close the file
    fclose(fid);
end

% Helper function to encode delta time as variable-length quantities
function var_len = var_len_encode(value)
    var_len = [];
    while true
        byte = bitand(value, 127);    % Keep only the 7 least significant bits
        value = bitshift(value, -7);  % Shift right by 7 bits
        if ~isempty(var_len)
            byte = bitor(byte, 128);  % Set the continuation bit for all bytes except the last
        end
        var_len = [byte, var_len];    % Prepend byte to the beginning of var_len
        if value == 0
            break;
        end
    end
end
