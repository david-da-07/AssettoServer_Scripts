-- Configuración de la Vuelta de Formación
local MAX_SPEED_FORMATION = 90      -- Límite informativo de velocidad en la vuelta (km/h)
local GRID_DETECTION_RADIUS = 3.5   -- Margen de distancia al cajón de parrilla (metros)
local MAX_GRID_SPEED = 5            -- Velocidad máxima para considerar coche parado (km/h)
local MAX_WAIT_TIME_SECONDS = 120   -- Tiempo máximo de espera en parrilla (segundos)

-- Rango de tiempo aleatorio para la luz verde (en milisegundos)
local MIN_DELAY_GREEN = 1500        -- Mínimo: 1.5 segundos
local MAX_DELAY_GREEN = 4500        -- Máximo: 4.5 segundos

-- Estados globales de la sesión (exportados para uso en otros scripts)
-- Estados: "WARMUP", "FORMATION", "GRID_WAIT", "COUNTDOWN", "GREEN_FLAG"
currentState = "WARMUP"

local readyCars = {}
local waitTimer = 0
local timerActive = false

function onSessionPhaseChanged(phase)
    if phase == "Race" then
        currentState = "FORMATION"
        readyCars = {}
        timerActive = false
        waitTimer = 0
        ac.broadcastChatMessage("=== VUELTA DE FORMACIÓN (VUELTA 1) ===")
        ac.broadcastChatMessage("Límite: " .. MAX_SPEED_FORMATION .. " km/h. Completad la vuelta y deteneos en parrilla.")
    end
end

function onTick(dt)
    if currentState == "FORMATION" then
        checkFormationSpeed()
        checkGridArrival()
    elseif currentState == "GRID_WAIT" then
        checkGridArrival()
        
        if timerActive then
            waitTimer = waitTimer + dt
            if waitTimer >= MAX_WAIT_TIME_SECONDS then
                ac.broadcastChatMessage("=== TIEMPO LÍMITE AGOTADO: INICIANDO SALIDA ===")
                currentState = "COUNTDOWN"
                startRaceCountdown()
            end
        end
    end
end

function checkFormationSpeed()
    for _, car in pairs(ac.getCars()) do
        if car.isConnected and car.speedKmh > (MAX_SPEED_FORMATION + 5) then
            ac.sendChatMessage(car.sessionID, "¡REDUCE VELOCIDAD! Límite: " .. MAX_SPEED_FORMATION .. " km/h")
        end
    end
end

function checkGridArrival()
    local totalConnected = 0
    local totalReady = 0

    for _, car in pairs(ac.getCars()) do
        if car.isConnected then
            totalConnected = totalConnected + 1

            local distToGrid = vec3.distance(car.position, car.gridPosition)

            if distToGrid <= GRID_DETECTION_RADIUS and car.speedKmh <= MAX_GRID_SPEED then
                if not readyCars[car.sessionID] then
                    readyCars[car.sessionID] = true
                    ac.broadcastChatMessage("Coche #" .. car.raceNumber .. " posicionado.")
                end
            else
                readyCars[car.sessionID] = false
            end

            if readyCars[car.sessionID] then
                totalReady = totalReady + 1
            end
        end
    end

    if currentState == "FORMATION" and totalReady > 0 then
        currentState = "GRID_WAIT"
        timerActive = true
        ac.broadcastChatMessage("=== ESPERANDO COLOCACIÓN EN PARRILLA ===")
        ac.broadcastChatMessage("Tiempo máximo de espera: " .. MAX_WAIT_TIME_SECONDS .. " segundos.")
    end

    if totalConnected > 0 and totalReady == totalConnected and currentState == "GRID_WAIT" then
        timerActive = false
        currentState = "COUNTDOWN"
        startRaceCountdown()
    end
end

function startRaceCountdown()
    ac.broadcastChatMessage("¡TODOS LOS COCHES LISTOS!")
    
    ac.setTimeout(function()
        ac.broadcastChatMessage("3...")
    end, 1000)

    ac.setTimeout(function()
        ac.broadcastChatMessage("2...")
    end, 2000)

    ac.setTimeout(function()
        ac.broadcastChatMessage("1...")
        
        local randomDelay = math.random(MIN_DELAY_GREEN, MAX_DELAY_GREEN)
        
        ac.setTimeout(function()
            currentState = "GREEN_FLAG"
            ac.broadcastChatMessage("=== ¡¡¡BANDERA VERDE - CARRERA LANZADA!!! ===")
        end, randomDelay)

    end, 3000)
end
