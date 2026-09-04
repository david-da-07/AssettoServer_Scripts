-- ============================================================================
-- GESTIÓN DE SALIDA LANZADA DETRÁS DE SAFETY CAR (ROLLING START)
-- ============================================================================

local SC_STEAM_ID = "76561198000000000"   -- Steam ID de 17 dígitos del piloto del SC
local FORMATION_SPEED_LIMIT = 90           -- Límite de velocidad en la vuelta (km/h)

-- Rango de tiempo aleatorio para la Bandera Verde cuando el líder enfoca la recta (ms)
local MIN_GREEN_DELAY = 1000               -- Mínimo 1.0 segundos
local MAX_GREEN_DELAY = 3500               -- Máximo 3.5 segundos

-- Estados: "FORMATION", "SC_IN_PITS", "GREEN_FLAG"
rollingState = "FORMATION"
local scSessionID = nil
local leaderSessionID = nil
local randomGreenTriggered = false

function onSessionPhaseChanged(phase)
    if phase == "Race" then
        rollingState = "FORMATION"
        randomGreenTriggered = false
        ac.broadcastChatMessage("=== SALIDA LANZADA TRAS SAFETY CAR (VUELTA 1) ===")
        ac.broadcastChatMessage("Formad en fila/doble fila tras el SC. Límite: " .. FORMATION_SPEED_LIMIT .. " km/h.")
    end
end

function onTick(dt)
    if rollingState == "FORMATION" then
        monitorFormationLap()
    elseif rollingState == "SC_IN_PITS" then
        monitorLeaderAcceleration()
    end
end

--- Monitoriza la vuelta de formación y detecta cuando el SC entra al Pit Lane
function monitorFormationLap()
    for _, car in pairs(ac.getCars()) do
        if car.guid == SC_STEAM_ID then
            scSessionID = car.sessionID
        end

        -- Identificar al líder de la carrera (Posición 1)
        if car.isConnected and car.racePosition == 1 and car.sessionID ~= scSessionID then
            leaderSessionID = car.sessionID
        end

        -- Avisar a quien supere el límite en la formación
        if car.isConnected and car.speedKmh > (FORMATION_SPEED_LIMIT + 10) then
            ac.sendChatMessage(car.sessionID, "¡REDUCE VELOCIDAD! Pelotón tras el Safety Car.")
        end
    end
end

--- Detectar cuando el Safety Car entra en el Pit Lane en la vuelta 1
function onCarEnteredPitLane(sessionID)
    if rollingState == "FORMATION" and sessionID == scSessionID then
        rollingState = "SC_IN_PITS"
        ac.broadcastChatMessage("=== SAFETY CAR EN PITS - LÍDER MARCA EL RITMO ===")
        ac.broadcastChatMessage("Mantened posiciones hasta la BANDER VERDE.")
    end
end

--- El servidor espera a que el líder entre a la recta principal para el retardo aleatorio de salida
function monitorLeaderAcceleration()
    if randomGreenTriggered then return end

    local leader = ac.getCar(leaderSessionID)
    if not leader then return end

    -- Comprobar si el líder entra en el último tramo / recta de meta (Spline / Porcentaje de vuelta)
    if leader.normalizedSplinePosition > 0.92 or leader.normalizedSplinePosition < 0.02 then
        randomGreenTriggered = true

        -- Generar el retardo aleatorio imprevisto para el lanzamiento
        local delay = math.random(MIN_GREEN_DELAY, MAX_GREEN_DELAY)

        ac.setTimeout(function()
            rollingState = "GREEN_FLAG"
            ac.broadcastChatMessage("=== ¡¡¡BANDERA VERDE - CARRERA LANZADA!!! ===")
        end, delay)
    end
end