-- todo:
-- finish instruments
    -- xp orb sound for triangle
-- Loading Texttask and Progress bar Texttask
-- Song info (name and bpm)
-- loading songs for players when they join halfway through or my avatar was loading
    -- id have to like start loading the song data partway through it, so maybe i should also ping the max size of the data so i can do padding
-- make missing instruments complain only once when playing a song while its loading
-- perhaps i should only read the new data coming in, process that, and append it to the notes array, to save on ticks.
-- song list command
-- optimise read_midi_raw_to_table() somehow
-- fix sounds getting stuck

-- i wonder how feasable it would be to read the raw data directly instead of turning it into a table...

-- read_midi_raw_to_table is the bottleneck

local option

local function getLoadingBar(percentage)
    local barLength = 50
    local filled = math.floor((percentage / 100) * barLength)
    local empty = barLength - filled
    local bar = "[" .. string.rep("|", filled) .. string.rep(":", empty) .. "]"
    return (bar .. " " .. math.round(percentage*100)/100 .. "%")
end

local function getProgressBar(percentage, maxSeconds)
    local barLength = 50
    local filled = math.floor((percentage / 100) * barLength)
    local empty = barLength - filled
    local bar = "[" .. string.rep("|", filled) .. string.rep(":", empty) .. "]"
    
    local currentSeconds = math.floor((percentage / 100) * maxSeconds)
    local currentMinutes = math.floor(currentSeconds / 60)
    local currentSecs = currentSeconds % 60
    local totalMinutes = math.floor(maxSeconds / 60)
    local totalSecs = maxSeconds % 60
    
    local timeDisplay = string.format("%d:%02d/%d:%02d", currentMinutes, currentSecs, totalMinutes, totalSecs)
    return (bar .. " " .. timeDisplay)
end

local songInfoPart = models:newPart("songInfoPart","Camera"):setPivot(0,50,0)
local songTitleTextTask = songInfoPart:newText("songTitle")
:setAlignment("center")
:setText("No song set!")
:setPos(0,4,0)
:setScale(0.4)
local loadingBarTextTask = songInfoPart:newText("loadingBar")
:setAlignment("center")
:setText(getLoadingBar(0))
:setPos(0,0,0)
:setScale(0.4)
local progressBarTextTask = songInfoPart:newText("progressBar")
:setAlignment("center")
:setText(getProgressBar(0,0))
:setPos(0,-4,0)
:setScale(0.4)
local bpmTextTask = nil

local instruments = {
    "Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano", "Honky-tonk Piano", "Electric Piano 1",
    "Electric Piano 2", "Harpsichord", "Clavinet", "Celesta", "Glockenspiel", "Music Box", "Vibraphone", "Marimba",
    "Xylophone", "Tubular Bells", "Dulcimer", "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
    "Reed Organ", "Accordion", "Harmonica", "Tango Accordion", "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)",
    "Electric Guitar (jazz)", "Electric Guitar (clean)", "Electric Guitar (muted)", "Overdriven Guitar",
    "Distortion Guitar", "Guitar Harmonics", "Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)",
    "Fretless Bass", "Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2", "Violin", "Viola", "Cello", "Contrabass",
    "Tremolo Strings", "Pizzicato Strings", "Orchestral Harp", "Timpani", "String Ensemble 1", "String Ensemble 2",
    "SynthStrings 1", "SynthStrings 2", "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit", "Trumpet", "Trombone",
    "Tuba", "Muted Trumpet", "French Horn", "Brass Section", "Synth Brass 1", "Synth Brass 2", "Soprano Sax", "Alto Sax",
    "Tenor Sax", "Baritone Sax", "Oboe", "English Horn", "Bassoon", "Clarinet", "Piccolo", "Flute", "Recorder", "Pan Flute",
    "Blown Bottle", "Shakuhachi", "Whistle", "Ocarina", "Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)",
    "Lead 4 (chiffer)", "Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass + lead)", "Pad 1 (new age)",
    "Pad 2 (warm)", "Pad 3 (polysynth)", "Pad 4 (choir)", "Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)",
    "Pad 8 (sweep)", "FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)", "FX 5 (brightness)",
    "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)", "Sitar", "Banjo", "Shamisen", "Koto", "Kalimba", "Bagpipe",
    "Fiddle", "Shanai", "Tinkle Bell", "Agogo", "Steel Drums", "Woodblock", "Taiko Drum", "Melodic Tom", "Synth Drum",
    "Reverse Cymbal", "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet", "Telephone Ring", "Helicopter",
    "Applause", "Gunshot", "Percussion"
}
local percussion = {
    "Acoustic Drum", "Electric Bass Drum", "Side Stick", "Acoustic Snare", "Electric Snare",
    "Low Floor Tom", "Closed Hi-hat", "High Floor Tom", "Pedal Hi-hat", "Low Tom",
    "Open Hi-hat", "Low-Mid Tom", "High-Mid Tom", "Crash Cymbal 1", "High Tom",
    "Ride Cymbal 1", "Chinese Cymbal", "Ride Bell", "Tambourine", "Splash Cymbal",
    "Cowbell", "Crash Cymbal 2", "Vibraslap", "Ride Cymbal 2", "High Bongo",
    "Low Bongo", "Mute High Conga", "Open High Conga", "Low Conga", "High Timbale",
    "Low Timbale", "High Agogô", "Low Agogô", "Cabasa", "Maracas",
    "Short Whistle", "Long Whistle", "Short Güiro", "Long Güiro", "Claves",
    "High Woodblock", "Low Woodblock", "Mute Cuíca", "Open Cuíca", "Mute Triangle",
    "Open Triangle"
}

