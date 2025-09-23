-- SaveHub.lua
-- Sistema completo de salvamento e restore de morfas + auto-restore

ClickMorphSaveHub = {}

-- Sistema principal de saves
ClickMorphSaveHub.saveSystem = {
    saves = {},
    settings = {
        autoRestore = true,
        autoSaveOnChange = true,
        autoRestoreOnZone = true,
        maxSaves = 50,
        debugMode = false
    },
    session = {
        lastAppliedMorph = nil,
        currentMorph = nil,
        loginMorph = nil
    },
    version = "2.0"
}

-- Debug print
local function SaveDebugPrint(...)
    if ClickMorphSaveHub.saveSystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cffff6600SaveHub:|r", message)
    end
end

-- Estrutura de dados para saves
function ClickMorphSaveHub.CreateSaveData(name, morphData, extraData)
    local saveData = {
        name = name or "Unnamed Save",
        timestamp = GetServerTime(),
        playerName = UnitName("player"),
        playerRealm = GetRealmName(),
        version = ClickMorphSaveHub.saveSystem.version,
        
        -- Dados do morph
        morph = {
            type = morphData.type or "creature", -- creature, item, mount, etc
            displayID = morphData.displayID,
            itemID = morphData.itemID, -- para item morphs
            slot = morphData.slot, -- para slot-specific morphs
            modID = morphData.modID, -- para item variants
            split = morphData.split, -- para pauldron splits
            command = morphData.command -- comando completo usado
        },
        
        -- Dados extras opcionais
        extra = extraData or {},
        
        -- Título atual
        title = GetCurrentTitle(),
        
        -- Localização onde foi salvo
        zone = GetZoneText(),
        subZone = GetSubZoneText(),
        
        -- Dados de transmog (se disponível)
        transmog = ClickMorphSaveHub.GetCurrentTransmog(),
        
        -- Metadata
        description = extraData and extraData.description or "",
        tags = extraData and extraData.tags or {},
        favorite = false
    }
    
    return saveData
end

-- Obter transmog atual do player
function ClickMorphSaveHub.GetCurrentTransmog()
    local transmogData = {}
    
    -- Slots de equipment
    local slots = {
        [1] = "head",
        [2] = "neck", 
        [3] = "shoulder",
        [5] = "chest",
        [6] = "waist",
        [7] = "legs",
        [8] = "feet",
        [9] = "wrist",
        [10] = "hands",
        [15] = "back",
        [16] = "mainhand",
        [17] = "offhand"
    }
    
    for slotID, slotName in pairs(slots) do
        local itemID = GetInventoryItemID("player", slotID)
        if itemID then
            transmogData[slotName] = {
                itemID = itemID,
                slotID = slotID
            }
        end
    end
    
    return transmogData
end

-- Salvar morph atual
function ClickMorphSaveHub.SaveCurrentMorph(saveName, morphData, extraData)
    local system = ClickMorphSaveHub.saveSystem
    
    if not saveName then
        saveName = "Quick Save " .. date("%H:%M:%S")
    end
    
    -- Criar dados do save
    local saveData = ClickMorphSaveHub.CreateSaveData(saveName, morphData, extraData)
    
    -- Salvar no sistema
    system.saves[saveName] = saveData
    
    -- Atualizar sessão atual
    system.session.lastAppliedMorph = saveData
    system.session.currentMorph = saveData.morph
    
    SaveDebugPrint("Saved morph:", saveName, "Type:", saveData.morph.type, "ID:", saveData.morph.displayID)
    
    -- Cleanup: remover saves antigos se exceder limite
    ClickMorphSaveHub.CleanupOldSaves()
    
    return saveData
end

-- Auto-save quando morph é aplicado
function ClickMorphSaveHub.AutoSaveMorph(morphData)
    local system = ClickMorphSaveHub.saveSystem
    
    if not system.settings.autoSaveOnChange then
        return
    end
    
    -- Save automático com timestamp
    local autoSaveName = "Auto-Save " .. date("%m/%d %H:%M")
    ClickMorphSaveHub.SaveCurrentMorph(autoSaveName, morphData, {
        description = "Automatic save",
        tags = {"auto"}
    })
    
    SaveDebugPrint("Auto-saved morph")
end

