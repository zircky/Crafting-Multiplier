local SETTING_NAME = "science-multiplier"

local function get_custom_multiplier()
  return math.max(1, tonumber(settings.global[SETTING_NAME].value) or 1)
end

local function apply_science_multiplier()
  local base_multiplier = storage.base_technology_price_multiplier or 1
  game.difficulty_settings.technology_price_multiplier =
    math.min(1000, base_multiplier * get_custom_multiplier())
end

script.on_init(function()
  storage.base_technology_price_multiplier =
    game.difficulty_settings.technology_price_multiplier or 1
  apply_science_multiplier()
end)

script.on_configuration_changed(function()
  if not storage.base_technology_price_multiplier then
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