local instrumentMap = {
    ["Acoustic Grand Piano"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3, volume = 0.75},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+12, volume = 0.5},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+24, volume = 0.1}},
    ["Bright Acoustic Piano"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3, volume = 0.5},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+12, volume = 0.5},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+24, volume = 0.25}},
    ["Electric Grand Piano"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3, volume = 0.75},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+12, volume = 0.5},
                                {path = "block.note_block.pling", pitch_offset = 0, note_offset = 3+24, volume = 0.1}},
    ["Honky-tonk Piano"] =  {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3, volume = 0.5},
                                {path = "block.note_block.harp", pitch_offset = 0.02, note_offset = 3+12, volume = 0.5},
                                {path = "block.note_block.harp", pitch_offset = 0.02, note_offset = 3+24, volume = 0.25}},
    ["Electric Piano 1"] = {{path = "block.note_block.pling", pitch_offset = 0, note_offset = 3, volume = 0.75},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+12, volume = 0.5}},
    ["Electric Piano 2"] = {{path = "block.note_block.bit", pitch_offset = 0, note_offset = 3+12, volume = 0.75},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+24, volume = 0.5}},
    ["Harpsichord"] = {{path = "block.note_block.pling", pitch_offset = 0, note_offset = 3, volume = 0.75},
                                {path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+24, volume = 0.5}},
    ["Clavinet"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+12, volume = 0.75},
                                {path = "block.note_block.bit", pitch_offset = 0, note_offset = 3+24, volume = 0.5}},
    ["Celesta"] = {{path = "block.note_block.chime", pitch_offset = 0, note_offset = 3, volume = 1}},
    ["Glockenspiel"] = {{path = "block.note_block.chime", pitch_offset = 0, note_offset = 3+12, volume = 0.5},
                        {path = "block.note_block.iron_xylophone", pitch_offset = 0, note_offset = 3+12, volume = 1}},
    ["Music Box"] = {{path = "block.note_block.chime", pitch_offset = 0, note_offset = 3, volume = 0.5},
                        {path = "block.note_block.iron_xylophone", pitch_offset = 0, note_offset = 3+12, volume = 1}},
    ["Vibraphone"] = {{path = "block.note_block.chime", pitch_offset = 0, note_offset = 3, volume = 0.5},
                        {path = "block.note_block.iron_xylophone", pitch_offset = 0, note_offset = 3, volume = 0.5}},
    ["Marimba"] = {{path = "block.note_block.iron_xylophone", pitch_offset = 0, note_offset = 3, volume = 0.75},
                        {path = "block.note_block.xylophone", pitch_offset = 0, note_offset = 3, volume = 0.75}},
    ["Xylophone"] = {{path = "block.note_block.xylophone", pitch_offset = 0, note_offset = 3, volume = 1}},
    ["Tubular Bells"] = {{path = "block.note_block.bell", pitch_offset = 0, note_offset = 3-12, volume = 1/1.4},
                        {path = "block.anvil.land", pitch_offset = 0.58, note_offset = 3+12, volume = 0.2/1.4}},
    ["Dulcimer"] = {{path = "block.note_block.iron_xylophone", pitch_offset = 0, note_offset = 3+12, volume = 0.5}},
    ["Drawbar Organ"] = {{path = "sine", pitch_offset = 0, note_offset = 3, volume = 0.25},
                        {path = "sine", pitch_offset = 0, note_offset = 3+12, volume = 0.25},
                        {path = "sine", pitch_offset = 0, note_offset = 3+24, volume = 0.25},
                        {path = "sine", pitch_offset = 0, note_offset = 3+24+12, volume = 0.25}},
    ["Percussive Organ"] = {{path = "block.note_block.iron_xylophone", pitch_offset = 0, note_offset = 3, volume = 0.2},
                            {path = "sine", pitch_offset = 0, note_offset = 3, volume = 0.5},
                        {path = "sine", pitch_offset = 0, note_offset = 3+12, volume = 0.5}},
    ["Rock Organ"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3, volume = 0.3},
                            {path = "sine", pitch_offset = 0, note_offset = 3, volume = 0.5}},
    ["Church Organ"] = {{path = "sine", pitch_offset = 0, note_offset = 3, volume = 0.5},
                        {path = "sine", pitch_offset = 0, note_offset = 3+12, volume = 0.5}},
    ["Reed Organ"] = {{path = "sine", pitch_offset = 0, note_offset = 3, volume = 0.5},
                        {path = "sine", pitch_offset = 0, note_offset = 3+12, volume = 0.5}},
    ["Accordion"] =  {{path = "block.note_block.bit", pitch_offset = 0, note_offset = 3, volume = 0.75},
                        {path = "block.note_block.bit", pitch_offset = 0.01, note_offset = 3+12, volume = 0.25},
                        {path = "block.note_block.bit", pitch_offset = 0.03, note_offset = 3+24, volume = 0.25},
                        {path = "block.note_block.flute", pitch_offset = 0.01, note_offset = 3, volume = 0.2},
                        {path = "block.note_block.flute", pitch_offset = 0.03, note_offset = 3, volume = 0.2}},
    -- ..
    ["Acoustic Guitar (nylon)"] = {{path = "block.note_block.guitar", pitch_offset = 0, note_offset = 3, volume = 1}},
    -- ..
    ["Overdriven Guitar"] = {{path = "overdrive", pitch_offset = 0, note_offset = -12, volume = 0.333333}},
    -- ..
    ["Flute"] = {{path = "block.note_block.flute", pitch_offset = 0, note_offset = 3-12, volume = 1}},
    ["Recorder"] = {{path = "block.note_block.flute", pitch_offset = 0.003, note_offset = 3-12, volume = 1}},
    -- ..
    ["Lead 1 (square)"] = {{path = "block.note_block.bit", pitch_offset = 0, note_offset = 3, volume = 0.8},
                           {path = "block.note_block.bit", pitch_offset = 0.005, note_offset = 3, volume = 0.8}},
    ["Lead 2 (sawtooth)"] = {{path = "block.note_block.bit", pitch_offset = 0, note_offset = 3, volume = 0.8},
                           {path = "block.note_block.bit", pitch_offset = 0.01, note_offset = 3, volume = 0.9}},
    ["Lead 5 (charang)"] = {{path = "block.note_block.didgeridoo", pitch_offset = 0, note_offset = 3+12, volume = 1},
                           {path = "block.note_block.didgeridoo", pitch_offset = 0.01, note_offset = 3+12, volume = 1}},
    ["Lead 8 (bass + lead)"] = {{path = "block.note_block.bit", pitch_offset = 0, note_offset = 3+12, volume = 0.6},
                           {path = "block.note_block.bit", pitch_offset = 0.005, note_offset = 3+12, volume = 0.6},
                           {path = "block.note_block.bit", pitch_offset = 0.005, note_offset = 3, volume = 0.6}},
    -- ..
    ["Sitar"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3+12, volume = 0.333}, 
                 {path = "block.note_block.banjo", pitch_offset = 0, note_offset = 3, volume = 0.333},
                 {path = "block.note_block.guitar", pitch_offset = 0, note_offset = 3+12, volume = 0.333}},
    ["Banjo"] = {{path = "block.note_block.banjo", pitch_offset = 0, note_offset = 3, volume = 1}},
    -- ...
    ["Koto"] = {{path = "block.note_block.harp", pitch_offset = 0, note_offset = 3, volume = 0.75}, 
                {path = "block.note_block.banjo", pitch_offset = 0, note_offset = 3+12, volume = 0.75}},
}

