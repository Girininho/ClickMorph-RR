-- MagiButton.lua
-- Sistema para salvar e restaurar morphs automaticamente
-- Inclui re-aplicação automática ao trocar mapas/recarregar
-- ATUALIZADO com melhor integração ao SaveHub

ClickMorphMagiButton = {}

-- Dados salvos (persistentes entre sessões)
ClickMorphMagiButtonSV = ClickMorphMagiButtonSV or {
    lastMorph = {},
    autoRestore = true,
    interceptCommands = true,
    debugMode = false
}

-- Sistema do MagiButton
ClickMorphMagiButton.system = {
    isActive = false,
    currentMorph = {},
    eventFrame = nil,
    originalSendChatMessage = nil
}

-- Debug print específico do MagiButton
local function MagiDebugPrint(...)
    if ClickMorphMagiButtonSV.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cffff00ccMagi:|r", message)
    end
end

-- Estrutura padrão de um morph
function ClickMorphMagiButton.CreateEmptyMorph()
    return {
        race = nil,
        gender = nil,
        items = {
            [1] = nil,  -- Head
            [2] = nil,  -- Neck  
            [3] = nil,  -- Shoulder
            [4] = nil,  -- Body/Shirt
            [5] = nil,  -- Chest
            [6] = nil,  -- Belt
            [7] = nil,  -- Legs
            [8] = nil,  -- Feet
            [9] = nil,  -- Wrist
            [10] = nil, -- Hands
            [11] = nil, -- Finger1
            [12] = nil, -- Finger2
            [13] = nil, -- Trinket1
            [14] = nil, -- Trinket2
            [15] = nil, -- Back
            [16] = nil, -- Main hand
            [17] = nil, -- Off hand
            [18] = nil, -- Ranged
            [19] = nil, -- Tabard
        },
        enchants = {},
        scale = nil, -- Para .morph scale
        timestamp = time(),
        playerName = UnitName("player"),
        realmName = GetRealmName()
    }
end

-- Interceptar comandos do iMorph para salvar automaticamente
function ClickMorphMagiButton.HookSendChatMessage()
    local system = ClickMorphMagiButton.system
    
    if system.originalSendChatMessage then
        return -- Já hooked
    end
    
    system.originalSendChatMessage = SendChatMessage
    
    SendChatMessage = function(msg, chatType, language, channel)
        -- Interceptar comandos do imorph
        if msg and type(msg) == "string" and msg:sub(1, 1) == "." then
            ClickMorphMagiButton.ProcessIMorphCommand(msg)
        end
        
        -- Chamar função original
        return system.originalSendChatMessage(msg, chatType, language, channel)
    end
    
    MagiDebugPrint("SendChatMessage hooked for command interception")
end

