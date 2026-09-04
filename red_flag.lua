-- ============================================================================
-- GESTIÓN DE BANDERA ROJA (SUSPENSIÓN DE CARRERA)
-- ============================================================================

local MAX_RED_FLAG_SPEED = 50   -- Límite estricto de velocidad en Bandera Roja (km/h)
isRedFlagActive = false

-- Comandos de administración por chat
function onChatMessage(sessionID, message)
    local car = ac.getCar(sessionID)
    if not car or not car.isAdmin then return end

    -- Comandos: /redflag para activar, /redflag clear para cancelar
    if message == "/redflag" or message == "/rf" then
        triggerRedFlag()
    elseif message == "/redflag clear" or message == "/rfc" then
        clearRedFlag()
    end
end

--- Activa el procedimiento de Bandera Roja
function triggerRedFlag()
    isRedFlagActive = true
    ac.broadcastChatMessage("=== ¡¡¡BANDERA ROJA - CARRERA SUSPENDIDA!!! ===")
    ac.broadcastChatMessage("REDUCID LA VELOCIDAD INMEDIATAMENTE Y REGRESAD A PITS.")
    ac.broadcastChatMessage("Prohibido adelantar. Límite de velocidad: " .. MAX_RED_FLAG_SPEED .. " km/h.")
    
    -- Forzar limitador en todos los coches
    for _, car in pairs(ac.getCars()) do
        if car.isConnected then
            ac.setPitLimiter(car.sessionID, true)
        end
    end
end

--- Cancela la Bandera Roja y prepara el relanzamiento
function clearRedFlag()
    if not isRedFlagActive then return end
    isRedFlagActive = false
    
    -- Desactivar limitadores forzados
    for _, car in pairs(ac.getCars()) do
        if car.isConnected then
            ac.setPitLimiter(car.sessionID, false)
        end
    end

    ac.broadcastChatMessage("=== BANDERA ROJA FINALIZADA ===")
    ac.broadcastChatMessage("Atentos a las instrucciones de la Dirección de Carrera para la resalida.")
end

function onTick(dt)
    if not isRedFlagActive then return end

    -- Sancionar o avisar a quien supere la velocidad o intente adelantar
    for _, car in pairs(ac.getCars()) do
        if car.isConnected then
            if car.speedKmh > (MAX_RED_FLAG_SPEED + 10) then
                ac.sendChatMessage(car.sessionID, "¡¡¡REDUCE VELOCIDAD!!! Bandera Roja activa. Límite: " .. MAX_RED_FLAG_SPEED .. " km/h")
            end
        end
    end
end