local percussionMap = {
    ["Acoustic Drum"] = {{path = "block.note_block.basedrum", pitch_offset = -1+0.5, note_offset = 0, volume = 1.5}},
    ["Electric Bass Drum"] = {{path = "block.note_block.basedrum", pitch_offset = -1+0.5, note_offset = 0, volume = 1.5},
                       {path = "block.note_block.snare", pitch_offset = -1+0.5, note_offset = 0, volume = 0.2}},
    ["Side Stick"] = {{path = "block.note_block.hat", pitch_offset = -1+1.5, note_offset = 0, volume = 1}},
    ["Acoustic Snare"] = {{path = "block.note_block.snare", pitch_offset = -1+1.4, note_offset = 0, volume = 1.2}},
    ["Hand Clap"] = {{path = "block.note_block.snare", pitch_offset = -1+1.8, note_offset = 0, volume = 0.3},
                          {path = "block.note_block.snare", pitch_offset = -1+2, note_offset = 0, volume = 0.3},
                          {path = "item.trident.hit", pitch_offset = 0, note_offset = 0, volume = 0.3}},
    ["Electric Snare"] = {{path = "block.note_block.snare", pitch_offset = -1+1.4, note_offset = 0, volume = 0.75},
                          {path = "block.note_block.snare", pitch_offset = -1+0.8, note_offset = 0, volume = 0.75}},
    ["Low Floor Tom"] = {{path = "block.note_block.basedrum", pitch_offset = -1+0.5, note_offset = 0, volume = 1},
                         {path = "block.note_block.bass", pitch_offset = -1+0.4, note_offset = -12, volume = 1.5}},
    ["Closed Hi-hat"] = {{path = "item.trident.hit", pitch_offset = -1+1.8, note_offset = 0, volume = 0.5},
                         {path = "block.note_block.snare", pitch_offset = -1+1.8, note_offset = 0, volume = 0.5}},
    ["High Floor Tom"] = {{path = "block.note_block.basedrum", pitch_offset = 0, note_offset = 0, volume = 1},
                         {path = "block.note_block.bass", pitch_offset = -1+0.7, note_offset = -12, volume = 1.5}},
    -- Pedal Hi-hat
    -- Low Tom
    ["Open Hi-hat"] = {{path = "item.trident.hit", pitch_offset = -1+1.8, note_offset = 0, volume = 0.666},
                       {path = "block.note_block.snare", pitch_offset = -1+1.8, note_offset = 0, volume = 0.666},
                       {path = "block.lava.extinguish", pitch_offset = -1+3, note_offset = 0, volume = 0.666}},
    -- Low-Mid Tom
    -- High-Mid Tom
    ["Crash Cymbal 1"] = {{path = "block.note_block.hat", pitch_offset = -1+2, note_offset = 0, volume = 0.75},
                       {path = "block.lava.extinguish", pitch_offset = 0, note_offset = 0, volume = 0.5}},
}