-- Processar comando do iMorph e salvar dados
function ClickMorphMagiButton.ProcessIMorphCommand(command)
    if not ClickMorphMagiButtonSV.interceptCommands then
        return
    end
    
    MagiDebugPrint("Processing iMorph command:", command)
    
    local cmd = command:lower()
    
    -- .morph race [race] [gender]
    if cmd:match("^%.morph%s+race%s+") then
        local race, gender = cmd:match("^%.morph%s+race%s+(%d+)%s*(%d*)")
        if race then
            ClickMorphMagiButton.system.currentMorph.race = tonumber(race)
            ClickMorphMagiButton.system.currentMorph.gender = tonumber(gender) or 0
            MagiDebugPrint("Saved race:", race, "gender:", gender or "0")
        end
    
    -- .morph item [slot] [entry] [split]
    elseif cmd:match("^%.morph%s+item%s+") then
        local slot, entry, split = cmd:match("^%.morph%s+item%s+(%d+)%s+(%d+)%s*(%d*)")
        if slot and entry then
            local slotNum = tonumber(slot)
            local entryNum = tonumber(entry)
            local splitNum = tonumber(split) or 0
            
            if not ClickMorphMagiButton.system.currentMorph.items then
                ClickMorphMagiButton.system.currentMorph.items = {}
            end
            
            ClickMorphMagiButton.system.currentMorph.items[slotNum] = {
                entry = entryNum,
                split = splitNum
            }
            
            MagiDebugPrint("Saved item - slot:", slotNum, "entry:", entryNum, "split:", splitNum)
        end
    
    -- .morph scale [value]
    elseif cmd:match("^%.morph%s+scale%s+") then
        local scale = cmd:match("^%.morph%s+scale%s+([%d%.]+)")
        if scale then
            ClickMorphMagiButton.system.currentMorph.scale = tonumber(scale)
            MagiDebugPrint("Saved scale:", scale)
        end
    
    -- .morph reset [slot] 
    elseif cmd:match("^%.morph%s+reset%s+") then
        local slot = cmd:match("^%.morph%s+reset%s+(%d+)")
        if slot then
            local slotNum = tonumber(slot)
            if ClickMorphMagiButton.system.currentMorph.items then
                ClickMorphMagiButton.system.currentMorph.items[slotNum] = nil
                MagiDebugPrint("Reset slot:", slotNum)
            end
        end
    
    -- .morph reset (tudo)
    elseif cmd:match("^%.morph%s+reset%s*$") then
        ClickMorphMagiButton.system.currentMorph = ClickMorphMagiButton.CreateEmptyMorph()
        MagiDebugPrint("Full morph reset")
    end
    
    -- Auto-salvar sempre que houver mudanças
    ClickMorphMagiButton.SaveCurrentMorph()
    
    -- Notificar SaveHub se disponível
    if ClickMorphSaveHub and ClickMorphSaveHub.NotifyMorphChange then
        ClickMorphSaveHub.NotifyMorphChange(ClickMorphMagiButton.system.currentMorph)
    end
end

-- Salvar morph atual como último morph
function ClickMorphMagiButton.SaveCurrentMorph()
    local currentMorph = ClickMorphMagiButton.system.currentMorph
    currentMorph.timestamp = time()
    currentMorph.playerName = UnitName("player")
    currentMorph.realmName = GetRealmName()
    
    -- Salvar nos dados persistentes
    ClickMorphMagiButtonSV.lastMorph = CopyTable(currentMorph)
    
    MagiDebugPrint("Current morph saved to persistent storage")
end

-- Restaurar último morph salvo
function ClickMorphMagiButton.RestoreLastMorph()
    local lastMorph = ClickMorphMagiButtonSV.lastMorph
    
    if not lastMorph or not next(lastMorph) then
        print("|cffff0000MagiButton:|r No saved morph to restore")
        return false
    end
    
    print("|cff00ff00MagiButton:|r Restoring saved morph...")
    MagiDebugPrint("Starting morph restoration")
    
    local commandsApplied = 0
    
    -- Restaurar race/gender
    if lastMorph.race then
        local raceCmd = string.format(".morph race %d %d", lastMorph.race, lastMorph.gender or 0)
        SendChatMessage(raceCmd, "SAY")
        commandsApplied = commandsApplied + 1
        MagiDebugPrint("Restored race command:", raceCmd)
    end
    
    -- Restaurar items
    if lastMorph.items then
        local delay = 0
        for slot, itemData in pairs(lastMorph.items) do
            if itemData and itemData.entry then
                C_Timer.After(delay * 0.15, function()
                    local itemCmd = string.format(".morph item %d %d %d", slot, itemData.entry, itemData.split or 0)
                    SendChatMessage(itemCmd, "SAY")
                    MagiDebugPrint("Restored item command:", itemCmd)
                end)
                delay = delay + 1
                commandsApplied = commandsApplied + 1
            end
        end
    end
    
    -- Restaurar scale
    if lastMorph.scale then
        C_Timer.After(commandsApplied * 0.15, function()
            local scaleCmd = string.format(".morph scale %s", tostring(lastMorph.scale))
            SendChatMessage(scaleCmd, "SAY")
            MagiDebugPrint("Restored scale command:", scaleCmd)
        end)
        commandsApplied = commandsApplied + 1
    end
    
    -- Atualizar morph atual
    ClickMorphMagiButton.system.currentMorph = CopyTable(lastMorph)
    
    print("|cff00ff00MagiButton:|r Restored morph with", commandsApplied, "commands")
    return true