-- Carregar save específico
function ClickMorphSaveHub.LoadSave(saveName)
    local system = ClickMorphSaveHub.saveSystem
    local saveData = system.saves[saveName]
    
    if not saveData then
        SaveDebugPrint("Save not found:", saveName)
        return false
    end
    
    SaveDebugPrint("Loading save:", saveName)
    
    -- Aplicar morph
    ClickMorphSaveHub.ApplyMorphFromSave(saveData)
    
    -- Aplicar título se configurado
    if saveData.title and saveData.title ~= GetCurrentTitle() then
        SetCurrentTitle(saveData.title)
        SaveDebugPrint("Applied title:", saveData.title)
    end
    
    -- Atualizar sessão
    system.session.currentMorph = saveData.morph
    system.session.lastAppliedMorph = saveData
    
    print("|cffff6600SaveHub:|r Loaded '" .. saveName .. "'")
    return true
end

-- Aplicar morph baseado nos dados salvos
function ClickMorphSaveHub.ApplyMorphFromSave(saveData)
    local morph = saveData.morph
    
    if not morph or not morph.displayID then
        SaveDebugPrint("Invalid morph data in save")
        return false
    end
    
    local command = ""
    
    -- Reconstruir comando baseado no tipo
    if morph.type == "creature" then
        command = ".morph " .. morph.displayID
    elseif morph.type == "item" and morph.slot then
        if morph.split then
            -- Pauldron com split
            command = ".morphitem " .. morph.slot .. " " .. morph.displayID .. " " .. morph.split
        elseif morph.modID then
            -- Item com modID
            command = ".morphitem " .. morph.slot .. " " .. morph.displayID .. " " .. morph.modID
        else
            -- Item simples
            command = ".morphitem " .. morph.slot .. " " .. morph.displayID
        end
    elseif morph.command then
        -- Usar comando salvo diretamente
        command = morph.command
    else
        -- Fallback para morph simples
        command = ".morph " .. morph.displayID
    end
    
    SaveDebugPrint("Applying command:", command)
    SendChatMessage(command, "GUILD")
    
    return true
end

-- Restore automático no login
function ClickMorphSaveHub.RestoreOnLogin()
    local system = ClickMorphSaveHub.saveSystem
    
    if not system.settings.autoRestore then
        SaveDebugPrint("Auto-restore disabled")
        return
    end
    
    local lastMorph = system.session.lastAppliedMorph
    if not lastMorph then
        SaveDebugPrint("No morph to restore")
        return
    end
    
    SaveDebugPrint("Auto-restoring last morph on login")
    
    -- Delay para garantir que player está completamente carregado
    C_Timer.After(3, function()
        ClickMorphSaveHub.ApplyMorphFromSave(lastMorph)
        print("|cffff6600SaveHub:|r Restored morph: " .. lastMorph.name)
    end)
end

-- Restore automático ao trocar de zona
function ClickMorphSaveHub.RestoreOnZoneChange()
    local system = ClickMorphSaveHub.saveSystem
    
    if not system.settings.autoRestoreOnZone then
        return
    end
    
    local currentMorph = system.session.currentMorph
    if not currentMorph then
        return
    end
    
    SaveDebugPrint("Auto-restoring morph after zone change")
    
    -- Delay pequeno para garantir que zone change terminou
    C_Timer.After(1, function()
        if system.session.lastAppliedMorph then
            ClickMorphSaveHub.ApplyMorphFromSave(system.session.lastAppliedMorph)
        end
    end)
end

-- Reset morph (usar .reset ao invés de .demorph)
function ClickMorphSaveHub.ResetMorph()
    SaveDebugPrint("Resetting morph")
    SendChatMessage(".reset", "GUILD")
    
    -- Limpar morph atual da sessão
    ClickMorphSaveHub.saveSystem.session.currentMorph = nil
end

-- Cleanup de saves antigos
function ClickMorphSaveHub.CleanupOldSaves()
    local system = ClickMorphSaveHub.saveSystem
    local maxSaves = system.settings.maxSaves
    
    -- Contar saves não-favoritos
    local saves = {}
    for name, data in pairs(system.saves) do
        if not data.favorite then
            table.insert(saves, {name = name, timestamp = data.timestamp})
        end
    end
    
    -- Ordenar por timestamp (mais antigo primeiro)
    table.sort(saves, function(a, b) return a.timestamp < b.timestamp end)
    
    -- Remover saves em excesso
    local toRemove = #saves - maxSaves
    if toRemove > 0 then
        for i = 1, toRemove do
            local saveName = saves[i].name
            system.saves[saveName] = nil
            SaveDebugPrint("Cleaned up old save:", saveName)
        end
    end
end

