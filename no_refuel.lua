-- ============================================================================
-- PROHIBICIÓN DE REPOSTAJE EN BOXES (NO REFUELING)
-- ============================================================================

local initialFuel = {}        -- Registro del combustible al entrar a Pits [sessionID] = litros
local isRaceSession = false

function onSessionPhaseChanged(phase)
    if phase == "Race" then
        isRaceSession = true
        initialFuel = {}
    else
        isRaceSession = false
    end
end

--- Cuando un coche entra en el Pit Lane, guardamos su nivel de combustible actual
function onCarEnteredPitLane(sessionID)
    if not isRaceSession then return end
    
    local car = ac.getCar(sessionID)
    if car and car.isConnected then
        initialFuel[sessionID] = car.fuel
    end
end

function onTick(dt)
    if not isRaceSession then return end

    for _, car in pairs(ac.getCars()) do
        if car.isConnected and car.isInPitLane then
            local entryFuel = initialFuel[car.sessionID]
            
            -- Si el combustible actual es mayor que el registrado al entrar (margen de 0.5L)
            if entryFuel and car.fuel > (entryFuel + 0.5) then
                
                -- Opción A: Restablecer el combustible al nivel con el que entró
                ac.setFuel(car.sessionID, entryFuel)
                
                -- Opción B: Sancionar al piloto por infringir la norma de repostaje
                ac.addPenalty(car.sessionID, ac.PenaltyType.StopAndGo)
                ac.sendChatMessage(car.sessionID, "¡PROHIBIDO REPOSTAR! Se ha cancelado la carga de combustible y aplicado una sanción.")
                
                -- Actualizar registro para evitar bucles de sanción
                initialFuel[car.sessionID] = entryFuel
            end
        end
    end
end