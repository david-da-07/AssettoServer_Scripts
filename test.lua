-- Envía un mensaje local cuando el script arranca en el cliente
ac.setMessage("¡Script de servidor CSP cargado correctamente!")

-- Evento cuando el piloto entra o cambia de sesión
ac.onSessionStart(function (sessionIndex, isReplay)
    ac.setMessage("¡Bienvenido al servidor!")
end)
