data:extend({
  {
    type = "int-setting",
    name = "crafting-multiplier",
    setting_type = "startup",
    default_value = 1,
    minimum_value = 1,
    maximum_value = 100,
    order = "a",
    localised_name = { "mod-setting-name.crafting-multiplier" },
    localised_description = { "mod-setting-description.crafting-multiplier" }
  },
  {
    type = "int-setting",
    name = "result-multiplier",
    setting_type = "startup",
    default_value = 1,
    minimum_value = 1,
    maximum_value = 2,
    order = "b",
    localised_name = { "mod-setting-name.result-multiplier" },
    localised_description = { "mod-setting-description.result-multiplier" }
  },
  {
    type = "int-setting",
    name = "science-multiplier",
    setting_type = "startup",
    default_value = 1,
    minimum_value = 1,
    maximum_value = 100,
    order = "c",
    localised_name = { "mod-setting-name.science-multiplier" },
    localised_description = { "mod-setting-description.science-multiplier" }
  },
  {
    type = "double-setting",
    name = "energy-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.01,
    maximum_value = 1000.0,
    order = "d",
    localised_name = { "mod-setting-name.energy-multiplier" },
    localised_description = { "mod-setting-description.energy-multiplier" }
  }
})