end

-- Sistema de eventos para auto-restore
function ClickMorphMagiButton.CreateEventFrame()
    local system = ClickMorphMagiButton.system
    
    if system.eventFrame then
        return system.eventFrame
    end
    
    local frame = CreateFrame("Frame", "ClickMorphMagiButtonEventFrame")
    
    -- Eventos que podem causar perda de morph
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("PLAYER_LOGIN")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        MagiDebugPrint("Event triggered:", event)
        
        if event == "PLAYER_LOGIN" then
            MagiDebugPrint("Player login - initializing MagiButton")
            C_Timer.After(5, function() -- Delay para garantir que tudo carregou
                if ClickMorphMagiButtonSV.autoRestore then
                    ClickMorphMagiButton.RestoreLastMorph()
                end
            end)
        
        elseif event == "PLAYER_ENTERING_WORLD" then
            local isLogin, isReload = ...
            if isLogin or isReload then
                MagiDebugPrint("Player entering world - login/reload detected")
                C_Timer.After(3, function()
                    if ClickMorphMagiButtonSV.autoRestore then
                        ClickMorphMagiButton.RestoreLastMorph()
                    end
                end)
            end
        
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            MagiDebugPrint("Zone changed - checking for auto-restore")
            C_Timer.After(2, function()
                if ClickMorphMagiButtonSV.autoRestore then
                    ClickMorphMagiButton.RestoreLastMorph()
                end
            end)
        end
    end)
    
    system.eventFrame = frame
    MagiDebugPrint("Event frame created and registered")
    return frame
end

-- Ativar sistema MagiButton
function ClickMorphMagiButton.Activate()
    local system = ClickMorphMagiButton.system
    
    if system.isActive then
        print("|cfffff00MagiButton:|r System already active")
        return
    end
    
    -- Hook SendChatMessage
    ClickMorphMagiButton.HookSendChatMessage()
    
    -- Criar event frame
    ClickMorphMagiButton.CreateEventFrame()
    
    -- Inicializar morph atual
    ClickMorphMagiButton.system.currentMorph = ClickMorphMagiButton.CreateEmptyMorph()
    
    system.isActive = true
    
    print("|cff00ff00MagiButton:|r System activated!")
    print("|cff00ff00MagiButton:|r Auto-restore:", ClickMorphMagiButtonSV.autoRestore and "ON" or "OFF")
    print("|cff00ff00MagiButton:|r Command interception:", ClickMorphMagiButtonSV.interceptCommands and "ON" or "OFF")
    
    MagiDebugPrint("MagiButton system fully activated")
end

-- Desativar sistema
function ClickMorphMagiButton.Deactivate()
    local system = ClickMorphMagiButton.system
    
    if not system.isActive then
        print("|cfffff00MagiButton:|r System not active")
        return
    end
    
    -- Restaurar SendChatMessage original
    if system.originalSendChatMessage then
        SendChatMessage = system.originalSendChatMessage
        system.originalSendChatMessage = nil
    end
    
    -- Unregister eventos
    if system.eventFrame then
        system.eventFrame:UnregisterAllEvents()
        system.eventFrame = nil
    end
    
    system.isActive = false
    
    print("|cff00ff00MagiButton:|r System deactivated")
    MagiDebugPrint("MagiButton system deactivated")
end

-- Obter morph atual para outros sistemas (API pública)
function ClickMorphMagiButton.GetCurrentMorph()
    return CopyTable(ClickMorphMagiButton.system.currentMorph)
