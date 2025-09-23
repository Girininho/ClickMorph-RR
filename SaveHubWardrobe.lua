-- ShowAllWardrobe.lua
-- Sistema completo para mostrar todos os itens de transmog (incluindo hidden/unobtainable)
-- e marcar todos como coletados - igual ao sistema de mounts

ClickMorphShowAllWardrobe = {}

-- Sistema principal de wardrobe
ClickMorphShowAllWardrobe.wardrobeSystem = {
    isActive = false,
    originalAPIs = {},
    unlockedAppearances = 0,
    unlockedSets = 0,
    debugMode = false,
    hiddenAppearances = {},
    hiddenSets = {},
    appearancesBuilt = false,
    setsBuilt = false
}

-- Base expandida de appearanceIDs hidden/unobtainable
ClickMorphShowAllWardrobe.HIDDEN_APPEARANCES = {
    -- Itens de desenvolvedor/GM
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    -- Itens de teste que nunca foram released
    50000, 50001, 50002, 50003, 50004, 50005,
    -- Itens removed/unused de várias expansões
    25000, 25001, 25002, 25003, 25004,
    35000, 35001, 35002, 35003, 35004,
    45000, 45001, 45002, 45003, 45004,
    -- Itens de eventos especiais não repetíveis
    15000, 15001, 15002, 15003, 15004,
    -- Variações unused de tier sets
    75000, 75001, 75002, 75003, 75004, 75005,
    -- Alpha/Beta only items
    99000, 99001, 99002, 99003, 99004
}

-- Base expandida de setIDs hidden/unobtainable
ClickMorphShowAllWardrobe.HIDDEN_SETS = {
    -- Sets de desenvolvedor
    1, 2, 3, 4, 5,
    -- Sets unused de várias expansões
    2000, 2001, 2002, 2003, 2004,
    3000, 3001, 3002, 3003, 3004,
    -- Sets de teste/debug
    9000, 9001, 9002, 9003, 9004,
    -- Sets de eventos únicos
    8000, 8001, 8002, 8003, 8004
}

-- Debug print global
local function WardrobeDebugPrint(...)
    if ClickMorphShowAllWardrobe.wardrobeSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff9966ffWardrobe:|r", message)
    end
end

-- Salvar APIs originais
function ClickMorphShowAllWardrobe.SaveOriginalAPIs()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if not system.originalAPIs.GetCategoryAppearances then
        -- APIs principais de transmog
        system.originalAPIs.GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances
        system.originalAPIs.GetAppearanceSources = C_TransmogCollection.GetAppearanceSources
        system.originalAPIs.GetAppearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo
        system.originalAPIs.GetAllAppearanceSources = C_TransmogCollection.GetAllAppearanceSources
        
        -- APIs de sets
        system.originalAPIs.GetAllSets = C_TransmogSets.GetAllSets
        system.originalAPIs.GetSetInfo = C_TransmogSets.GetSetInfo
        system.originalAPIs.GetSetSources = C_TransmogSets.GetSetSources
        
        -- APIs de busca/filtro
        if C_TransmogCollection.SetSearch then
            system.originalAPIs.SetSearch = C_TransmogCollection.SetSearch
        end
        
        -- API de verificação de coleção
        if C_TransmogCollection.PlayerHasTransmogByItemInfo then
            system.originalAPIs.PlayerHasTransmogByItemInfo = C_TransmogCollection.PlayerHasTransmogByItemInfo
        end
        
        if C_TransmogCollection.PlayerHasTransmog then
            system.originalAPIs.PlayerHasTransmog = C_TransmogCollection.PlayerHasTransmog
        end
        
        WardrobeDebugPrint("Original wardrobe APIs saved successfully")
    end
end

