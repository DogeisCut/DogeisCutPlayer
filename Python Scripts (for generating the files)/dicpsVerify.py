import os

def parse_note_data(file_path):
    if not os.path.exists(file_path):
        print(f"File {file_path} does not exist.")
        return

    with open(file_path, 'rb') as f:
        data = f.read()

    if len(data) % 5 != 0:
        print("Data length is not a multiple of 5. File may be corrupted.")
        return
    
    tempo_low_byte = data[0]
    tempo_high_byte = data[1]
    tempo_higher_byte = data[2]
    tempo_highest_byte = data[3]

    tempo = (tempo_highest_byte << 24) | (tempo_higher_byte << 16) | (tempo_high_byte << 8) | tempo_low_byte

    notes = []
    for i in range(5, len(data), 5):
        low_byte = data[i]
        high_byte = data[i + 1]
        pitch = data[i + 2]
        instrument = data[i + 3]
        volume = data[i + 4]

        delta_time = (high_byte << 8) | low_byte
        notes.append({
            "delta_time": delta_time,
            "pitch": pitch,
            "instrument": instrument,
            "volume": volume
        })

    for idx, note in enumerate(notes):
        print(f"Note {idx + 1}: Delta Time: {note['delta_time']}, Pitch: {note['pitch']}, "
              f"Instrument: {note['instrument']}, Volume: {note['volume']}")
    
    print(f"Tempo: {tempo}")
    print(f"tempo_low_byte: {tempo_low_byte}")
    print(f"tempo_high_byte: {tempo_high_byte}")
    print(f"tempo_higher_byte: {tempo_higher_byte}")
    print(f"tempo_highest_byte: {tempo_highest_byte}")

output_file = os.path.join(os.path.dirname(__file__), "output.dicps")
parse_note_data(output_file)
