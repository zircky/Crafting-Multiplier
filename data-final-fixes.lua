-- Максимальное количество для ингредиентов/результатов/пакетов (uint16)
local MAX_AMOUNT = 65535

-- Получаем значения множителей из настроек мода (целые числа из startup)
local crafting_multiplier = settings.startup["crafting-multiplier"].value or 1
local result_multiplier = settings.startup["result-multiplier"].value or 1
local science_multiplier = settings.startup["science-multiplier"].value or 1
local energy_multiplier = settings.startup["energy-multiplier"].value or 1

-- Проверка типов
if type(crafting_multiplier) ~= "number" then
  log("Error: crafting-multiplier is not a number: " .. tostring(crafting_multiplier))
  crafting_multiplier = 1
end
if type(result_multiplier) ~= "number" then
  log("Error: result-multiplier is not a number: " .. tostring(result_multiplier))
  result_multiplier = 1
end
if type(science_multiplier) ~= "number" then
  log("Error: science-multiplier is not a number: " .. tostring(science_multiplier))
  science_multiplier = 1
end
if type(energy_multiplier) ~= "number" then
  log("Error: energy-multiplier is not a number: " .. tostring(energy_multiplier))
  energy_multiplier = 1
end


-- Убедимся, что множители не меньше 1
crafting_multiplier = math.max(1, crafting_multiplier)
result_multiplier = math.max(1, result_multiplier)
science_multiplier = math.max(1, science_multiplier)
energy_multiplier = math.max(0.01, energy_multiplier) -- время крафта может быть меньше 1


log("Applying crafting multiplier: " .. crafting_multiplier)
log("Applying result multiplier: " .. result_multiplier)
log("Applying science multiplier: " .. science_multiplier)
log("Applying energy multiplier: " .. energy_multiplier)

-- Масштабирование ингредиентов
local function scale_ingredients(ingredients, multiplier)
  for _, ing in pairs(ingredients or {}) do
    if type(ing) == "table" then
      if ing.name and ing.amount then
        ing.amount = math.max(1, math.min(MAX_AMOUNT, math.floor(ing.amount * multiplier)))
      elseif type(ing[1]) == "string" and type(ing[2]) == "number" then
        ing[2] = math.max(1, math.min(MAX_AMOUNT, math.floor(ing[2] * multiplier)))
      end
    end
  end
end

-- Масштабирование результатов
local function scale_results(results, multiplier)
  for _, res in pairs(results or {}) do
    if res.amount and type(res.amount) == "number" then
      res.amount = math.max(1, math.min(MAX_AMOUNT, math.floor(res.amount * multiplier)))
    elseif type(res[1]) == "string" and type(res[2]) == "number" then
      res[2] = math.max(1, math.min(MAX_AMOUNT, math.floor(res[2] * multiplier)))
    end
  end
end

-- Масштабирование result_count
local function scale_result_count(recipe, multiplier)
  recipe.result_count = recipe.result_count or 1
  if type(recipe.result_count) == "number" and recipe.result_count > 0 then
    recipe.result_count = math.max(1, math.min(MAX_AMOUNT, math.floor(recipe.result_count * multiplier)))
  end
end

-- Масштабирование строковых значений энергии (например "180kW", "2MW", "500W")
local function scale_energy_string(value, multiplier)
  if type(value) ~= "string" then return value end
  local number, unit = string.match(value, "([%d%.]+)%s*(%a+)")
  number = tonumber(number)
  if number and unit then
    return tostring(number * multiplier) .. unit
  end
  return value
end

-- Обработка рецептов
for _, recipe in pairs(data.raw.recipe) do
  if recipe.ingredients then
    scale_ingredients(recipe.ingredients, crafting_multiplier)
  end
  if recipe.results then
    scale_results(recipe.results, result_multiplier)
  elseif recipe.result then
    scale_result_count(recipe, result_multiplier)
  end

  if recipe.normal then
    if recipe.normal.ingredients then
      scale_ingredients(recipe.normal.ingredients, crafting_multiplier)
    end
    if recipe.normal.results then
      scale_results(recipe.normal.results, result_multiplier)
    elseif recipe.normal.result then
      scale_result_count(recipe.normal, result_multiplier)
    end
  end

  if recipe.expensive then
    if recipe.expensive.ingredients then
      scale_ingredients(recipe.expensive.ingredients, crafting_multiplier)
    end
    if recipe.expensive.results then
      scale_results(recipe.expensive.results, result_multiplier)
    elseif recipe.expensive.result then
      scale_result_count(recipe.expensive, result_multiplier)
    end
  end

  -- Масштабируем энергию крафта (energy_required)
  if recipe.energy_required then
    recipe.energy_required = recipe.energy_required * energy_multiplier
  end
  if recipe.normal and recipe.normal.energy_required then
    recipe.normal.energy_required = recipe.normal.energy_required * energy_multiplier
  end
  if recipe.expensive and recipe.expensive.energy_required then
    recipe.expensive.energy_required = recipe.expensive.energy_required * energy_multiplier
  end
end

-- Масштабирование науки
for _, tech in pairs(data.raw.technology) do
  if tech.unit and type(tech.unit.count) == "number" then
    tech.unit.count = math.max(1, math.floor(tech.unit.count * science_multiplier))
  end
end

-- Масштабирование энергопотребления машин
for _, prototype_type in pairs(data.raw) do
  for _, entity in pairs(prototype_type) do
    if entity.energy_usage then
      entity.energy_usage = scale_energy_string(entity.energy_usage, energy_multiplier)
    end
    if entity.drain then
      entity.drain = scale_energy_string(entity.drain, energy_multiplier)
    end
    if entity.energy_source and entity.energy_source.emissions_per_minute then
      if type(entity.energy_source.emissions_per_minute) == "number" then
        entity.energy_source.emissions_per_minute =
          entity.energy_source.emissions_per_minute * energy_multiplier
      elseif type(entity.energy_source.emissions_per_minute) == "table" then
        for k, v in pairs(entity.energy_source.emissions_per_minute) do
          if type(v) == "number" then
            entity.energy_source.emissions_per_minute[k] = v * energy_multiplier
          end
        end
      end
    end
  end
end