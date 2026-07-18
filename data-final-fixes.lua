-- Maximum quantity for ingredients/results/bags (uint16)
local MAX_AMOUNT = 65535

-- Get the multiplier values from the mod settings (integers from startup)
local crafting_multiplier = settings.startup["crafting-multiplier"].value or 1
local result_multiplier = settings.startup["result-multiplier"].value or 1
local energy_multiplier = settings.startup["energy-multiplier"].value or 1

-- Type checking
if type(crafting_multiplier) ~= "number" then
  log("Error: crafting-multiplier is not a number: " .. tostring(crafting_multiplier))
  crafting_multiplier = 1
end
if type(result_multiplier) ~= "number" then
  log("Error: result-multiplier is not a number: " .. tostring(result_multiplier))
  result_multiplier = 1
end
if type(energy_multiplier) ~= "number" then
  log("Error: energy-multiplier is not a number: " .. tostring(energy_multiplier))
  energy_multiplier = 1
end

-- Let's make sure that the multipliers are not less than 1
crafting_multiplier = math.max(1, crafting_multiplier)
result_multiplier = math.max(1, result_multiplier)
energy_multiplier = math.max(0.01, energy_multiplier)

log("Applying crafting multiplier: " .. crafting_multiplier)
log("Applying result multiplier: " .. result_multiplier)
log("Applying energy multiplier: " .. energy_multiplier)


----------------------------------------------------------------
-- 🔵 Stack size lookup
----------------------------------------------------------------
local function get_stack_size(item_name)
  if not item_name then return nil end

  return (data.raw.item[item_name]
    or (data.raw["ammo"] and data.raw["ammo"][item_name])
    or (data.raw["tool"] and data.raw["tool"][item_name])
    or (data.raw["module"] and data.raw["module"][item_name])
    or (data.raw["capsule"] and data.raw["capsule"][item_name])
    or (data.raw["armor"] and data.raw["armor"][item_name])
    or (data.raw["gun"] and data.raw["gun"][item_name])
    or (data.raw["repair-tool"] and data.raw["repair-tool"][item_name])
    or nil)
end

----------------------------------------------------------------
-- 🔵 Variant A: Round amount up to full stacks
----------------------------------------------------------------
local function apply_stack_logic(item_name, amount)
  local proto = get_stack_size(item_name)
  if not proto or not proto.stack_size then
    return amount
  end

  local stack = proto.stack_size

  -- If fits in 1 stack → leave as is
  if amount <= stack then
    return amount
  end

  local stacks_needed = math.ceil(amount / stack)
  return stacks_needed * stack
end


----------------------------------------------------------------
-- Ingredient scaling (with stack logic)
----------------------------------------------------------------
local function scale_ingredients(ingredients, multiplier)
  for _, ing in pairs(ingredients or {}) do

    -- long format { name="", amount=N }
    if ing.name and ing.amount then
      local raw = ing.amount * multiplier
      local rounded = apply_stack_logic(ing.name, raw)
      ing.amount = math.max(1, math.min(MAX_AMOUNT, rounded))

    -- short format { "item", N }
    elseif type(ing[1]) == "string" and type(ing[2]) == "number" then
      local name = ing[1]
      local raw = ing[2] * multiplier
      local rounded = apply_stack_logic(name, raw)
      ing[2] = math.max(1, math.min(MAX_AMOUNT, rounded))

    end
  end
end


----------------------------------------------------------------
-- Scaling results
----------------------------------------------------------------
local function scale_results(results, multiplier)
  for _, res in pairs(results or {}) do

    -- long format
    if res.name and res.amount then
      res.amount = math.max(1, math.min(MAX_AMOUNT, math.floor(res.amount * multiplier)))

    -- short format
    elseif type(res[1]) == "string" and type(res[2]) == "number" then
      res[2] = math.max(1, math.min(MAX_AMOUNT, math.floor(res[2] * multiplier)))
    end
  end
end


----------------------------------------------------------------
-- Scaling result_count
----------------------------------------------------------------
local function scale_result_count(recipe, multiplier)
  recipe.result_count = recipe.result_count or 1
  if type(recipe.result_count) == "number" and recipe.result_count > 0 then
    recipe.result_count = math.max(1, math.min(MAX_AMOUNT, math.floor(recipe.result_count * multiplier)))
  end
end


----------------------------------------------------------------
-- Scaling of string energy values
----------------------------------------------------------------
local function scale_energy_string(value, multiplier)
  if type(value) ~= "string" then return value end
  local number, unit = string.match(value, "([%d%.]+)%s*(%a+)")
  number = tonumber(number)
  if number and unit then
    return tostring(number * multiplier) .. unit
  end
  return value
end


----------------------------------------------------------------
-- 🔥 Recipe Processing
----------------------------------------------------------------
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

  -- Scaling Crafting Energy (energy_required)
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


----------------------------------------------------------------
-- 🔥 Scaling the power consumption of machines
----------------------------------------------------------------
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