script.on_init(function()
  apply_science_multiplier()
end)

script.on_configuration_changed(function()
  apply_science_multiplier()
end)

function apply_science_multiplier()
  local setting_value = settings.global["science-multiplier"].value or 1

  if game.difficulty_settings then
    game.difficulty_settings.technology_price_multiplier = setting_value
    game.print("Applied science multiplier: " .. setting_value)
  else
    log("Warning: game.difficulty_settings not available")
  end
end