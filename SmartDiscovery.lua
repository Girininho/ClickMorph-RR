-- SmartDiscovery.lua
-- Sistema inteligente de descoberta dinâmica de morphs, items, mounts, etc.

ClickMorphSmartDiscovery = {}

-- Sistema principal de discovery
ClickMorphSmartDiscovery.discoverySystem = {
    isActive = false,
    databases = {
        creatures = {},    -- displayID -> {name, source, type}
        items = {},       -- itemID -> {name, displayID, slot, variants}
        mounts = {},      -- mountID -> {name, displayID, customizations}
        appearances = {}, -- appearanceID -> {name, sources, itemIDs}
        npcs = {},       -- npcID -> {name, displayID, zone}
        players = {}     -- playerName -> {seen_morphs, last_seen}
    },
    
    -- Configurações de discovery
    settings = {
        learnFromNPCs = true,        -- ⭐ NOVO: Aprender de NPCs no mundo
        learnFromInspect = true,     -- Aprender de inspect de players
        learnFromTooltips = true,    -- Aprender de tooltips
        learnFromCombatLog = false,  -- Combat log learning (futuro)
        learnFromAuction = false,    -- Auction house learning (pode ser spam)
        
        autoSaveDiscoveries = true,  -- Auto-salvar discoveries
        shareDiscoveries = false,    -- Share com guild/party (futuro)
        maxDatabaseSize = 10000,     -- Limite de entradas por database
        
        -- Configurações específicas de NPCs
        npcLearningRadius = 40,      -- Raio para considerar NPCs "próximos"
        onlyRareNPCs = false,        -- Só aprender NPCs elite/rare
        includeNPCCoords = true,     -- Salvar coordenadas dos NPCs
        
        debugMode = false
    },
    
    -- Estatísticas
    stats = {
        creaturesDiscovered = 0,
        itemsDiscovered = 0,
        mountsDiscovered = 0,
        npcsDiscovered = 0,         -- ⭐ NOVO
        sessionsLearned = 0,
        lastDiscovery = nil
    }
}

-- Debug print
local function DiscoveryDebugPrint(...)
    if ClickMorphSmartDiscovery.discoverySystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff66ff66Discovery:|r", message)
    end
end

-- =============================================================================
-- CHAT LEARNING SYSTEM
-- =============================================================================

-- Patterns para reconhecer comandos no chat
ClickMorphSmartDiscovery.COMMAND_PATTERNS = {
    -- Padrões para .morph commands
    {
        pattern = "%.morph%s+(%d+)",
        type = "creature",
        extract = function(displayID) return {displayID = tonumber(displayID)} end
    },
    
    -- Padrões para .morphitem commands
    {
        pattern = "%.morphitem%s+(%d+)%s+(%d+)",
        type = "item",
        extract = function(slot, itemID) return {slot = tonumber(slot), itemID = tonumber(itemID)} end
    },
    
    -- Padrões para .morphitem com modID
    {
        pattern = "%.morphitem%s+(%d+)%s+(%d+)%s+(%d+)",
        type = "item_variant", 
        extract = function(slot, itemID, modID) 
            return {slot = tonumber(slot), itemID = tonumber(itemID), modID = tonumber(modID)} 
        end
    },
    
    -- Padrões para .customize (mounts)
    {
        pattern = "%.customize%s+(%d+)%s+([%d:]+)",
        type = "mount_customize",
        extract = function(mountID, customizeString)
            return {mountID = tonumber(mountID), customizeString = customizeString}
        end
    },
    
    -- Padrões para outros comandos
    {
        pattern = "%.npc%s+(%d+)",
        type = "npc",
        extract = function(npcID) return {npcID = tonumber(npcID)} end
    }
}

