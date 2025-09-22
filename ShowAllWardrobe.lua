-- ShowAllWardrobe.lua
-- Sistema dedicado para unlock de transmog e wardrobe
-- Parte do ClickMorph ShowAll System

ClickMorphShowAllWardrobe = {}

-- Sistema de wardrobe
ClickMorphShowAllWardrobe.wardrobeSystem = {
    isActive = false,
    originalAPIs = {},
    unlockedAppearances = 0,
    unlockedSets = 0
}

-- Sistema de debug específico do wardrobe
ClickMorphShowAllWardrobe.debugMode = false
local function WardrobeDebugPrint(...)
    if ClickMorphShowAllWardrobe.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cffff6600Wardrobe:|r", message)
    end
end

-- Mapeamento de categorias de transmog
ClickMorphShowAllWardrobe.TRANSMOG_CATEGORIES = {
    [1] = "Head",
    [2] = "Shoulder",
    [3] = "Back",
    [4] = "Chest",
    [5] = "Shirt",
    [6] = "Tabard",
    [7] = "Wrist",
    [8] = "Hands",
    [9] = "Waist",
    [10] = "Legs",
    [11] = "Feet",
    [12] = "Main Hand",
    [13] = "Off Hand",
    [14] = "Ranged",
    [15] = "Two-Hand"
}

-- Salvar APIs originais do wardrobe
function ClickMorphShowAllWardrobe.SaveOriginalAPIs()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem

    if not system.originalAPIs.GetAllAppearanceSources then
        system.originalAPIs.GetAllAppearanceSources = C_TransmogCollection.GetAllAppearanceSources
        system.originalAPIs.GetAppearanceSources = C_TransmogCollection.GetAppearanceSources
        system.originalAPIs.GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances
        system.originalAPIs.GetAppearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo

        system.originalAPIs.GetAllSets = C_TransmogSets.GetAllSets
        system.originalAPIs.GetSetInfo = C_TransmogSets.GetSetInfo
        system.originalAPIs.GetSetsContainingSourceID = C_TransmogSets.GetSetsContainingSourceID

        if C_TransmogCollection.GetAppearanceInfoBySource then
            system.originalAPIs.GetAppearanceInfoBySource = C_TransmogCollection.GetAppearanceInfoBySource
        end

        WardrobeDebugPrint("Original wardrobe APIs saved successfully")
    end
end

-- Sistema para descobrir aparências hidden/unobtainable
ClickMorphShowAllWardrobe.hiddenAppearances = {}
ClickMorphShowAllWardrobe.hiddenBuilt = false

