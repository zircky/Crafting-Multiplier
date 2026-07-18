local SETTING_NAME = "science-multiplier"
local ESIR_MOD_NAME = "exotic-space-industries-remembrance"

local function esir_is_active()
  return script.active_mods[ESIR_MOD_NAME] ~= nil
end

local function get_custom_multiplier()
  return math.max(1, tonumber(settings.global[SETTING_NAME].value) or 1)
end

local function apply_science_multiplier()
  local base_multiplier = storage.base_technology_price_multiplier or 1
  local applied_multiplier = math.min(1000, base_multiplier * get_custom_multiplier())

  game.difficulty_settings.technology_price_multiplier = applied_multiplier
  storage.last_applied_technology_price_multiplier = applied_multiplier
end

local function capture_external_multiplier()
  storage.base_technology_price_multiplier =
    game.difficulty_settings.technology_price_multiplier or 1
end

script.on_init(function()
  capture_external_multiplier()
  apply_science_multiplier()
end)

script.on_configuration_changed(function()
  if esir_is_active() then
    -- The optional dependency makes ESIR's handler run first. Capture its newly
    -- calculated Age-ramp multiplier, then apply our multiplier on top of it.
    capture_external_multiplier()
  elseif not storage.base_technology_price_multiplier then
    -- Versions before 0.2.4 wrote the custom value directly into DifficultySettings.
    -- Recover the original map multiplier when upgrading an existing save.
    local current = game.difficulty_settings.technology_price_multiplier or 1
    storage.base_technology_price_multiplier = current / get_custom_multiplier()
  end
  apply_science_multiplier()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting_type == "runtime-global" and event.setting == SETTING_NAME then
    apply_science_multiplier()
  end
end)

if esir_is_active() then
  script.on_event(defines.events.on_research_finished, function()
    -- ESIR recalculates its Age-ramp after each completed technology. Dependency
    -- ordering guarantees that this handler observes ESIR's updated value.
    capture_external_multiplier()
    apply_science_multiplier()
  end)

  script.on_event(defines.events.on_tick, function()
    -- Also catch ESIR's deferred scripted research and /refresh_tech_scaling command,
    -- which can update DifficultySettings outside on_research_finished.
    local current = game.difficulty_settings.technology_price_multiplier or 1
    local last_applied = storage.last_applied_technology_price_multiplier

    if type(last_applied) == "number" and math.abs(current - last_applied) > 0.000000001 then
      capture_external_multiplier()
      apply_science_multiplier()
    end
  end)
end
