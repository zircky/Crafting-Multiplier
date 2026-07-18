script.on_init(function()
  apply_science_multiplier()
end)

script.on_configuration_changed(function()
  apply_science_multiplier()
end)

function apply_science_multiplier()
  local custom_multiplier = settings.global["science-multiplier"].value or 1
  local vanilla_multiplier = game.difficulty_settings.technology_price_multiplier or 1

  local new_multiplier = vanilla_multiplier * custom_multiplier

  if new_multiplier > 1000 then
      new_multiplier = 1000
      for _, player in pairs(game.players) do
        player.print({"", "[color=red][CraftingMultiplier][/color] Warning: Science multiplier capped at 1000 (Factorio limit)."})
      end
  end

  game.difficulty_settings.technology_price_multiplier = new_multiplier

  for _, player in pairs(game.players) do
      player.print({"", "[color=green][CraftingMultiplier][/color] Vanilla multiplier: ",
        vanilla_multiplier, " | Custom multiplier: ",
        custom_multiplier, " | Final applied multiplier: ",
        new_multiplier})
    end
end