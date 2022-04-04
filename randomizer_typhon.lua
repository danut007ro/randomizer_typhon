-- Randomizer for Dreadbox Typhon
-- 1.0.0 @danut007ro
-- llllllll.co/t/randomizer_typhon
--
-- Generate random patches
-- for Dreadbox Typhon
--
-- K2 : Randomize

local midi_device
local midi_channel
local randomizing = false

local modulation_ccs = {
  {43, 59, 76}, -- CV LEVEL
  {44, 60, 77}, -- CV1 LEVEL
  {45, 61, 78}, -- CV2 LEVEL
  {46, 62, 79}, -- WAVE LEVEL
  {47, 63, 80}, -- CUT LEVEL
  {48, 65, 81}, -- VCA LEVEL
  {49, 66, 82}, -- FX1 LEVEL
  {50, 67, 83}, -- FFM LEVEL
  {51, 68, 84}, -- FX2 LEVEL
  {52, 69, 85}, -- FX3 LEVEL
  {53, 70, 86}, -- CUSTOM 1 LEVEL
  {54, 71, 87}, -- CUSTOM 2 LEVEL
  {55, 72, 88}, -- CUSTOM 3 LEVEL
}

function init()
  params:add_separator("MIDI")
  params:add_number("midi_device", "MIDI device", 1, 16, 1)
  params:add_number("midi_channel", "MIDI channel", 1, 16, 1)

  params:add_separator("ADSR")
  params:add_option("amp_adsr", "AMP ADSR", {"YES", "NO"}, 2)
  params:add_option("vcf_adsr", "VCF ADSR", {"YES", "NO"}, 2)

  params:add_separator("Modulators")
  params:add_option("modulate_same_parameters", "Modulate same parameters", {"YES", "NO"}, 1)
  params:add_number("m1_destinations", "M1 destinations", 0, 13, 1)
  params:add_number("m1_random_destinations", "M1 random destinations", 0, 13, 3)
  params:add_number("m2_destinations", "M2 destinations", 0, 13, 1)
  params:add_number("m2_random_destinations", "M2 random destinations", 0, 13, 3)
  params:add_number("m3_destinations", "M3 destinations", 0, 13, 1)
  params:add_number("m3_random_destinations", "M3 random destinations", 0, 13, 3)

  params:add_separator("FX")
  params:add_option("fx1", "FX1", {"YES", "NO"}, 1)
  params:add_option("fx2", "FX2", {"YES", "NO"}, 1)
  params:add_option("fx3", "FX3", {"YES", "NO"}, 1)
end

function redraw()
  screen.clear()
  
  screen.move(64, 15)
  screen.level(15)
  screen.text_center("Dreadbox Typhon randomizer")
  
  if randomizing then
    screen.move(64, 45)
    screen.level(10)
    screen.text_center("randomizing...")
  end

  screen.update()
end

function key(n, z)
  if n == 2 and z == 0 and not randomizing then
    randomizing = true
    redraw()
    randomize()
    randomizing = false
    redraw()
  end
end

function randomize_cc(cc, cc_min, cc_max)
  cc_min = cc_min or 0
  cc_max = cc_max or 127
  if type(cc) ~= "table" then
    cc = {cc}
  end

  for i=1,#cc do
    midi_device:cc(cc[i], math.random(cc_min, cc_max), midi_channel)
  end
end

function table.shallow_copy(original)
  local copy = {}
  for k,v in pairs(original) do
    copy[k] = v
  end

  return copy
end

function sleep(s)
  local ntime = os.clock() + s/10
  repeat until os.clock() > ntime
end

function randomize()
  midi_device = midi.connect(params:get("midi_device"))
  midi_channel = params:get("midi_channel")

  randomize_cc({
    1, -- MOD WHEEL
    2, -- CC2
    3, -- RESONANCE
    4, -- CUTOFF
    5, -- WAVE
    6, -- OSC
    7, -- GLIDE AMOUNT
    8, -- VCO LEVEL
    9, -- FILTER TRACKING
    11, -- FILTER FM AMOUNT
    12, -- HP CUTOFF
    13, -- HP RESONANCE
  })

  if params:get("amp_adsr") == 1 then
    randomize_cc({
      34, -- VCA EG ATTACK
      35, -- VCA EG DECAY
      36, -- VCA EG SUSTAIN
      37, -- VCA EG RELEASE
      38, -- VCA EG TIME
    })
  end

  if params:get("vcf_adsr") == 1 then
    randomize_cc({
      27, -- VCF EG ATTACK
      28, -- VCF EG DECAY
      29, -- VCF EG SUSTAIN
      30, -- VCF EG RELEASE
      31, -- VCF EG TIME
      33, -- VCF EG LEVEL
    })
  end

  randomize_modulators()

  if params:get("fx1") == 1 then
    randomize_cc({
      14, -- FX1 PARAMETER 1
      15, -- FX1 PARAMETER 2
      16, -- FX1 MIX
    })

    sleep(0.1)
  end

  if params:get("fx2") == 1 then
    randomize_cc({
      17, -- FX2 PARAMETER 1
      18, -- FX2 PARAMETER 2
      19, -- FX2 PARAMETER 3
      20, -- FX2 PARAMETER 4
      21, -- FX2 MIX
    })

    sleep(0.1)
  end

  if params:get("fx3") == 1 then
    randomize_cc({
      22, -- FX3 PARAMETER 1
      23, -- FX3 PARAMETER 2
      24, -- FX3 PARAMETER 3
      25, -- FX3 PARAMETER 4
      26, -- FX3 MIX
    })

    sleep(0.1)
  end
end

function randomize_modulators()
  -- Table of allowed modulation parameters.
  local parameters = table.shallow_copy(modulation_ccs)

  local index = 0
  local modulators = {
    ["m1"] = {40, 41, 42},
    ["m2"] = {56, 57, 58},
    ["m3"] = {73, 74, 75},
  }
  for modulator, modulator_params in pairs(modulators) do
    index = index + 1

    -- If no destinations should be modulated then leave as it is.
    local destinations = params:get(modulator .. "_destinations")
    local random_destinations = params:get(modulator .. "_random_destinations")
    if destinations + random_destinations == 0 then
      goto next_modulator
    end

    -- Randomize modulator parameters.
    for param=1,#modulator_params do
      randomize_cc(modulator_params[param])
    end

    -- Update allowed parameters if allowed to modulate same.
    if params:get("modulate_same_parameters") == 1 then
      parameters = table.shallow_copy(modulation_ccs)
    end

    -- Reset modulator destinations.
    for param=1,#parameters do
      randomize_cc(parameters[param][index], 64, 64)
    end
    sleep(0.1)

    for i=1,(destinations + random_destinations) do
      -- Random destinations might be skipped.
      if i > destinations and math.random(0, 1) == 0 then
        goto next_destination
      end

      -- Modulate parameter and remove from allowed.
      if #parameters > 0 then
        param = math.random(1, #parameters)
        randomize_cc(parameters[param][index], 0, 127)
        table.remove(parameters, param)
      end
      sleep(0.1)
      
      ::next_destination::
    end

    ::next_modulator::
  end
end