-- Listar saves disponíveis
function ClickMorphSaveHub.ListSaves()
    local system = ClickMorphSaveHub.saveSystem
    local count = 0
    
    print("|cffff6600=== SAVE HUB SAVES ===|r")
    
    -- Criar lista ordenada por timestamp
    local saves = {}
    for name, data in pairs(system.saves) do
        table.insert(saves, {name = name, data = data})
        count = count + 1
    end
    
    table.sort(saves, function(a, b) return a.data.timestamp > b.data.timestamp end)
    
    for _, save in ipairs(saves) do
        local data = save.data
        local favorite = data.favorite and "★" or ""
        local typeInfo = data.morph.type .. " " .. (data.morph.displayID or "?")
        local timeStr = date("%m/%d %H:%M", data.timestamp)
        
        print(string.format("%s %s - %s (%s)", favorite, save.name, typeInfo, timeStr))
    end
    
    print(string.format("Total: %d saves", count))
end

-- Deletar save
function ClickMorphSaveHub.DeleteSave(saveName)
    local system = ClickMorphSaveHub.saveSystem
    
    if system.saves[saveName] then
        system.saves[saveName] = nil
        SaveDebugPrint("Deleted save:", saveName)
        print("|cffff6600SaveHub:|r Deleted save '" .. saveName .. "'")
        return true
    end
    
    print("|cffff6600SaveHub:|r Save '" .. saveName .. "' not found")
    return false
end

-- Toggle favorito
function ClickMorphSaveHub.ToggleFavorite(saveName)
    local system = ClickMorphSaveHub.saveSystem
    local save = system.saves[saveName]
    
    if save then
        save.favorite = not save.favorite
        local status = save.favorite and "added to" or "removed from"
        print("|cffff6600SaveHub:|r '" .. saveName .. "' " .. status .. " favorites")
        return save.favorite
    end
    
    return false
end

-- Export save como string
function ClickMorphSaveHub.ExportSave(saveName)
    local system = ClickMorphSaveHub.saveSystem
    local save = system.saves[saveName]
    
    if not save then
        print("|cffff6600SaveHub:|r Save not found")
        return nil
    end
    
    -- Serializar dados básicos
    local exportData = {
        name = save.name,
        morph = save.morph,
        title = save.title,
        description = save.description or ""
    }
    
    -- Converter para string (implementação simples)
    local exportString = "ClickMorph:" .. table.concat({
        exportData.name,
        exportData.morph.type or "creature",
        exportData.morph.displayID or 0,
        exportData.title or 0,
        exportData.description
    }, ":")
    
    return exportString
end

-- Import save de string
function ClickMorphSaveHub.ImportSave(exportString)
    if not exportString:match("^ClickMorph:") then
        print("|cffff6600SaveHub:|r Invalid import string")
        return false
    end
    
    local parts = {strsplit(":", exportString)}
    
    if #parts < 5 then
        print("|cffff6600SaveHub:|r Invalid import format")
        return false
    end
    
    local name = parts[2] .. " (Imported)"
    local morphData = {
        type = parts[3],
        displayID = tonumber(parts[4]) or 0
    }
    
    local extraData = {
        description = parts[6] or "Imported save"
    }
    
    ClickMorphSaveHub.SaveCurrentMorph(name, morphData, extraData)
    print("|cffff6600SaveHub:|r Imported save '" .. name .. "'")
    
    return true
end

-- Status do sistema
function ClickMorphSaveHub.ShowStatus()
    local system = ClickMorphSaveHub.saveSystem
    
    print("|cffff6600=== SAVE HUB STATUS ===|r")
    print("Total Saves:", table.getn(system.saves))
    print("Auto-Restore:", system.settings.autoRestore and "ON" or "OFF")
    print("Auto-Save:", system.settings.autoSaveOnChange and "ON" or "OFF")
    print("Zone Restore:", system.settings.autoRestoreOnZone and "ON" or "OFF")
    print("Debug Mode:", system.settings.debugMode and "ON" or "OFF")
    
    if system.session.currentMorph then
        local morph = system.session.currentMorph
        print("Current Morph:", morph.type, morph.displayID)
    end
    
    if system.session.lastAppliedMorph then
        print("Last Applied:", system.session.lastAppliedMorph.name)
    end
end