local song = nil
local tempo = 10

local playing = false

local chunked_song_data = ""

local tick = 0
local syncTimer = 0

local chunking_timer = 0
local chunking_count = 0

local knownMissingInstruments = {}

local tick_counter = 0

local function read_midi_raw_to_table(song_data)
    local table_result = {}
    local delta_accumulation = 0

    local tempo_low_byte = string.byte(song_data, 1)
    local tempo_high_byte = string.byte(song_data, 2)
    local tempo_higher_byte = string.byte(song_data, 3)
    local tempo_highest_byte = string.byte(song_data, 4)

    tempo = (tempo_low_byte + (tempo_high_byte * 256) + (tempo_higher_byte * 65536) + (tempo_highest_byte * 16777216))
    tempo = 60000000/tempo
    tempo = (tempo*96)/1200

    for i = 2, (#song_data / 5) - 1 do
        local base_index = (i - 1) * 5

        local lower_byte = string.byte(song_data, base_index + 1)
        local upper_byte = string.byte(song_data, base_index + 2)

        delta_accumulation = delta_accumulation + (lower_byte + (upper_byte * 256))

        local note = {
            time = delta_accumulation,
            pitch = string.byte(song_data, base_index + 3),
            instrument = string.byte(song_data, base_index + 4),
            volume = string.byte(song_data, base_index + 5)
        }

        if table_result[delta_accumulation] then
            table.insert(table_result[delta_accumulation], note)
        else
            table_result[delta_accumulation] = {note}
        end
        table.insert(table_result, note)
    end
    
    return table_result
end

function pings.syncTick(to, to2)
    tick = to
    tick_counter = to2
end

local function setSong(data)
    knownMissingInstruments = {}
    song = read_midi_raw_to_table(data)
end

local function extendSong(data, percent)
    song = read_midi_raw_to_table(data)
    loadingBarTextTask:setText(getLoadingBar(percent))
end

function pings.setPlaying(to)
    setSong(chunked_song_data)
    playing = to
end

function pings.restartSong()
    playing = true
    tick = 0
end

table.has = function(tbl, val)
  for _, v in pairs(tbl) do
      if v == val then
          return true
      end
  end
  return false
end

local function play_note(pitch, instrument, volume)
    if player:isLoaded() then
        if instruments[instrument + 1] == "Percussion" then
            if not percussionMap[percussion[pitch-35]] then
                if not table.has(knownMissingInstruments, percussion[pitch-35]) then
                    if percussion and pitch-35 and percussion[pitch-35] then
                        print("Unknown percussion: " .. percussion[pitch-35] .. " (" .. pitch-35 .. ") ")
                        table.insert(knownMissingInstruments, percussion[pitch-35])
                    end
                end
            else
                local percussion = percussionMap[percussion[pitch-35]]
                for _,sound in ipairs(percussion) do
                    sounds[sound.path]
                    :setPos(player:getPos())
                    :setAttenuation(2.5)
                    :setVolume((volume/100) * sound.volume * 0.5)
                    :setPitch((2^((sound.note_offset + 1)/12)) + sound.pitch_offset)
                    :setSubtitle("Percussion")
                    :play()
                end
            end
        else
            local actualInstrument = {{path = "block.note_block.harp", pitch_offset = 0, note_offset=3+12, volume=1, timing_offset = 0}}
            if not instrumentMap[instruments[instrument + 1]] then
                if not table.has(knownMissingInstruments, instruments[instrument + 1]) then
                    if instrument and instruments[instrument + 1] then
                        print("Unknown instrument: " .. instruments[instrument + 1] .. " (" .. instrument .. ") ")
                        table.insert(knownMissingInstruments, instruments[instrument + 1])
                    end
                end
            else
                actualInstrument = instrumentMap[instruments[instrument + 1]]
            end
            for _,sound in ipairs(actualInstrument) do
                sounds[sound.path]
                :setPos(player:getPos())
                :setAttenuation(2.5)
                :setVolume((volume/100) * sound.volume * 0.5)
                :setPitch((2^(((pitch+sound.note_offset) - 69)/12)) + sound.pitch_offset)
                :setSubtitle(instruments[instrument + 1])
                :play()
            end
        end
    end 
end

--todo: move this out of music.lua

local mainPage = action_wheel:newPage()
action_wheel:setPage(mainPage)

local file_path = "DogeisCutPlayerSongs/output.dicps"
local file_data = ""

function pings.appendSongData(what, percent)
    chunked_song_data = chunked_song_data .. what
    extendSong(chunked_song_data, percent)
end

local function loadSongData()
    if host:isHost() then
        if not file:exists(file_path) then
            print("File '" .. file_path .. "' not found!")
            return
        end

        --file_data = file:readString(file_path)
        local is = file:openReadStream(file_path)

        for i = 1, is:available(), 1 do
            file_data = file_data .. string.char(is:read())
        end

        is:close()
    end
end

mainPage:newAction()
  :title("Play Song")
  :item("minecraft:jukebox")
  :hoverColor(1, 0, 1)
  :onLeftClick(function() 
    if file_data == "" then
        print("Please load the song first!")
    else
        pings.setPlaying(true)
    end
end)

mainPage:newAction()
  :title("Restart Song")
  :item("minecraft:jukebox")
  :hoverColor(1, 0, 1)
  :onLeftClick(function() 
   pings.restartSong()
end)

mainPage:newAction()
  :title("Stop/Unload Song")
  :item("minecraft:jukebox")
  :hoverColor(1, 0, 1)
  :onLeftClick(function() 
   pings.setPlaying(false)
   pings.reset()
end)

mainPage:newAction()
  :title("Pause Song")
  :item("minecraft:jukebox")
  :hoverColor(1, 0, 1)
  :onLeftClick(function() 
   pings.setPlaying(false)
end)

function pings.reset()
    song = nil
    playing = false
    
    chunked_song_data = ""
    file_data = ""
    
    tick = 0
    syncTimer = 0

    chunking_timer = 0
    chunking_count = 0
end

function pings.resetAndLoad()
    song = nil
    playing = false
    
    chunked_song_data = ""
    file_data = ""
    
    tick = 0
    syncTimer = 0

    chunking_timer = 32
    chunking_count = 0
    loadSongData()
end

mainPage:newAction()
  :title("Load Song")
  :item("minecraft:jukebox")
  :hoverColor(1, 0, 1)
  :onLeftClick(function() 
    pings.resetAndLoad()
end)

function events.tick()
    if file_data ~= "" and chunking_timer>=0 then
        chunking_timer = chunking_timer + 1
        if chunking_timer >= 32 then
            local chunkSize = 900

            chunking_count = chunking_count + 1

            local processed_bytes = math.min(chunkSize * chunking_count, #file_data)
            local total_bytes = #file_data
            local percentage_done = (processed_bytes / total_bytes) * 100

            --print(string.format("Progress: %.2f%%", percentage_done))

            chunking_timer = 0
            pings.appendSongData(string.sub(file_data, 1 + ((chunking_count-1) * chunkSize), math.min(chunkSize*chunking_count, #file_data)), percentage_done)
            if math.min(chunkSize*chunking_count, #file_data) == #file_data then
                chunking_timer = -9999999999
                --print("chunking done!")
            end
        end
    end
    syncTimer = syncTimer + 1
    if syncTimer > 120 then
        pings.syncTick(tick, tick_counter)
        syncTimer = 0
    end
    if playing then
        tick_counter = tick_counter + tempo
        while tick_counter >= 1 do
            tick_counter = tick_counter - 1
            if song[tick] then
                for i, note in ipairs(song[tick]) do
                    play_note(note.pitch, note.instrument, note.volume)
                end
            end
            tick = tick + 1
        end
    end
end   

function pings.setTempo(to)
    tempo = to
    print("Tempo set to: " .. tempo)
end

function pings.setSongPath(to, title)
    file_path = to
    songTitleTextTask:setText(title)
    loadingBarTextTask:setText(getLoadingBar(0))
    print("Song path set to: " .. file_path)
end

function events.CHAT_SEND_MESSAGE(msg)
    if msg:sub(1, 5) == ">mus " then
        local command, arg = msg:match("^>mus (%S+)%s*(.*)$")
        
        if command == "tempo" then
            local num_arg = tonumber(arg)
            if num_arg then
                pings.setTempo(num_arg)
            else
                print("Invalid tempo argument!")
            end
            
        elseif command == "song" then
            if arg ~= "" then
                if playing or file_data ~= "" then
                    print("Please stop the song or stop loading it before trying to change it!")
                else
                    pings.setSongPath( "DogeisCutPlayerSongs/" .. arg .. ".dicps", arg)
                end
            else
                print("Invalid file path argument!")
            end
        elseif command == "bpm" then
            local num_arg = (tonumber(arg)*96)/1200
            if num_arg then
                pings.setTempo(num_arg)
            else
                print("Invalid tempo argument!")
            end
        elseif command == "instrum" then
            local num_arg = tonumber(arg)
            play_note(69, num_arg, 100)
            print("Locally played A4 of instrument " .. instruments[num_arg+1] .. " (" .. num_arg .. ")")
        else
            print("Unknown sub-command: " .. (command or ""))
        end
        return
    end
    
    return msg
end