-- Construir lista expandida de appearances hidden
function ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.appearancesBuilt then
        WardrobeDebugPrint("Hidden appearances list already built with", #system.hiddenAppearances, "appearances")
        return system.hiddenAppearances
    end
    
    WardrobeDebugPrint("Building expanded hidden appearances list...")
    wipe(system.hiddenAppearances)
    
    -- Começar com base hardcoded
    for _, appearanceID in ipairs(ClickMorphShowAllWardrobe.HIDDEN_APPEARANCES) do
        table.insert(system.hiddenAppearances, appearanceID)
    end
    
    -- NOVO: Descobrir appearances dinamicamente através de gaps nos IDs
    local knownAppearances = {}
    
    -- Mapear appearances já conhecidas
    for categoryID = 1, 30 do
        local categoryAppearances = system.originalAPIs.GetCategoryAppearances(categoryID)
        if categoryAppearances then
            for _, appearanceID in ipairs(categoryAppearances) do
                knownAppearances[appearanceID] = true
            end
        end
    end
    
    WardrobeDebugPrint("Found", table.getn(knownAppearances), "known appearances from API")
    
    -- Descobrir gaps nos IDs (appearances missing)
    local maxKnownID = 0
    for appearanceID in pairs(knownAppearances) do
        if appearanceID > maxKnownID then
            maxKnownID = appearanceID
        end
    end
    
    local gapsFound = 0
    local maxGapsToAdd = 1000 -- Limite para não sobrecarregar
    
    for appearanceID = 1, maxKnownID do
        if not knownAppearances[appearanceID] and gapsFound < maxGapsToAdd then
            -- Verificar se é um ID válido tentando obter info
            local sources = system.originalAPIs.GetAppearanceSources(appearanceID)
            if sources and #sources > 0 then
                table.insert(system.hiddenAppearances, appearanceID)
                gapsFound = gapsFound + 1
                WardrobeDebugPrint("Found hidden appearance ID:", appearanceID)
            end
        end
    end
    
    WardrobeDebugPrint("Discovered", gapsFound, "additional hidden appearances via gap analysis")
    
    -- NOVO: Descobrir através de item scanning
    local itemScanCount = 0
    for itemID = 1, 200000 do -- Scan range de items
        if itemScanCount > 500 then break end -- Limite para performance
        
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
        if itemName and itemEquipLoc and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_NON_EQUIP" then
            -- Tentar obter appearance deste item
            local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemID)
            if appearanceID and not knownAppearances[appearanceID] then
                table.insert(system.hiddenAppearances, appearanceID)
                knownAppearances[appearanceID] = true
                itemScanCount = itemScanCount + 1
                WardrobeDebugPrint("Found hidden appearance from item scan:", appearanceID, "from item", itemID)
            end
        end
        
        -- Performance throttle
        if itemID % 1000 == 0 then
            coroutine.yield()
        end
    end
    
    -- Remover duplicatas e ordenar
    local uniqueAppearances = {}
    local seenAppearances = {}
    for _, appearanceID in ipairs(system.hiddenAppearances) do
        if not seenAppearances[appearanceID] then
            table.insert(uniqueAppearances, appearanceID)
            seenAppearances[appearanceID] = true
        end
    end
    table.sort(uniqueAppearances)
    
    system.hiddenAppearances = uniqueAppearances
    system.appearancesBuilt = true
    
    WardrobeDebugPrint("Hidden appearances list built with", #system.hiddenAppearances, "total appearances")
    return system.hiddenAppearances
end

-- Construir lista expandida de sets hidden
function ClickMorphShowAllWardrobe.BuildHiddenSetsList()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.setsBuilt then
        WardrobeDebugPrint("Hidden sets list already built with", #system.hiddenSets, "sets")
        return system.hiddenSets
    end
    
    WardrobeDebugPrint("Building expanded hidden sets list...")
    wipe(system.hiddenSets)
    
    -- Começar com base hardcoded
    for _, setID in ipairs(ClickMorphShowAllWardrobe.HIDDEN_SETS) do
        table.insert(system.hiddenSets, setID)
    end
    
    -- Descobrir sets dinamicamente
    local knownSets = {}
    local originalSets = system.originalAPIs.GetAllSets() or {}
    
    for _, setData in ipairs(originalSets) do
        if setData.setID then
            knownSets[setData.setID] = true
        end
    end
    
    WardrobeDebugPrint("Found", table.getn(knownSets), "known sets from API")
    
    -- Descobrir gaps nos setIDs
    local maxKnownSetID = 0
    for setID in pairs(knownSets) do
        if setID > maxKnownSetID then
            maxKnownSetID = setID
        end
    end
    
    local setGapsFound = 0
    local maxSetGaps = 200 -- Limite menor para sets
    
    for setID = 1, maxKnownSetID do
        if not knownSets[setID] and setGapsFound < maxSetGaps then
            -- Tentar obter info do set
            local setInfo = system.originalAPIs.GetSetInfo(setID)
            if setInfo and setInfo.name then
                table.insert(system.hiddenSets, setID)
                setGapsFound = setGapsFound + 1
                WardrobeDebugPrint("Found hidden set ID:", setID, "named:", setInfo.name)
            end
        end
    end
    
    WardrobeDebugPrint("Discovered", setGapsFound, "additional hidden sets via gap analysis")
    
    -- Remover duplicatas e ordenar
    local uniqueSets = {}
    local seenSets = {}
    for _, setID in ipairs(system.hiddenSets) do
        if not seenSets[setID] then
            table.insert(uniqueSets, setID)
            seenSets[setID] = true
        end
    end
    table.sort(uniqueSets)
    
    system.hiddenSets = uniqueSets
    system.setsBuilt = true
    
    WardrobeDebugPrint("Hidden sets list built with", #system.hiddenSets, "total sets")
    return system.hiddenSets
end

-- Gerar appearances extras para categoria
function ClickMorphShowAllWardrobe.GenerateExtraAppearances(categoryID)
    local extraAppearances = {}
    local hiddenAppearances = ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
    
    -- Adicionar todas as appearances hidden/unobtainable
    for _, appearanceID in ipairs(hiddenAppearances) do
        table.insert(extraAppearances, appearanceID)
    end
    
    WardrobeDebugPrint("Generated", #extraAppearances, "extra appearances for category", categoryID)
    return extraAppearances
end

-- Instalar hooks do sistema
function ClickMorphShowAllWardrobe.InstallWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    WardrobeDebugPrint("Installing wardrobe hooks...")
    
    -- Hook GetCategoryAppearances - EXPANDE A LISTA
    C_TransmogCollection.GetCategoryAppearances = function(categoryID)
        local appearances = system.originalAPIs.GetCategoryAppearances(categoryID) or {}
        
        WardrobeDebugPrint("GetCategoryAppearances called for category", categoryID)
        WardrobeDebugPrint("Original count:", #appearances)
        
        -- Adicionar appearances hidden/unobtainable
        local extraAppearances = ClickMorphShowAllWardrobe.GenerateExtraAppearances(categoryID)
        for _, extraApp in ipairs(extraAppearances) do
            table.insert(appearances, extraApp)
        end
        
        WardrobeDebugPrint("Expanded count:", #appearances)
        return appearances
    end
    
    -- Hook GetAppearanceSourceInfo - MARCA TUDO COMO COLETADO
    C_TransmogCollection.GetAppearanceSourceInfo = function(sourceID)
        local info = system.originalAPIs.GetAppearanceSourceInfo(sourceID)
        
        if info then
            -- FORÇAR como coletado e usável
            info.isCollected = true
            info.isUsable = true
            info.useError = nil
            info.useErrorType = nil
            
            WardrobeDebugPrint("Marked source", sourceID, "as collected:", info.name or "Unknown")
            return info
        end
        
        -- Se não existe info original, criar info fake mas válida
        WardrobeDebugPrint("Creating fake info for source", sourceID)
        return {
            sourceID = sourceID,
            isCollected = true,
            isUsable = true,
            sourceType = 1, -- SOURCEFILTER_UNKNOWN
            quality = 4, -- Epic quality por padrão
            name = "Hidden Item",
            useError = nil,
            useErrorType = nil
        }
    end
    
    -- Hook GetAppearanceSources - garante que sources existam
    C_TransmogCollection.GetAppearanceSources = function(appearanceID)
        local sources = system.originalAPIs.GetAppearanceSources(appearanceID)
        
        if sources and #sources > 0 then
            WardrobeDebugPrint("Found", #sources, "sources for appearance", appearanceID)
            return sources
        end
        
        -- Se não tem sources, criar um source fake
        WardrobeDebugPrint("Creating fake source for appearance", appearanceID)
        return {appearanceID} -- Usar o próprio appearanceID como sourceID
    end
    
    -- Hook GetAllAppearanceSources
    C_TransmogCollection.GetAllAppearanceSources = function(appearanceID)
        local sources = system.originalAPIs.GetAllAppearanceSources(appearanceID)
        
        if sources and #sources > 0 then
            return sources
        end
        
        -- Criar source fake se necessário
        return {appearanceID}
    end
    
    -- Hook PlayerHasTransmog - SEMPRE RETORNA TRUE
    if system.originalAPIs.PlayerHasTransmog then
        C_TransmogCollection.PlayerHasTransmog = function(itemID, itemModID)
            WardrobeDebugPrint("PlayerHasTransmog called for item", itemID, "mod", itemModID, "- returning TRUE")
            return true
        end
    end
    
    -- Hook PlayerHasTransmogByItemInfo - SEMPRE RETORNA TRUE
    if system.originalAPIs.PlayerHasTransmogByItemInfo then
        C_TransmogCollection.PlayerHasTransmogByItemInfo = function(itemInfo)
            WardrobeDebugPrint("PlayerHasTransmogByItemInfo called - returning TRUE")
            return true
        end
    end
    
    -- HOOKS DE SETS
    
    -- Hook GetAllSets - EXPANDE LISTA DE SETS
    C_TransmogSets.GetAllSets = function()
        local sets = system.originalAPIs.GetAllSets() or {}
        local originalCount = #sets
        
        WardrobeDebugPrint("GetAllSets called, original count:", originalCount)
        
        -- Adicionar sets hidden
        local hiddenSets = ClickMorphShowAllWardrobe.BuildHiddenSetsList()
        for _, setID in ipairs(hiddenSets) do
            local setInfo = system.originalAPIs.GetSetInfo(setID)
            if setInfo then
                -- Marcar como coletado
                setInfo.collected = true
                setInfo.favorite = false
                setInfo.limitedTimeSet = false
                table.insert(sets, setInfo)
            else
                -- Criar info fake para set
                table.insert(sets, {
                    setID = setID,
                    name = "Hidden Set " .. setID,
                    description = "Unobtainable set",
                    collected = true,
                    favorite = false,
                    limitedTimeSet = false,
                    label = 1,
                    expansionID = 0,
                    patchID = 0,
                    uiOrder = 999,
                    classMask = 0,
                    hiddenUntilCollected = false,
                    requiredFaction = nil
                })
            end
        end
        
        WardrobeDebugPrint("Expanded sets count:", #sets)
        return sets
    end
    
    -- Hook GetSetInfo - MARCA SET COMO COLETADO
    C_TransmogSets.GetSetInfo = function(setID)
        local info = system.originalAPIs.GetSetInfo(setID)
        
        if info then
            info.collected = true
            info.favorite = false
            WardrobeDebugPrint("Marked set", setID, "as collected:", info.name)
            return info
        end
        
        -- Criar info fake se não existir
        WardrobeDebugPrint("Creating fake info for set", setID)
        return {
            setID = setID,
            name = "Hidden Set " .. setID,
            description = "Unobtainable transmog set",
            collected = true,
            favorite = false,
            limitedTimeSet = false,
            label = 1,
            expansionID = 0,
            patchID = 0,
            uiOrder = 999,
            classMask = 0,
            hiddenUntilCollected = false,
            requiredFaction = nil
        }
    end
    
    system.isActive = true
    WardrobeDebugPrint("Wardrobe hooks installed successfully")
end

-- Ativar sistema de wardrobe
function ClickMorphShowAllWardrobe.ActivateWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.isActive then
        WardrobeDebugPrint("Wardrobe system already active")
        print("|cff00ff00ClickMorph Wardrobe:|r System already active!")
        return
    end
    
    WardrobeDebugPrint("Activating wardrobe unlock system...")
    
    -- Salvar APIs originais
    ClickMorphShowAllWardrobe.SaveOriginalAPIs()
    
    -- Instalar hooks
    ClickMorphShowAllWardrobe.InstallWardrobe()
    
    -- Construir listas de items hidden (async para não travrar)
    C_Timer.After(0.1, function()
        ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
    end)
    
    C_Timer.After(0.2, function()
        ClickMorphShowAllWardrobe.BuildHiddenSetsList()
    end)
    
    -- Refresh da UI após um delay
    C_Timer.After(1, function()
        ClickMorphShowAllWardrobe.RefreshWardrobe()
        
        local appearanceCount = #system.hiddenAppearances
        local setCount = #system.hiddenSets
        
        print("|cff00ff00ClickMorph Wardrobe:|r Unlocked " .. appearanceCount .. " hidden appearances and " .. setCount .. " hidden sets!")
        print("|cff00ff00ClickMorph Wardrobe:|r All transmog items are now marked as collected!")
        WardrobeDebugPrint("Activation complete")
    end)
end

-- Refresh da interface do wardrobe
function ClickMorphShowAllWardrobe.RefreshWardrobe()
    WardrobeDebugPrint("Refreshing wardrobe interface...")
    
    -- Refresh do Collections frame se estiver aberto
    if CollectionsJournal and CollectionsJournal:IsVisible() then
        local selectedTab = CollectionsJournal.selectedTab
        if selectedTab and selectedTab == 5 then -- Wardrobe tab
            WardrobeCollectionFrame_OnShow(WardrobeCollectionFrame)
            
            -- Refresh da aba ativa
            local activeFrame = WardrobeCollectionFrame.activeFrame
            if activeFrame and activeFrame.RefreshItems then
                activeFrame:RefreshItems()
            end
            
            -- Force refresh das várias abas
            if WardrobeCollectionFrame.ItemsCollectionFrame then
                WardrobeCollectionFrameTab1_OnClick(WardrobeCollectionFrameTab1)
            end
        end
    end
    
    -- Forçar atualização de eventos
    C_Timer.After(0.1, function()
        if CollectionsJournal then
            CollectionsJournal:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
        end
    end)
    
    WardrobeDebugPrint("Wardrobe refresh completed")
end

-- Reverter sistema
function ClickMorphShowAllWardrobe.RevertWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if not system.isActive then
        print("|cff00ff00ClickMorph Wardrobe:|r System not active")
        return
    end
    
    WardrobeDebugPrint("Reverting wardrobe system to original state...")
    
    -- Restaurar APIs originais
    if system.originalAPIs.GetCategoryAppearances then
        C_TransmogCollection.GetCategoryAppearances = system.originalAPIs.GetCategoryAppearances
    end
    if system.originalAPIs.GetAppearanceSources then
        C_TransmogCollection.GetAppearanceSources = system.originalAPIs.GetAppearanceSources
    end
    if system.originalAPIs.GetAppearanceSourceInfo then
        C_TransmogCollection.GetAppearanceSourceInfo = system.originalAPIs.GetAppearanceSourceInfo
    end
    if system.originalAPIs.GetAllSets then
        C_TransmogSets.GetAllSets = system.originalAPIs.GetAllSets
    end
    if system.originalAPIs.GetSetInfo then
        C_TransmogSets.GetSetInfo = system.originalAPIs.GetSetInfo
    end
    if system.originalAPIs.PlayerHasTransmog then
        C_TransmogCollection.PlayerHasTransmog = system.originalAPIs.PlayerHasTransmog
    end
    if system.originalAPIs.PlayerHasTransmogByItemInfo then
        C_TransmogCollection.PlayerHasTransmogByItemInfo = system.originalAPIs.PlayerHasTransmogByItemInfo
    end
    
    -- Limpar sistema
    wipe(system.originalAPIs)
    wipe(system.hiddenAppearances)
    wipe(system.hiddenSets)
    
    system.isActive = false
    system.unlockedAppearances = 0
    system.unlockedSets = 0
    system.appearancesBuilt = false
    system.setsBuilt = false
    
    -- Refresh da interface
    ClickMorphShowAllWardrobe.RefreshWardrobe()
    
    print("|cff00ff00ClickMorph Wardrobe:|r All wardrobe APIs restored to original state")
    WardrobeDebugPrint("Wardrobe revert completed")
end

-- Status do sistema
function ClickMorphShowAllWardrobe.ShowStatus()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    print("|cff00ff00=== WARDROBE SYSTEM STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Debug Mode:", system.debugMode and "ON" or "OFF")
    print("APIs Hooked:", next(system.originalAPIs) and "YES" or "NO")
    
    if system.isActive then
        print("Hidden Appearances Loaded:", #system.hiddenAppearances)
        print("Hidden Sets Loaded:", #system.hiddenSets)
        print("Appearances Cache Built:", system.appearancesBuilt and "YES" or "NO")
        print("Sets Cache Built:", system.setsBuilt and "YES" or "NO")
        
        print("\nHooked APIs:")
        for apiName, _ in pairs(system.originalAPIs) do
            print("  ✓", apiName)
        end
    end
end

-- Comandos de wardrobe
SLASH_CLICKMORPH_WARDROBE1 = "/cmwardrobe"
SlashCmdList.CLICKMORPH_WARDROBE = function(arg)
    local command = string.lower(arg or "")
    
    if command == "on" or command == "" then
        ClickMorphShowAllWardrobe.ActivateWardrobe()
    elseif command == "off" then
        ClickMorphShowAllWardrobe.RevertWardrobe()
    elseif command == "status" then
        ClickMorphShowAllWardrobe.ShowStatus()
    elseif command == "refresh" then
        ClickMorphShowAllWardrobe.RefreshWardrobe()
        print("|cff00ff00ClickMorph Wardrobe:|r Wardrobe refreshed")
    elseif command == "rebuild" then
        -- Rebuildar caches
        ClickMorphShowAllWardrobe.wardrobeSystem.appearancesBuilt = false
        ClickMorphShowAllWardrobe.wardrobeSystem.setsBuilt = false
        ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
        ClickMorphShowAllWardrobe.BuildHiddenSetsList()
        print("|cff00ff00ClickMorph Wardrobe:|r Rebuilt hidden items cache")
    elseif command == "debug" then
        ClickMorphShowAllWardrobe.wardrobeSystem.debugMode = not ClickMorphShowAllWardrobe.wardrobeSystem.debugMode
        print("|cff00ff00ClickMorph Wardrobe:|r Debug mode", ClickMorphShowAllWardrobe.wardrobeSystem.debugMode and "ON" or "OFF")
    else
        print("|cff00ff00ClickMorph Wardrobe Commands:|r")
        print("/cmwardrobe on - Activate wardrobe unlock (show all items as collected)")
        print("/cmwardrobe off - Revert to original wardrobe")
        print("/cmwardrobe status - Show detailed system status")
        print("/cmwardrobe refresh - Refresh wardrobe UI")
        print("/cmwardrobe rebuild - Rebuild hidden items cache")
        print("/cmwardrobe debug - Toggle debug mode")
        print("")
        print("|cffccccccThis system unlocks hidden/unobtainable transmog items")
        print("and marks all items as collected, similar to the mount system.|r")
    end
end

-- Inicialização
local function Initialize()
    WardrobeDebugPrint("Initializing ShowAll Wardrobe system...")
    
    -- Event frame para detectar quando Collections está carregado
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_Collections" then
            WardrobeDebugPrint("Blizzard_Collections loaded, wardrobe ready")
            C_Timer.After(1, function()
                if ClickMorphShowAllWardrobe.wardrobeSystem.isActive then
                    ClickMorphShowAllWardrobe.RefreshWardrobe()
                end
            end)
        end
    end)
end

Initialize()

print("|cff00ff00ClickMorph ShowAll Wardrobe|r loaded!")
print("Use |cffffcc00/cmwardrobe on|r to unlock all transmog appearances and sets")
print("Use |cffffcc00/cmwardrobe status|r to check system status")
WardrobeDebugPrint("ShowAllWardrobe.lua loaded successfully")