-- Comandos do SaveHub
SLASH_CLICKMORPH_SAVEHUB1 = "/cmsave"
SlashCmdList.CLICKMORPH_SAVEHUB = function(arg)
    local args = {strsplit(" ", arg or "")}
    local command = string.lower(args[1] or "")
    
    if command == "list" or command == "" then
        ClickMorphSaveHub.ListSaves()
        
    elseif command == "load" then
        local saveName = table.concat(args, " ", 2)
        if saveName ~= "" then
            ClickMorphSaveHub.LoadSave(saveName)
        else
            print("|cffff6600SaveHub:|r Usage: /cmsave load <save name>")
        end
        
    elseif command == "delete" then
        local saveName = table.concat(args, " ", 2)
        if saveName ~= "" then
            ClickMorphSaveHub.DeleteSave(saveName)
        else
            print("|cffff6600SaveHub:|r Usage: /cmsave delete <save name>")
        end
        
    elseif command == "favorite" then
        local saveName = table.concat(args, " ", 2)
        if saveName ~= "" then
            ClickMorphSaveHub.ToggleFavorite(saveName)
        else
            print("|cffff6600SaveHub:|r Usage: /cmsave favorite <save name>")
        end
        
    elseif command == "export" then
        local saveName = table.concat(args, " ", 2)
        if saveName ~= "" then
            local exportString = ClickMorphSaveHub.ExportSave(saveName)
            if exportString then
                print("|cffff6600SaveHub:|r Export string (copy this):")
                print(exportString)
            end
        else
            print("|cffff6600SaveHub:|r Usage: /cmsave export <save name>")
        end
        
    elseif command == "import" then
        local importString = table.concat(args, ":", 2)
        if importString ~= "" then
            ClickMorphSaveHub.ImportSave(importString)
        else
            print("|cffff6600SaveHub:|r Usage: /cmsave import <export string>")
        end
        
    elseif command == "auto" then
        local system = ClickMorphSaveHub.saveSystem
        system.settings.autoRestore = not system.settings.autoRestore
        print("|cffff6600SaveHub:|r Auto-restore", system.settings.autoRestore and "ON" or "OFF")
        
    elseif command == "zone" then
        local system = ClickMorphSaveHub.saveSystem
        system.settings.autoRestoreOnZone = not system.settings.autoRestoreOnZone
        print("|cffff6600SaveHub:|r Zone auto-restore", system.settings.autoRestoreOnZone and "ON" or "OFF")
        
    elseif command == "debug" then
        local system = ClickMorphSaveHub.saveSystem
        system.settings.debugMode = not system.settings.debugMode
        print("|cffff6600SaveHub:|r Debug mode", system.settings.debugMode and "ON" or "OFF")
        
    elseif command == "status" then
        ClickMorphSaveHub.ShowStatus()
        
    elseif command == "reset" then
        ClickMorphSaveHub.ResetMorph()
        
    else
        print("|cffff6600SaveHub Commands:|r")
        print("/cmsave list - List all saves")
        print("/cmsave load <name> - Load specific save")
        print("/cmsave delete <name> - Delete save")
        print("/cmsave favorite <name> - Toggle favorite")
        print("/cmsave export <name> - Export save as string")
        print("/cmsave import <string> - Import save from string")
        print("/cmsave auto - Toggle auto-restore")
        print("/cmsave zone - Toggle zone auto-restore")
        print("/cmsave reset - Reset morph (.reset)")
        print("/cmsave status - Show system status")
        print("/cmsave debug - Toggle debug mode")
    end
end

-- Event handling
local function InitializeSaveHub()
    SaveDebugPrint("Initializing SaveHub...")
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local addonName = ...
            if addonName == "ClickMorph" then
                SaveDebugPrint("ClickMorph loaded")
            end
            
        elseif event == "PLAYER_LOGIN" then
            C_Timer.After(2, ClickMorphSaveHub.RestoreOnLogin)
            
        elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
            C_Timer.After(0.5, ClickMorphSaveHub.RestoreOnZoneChange)
            
        elseif event == "PLAYER_ENTERING_WORLD" then
            local isLogin, isReload = ...
            if isLogin or isReload then
                C_Timer.After(3, ClickMorphSaveHub.RestoreOnLogin)
            end
        end
    end)
    
    SaveDebugPrint("SaveHub initialized")
end

-- Public API para outros módulos usarem
ClickMorphSaveHub.API = {
    -- Salvar morph atual
    Save = function(name, morphData, extraData)
        return ClickMorphSaveHub.SaveCurrentMorph(name, morphData, extraData)
    end,
    
    -- Auto-save (chamado pelos módulos quando aplicam morph)
    AutoSave = function(morphData)
        ClickMorphSaveHub.AutoSaveMorph(morphData)
    end,
    
    -- Carregar save
    Load = function(name)
        return ClickMorphSaveHub.LoadSave(name)
    end,
    
    -- Reset morph
    Reset = function()
        ClickMorphSaveHub.ResetMorph()
    end
}

InitializeSaveHub()

print("|cffff6600ClickMorph SaveHub Enhanced|r loaded!")
print("Use |cffffcc00/cmsave|r for save management commands")
SaveDebugPrint("SaveHub.lua loaded successfully")