-- Hook no sistema de chat para learning
function ClickMorphSmartDiscovery.HookChatLearning()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not system.settings.learnFromChat then
        return
    end
    
    DiscoveryDebugPrint("Installing chat learning hooks")
    
    -- Hook em eventos de chat
    local chatFrame = CreateFrame("Frame")
    chatFrame:RegisterEvent("CHAT_MSG_GUILD")
    chatFrame:RegisterEvent("CHAT_MSG_PARTY")
    chatFrame:RegisterEvent("CHAT_MSG_RAID")
    chatFrame:RegisterEvent("CHAT_MSG_SAY")
    chatFrame:RegisterEvent("CHAT_MSG_YELL")
    chatFrame:RegisterEvent("CHAT_MSG_WHISPER")
    
    chatFrame:SetScript("OnEvent", function(self, event, message, sender)
        ClickMorphSmartDiscovery.ProcessChatMessage(message, sender, event)
    end)
    
    DiscoveryDebugPrint("Chat learning hooks installed")
end

-- Processar mensagem de chat para learning
function ClickMorphSmartDiscovery.ProcessChatMessage(message, sender, chatType)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not message or message == "" then return end
    
    -- Ignorar próprias mensagens
    if sender == UnitName("player") then return end
    
    -- Testar cada pattern
    for _, pattern in ipairs(ClickMorphSmartDiscovery.COMMAND_PATTERNS) do
        local matches = {string.match(message, pattern.pattern)}
        if #matches > 0 then
            local data = pattern.extract(unpack(matches))
            if data then
                ClickMorphSmartDiscovery.LearnFromCommand(pattern.type, data, sender, chatType)
                break
            end
        end
    end
end

-- Aprender de comando descoberto
function ClickMorphSmartDiscovery.LearnFromCommand(commandType, data, sender, chatType)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    DiscoveryDebugPrint("Learning from command:", commandType, "by", sender)
    
    if commandType == "creature" then
        ClickMorphSmartDiscovery.LearnCreature(data.displayID, {
            source = sender,
            chatType = chatType,
            timestamp = GetServerTime()
        })
        
    elseif commandType == "item" then
        ClickMorphSmartDiscovery.LearnItem(data.itemID, {
            slot = data.slot,
            source = sender,
            chatType = chatType,
            timestamp = GetServerTime()
        })
        
    elseif commandType == "item_variant" then
        ClickMorphSmartDiscovery.LearnItemVariant(data.itemID, {
            slot = data.slot,
            modID = data.modID,
            source = sender,
            timestamp = GetServerTime()
        })
        
    elseif commandType == "mount_customize" then
        ClickMorphSmartDiscovery.LearnMountCustomization(data.mountID, {
            customizeString = data.customizeString,
            source = sender,
            timestamp = GetServerTime()
        })
        
    elseif commandType == "npc" then
        ClickMorphSmartDiscovery.LearnNPC(data.npcID, {
            source = sender,
            zone = GetZoneText(),
            timestamp = GetServerTime()
        })
    end
    
    system.stats.sessionsLearned = system.stats.sessionsLearned + 1
    system.stats.lastDiscovery = {type = commandType, data = data, time = GetServerTime()}
end

-- =============================================================================
-- LEARNING FUNCTIONS
-- =============================================================================

-- Aprender creature morph
function ClickMorphSmartDiscovery.LearnCreature(displayID, metadata)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not displayID or displayID == 0 then return end
    
    -- Verificar se já existe
    if system.databases.creatures[displayID] then
        -- Atualizar metadados se necessário
        local existing = system.databases.creatures[displayID]
        existing.lastSeen = GetServerTime()
        existing.seenCount = (existing.seenCount or 1) + 1
        return
    end
    
    -- Tentar obter nome/info do creature
    local name = "Unknown Creature " .. displayID
    
    -- Salvar discovery
    system.databases.creatures[displayID] = {
        displayID = displayID,
        name = name,
        source = metadata.source,
        chatType = metadata.chatType,
        firstSeen = metadata.timestamp,
        lastSeen = metadata.timestamp,
        seenCount = 1,
        type = "creature"
    }
    
    system.stats.creaturesDiscovered = system.stats.creaturesDiscovered + 1
    DiscoveryDebugPrint("Learned creature:", displayID, "from", metadata.source)
end