end

-- Status do sistema
function ClickMorphMagiButton.ShowStatus()
    local system = ClickMorphMagiButton.system
    local lastMorph = ClickMorphMagiButtonSV.lastMorph
    
    print("|cff00ff00=== MAGIBUTTON STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Auto-restore:", ClickMorphMagiButtonSV.autoRestore and "ON" or "OFF")
    print("Command interception:", ClickMorphMagiButtonSV.interceptCommands and "ON" or "OFF")
    print("Debug mode:", ClickMorphMagiButtonSV.debugMode and "ON" or "OFF")
    
    if lastMorph and lastMorph.timestamp then
        local timeStr = date("%Y-%m-%d %H:%M:%S", lastMorph.timestamp)
        print("Last saved morph:", timeStr)
        print("Player:", (lastMorph.playerName or "Unknown") .. "@" .. (lastMorph.realmName or "Unknown"))
        
        if lastMorph.race then
            print("Race/Gender:", lastMorph.race .. "/" .. (lastMorph.gender or 0))
        end
        
        if lastMorph.scale then
            print("Scale:", lastMorph.scale)
        end
        
        if lastMorph.items then
            local itemCount = 0
            for _ in pairs(lastMorph.items) do
                itemCount = itemCount + 1
            end
            print("Morphed items:", itemCount)
        end
    else
        print("No saved morph available")
    end
    
    -- Integração info
    print("SaveHub Integration:", ClickMorphSaveHub and "AVAILABLE" or "NOT LOADED")
end

-- Comandos do MagiButton
SLASH_CLICKMORPH_MAGI1 = "/magi"
SlashCmdList.CLICKMORPH_MAGI = function(arg)
    local args = {}
    for word in arg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = string.lower(args[1] or "")
    
    if command == "on" or command == "activate" then
        ClickMorphMagiButton.Activate()
    elseif command == "off" or command == "deactivate" then
        ClickMorphMagiButton.Deactivate()
    elseif command == "restore" then
        ClickMorphMagiButton.RestoreLastMorph()
    elseif command == "save" then
        ClickMorphMagiButton.SaveCurrentMorph()
        print("|cff00ff00MagiButton:|r Current morph saved manually")
    elseif command == "autorestore" then
        ClickMorphMagiButtonSV.autoRestore = not ClickMorphMagiButtonSV.autoRestore
        print("|cff00ff00MagiButton:|r Auto-restore", ClickMorphMagiButtonSV.autoRestore and "ON" or "OFF")
    elseif command == "intercept" then
        ClickMorphMagiButtonSV.interceptCommands = not ClickMorphMagiButtonSV.interceptCommands
        print("|cff00ff00MagiButton:|r Command interception", ClickMorphMagiButtonSV.interceptCommands and "ON" or "OFF")
    elseif command == "status" then
        ClickMorphMagiButton.ShowStatus()
    elseif command == "debug" then
        ClickMorphMagiButtonSV.debugMode = not ClickMorphMagiButtonSV.debugMode
        print("|cff00ff00MagiButton:|r Debug mode", ClickMorphMagiButtonSV.debugMode and "ON" or "OFF")
    else
        print("|cff00ff00MagiButton Commands:|r")
        print("/magi on - Activate system")
        print("/magi off - Deactivate system") 
        print("/magi restore - Restore last saved morph")
        print("/magi save - Manually save current morph")
        print("/magi autorestore - Toggle auto-restore on map/reload")
        print("/magi intercept - Toggle command interception")
        print("/magi status - Show system status")
        print("/magi debug - Toggle debug mode")
        print("")
        print("Use the iMorph tab interface for enhanced functionality!")
    end
end

print("|cff00ff00ClickMorph MagiButton System|r loaded!")
print("Use |cffffcc00/magi on|r to activate auto-save/restore")
print("Enhanced SaveHub integration ready!")