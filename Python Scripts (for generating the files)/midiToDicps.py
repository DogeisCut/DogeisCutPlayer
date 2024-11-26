from mido import MidiFile
from tkinter import Tk
from tkinter.filedialog import askopenfilename, asksaveasfilename
import os

def midi_to_minimal():
    Tk().withdraw()
    input_file = askopenfilename(filetypes=[("MIDI Files", ".mid .midi")], title="Select a MIDI File")
    if not input_file:
        print("No file selected.")
        return

    instrument = 0
    events = bytearray()
    notes = []
    tempo = 120
    #last_note_velocity = None
    #last_note_pitch = None

    midi = MidiFile(input_file)
    for track in midi.tracks:
        note_time = 0
        for msg in track:
            note_time += msg.time
            if msg.type == 'set_tempo':
                tempo = int(msg.tempo / (midi.ticks_per_beat/96))
            elif msg.type == 'program_change':
                instrument = msg.program
            elif msg.type == 'note_on' and msg.velocity > 0:
                #last_note_velocity = msg.velocity
                notes.append({
                    "note_time": note_time,
                    "note": msg.note,
                    "instrument": instrument,
                    "velocity": msg.velocity,
                    "channel": msg.channel
                })
            # Bad experiment
            # elif msg.type == 'pitchwheel':
            #     if last_note_pitch is not None:
            #         bend_value = msg.pitch
            #         pitch_bend_ratio = bend_value / 8192
            #         pitch_bend  = int(last_note_pitch + (pitch_bend_ratio * 12))
            #         notes.append({
            #             "note_time": note_time,
            #             "note": pitch_bend,
            #             "instrument": instrument,
            #             "velocity": last_note_velocity,
            #             "channel": msg.channel
            #         })


    notes.sort(key=lambda x: x['note_time'])
    previous_time = 0
    for note in notes:
        note['delta_time'] = note['note_time'] - previous_time
        previous_time = note['note_time']

    tempo_low_byte = tempo & 0xFF
    tempo_high_byte = (tempo >> 8) & 0xFF
    tempo_higher_byte = (tempo >> 16) & 0xFF
    tempo_highest_byte = (tempo >> 24) & 0xFF

    events.extend([
        tempo_low_byte,
        tempo_high_byte,
        tempo_higher_byte,
        tempo_highest_byte,
        0x00
    ])

    for note in notes:
        low_byte = note['delta_time'] & 0xFF
        high_byte = (note['delta_time'] >> 8) & 0xFF

        instrument = note['instrument']
        if note['channel'] == 9:
            instrument = 128
        
        events.extend([
            low_byte,
            high_byte,
            note['note'] & 0xFF,
            instrument & 0xFF,
            note['velocity'] & 0xFF
        ])

    output_file = asksaveasfilename(defaultextension=".dicps", filetypes=[("DICPS Files", "*.dicps")], title="Save Output File")
    if not output_file:
        print("No file selected for saving.")
        return
    
    with open(output_file, 'wb') as f:
        f.write(events)

    print(f"Raw byte data saved to {output_file}")

midi_to_minimal()
