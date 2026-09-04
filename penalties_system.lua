-- ============================================================================
-- SISTEMA INTEGRAL DE SANCIONES AUTOMÁTICAS Y MANUALES
-- ============================================================================

-- Configuración de Tolerancias e Infracciones
local JUMP_START_SPEED = 2         -- Velocidad (km/h) para detectar salida en falso
local JUMP_START_DISTANCE = 2.5     -- Distancia extra (m) fuera del cajón asignado
local MAX_FORMATION_SPEED = 110      -- Límite de velocidad en vuelta de formación (km/h)
local PENALTY_TIME_JUMPSTART = 10   -- Segundos de penalización por defecto

-- Tipos de sanción soportados
local PenaltyMode = {
    TIME = "TIME",                   -- Agregar segundos al tiempo final
    INVALIDATE_LAP = "INVALIDATE",   -- Invalidar vuelta actual (solo Práctica/Clasificación)
    DRIVE_THROUGH = "DRIVETHROUGH", -- Drive-Through
    STOP_AND_GO = "STOPANDGO"        -- Stop & Go
}

local JUMP_START_PENALTY_TYPE = PenaltyMode.DRIVE_THROUGH

-- Registros del servidor
local penalizedJumpStart = {}
local currentSessionType = "PRACTICE" -- "PRACTICE", "QUALIFY", "RACE"
local addedTimePenalties = {}

-- ============================================================================
-- FUNCIONES DE APLICACIÓN DE SANCIONES
-- ============================================================================

--- Aplica la sanción correspondiente a un piloto
function applyPenalty(sessionID, penaltyType, parameter, reason)
    local car = ac.getCar(sessionID)
    if not car or not car.isConnected then return end

    if penaltyType == PenaltyMode.DRIVE_THROUGH then
        ac.addPenalty(sessionID, ac.PenaltyType.DriveThrough)
        ac.broadcastChatMessage("SANCIÓN MANUAL [Drive-Through]: Coche #" .. car.raceNumber .. " (" .. car.driverName .. ") - " .. reason)

    elseif penaltyType == PenaltyMode.STOP_AND_GO then
        ac.addPenalty(sessionID, ac.PenaltyType.StopAndGo)
        ac.broadcastChatMessage("SANCIÓN MANUAL [Stop & Go]: Coche #" .. car.raceNumber .. " (" .. car.driverName .. ") - " .. reason)

    elseif penaltyType == PenaltyMode.TIME then
        local seconds = parameter or 10
        addedTimePenalties[sessionID] = (addedTimePenalties[sessionID] or 0) + seconds
        ac.addPenaltyTime(sessionID, seconds)
        ac.broadcastChatMessage("SANCIÓN MANUAL [+" .. seconds .. "s]: Coche #" .. car.raceNumber .. " (" .. car.driverName .. ") - " .. reason)

    elseif penaltyType == PenaltyMode.INVALIDATE_LAP then
        if currentSessionType == "PRACTICE" or currentSessionType == "QUALIFY" then
            ac.invalidateCurrentLap(sessionID)
            ac.sendChatMessage(sessionID, "¡VUELTA INVALIDADA! Razón: " .. reason)
        else
            applyPenalty(sessionID, PenaltyMode.TIME, 5, reason .. " (Convertida a tiempo en carrera)")
        end
    end
end


-- ============================================================================
-- LECTURA DE COMANDOS DE ADMINISTRACIÓN POR CHAT
-- ============================================================================

function onChatMessage(sessionID, message)
    local adminCar = ac.getCar(sessionID)
    if not adminCar or not adminCar.isAdmin then return end

    -- Parsear comando y argumentos (ej: "/time 2 10")
    local args = {}
    for word in string.gmatch(message, "%S+") do
        table.insert(args, word)
    end

    local cmd = args[1]
    if not cmd then return end

    -- 1. Comando /dt <targetID> (Drive-Through)
    if cmd == "/dt" and args[2] then
        local targetID = tonumber(args[2])
        if targetID then
            applyPenalty(targetID, PenaltyMode.DRIVE_THROUGH, nil, "Decisión de Dirección de Carrera")
        end

    -- 2. Comando /sg <targetID> (Stop & Go)
    elseif cmd == "/sg" and args[2] then
        local targetID = tonumber(args[2])
        if targetID then
            applyPenalty(targetID, PenaltyMode.STOP_AND_GO, nil, "Decisión de Dirección de Carrera")
        end

    -- 3. Comando /time <targetID> <segundos> (Sanción de tiempo)
    elseif cmd == "/time" and args[2] and args[3] then
        local targetID = tonumber(args[2])
        local seconds = tonumber(args[3])
        if targetID and seconds then
            applyPenalty(targetID, PenaltyMode.TIME, seconds, "Decisión de Dirección de Carrera")
        end
    end