-- Gerar aparências extras por categoria
function ClickMorphShowAllWardrobe.GenerateExtraAppearances(categoryID)
    local extraAppearances = {}

    local extraRanges = {
        [1] = {start = 25001, count = 200},
        [2] = {start = 25201, count = 150},
        [3] = {start = 25351, count = 100},
        [4] = {start = 25451, count = 300},
        [12] = {start = 26001, count = 500}
    }

    local range = extraRanges[categoryID]
    if range then
        WardrobeDebugPrint("Adding", range.count, "extra appearances for category", categoryID)
        for i = 1, range.count do
            local visualID = range.start + i
            table.insert(extraAppearances, {
                visualID = visualID,
                sourceID = visualID,
                isCollected = true,
                isUsable = true,
                isValidAppearanceForPlayer = true,
                hasNoSourceInfo = false,
                isHideVisual = false,
                canEnchant = true,
                sourceType = 1,
                quality = 4,
                uiOrder = visualID,
                isExtra = true
            })
        end
    end

    WardrobeDebugPrint("Generated", #extraAppearances, "extra appearances for category", categoryID)
    return extraAppearances
end

-- Hook principal das APIs de transmog
function ClickMorphShowAllWardrobe.HookTransmogAPIs()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    WardrobeDebugPrint("Starting transmog APIs hook...")

    -- Hook GetAllAppearanceSources
    C_TransmogCollection.GetAllAppearanceSources = function(visualID)
        local sources = system.originalAPIs.GetAllAppearanceSources(visualID)
        if sources and type(sources) == "table" and #sources > 0 then
            for _, source in ipairs(sources) do
                if type(source) == "table" then
                    source.isCollected = true
                    source.isUsable = true
                    source.isValidAppearanceForPlayer = true
                    source.hasNoSourceInfo = false
                    source.isHideVisual = false
                end
            end
            return sources
        end
        return {{
            sourceID = visualID or 0,
            isCollected = true,
            isUsable = true,
            isValidAppearanceForPlayer = true,
            visualID = visualID or 0,
            hasNoSourceInfo = false,
            isHideVisual = false,
            sourceType = 1,
            quality = 4
        }}
    end

    -- Hook GetAppearanceSources
    C_TransmogCollection.GetAppearanceSources = function(visualID)
        return C_TransmogCollection.GetAllAppearanceSources(visualID)
    end

    -- Hook GetCategoryAppearances
    C_TransmogCollection.GetCategoryAppearances = function(categoryID, ...)
        local appearances = system.originalAPIs.GetCategoryAppearances(categoryID, ...) or {}
        for _, appearance in ipairs(appearances) do
            if type(appearance) == "table" then
                appearance.isCollected = true
                appearance.isUsable = true
                appearance.isValidAppearanceForPlayer = true
                appearance.hasNoSourceInfo = false
                appearance.isHideVisual = false
            end
        end

        local extraAppearances = ClickMorphShowAllWardrobe.GenerateExtraAppearances(categoryID)
        for _, extraApp in ipairs(extraAppearances) do
            table.insert(appearances, extraApp)
        end

        WardrobeDebugPrint("Category", categoryID, "expanded to", #appearances, "appearances")
        return appearances
    end

    -- Hook GetAppearanceSourceInfo
    if system.originalAPIs.GetAppearanceSourceInfo then
        C_TransmogCollection.GetAppearanceSourceInfo = function(sourceID)
            local info = system.originalAPIs.GetAppearanceSourceInfo(sourceID)
            if info then
                info.isCollected = true
                info.isUsable = true
                return info
            end
            return {
                sourceID = sourceID,
                isCollected = true,
                isUsable = true,
                sourceType = 1,
                quality = 4
            }
        end
    end

    WardrobeDebugPrint("Transmog appearance APIs hooked successfully")
end

-- Sistema para descobrir conjuntos hidden/unobtainable
ClickMorphShowAllWardrobe.hiddenSets = {}
ClickMorphShowAllWardrobe.hiddenSetsBuilt = false

-- Construir lista de conjuntos hidden
function ClickMorphShowAllWardrobe.BuildHiddenSetsList()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem

    if ClickMorphShowAllWardrobe.hiddenSetsBuilt then
        WardrobeDebugPrint("Hidden sets list already built with", #ClickMorphShowAllWardrobe.hiddenSets, "sets")
        return ClickMorphShowAllWardrobe.hiddenSets
    end

    WardrobeDebugPrint("Building hidden sets list...")
    wipe(ClickMorphShowAllWardrobe.hiddenSets)

    local displayedSets = {}
    local originalSets = system.originalAPIs.GetAllSets() or {}
    for _, setData in ipairs(originalSets) do
        if setData.setID then
            displayedSets[setData.setID] = true
        end
    end

    local searchRanges = {
    {start = 1, ["end"] = 500},
    {start = 501, ["end"] = 1000},
    {start = 1001, ["end"] = 1500},
    {start = 1501, ["end"] = 2000},
    {start = 2001, ["end"] = 2500},
    {start = 2501, ["end"] = 3000},
    {start = 3001, ["end"] = 3500},
    {start = 3501, ["end"] = 4000},
    {start = 4001, ["end"] = 4500},
    {start = 4501, ["end"] = 5000}
}


    local hiddenFound = 0
    for _, range in ipairs(searchRanges) do
        WardrobeDebugPrint("Scanning set range", range.start, "-", range["end"])
        for setID = range.start, range["end"] do
            if not displayedSets[setID] then
                local setInfo = system.originalAPIs.GetSetInfo(setID)
                if setInfo and setInfo.name and setInfo.name ~= "" then
                    table.insert(ClickMorphShowAllWardrobe.hiddenSets, {
                        setID = setID,
                        name = setInfo.name,
                        baseSetID = setInfo.baseSetID or setID,
                        description = setInfo.description or "",
                        label = setInfo.label or "",
                        expansionID = setInfo.expansionID or 0,
                        patchID = setInfo.patchID or 0,
                        uiOrder = setInfo.uiOrder or setID,
                        classMask = setInfo.classMask or -1,
                        collected = true,
                        favorite = false,
                        limitedTimeSet = false,
                        validForCharacter = true,
                        canCollect = true,
                        sources = setInfo.sources or {},
                        isHidden = true
                    })
                    hiddenFound = hiddenFound + 1
                end
            end
        end
    end

    ClickMorphShowAllWardrobe.hiddenSetsBuilt = true
    WardrobeDebugPrint("Hidden sets scan completed. Found", hiddenFound, "hidden sets")

    return ClickMorphShowAllWardrobe.hiddenSets
end



-- Hook das APIs de sets
function ClickMorphShowAllWardrobe.HookSetAPIs()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    WardrobeDebugPrint("Starting set APIs hook...")
    
    -- Hook GetAllSets
    C_TransmogSets.GetAllSets = function()
        local sets = system.originalAPIs.GetAllSets() or {}
        
        -- Unlock conjuntos originais
        for _, set in ipairs(sets) do
            if type(set) == "table" then
                set.collected = true
                set.favorite = false
                set.limitedTimeSet = false
                set.validForCharacter = true
                set.canCollect = true
                
                if set.sources then
                    for _, source in ipairs(set.sources) do
                        if type(source) == "table" then
                            source.isCollected = true
                            source.isUsable = true
                        end
                    end
                end
            end
        end
        
        -- Adicionar conjuntos hidden
        local hiddenSets = ClickMorphShowAllWardrobe.BuildHiddenSetsList()
        for _, hiddenSet in ipairs(hiddenSets) do
            table.insert(sets, hiddenSet)
        end
        
        local totalSets = #sets
        local originalCount = #(system.originalAPIs.GetAllSets() or {})
        local hiddenCount = totalSets - originalCount
        
        WardrobeDebugPrint("Returning", totalSets, "total sets (", originalCount, "original +", hiddenCount, "hidden )")
        system.unlockedSets = totalSets
        
        return sets
    end
    
    -- Hook GetSetInfo
    C_TransmogSets.GetSetInfo = function(setID)
        local setInfo = system.originalAPIs.GetSetInfo(setID)
        if setInfo then
            setInfo.collected = true
            setInfo.validForCharacter = true
            setInfo.canCollect = true
            return setInfo
        end
        
        -- Procurar em hidden sets
        for _, hiddenSet in ipairs(ClickMorphShowAllWardrobe.hiddenSets) do
            if hiddenSet.setID == setID then
                WardrobeDebugPrint("Returning info for hidden set:", hiddenSet.name)
                return hiddenSet
            end
        end
        
        return nil
    end
    
    WardrobeDebugPrint("Set APIs hooked successfully")
end

-- Função principal para ativar o sistema de wardrobe
function ClickMorphShowAllWardrobe.ActivateWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.isActive then
        print("|cfffff00ClickMorph Wardrobe:|r System already active!")
        return
    end
    
    WardrobeDebugPrint("Activating ShowAll Wardrobe system...")
    
    ClickMorphShowAllWardrobe.SaveOriginalAPIs()
    ClickMorphShowAllWardrobe.HookTransmogAPIs()
    ClickMorphShowAllWardrobe.HookSetAPIs()
    
    system.isActive = true
    ClickMorphShowAllWardrobe.RefreshWardrobe()
    
    print("|cff00ff00ClickMorph Wardrobe:|r All transmog appearances and sets unlocked!")
    print("|cff00ff00ClickMorph:|r Open your Collections -> Appearance tab to see everything")
    
    WardrobeDebugPrint("Wardrobe system activated successfully")
end

-- Refresh do wardrobe
function ClickMorphShowAllWardrobe.RefreshWardrobe()
    if WardrobeCollectionFrame and WardrobeCollectionFrame:IsShown() then
        local itemsFrame = WardrobeCollectionFrame.ItemsCollectionFrame
        if itemsFrame then
            pcall(function()
                if itemsFrame.RefreshVisualsList then
                    itemsFrame:RefreshVisualsList()
                end
                if itemsFrame.UpdateItems then
                    itemsFrame:UpdateItems()
                end
            end)
            WardrobeDebugPrint("Wardrobe UI refreshed")
        end
    end
end

-- Reverter wardrobe para estado original
function ClickMorphShowAllWardrobe.RevertWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if not system.isActive then
        print("|cfffff00ClickMorph Wardrobe:|r No wardrobe system active to revert")
        return
    end
    
    WardrobeDebugPrint("Reverting wardrobe APIs...")
    
    if system.originalAPIs.GetAllAppearanceSources then
        C_TransmogCollection.GetAllAppearanceSources = system.originalAPIs.GetAllAppearanceSources
    end
    if system.originalAPIs.GetAppearanceSources then
        C_TransmogCollection.GetAppearanceSources = system.originalAPIs.GetAppearanceSources
    end
    if system.originalAPIs.GetCategoryAppearances then
        C_TransmogCollection.GetCategoryAppearances = system.originalAPIs.GetCategoryAppearances
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
    
    wipe(system.originalAPIs)
    system.isActive = false
    system.unlockedAppearances = 0
    system.unlockedSets = 0
    
    ClickMorphShowAllWardrobe.RefreshWardrobe()
    
    print("|cff00ff00ClickMorph Wardrobe:|r All wardrobe APIs restored to original state")
    WardrobeDebugPrint("Wardrobe revert completed")
end

-- Status do sistema de wardrobe
function ClickMorphShowAllWardrobe.ShowStatus()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    print("|cff00ff00=== WARDROBE SYSTEM STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Debug Mode:", ClickMorphShowAllWardrobe.debugMode and "ON" or "OFF")
    print("APIs Hooked:", next(system.originalAPIs) and "YES" or "NO")
    
    if system.isActive then
        print("Unlocked Sets:", system.unlockedSets)
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
    elseif command == "debug" then
        ClickMorphShowAllWardrobe.debugMode = not ClickMorphShowAllWardrobe.debugMode
        print("|cff00ff00ClickMorph Wardrobe:|r Debug mode", ClickMorphShowAllWardrobe.debugMode and "ON" or "OFF")
    else
        print("|cff00ff00ClickMorph Wardrobe Commands:|r")
        print("/cmwardrobe on - Activate wardrobe unlock")
        print("/cmwardrobe off - Revert to original")
        print("/cmwardrobe status - Show system status")
        print("/cmwardrobe refresh - Refresh wardrobe UI")
        print("/cmwardrobe debug - Toggle debug mode")
    end
end

print("|cff00ff00ClickMorph ShowAll Wardrobe|r loaded!")
print("Use |cffffcc00/cmwardrobe on|r to unlock all transmog appearances")