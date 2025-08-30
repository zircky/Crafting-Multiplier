local science_multiplier = settings.startup["science-multiplier"].value or 1

if type(science_multiplier) ~= "number" then
  log("Error: science-multiplier is not a number: " .. tostring(science_multiplier))
  science_multiplier = 1
end

science_multiplier = math.max(1, science_multiplier)

log("Applying science multiplier: " .. science_multiplier)

-- Масштабирование науки
for tech_name, tech in pairs(data.raw.technology) do
    if tech.unit then
        -- Логируем структуру технологии
        log("Processing technology " .. tech_name .. ": unit = " .. serpent.line(tech.unit))

        -- Обработка unit.count
        if tech.unit.count and type(tech.unit.count) == "number" then
            local old_count = tech.unit.count
            tech.unit.count = math.max(1, tech.unit.count * science_multiplier)
            log("Scaling unit.count for " .. tech_name .. ": old count = " .. old_count .. ", new count = " .. tech.unit.count)
        elseif tech.unit.count_formula and type(tech.unit.count_formula) == "string" then
            local old_formula = tech.unit.count_formula
            local new_formula = tech.unit.count_formula:gsub("(%d+)", function(num)
                local scaled = tonumber(num) * science_multiplier
                return tostring(math.floor(scaled))
            end)
            tech.unit.count_formula = new_formula
            log("Scaling count_formula for " .. tech_name .. ": old formula = " .. old_formula .. " -> new formula = " .. new_formula)
        else
            log("Warning: Invalid or missing unit.count/count_formula in technology " .. tech_name)
        end

        -- Масштабирование unit.ingredients
        if tech.unit.ingredients then
            for _, ing in pairs(tech.unit.ingredients) do
                if type(ing) == "table" then
                    local name = ing.name or ing[1]
                    local amount = ing.amount or ing[2]
                    if name and amount and type(amount) == "number" and amount > 0 and amount == amount then
                        local new_amount = math.max(1, amount * science_multiplier)
                        if ing.amount then
                            ing.amount = new_amount
                        elseif ing[2] then
                            ing[2] = new_amount
                        end
                        log("Scaling science ingredient for " .. tech_name .. ": name = " .. tostring(name) .. ", old amount = " .. tostring(amount) .. ", new amount = " .. new_amount)
                    else
                        log("Warning: Skipping invalid science ingredient in technology " .. tech_name .. ": " .. serpent.line(ing))
                    end
                else
                    log("Warning: Skipping non-table science ingredient in technology " .. tech_name .. ": " .. serpent.line(ing))
                end
            end
        else
            log("Warning: No ingredients in technology " .. tech_name)
        end
    else
        log("Warning: No unit in technology " .. tech_name)
    end
end