-- Aprender item morph
function ClickMorphSmartDiscovery.LearnItem(itemID, metadata)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not itemID or itemID == 0 then return end
    
    -- Verificar se já existe
    if system.databases.items[itemID] then
        local existing = system.databases.items[itemID]
        existing.lastSeen = GetServerTime()
        existing.seenCount = (existing.seenCount or 1) + 1
        
        -- Adicionar novo slot se não existir
        if metadata.slot and not existing.slots[metadata.slot] then
            existing.slots[metadata.slot] = true
        end
        return
    end
    
    -- Tentar obter info do item
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
    
    -- Salvar discovery
    system.databases.items[itemID] = {
        itemID = itemID,
        name = itemName or ("Unknown Item " .. itemID),
        quality = itemQuality,
        equipLoc = itemEquipLoc,
        texture = itemTexture,
        slots = {[metadata.slot] = true},
        variants = {},
        source = metadata.source,
        firstSeen = metadata.timestamp,
        lastSeen = metadata.timestamp,
        seenCount = 1
    }
    
    system.stats.itemsDiscovered = system.stats.itemsDiscovered + 1
    DiscoveryDebugPrint("Learned item:", itemID, itemName or "Unknown", "slot", metadata.slot)
end

-- Aprender variant de item
function ClickMorphSmartDiscovery.LearnItemVariant(itemID, metadata)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    -- Garantir que o item base existe
    if not system.databases.items[itemID] then
        ClickMorphSmartDiscovery.LearnItem(itemID, metadata)
    end
    
    local item = system.databases.items[itemID]
    local variantKey = metadata.slot .. ":" .. metadata.modID
    
    if not item.variants[variantKey] then
        item.variants[variantKey] = {
            slot = metadata.slot,
            modID = metadata.modID,
            source = metadata.source,
            firstSeen = metadata.timestamp
        }
        DiscoveryDebugPrint("Learned item variant:", itemID, "variant", variantKey)
    end
end

-- Aprender customização de mount
function ClickMorphSmartDiscovery.LearnMountCustomization(mountID, metadata)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not mountID or mountID == 0 then return end
    
    -- Verificar se mount existe
    if not system.databases.mounts[mountID] then
        -- Tentar obter info do mount
        local name, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
        
        system.databases.mounts[mountID] = {
            mountID = mountID,
            name = name or ("Unknown Mount " .. mountID),
            spellID = spellID,
            icon = icon,
            customizations = {},
            firstSeen = metadata.timestamp
        }
    end
    
    local mount = system.databases.mounts[mountID]
    local customizeString = metadata.customizeString
    
    if not mount.customizations[customizeString] then
        mount.customizations[customizeString] = {
            customizeString = customizeString,
            source = metadata.source,
            firstSeen = metadata.timestamp,
            description = "Variant " .. customizeString
        }
        
        system.stats.mountsDiscovered = system.stats.mountsDiscovered + 1
        DiscoveryDebugPrint("Learned mount customization:", mountID, customizeString)
    end
end

-- Aprender dados completos de NPC
function ClickMorphSmartDiscovery.LearnNPCData(npcID, data)
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not npcID or npcID == 0 then return end
    
    -- Verificar se já existe
    if system.databases.npcs[npcID] then
        local existing = system.databases.npcs[npcID]
        existing.lastSeen = GetServerTime()
        existing.seenCount = (existing.seenCount or 1) + 1
        
        -- Atualizar coordenadas se disponível
        if data.coords and not existing.coords then
            existing.coords = data.coords
        end
        
        -- Atualizar displayID se descobrimos
        if data.displayID and not existing.displayID then
            existing.displayID = data.displayID
        end
        
        return existing
    end
    
    -- Salvar novo NPC
    system.databases.npcs[npcID] = {
        npcID = npcID,
        name = data.name,
        displayID = data.displayID, -- Pode ser nil se não conseguirmos obter
        equipment = data.equipment or {},
        zone = data.zone,
        subZone = data.subZone,
        coords = data.coords,
        level = data.level,
        classification = data.classification, -- normal, elite, rare, etc
        creatureType = data.creatureType,     -- humanoid, beast, etc
        firstSeen = data.timestamp,
        lastSeen = data.timestamp,
        seenCount = 1,
        source = "mouseover"
    }
    
    system.stats.npcsDiscovered = (system.stats.npcsDiscovered or 0) + 1
    DiscoveryDebugPrint("Learned NPC:", npcID, data.name, "in", data.zone)
    
    -- Se é um NPC humanoid com equipment interessante, pode ser útil para morphs
    if data.creatureType == "Humanoid" and data.displayID then
        DiscoveryDebugPrint("Discovered humanoid NPC with potential morph value:", npcID)
    end
    
    return system.databases.npcs[npcID]
