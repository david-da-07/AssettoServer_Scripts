-- ============================================================================
-- SISTEMA DE AYUDA Y COMANDOS DEL SERVIDOR (/chelp)
-- ============================================================================

function onChatMessage(sessionID, message)
    local car = ac.getCar(sessionID)
    if not car then return end
    -- Escuchar el comando /chelp o /help
    if message == "/chelp" or message == "/help" then
        local car = ac.getCar(sessionID)
        if not car then return end

        sendPlayerHelp(sessionID)

        -- Si el usuario es Administrador del servidor, mostrar comandos avanzados
        if car.isAdmin then
            sendAdminHelp(sessionID)
        end
    end

    if (message == "/list" or message == "/pilotos") and car.isAdmin then
        ac.sendChatMessage(sessionID, "=== LISTA DE PILOTOS CONECTADOS ===")
        for _, player in pairs(ac.getCars()) do
            if player.isConnected then
                ac.sendChatMessage(sessionID, string.format("ID: %d | Coche #%d | %s", player.sessionID, player.raceNumber, player.driverName))
            end
        end
    end
end

--- Muestra los comandos públicos y normas generales a cualquier piloto
function sendPlayerHelp(sessionID)
    ac.sendChatMessage(sessionID, "=== COMANDOS Y GUÍA DE PILOTO ===")
    ac.sendChatMessage(sessionID, "• /chelp : Muestra esta lista de comandos de ayuda.")
    ac.sendChatMessage(sessionID, "--- REGLAS DE CARRERA ---")
    ac.sendChatMessage(sessionID, "• Vuelta 1: Vuelta de formación (Respetad límite de velocidad).")
    ac.sendChatMessage(sessionID, "• Salida en Parrilla: Deteneos en vuestro cajón asignado tras la vuelta.")
    ac.sendChatMessage(sessionID, "• Salida Lanzada: Mantened posición tras el Safety Car hasta la Bandera Verde.")
    ac.sendChatMessage(sessionID, "• Prohibido adelantar bajo Safety Car o Bandera Roja (Sanción automática).")
end

--- Muestra la lista de comandos exclusiva para Administradores
function sendAdminHelp(sessionID)
    ac.sendChatMessage(sessionID, "=== COMANDOS DE ADMINISTRACIÓN ===")
    ac.sendChatMessage(sessionID, "• /sc deploy  : Despliega el Safety Car en pista.")
    ac.sendChatMessage(sessionID, "• /sc in      : Anuncia la entrada del Safety Car a Pits en esta vuelta.")
    ac.sendChatMessage(sessionID, "• /sc clear   : Cancela el Safety Car y da Bandera Verde.")
    ac.sendChatMessage(sessionID, "• /rf         : Activa la BANDERA ROJA y limita la velocidad global.")
    ac.sendChatMessage(sessionID, "• /rfc        : Cancela la Bandera Roja y reanuda la sesión.")
    ac.sendChatMessage(sessionID, "--- SANCIONES MANUALES ---")
    ac.sendChatMessage(sessionID, "• /dt <id>    : Aplica Drive-Through al coche (ID de sesión).")
    ac.sendChatMessage(sessionID, "• /sg <id>    : Aplica Stop & Go al coche (ID de sesión).")
    ac.sendChatMessage(sessionID, "• /time <id> <seg> : Añade segundos de penalización en meta.")
    ac.sendChatMessage(sessionID, "• /power <id> <porcentaje> : Limita potencia de motor al porcentaje indicado.")
    ac.sendChatMessage(sessionID, "• /ballast <id> <kg> : Añade peso al coche de un piloto.")
    ac.sendChatMessage(sessionID, "• /clearhandicap <id> : Elimina lastres a un piloto.")
end