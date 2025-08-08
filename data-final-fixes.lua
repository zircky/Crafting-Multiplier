-- Максимальное количество для ингредиентов/результатов/пакетов (uint16)
local MAX_AMOUNT = 65535

-- Получаем значения множителей из настроек мода (целые числа из startup)
local crafting_multiplier = settings.startup["crafting-multiplier"].value or 1
local result_multiplier = settings.startup["result-multiplier"].value or 1
local science_multiplier = settings.startup["science-multiplier"].value or 1

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

-- Убедимся, что множители не меньше 1
crafting_multiplier = math.max(1, crafting_multiplier)
result_multiplier = math.max(1, result_multiplier)
science_multiplier = math.max(1, science_multiplier)

log("Applying crafting multiplier: " .. crafting_multiplier)
log("Applying result multiplier: " .. result_multiplier)
log("Applying science multiplier: " .. science_multiplier)

-- 🔧 Функции масштабирования
local function scale_ingredients(ingredients, multiplier)
  for _, ing in pairs(ingredients or {}) do
    if type(ing) == "table" then
      if ing.name and ing.amount then
        ing.amount = math.max(1, math.min(MAX_AMOUNT, math.floor(ing.amount * multiplier)))
      elseif type(ing[1]) == "string" and type(ing[2]) == "number" then
        ing[2] = math.max(1, math.min(MAX_AMOUNT, math.floor(ing[2] * multiplier)))
      else
        log("Unknown ingredient format: " .. serpent.line(ing))
      end
    end
  end
end

local function scale_results(results, multiplier)
  for _, res in pairs(results or {}) do
    if res.amount and type(res.amount) == "number" then
      res.amount = math.max(1, math.min(MAX_AMOUNT, math.floor(res.amount * multiplier)))
    elseif type(res[1]) == "string" and type(res[2]) == "number" then
      res[2] = math.max(1, math.min(MAX_AMOUNT, math.floor(res[2] * multiplier)))
    else
      log("Unknown result format: " .. serpent.line(res))
    end
  end
end

local function scale_result_count(recipe, multiplier)
  recipe.result_count = recipe.result_count or 1
  if type(recipe.result_count) == "number" and recipe.result_count > 0 then
    recipe.result_count = math.max(1, math.min(MAX_AMOUNT, math.floor(recipe.result_count * multiplier)))
  else
    log("Warning: Skipping invalid result_count: " .. tostring(recipe.result_count))
  end
end

-- 🎯 Обработка всех рецептов
for recipe_name, recipe in pairs(data.raw.recipe) do
  if recipe_name == "fast-underground-belt" then
    log("Skipping fast-underground-belt due to potential invalid ingredients")
    goto continue
  end

  -- Стандартный рецепт (без normal/expensive)
  if recipe.ingredients then
    scale_ingredients(recipe.ingredients, crafting_multiplier)
  end
  if recipe.results then
    scale_results(recipe.results, result_multiplier)
  elseif recipe.result then
    scale_result_count(recipe, result_multiplier)
  end

  -- Режим normal
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

  -- Режим expensive (устаревшее название hard)
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

  ::continue::
end

-- ⚙️ Обработка всех технологий
for tech_name, tech in pairs(data.raw.technology) do
  if tech.unit then
    if tech.unit.count and type(tech.unit.count) == "number" then
      tech.unit.count = math.max(1, tech.unit.count * science_multiplier)
    elseif tech.unit.count_formula then
      log("Skipping technology with formula: " .. tech_name .. " -> formula: " .. tech.unit.count_formula)
    else
      log("Warning: Invalid unit count in technology " .. tech_name)
    end
  end
end