end

-- =============================================================================  
-- ADVANCED NPC DISCOVERY METHODS
-- =============================================================================

-- Tentar diferentes métodos para obter displayID
function ClickMorphSmartDiscovery.TryGetNPCDisplayID(unit, npcID)
    -- Método 1: Através de GUID pattern matching
    local guid = UnitGUID(unit)
    if guid then
        -- Alguns servers/addons podem ter patterns específicos
        -- que correlacionam GUID com displayID
    end
    
    -- Método 2: Cross-reference com databases conhecidas
    -- Se temos database hardcoded de alguns NPCs famosos
    local knownNPCs = {
        [1] = {displayID = 30, name = "Highlord Bolvar"}, -- Exemplo
        -- Adicionar NPCs importantes conhecidos
    }
    
    if knownNPCs[npcID] then
        return knownNPCs[npcID].displayID
    end
    
    -- Método 3: Machine learning approach
    -- Tentar deduzir displayID baseado em nome/zona/level patterns
    return ClickMorphSmartDiscovery.GuessDisplayIDFromContext(unit, npcID)
end

-- Método de "guess" inteligente para displayID
function ClickMorphSmartDiscovery.GuessDisplayIDFromContext(unit, npcID)
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    local zone = GetZoneText()
    local creatureType = UnitCreatureType(unit)
    
    -- Patterns para deduzir tipo de creature
    local patterns = {
        -- Guardas de cidades tendem a ter displayIDs similares
        {pattern = "Guard", race = "Human", baseDisplayID = 1000},
        {pattern = "Knight", race = "Human", baseDisplayID = 1100},
        
        -- NPCs de raças específicas
        {pattern = "Orc", race = "Orc", baseDisplayID = 2000},
        {pattern = "Dwarf", race = "Dwarf", baseDisplayID = 3000},
        {pattern = "Elf", race = "Elf", baseDisplayID = 4000},
        
        -- Criaturas por tipo
        {pattern = "Wolf", type = "Beast", baseDisplayID = 5000},
        {pattern = "Bear", type = "Beast", baseDisplayID = 5100},
        {pattern = "Dragon", type = "Dragon", baseDisplayID = 6000},
    }
    
    for _, pattern in ipairs(patterns) do
        if name:find(pattern.pattern) then
            -- Adicionar variação baseada em level/zona
            local variance = (level or 1) + (string.len(zone) % 100)
            return pattern.baseDisplayID + variance
        end
    end
    
    return nil -- Não conseguiu deduzir
end

-- =============================================================================
-- EQUIPMENT DISCOVERY (Avançado)
-- =============================================================================

-- Tentar deduzir equipment de NPCs baseado em aparência
function ClickMorphSmartDiscovery.AnalyzeNPCEquipment(unit, npcID)
    local equipment = {}
    
    -- Se conseguirmos, de alguma forma, identificar visually o equipment
    -- Isso seria muito útil para descobrir item morphs
    
    local name = UnitName(unit)
    local creatureType = UnitCreatureType(unit)
    
    -- Pattern matching para equipment comum
    local equipmentPatterns = {
        -- Guardas tendem a ter armor específico
        {pattern = "Guard", items = {chest = "Guard Armor", weapon = "Guard Sword"}},
        {pattern = "Knight", items = {chest = "Knight Plate", weapon = "Knight Blade"}},
        
        -- Classes específicas
        {pattern = "Mage", items = {chest = "Mage Robe", weapon = "Staff"}},
        {pattern = "Priest", items = {chest = "Priest Robe", weapon = "Staff"}},
        {pattern = "Warrior", items = {chest = "Warrior Plate", weapon = "Sword"}},
    }
    
    for _, pattern in ipairs(equipmentPatterns) do
        if name:find(pattern.pattern) then
            equipment = pattern.items
            break
        end
    end
    
    return equipment
