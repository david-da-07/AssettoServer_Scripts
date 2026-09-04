-- ============================================================================
-- SISTEMA DE RESTRICCIÓN DE POTENCIA Y LASTRE (HANDICAP / BOP)
-- ============================================================================

-- Registro de restricciones asignadas [sessionID] = {power = %, ballast = kg}
local playerHandicaps = {}

function onChatMessage(sessionID, message)
    local adminCar = ac.getCar(sessionID)
    if not adminCar or not adminCar.isAdmin then return end

    local args = {}
    for word in string.gmatch(message, "%S+") do
        table.insert(args, word)
    end

    local cmd = args[1]
    if not cmd then return end

    -- 1. Comando: /power <targetID> <porcentaje>
    -- Ejemplo: /power 2 80  (Aplica un 80% de la potencia total del motor)
    if cmd == "/power" and args[2] and args[3] then
        local targetID = tonumber(args[2])
        local powerPercent = tonumber(args[3])

        if targetID and powerPercent then
            setCarPowerLimit(targetID, powerPercent)
        end

    -- 2. Comando: /ballast <targetID> <kg>
    -- Ejemplo: /ballast 2 50  (Añade 50 kg de peso extra)
    elseif cmd == "/ballast" and args[2] and args[3] then
        local targetID = tonumber(args[2])
        local weightKg = tonumber(args[3])

        if targetID and weightKg then
            setCarBallast(targetID, weightKg)
        end

    -- 3. Comando: /clearhandicap <targetID>
    -- Ejemplo: /clearhandicap 2  (Elimina todas las restricciones al piloto)
    elseif (cmd == "/clearhandicap" or cmd == "/powerclear") and args[2] then
        local targetID = tonumber(args[2])
        if targetID then
            clearCarHandicap(targetID)
        end
    end
end

--- Ajusta la restricción de potencia a un piloto
function setCarPowerLimit(sessionID, powerPercent)
    local car = ac.getCar(sessionID)
    if not car or not car.isConnected then return end

    -- Asegurar que el porcentaje está entre 10% y 100%
    if powerPercent < 10 then powerPercent = 10 end
    if powerPercent > 100 then powerPercent = 100 end

    -- En Assetto Corsa, el restrictor de admisión va de 0 a 100 (donde 100 es máxima restricción)
    local restrictorValue = 100 - powerPercent

    -- Aplicar la restricción al motor
    ac.setRestrictor(sessionID, restrictorValue)

    -- Guardar en registro
    if not playerHandicaps[sessionID] then playerHandicaps[sessionID] = {} end
    playerHandicaps[sessionID].power = powerPercent

    ac.broadcastChatMessage("BOP / HANDICAP: Coche #" .. car.raceNumber .. " (" .. car.driverName .. ") limitado al " .. powerPercent .. "% de potencia.")
end

--- Añade peso adicional al coche
function setCarBallast(sessionID, weightKg)
    local car = ac.getCar(sessionID)
    if not car or not car.isConnected then return end

    if weightKg < 0 then weightKg = 0 end

    -- Aplicar el lastre
    ac.setBallast(sessionID, weightKg)

    if not playerHandicaps[sessionID] then playerHandicaps[sessionID] = {} end
    playerHandicaps[sessionID].ballast = weightKg

    ac.broadcastChatMessage("BOP / LASTRE: Coche #" .. car.raceNumber .. " (" .. car.driverName .. ") penalizado con +" .. weightKg .. " kg.")
end

--- Restablece la potencia y peso original del coche
function clearCarHandicap(sessionID)
    local car = ac.getCar(sessionID)
    if not car or not car.isConnected then return end

    ac.setRestrictor(sessionID, 0)
    ac.setBallast(sessionID, 0)
    playerHandicaps[sessionID] = nil

    ac.sendChatMessage(sessionID, "Se han eliminado todas las restricciones de potencia y peso en tu vehículo.")
    ac.broadcastChatMessage("BOP: Restricciones eliminadas para el Coche #" .. car.raceNumber .. " (" .. car.driverName .. ").")
end