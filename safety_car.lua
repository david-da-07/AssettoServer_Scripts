-- ============================================================================
-- GESTIÓN DE SAFETY CAR CONDUCIDO POR USUARIO
-- ============================================================================

-- Configuración del Safety Car
local SC_STEAM_ID = "76561198000000000"  -- Reemplaza por la Steam ID (GUID) del piloto del Safety Car
local SC_MAX_SPEED = 90                   -- Límite de velocidad del peloteo tras el SC (km/h)

-- Estados globales exportados
-- SafetyCarState: "NONE", "DEPLOYED", "RETIRING"
SafetyCarState = "NONE"
local safetyCarSessionID = nil

-- Comandos de chat para Administradores
function onChatMessage(sessionID, message)
    local car = ac.getCar(sessionID)
    if not car or not car.isAdmin then return end

    -- Comando: /sc deploy -> Despliega el Safety Car
    if message == "/sc deploy" or message == "/sc" then
        deploySafetyCar()

    -- Comando: /sc in -> El Safety Car se retira al Pit Lane en esa vuelta
    elseif message == "/sc in" then
        retireSafetyCar()

    -- Comando: /sc clear -> Cancela el procedimiento de SC inmediatamente
    elseif message == "/sc clear" then
        clearSafetyCar()
    end
end

--- Despliega el Safety Car y activa el procedimiento
function deploySafetyCar()
    SafetyCarState = "DEPLOYED"
    ac.broadcastChatMessage("=== SAFETY CAR DESPLEGADO ===")
    ac.broadcastChatMessage("PROHIBIDO ADELANTAR. Reducid la velocidad y agrupaos tras el SC.")
end

--- Notifica que el SC entra en el pit lane en la presente vuelta
function retireSafetyCar()
    if SafetyCarState == "DEPLOYED" then
        SafetyCarState = "RETIRING"
        ac.broadcastChatMessage("=== SAFETY CAR EN ESTA VUELTA ===")
        ac.broadcastChatMessage("El peloteo será controlado por el líder al entrar el SC a Pits.")
    end
end

--- Restablece el estado de Bandera Verde
function clearSafetyCar()
    SafetyCarState = "NONE"
    ac.broadcastChatMessage("=== ¡¡¡BANDERA VERDE - CARRERA REANUDADA!!! ===")
end

function onTick(dt)
    if SafetyCarState == "DEPLOYED" or SafetyCarState == "RETIRING" then
        checkSafetyCarRules()
    end
end

--- Lógica de control durante el periodo de Safety Car
function checkSafetyCarRules()
    for _, car in pairs(ac.getCars()) do
        -- Identificar si el cliente actual es el vehículo del SC
        if car.guid == SC_STEAM_ID then
            safetyCarSessionID = car.sessionID
        end

        -- Avisar a los pilotos que superen la velocidad de referencia en fase de agrupar
        if car.isConnected and car.sessionID ~= safetyCarSessionID then
            if car.speedKmh > (SC_MAX_SPEED + 15) then
                ac.sendChatMessage(car.sessionID, "¡REDUCE VELOCIDAD! Período de Safety Car activo.")
            end
        end
    end
end

--- Si el Safety Car cruza la línea de boxes al retirarse, activa Bandera Verde
function onCarEnteredPitLane(sessionID)
    if SafetyCarState == "RETIRING" and sessionID == safetyCarSessionID then
        clearSafetyCar()
    end
end