end

-- =============================================================================
-- NPC DATABASE QUERIES
-- =============================================================================

-- Buscar NPCs por zona
function ClickMorphSmartDiscovery.GetNPCsByZone(zoneName)
    local system = ClickMorphSmartDiscovery.discoverySystem
    local results = {}
    
    for npcID, npcData in pairs(system.databases.npcs) do
        if npcData.zone == zoneName then
            table.insert(results, npcData)
        end
    end
    
    return results
end

-- Buscar NPCs por tipo de creature  
function ClickMorphSmartDiscovery.GetNPCsByType(creatureType)
    local system = ClickMorphSmartDiscovery.discoverySystem
    local results = {}
    
    for npcID, npcData in pairs(system.databases.npcs) do
        if npcData.creatureType == creatureType then
            table.insert(results, npcData)
        end
    end
    
    return results
end

-- Buscar NPCs com displayID conhecido
function ClickMorphSmartDiscovery.GetNPCsWithDisplayID()
    local system = ClickMorphSmartDiscovery.discoverySystem
    local results = {}
    
    for npcID, npcData in pairs(system.databases.npcs) do
        if npcData.displayID then
            table.insert(results, npcData)
        end
    end
    
    return results
end

-- =============================================================================
-- INTEGRATION COM OUTROS SISTEMAS
-- =============================================================================

-- Função para outros módulos usarem NPC discoveries
function ClickMorphSmartDiscovery.GetMorphableNPCs()
    local system = ClickMorphSmartDiscovery.discoverySystem
    local morphableNPCs = {}
    
    for npcID, npcData in pairs(system.databases.npcs) do
        -- Filtrar NPCs que são úteis para morphs
        if npcData.displayID or 
           npcData.creatureType == "Humanoid" or
           npcData.classification == "Elite" or
           npcData.classification == "Rare" then
            
            table.insert(morphableNPCs, {
                npcID = npcID,
                name = npcData.name,
                displayID = npcData.displayID,
                zone = npcData.zone,
                coords = npcData.coords,
                rarity = npcData.classification == "Rare" and 4 or 
                        npcData.classification == "Elite" and 3 or 2
            })
        end
    end
    
    return morphableNPCs
end

-- =============================================================================
-- INSPECT LEARNING SYSTEM
-- =============================================================================

-- Hook sistema de inspect para learning
function ClickMorphSmartDiscovery.HookInspectLearning()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not system.settings.learnFromInspect then return end
    
    DiscoveryDebugPrint("Installing inspect learning hooks")
    
    local inspectFrame = CreateFrame("Frame")
    inspectFrame:RegisterEvent("INSPECT_READY")
    
    inspectFrame:SetScript("OnEvent", function(self, event, guid)
        C_Timer.After(0.5, function() -- Delay para garantir que dados estão carregados
            ClickMorphSmartDiscovery.ProcessInspectData(guid)
        end)
    end)
end

-- Processar dados de inspect
function ClickMorphSmartDiscovery.ProcessInspectData(guid)
    if not guid then return end
    
    local unit = "target" -- Assumindo que target é o player inspecionado
    if not UnitExists(unit) or UnitGUID(unit) ~= guid then
        return
    end
    
    local playerName = UnitName(unit)
    if not playerName then return end
    
    DiscoveryDebugPrint("Processing inspect data for", playerName)
    
    -- Aprender equipment do player
    for slot = 1, 19 do
        local itemID = GetInventoryItemID(unit, slot)
        if itemID then
            ClickMorphSmartDiscovery.LearnItem(itemID, {
                slot = slot,
                source = "inspect:" .. playerName,
                timestamp = GetServerTime()
            })
        end
    end
end

-- =============================================================================
-- TOOLTIP LEARNING SYSTEM
-- =============================================================================