end

-- ============================================================================
-- EVENTOS DEL SERVIDOR
-- ============================================================================

function onSessionPhaseChanged(phase)
    -- Detectar tipo de sesión
    if phase == "Practice" then
        currentSessionType = "PRACTICE"
    elseif phase == "Qualify" then
        currentSessionType = "QUALIFY"
    elseif phase == "Race" then
        currentSessionType = "RACE"
        penalizedJumpStart = {}
        addedTimePenalties = {}
    end
end

function onTick(dt)
    -- Solo verificar infracciones específicas de salida durante la carrera
    if currentSessionType == "RACE" then
        
        -- 1. Detección de Salida en Falso durante la cuenta atrás
        if currentState == "COUNTDOWN" then
            checkJumpStarts()
        end

        -- 2. Detección de Adelantamientos Ilegales en Vuelta de Formación
        if currentState == "FORMATION" then
            checkFormationOvertakes()
        end
    end

    if SafetyCarState == "DEPLOYED" or SafetyCarState == "RETIRING" then
        checkSafetyCarOvertakes()
    end

    if isRedFlagActive then
        checkRedFlagOvertakes()
    end

    if rollingState == "FORMATION" or rollingState == "SC_IN_PITS" then
        checkRollingOvertakes()
    end
end

-- ============================================================================
-- MONITORIZACIÓN Y LÓGICA DE DETECCIÓN
-- ============================================================================

--- Comprueba si algún coche se mueve antes de la Bandera Verde
function checkJumpStarts()
    for _, car in pairs(ac.getCars()) do
        if car.isConnected and not penalizedJumpStart[car.sessionID] then
            local distToGrid = vec3.distance(car.position, car.gridPosition)

            if car.speedKmh > JUMP_START_SPEED or distToGrid > (3.5 + JUMP_START_DISTANCE) then
                penalizedJumpStart[car.sessionID] = true
                applyPenalty(car.sessionID, JUMP_START_PENALTY_TYPE, PENALTY_TIME_JUMPSTART, "Salida en falso (Jump Start)")
            end
        end
    end
end

--- Comprueba si algún coche adelanta durante la vuelta de formación
function checkFormationOvertakes()
    -- Lógica de comprobación de orden de posiciones en la vuelta 1
    for _, car in pairs(ac.getCars()) do
        if car.isConnected and car.racePosition < car.gridOrderPosition then
            -- El coche ha ganado puestos antes de la salida
            applyPenalty(car.sessionID, PenaltyMode.DRIVE_THROUGH, nil, "Adelantamiento en Vuelta de Formacion")
        end
    end
end

--- Evento al cruzar la línea de meta para invalidar vuelta si corta pista
function onLapCompleted(sessionID, lapTime, isValid)
    if (currentSessionType == "PRACTICE" or currentSessionType == "QUALIFY") and not isValid then
        applyPenalty(sessionID, PenaltyMode.INVALIDATE_LAP, nil, "Limites de pista excedidos")
    end
end

function checkSafetyCarOvertakes()
    for _, car in pairs(ac.getCars()) do
        -- Si un piloto gana posiciones de forma injustificada durante el Safety Car
        if car.isConnected and car.guid ~= SC_STEAM_ID then
            if car.racePosition < car.previousRacePosition then
                applyPenalty(car.sessionID, PenaltyMode.DRIVE_THROUGH, nil, "Adelantamiento bajo periodo de Safety Car")
            end
        end
    end
end

function checkRedFlagOvertakes()
    for _, car in pairs(ac.getCars()) do
        if car.isConnected and car.racePosition < car.previousRacePosition then
            applyPenalty(car.sessionID, PenaltyMode.STOP_AND_GO, nil, "Adelantamiento ilegal con Bandera Roja")
        end
    end
end

function checkRollingOvertakes()
    for _, car in pairs(ac.getCars()) do
        if car.isConnected and car.guid ~= SC_STEAM_ID then
            -- Sancionar si gana posiciones antes de la Bandera Verde
            if car.racePosition < car.previousRacePosition then
                applyPenalty(car.sessionID, PenaltyMode.DRIVE_THROUGH, nil, "Adelantamiento no autorizado antes de la Bandera Verde")
            end
        end
    end
end