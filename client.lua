local isAutopilotActive = false
local blip = nil
local STOP_DISTANCE = 12.0

local BuckoConfig = BuckoConfig or {
    EnableWalkingAutopilot = true,
    EnableDrivingAutopilot = true,
}

RegisterCommand("autopilot", function()
    if isAutopilotActive then
        TriggerEvent('chat:addMessage', { args = { "^3Bucko Autopilot", "Already active!" } })
        return
    end

    local playerPed = PlayerPedId()
    blip = GetFirstBlipInfoId(8)

    if not DoesBlipExist(blip) then
        TriggerEvent('chat:addMessage', { args = { "^1Error", "Set a waypoint first." } })
        return
    end

    local dest = GetBlipInfoIdCoord(blip)
    isAutopilotActive = true

    if IsPedInAnyVehicle(playerPed, false) then
        if not BuckoConfig.EnableDrivingAutopilot then
            TriggerEvent('chat:addMessage', { args = { "^1Bucko Autopilot", "Driving autopilot is disabled on this server." } })
            isAutopilotActive = false
            return
        end

        local vehicle = GetVehiclePedIsIn(playerPed, false)
        TaskVehicleDriveToCoordLongrange(playerPed, vehicle, dest.x, dest.y, dest.z, 30.0, 786603, 10.0)
        TriggerEvent('chat:addMessage', { args = { "^2Bucko Autopilot", "Driving to waypoint..." } })
        DriveToWaypoint(playerPed, vehicle, dest)

    else
        if not BuckoConfig.EnableWalkingAutopilot then
            TriggerEvent('chat:addMessage', { args = { "^1Bucko Autopilot", "Walking autopilot is disabled on this server." } })
            isAutopilotActive = false
            return
        end

        TriggerEvent('chat:addMessage', { args = { "^2Bucko Autopilot", "Walking to waypoint..." } })
        WalkToWaypointSafely(playerPed, dest)
    end
end)

RegisterCommand("stopautopilot", function()
    StopAutopilot()
end)

function StopAutopilot()
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        ClearPedTasks(playerPed)
        SetVehicleHandbrake(vehicle, false)
        SetDriveTaskCruiseSpeed(playerPed, 0.0)
        SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)
        Wait(100)
    else
        ClearPedTasks(playerPed)
    end

    isAutopilotActive = false
    blip = nil

    TriggerEvent('chat:addMessage', { args = { "^3Bucko Autopilot", "Autopilot deactivated. You now have full control." } })
end

function WalkToWaypointSafely(playerPed, destination)
    CreateThread(function()
        local arrived = false

        ClearPedTasks(playerPed)

        local blockVehicleEntryThread = CreateThread(function()
            while isAutopilotActive and not arrived do
                if IsPedTryingToEnterALockedVehicle(playerPed) or IsPedGettingIntoAVehicle(playerPed) then
                    ClearPedTasks(playerPed)
                end
                Wait(200)
            end
        end)

        while isAutopilotActive and not arrived do
            local pedCoords = GetEntityCoords(playerPed)
            local distance = #(destination - pedCoords)

            if distance < STOP_DISTANCE then
                ClearPedTasks(playerPed)
                isAutopilotActive = false
                blip = nil
                TriggerEvent('chat:addMessage', { args = { "^2Bucko Autopilot", "Arrived at destination. Autopilot stopped." } })
                arrived = true
                break
            end

            TaskFollowNavMeshToCoord(playerPed, destination.x, destination.y, destination.z, 1.0, -1, 0.0, 0, 0.0)

            Wait(1000)
        end

        if blockVehicleEntryThread then
            TerminateThread(blockVehicleEntryThread)
        end
    end)
end

function DriveToWaypoint(playerPed, vehicle, destination)
    CreateThread(function()
        local arrived = false
        while isAutopilotActive and not arrived do
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(destination - vehCoords)

            if distance < STOP_DISTANCE then
                ClearPedTasks(playerPed)
                isAutopilotActive = false
                blip = nil
                TriggerEvent('chat:addMessage', { args = { "^2Bucko Autopilot", "Arrived at destination. Autopilot stopped." } })
                arrived = true
                break
            end

            Wait(1000)
        end
    end)
end