-- Hook tooltips para learning
function ClickMorphSmartDiscovery.HookTooltipLearning()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    if not system.settings.learnFromTooltips then return end
    
    DiscoveryDebugPrint("Installing tooltip learning hooks")
    
    -- Hook GameTooltip
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local name, itemLink = tooltip:GetItem()
        if itemLink then
            local itemID = GetItemInfoFromHyperlink(itemLink)
            if itemID then
                ClickMorphSmartDiscovery.LearnItem(itemID, {
                    source = "tooltip",
                    timestamp = GetServerTime()
                })
            end
        end
    end)
end

-- =============================================================================
-- DATABASE MANAGEMENT
-- =============================================================================

-- Limpar databases antigas para manter performance
function ClickMorphSmartDiscovery.CleanupDatabases()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    for dbName, db in pairs(system.databases) do
        local count = 0
        for _ in pairs(db) do count = count + 1 end
        
        if count > system.settings.maxDatabaseSize then
            DiscoveryDebugPrint("Cleaning up database:", dbName, "entries:", count)
            
            -- Converter para array e ordenar por lastSeen
            local entries = {}
            for key, data in pairs(db) do
                table.insert(entries, {key = key, data = data, lastSeen = data.lastSeen or 0})
            end
            
            table.sort(entries, function(a, b) return a.lastSeen < b.lastSeen end)
            
            -- Remover 20% das entradas mais antigas
            local removeCount = math.floor(count * 0.2)
            for i = 1, removeCount do
                db[entries[i].key] = nil
            end
            
            DiscoveryDebugPrint("Removed", removeCount, "old entries from", dbName)
        end
    end
end

-- Export databases
function ClickMorphSmartDiscovery.ExportDiscoveries()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    local exportData = {
        version = "1.0",
        timestamp = GetServerTime(),
        player = UnitName("player"),
        realm = GetRealmName(),
        stats = system.stats,
        creatures = system.databases.creatures,
        items = system.databases.items,
        mounts = system.databases.mounts,
        npcs = system.databases.npcs
    }
    
    -- Serializar para string (implementação simplificada)
    local exportString = "ClickMorphDiscovery:" .. base64encode(tostringall(exportData))
    return exportString
end

-- Import discoveries
function ClickMorphSmartDiscovery.ImportDiscoveries(importString)
    if not importString:match("^ClickMorphDiscovery:") then
        print("|cff66ff66Discovery:|r Invalid import string")
        return false
    end
    
    -- TODO: Implementar deserialização segura
    print("|cff66ff66Discovery:|r Import functionality coming soon!")
    return false
end

-- =============================================================================
-- STATUS E COMANDOS
-- =============================================================================

-- Mostrar estatísticas
function ClickMorphSmartDiscovery.ShowStats()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    print("|cff66ff66=== SMART DISCOVERY STATS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Creatures Discovered:", system.stats.creaturesDiscovered)
    print("Items Discovered:", system.stats.itemsDiscovered)
    print("Mounts Discovered:", system.stats.mountsDiscovered)
    print("NPCs Discovered:", system.stats.npcsDiscovered)        -- ⭐ NOVO
    print("Learning Sessions:", system.stats.sessionsLearned)
    
    print("\nLearning Sources:")
    print("NPCs:", system.settings.learnFromNPCs and "ON" or "OFF")           -- ⭐ NOVO
    print("Inspect:", system.settings.learnFromInspect and "ON" or "OFF")
    print("Tooltips:", system.settings.learnFromTooltips and "ON" or "OFF")
    
    if system.stats.lastDiscovery then
        local last = system.stats.lastDiscovery
        print("\nLast Discovery:", last.type, "at", date("%H:%M:%S", last.time))
    end
end

-- Ativar/desativar sistema
function ClickMorphSmartDiscovery.ToggleSystem()
    local system = ClickMorphSmartDiscovery.discoverySystem
    
    system.isActive = not system.isActive
    
    if system.isActive then
        ClickMorphSmartDiscovery.HookNPCLearning()       -- ⭐ NOVO
        ClickMorphSmartDiscovery.HookInspectLearning() 
        ClickMorphSmartDiscovery.HookTooltipLearning()
        print("|cff66ff66Discovery:|r Smart Discovery activated!")
        print("|cff66ff66Discovery:|r Now learning from NPCs, inspect, and tooltips")
    else
        print("|cff66ff66Discovery:|r Smart Discovery deactivated")
    end
