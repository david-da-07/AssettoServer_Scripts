-- Envía un mensaje al chat en cuanto el script arranca en el cliente
ac.sendChatMessage("¡Script de servidor CSP cargado correctamente!")

-- Envía un mensaje al chat cuando el piloto entra a la pista
ac.on('sessionStart', function ()
    ac.sendChatMessage("¡Bienvenido al servidor!")
end)