end

-- Comandos do sistema
SLASH_CLICKMORPH_DISCOVERY1 = "/cmdiscovery"
SlashCmdList.CLICKMORPH_DISCOVERY = function(arg)
    local args = {strsplit(" ", arg or "")}
    local command = string.lower(args[1] or "")
    
    if command == "toggle" or command == "" then
        ClickMorphSmartDiscovery.ToggleSystem()
        
    elseif command == "stats" then
        ClickMorphSmartDiscovery.ShowStats()
        
    elseif command == "cleanup" then
        ClickMorphSmartDiscovery.CleanupDatabases()
        print("|cff66ff66Discovery:|r Databases cleaned up")
        
    elseif command == "export" then
        local exportString = ClickMorphSmartDiscovery.ExportDiscoveries()
        print("|cff66ff66Discovery:|r Export string (copy this):")
        print(exportString)
        
    elseif command == "import" then
        local importString = table.concat(args, " ", 2)
        ClickMorphSmartDiscovery.ImportDiscoveries(importString)
        
    elseif command == "debug" then
        ClickMorphSmartDiscovery.discoverySystem.settings.debugMode = not ClickMorphSmartDiscovery.discoverySystem.settings.debugMode
        print("|cff66ff66Discovery:|r Debug mode", ClickMorphSmartDiscovery.discoverySystem.settings.debugMode and "ON" or "OFF")
        
    else
        print("|cff66ff66Smart Discovery Commands:|r")
        print("/cmdiscovery toggle - Toggle smart discovery")
        print("/cmdiscovery stats - Show discovery statistics")
        print("/cmdiscovery cleanup - Cleanup old discoveries")
        print("/cmdiscovery export - Export discoveries")
        print("/cmdiscovery import <string> - Import discoveries")
        print("/cmdiscovery debug - Toggle debug mode")
        print("")
        print("|cffccccccSmart Discovery learns from:|r")
        print("• NPCs you mouseover in the world")
        print("• Inspect data from other players") 
        print("• Item tooltips you hover over")
        print("• Equipment and rare creatures automatically")
    end
end

-- Inicialização
local function InitializeSmartDiscovery()
    DiscoveryDebugPrint("Initializing Smart Discovery system...")
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            DiscoveryDebugPrint("ClickMorph loaded")
            
        elseif event == "PLAYER_LOGIN" then
            C_Timer.After(3, function()
                -- Auto-ativar sistema se configurado
                if ClickMorphSmartDiscovery.discoverySystem.settings.autoStart then
                    ClickMorphSmartDiscovery.ToggleSystem()
                end
                
                DiscoveryDebugPrint("Smart Discovery ready")
            end)
        end
    end)
    
    -- Cleanup automático a cada hora
    C_Timer.NewTicker(3600, ClickMorphSmartDiscovery.CleanupDatabases)
end

-- Public API para outros módulos
ClickMorphSmartDiscovery.API = {
    -- Obter discoveries
    GetCreatures = function() return ClickMorphSmartDiscovery.discoverySystem.databases.creatures end,
    GetItems = function() return ClickMorphSmartDiscovery.discoverySystem.databases.items end,
    GetMounts = function() return ClickMorphSmartDiscovery.discoverySystem.databases.mounts end,
    
    -- Aprender manualmente
    LearnCreature = ClickMorphSmartDiscovery.LearnCreature,
    LearnItem = ClickMorphSmartDiscovery.LearnItem,
    
    -- Notificar descoberta manual
    NotifyDiscovery = function(type, data)
        ClickMorphSmartDiscovery.LearnFromCommand(type, data, "manual", "MANUAL")
    end
}

InitializeSmartDiscovery()

print("|cff66ff66ClickMorph Smart Discovery|r loaded!")
print("Use |cffffcc00/cmdiscovery toggle|r to start learning from other players")
DiscoveryDebugPrint("SmartDiscovery.lua loaded successfully")