-- Titles.lua
-- Sistema para unlock de todos os títulos disponíveis no jogo

ClickMorphShowAllTitles = {}

-- Sistema de títulos
ClickMorphShowAllTitles.titleSystem = {
    isActive = false,
    originalAPIs = {},
    unlockedTitles = 0,
    hiddenTitles = {},
    debugMode = false
}

-- Debug print específico dos títulos
local function TitleDebugPrint(...)
    if ClickMorphShowAllTitles.titleSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff9966ffTitles:|r", message)
    end
end

-- Salvar APIs originais de títulos
function ClickMorphShowAllTitles.SaveOriginalAPIs()
    local system = ClickMorphShowAllTitles.titleSystem
    
    if not system.originalAPIs.GetKnownTitles then
        -- APIs principais de títulos
        system.originalAPIs.GetKnownTitles = GetKnownTitles
        
        -- APIs de PvP (muitos títulos vêm daqui)
        if C_PvP and C_PvP.GetAvailableTitles then
            system.originalAPIs.GetAvailableTitles = C_PvP.GetAvailableTitles
        end
        
        -- APIs de Achievement (títulos por conquistas)
        if GetAchievementReward then
            system.originalAPIs.GetAchievementReward = GetAchievementReward
        end
        
        -- API de título atual
        if GetCurrentTitle then
            system.originalAPIs.GetCurrentTitle = GetCurrentTitle
        end
        
        -- Hook IsTitleKnown
        if IsTitleKnown then
            system.originalAPIs.IsTitleKnown = IsTitleKnown
        end
        
        TitleDebugPrint("Original title APIs saved successfully")
    end
end

-- Descobrir títulos hidden/unobtainable
function ClickMorphShowAllTitles.BuildHiddenTitlesList()
    local system = ClickMorphShowAllTitles.titleSystem
    
    TitleDebugPrint("Building hidden titles list...")
    
    -- Limpar lista anterior
    wipe(system.hiddenTitles)
    
    -- Pegar títulos já disponíveis
    local knownTitles = {}
    local originalTitles = system.originalAPIs.GetKnownTitles() or {}
    
    TitleDebugPrint("Originally known titles:", #originalTitles)
    
    for i, titleID in ipairs(originalTitles) do
        knownTitles[titleID] = true
        TitleDebugPrint("Known title ID:", titleID)
    end
    
    -- Buscar por títulos hidden em ranges conhecidos
    local searchRanges = {
    {start = 1, ["end"] = 50},
    {start = 51, ["end"] = 100},
    {start = 101, ["end"] = 150},
    {start = 151, ["end"] = 200},
    {start = 201, ["end"] = 250},
    {start = 251, ["end"] = 300},
    {start = 301, ["end"] = 400},
    {start = 401, ["end"] = 500}
}

    
    local hiddenFound = 0
    
   for _, range in ipairs(searchRanges) do
    TitleDebugPrint("Scanning title range", range.start, "-", range["end"])
    
    for titleID = range.start, range["end"] do
        if not knownTitles[titleID] then
            local titleName = GetTitleName(titleID)
            if titleName and titleName ~= "" then
                table.insert(system.hiddenTitles, {
                    id = titleID,
                    name = titleName,
                    isHidden = true
                })
                hiddenFound = hiddenFound + 1
                TitleDebugPrint("Found hidden title:", titleName, "(ID:", titleID, ")")
            end
        end
    end
end

    
    TitleDebugPrint("Hidden titles scan completed. Found", hiddenFound, "hidden titles")
    return system.hiddenTitles
end

-- Hook das APIs de títulos
function ClickMorphShowAllTitles.HookTitleAPIs()
    local system = ClickMorphShowAllTitles.titleSystem
    
    TitleDebugPrint("Starting title APIs hook...")
    
    -- Hook GetKnownTitles
    GetKnownTitles = function()
        local titles = system.originalAPIs.GetKnownTitles() or {}
        local originalCount = #titles
        
        -- Adicionar títulos hidden
        local hiddenTitles = ClickMorphShowAllTitles.BuildHiddenTitlesList()
        for _, hiddenTitle in ipairs(hiddenTitles) do
            table.insert(titles, hiddenTitle.id)
        end
        
        local totalTitles = #titles
        local hiddenCount = totalTitles - originalCount
        
        TitleDebugPrint("Returning", totalTitles, "total titles (", originalCount, "original +", hiddenCount, "hidden )")
        system.unlockedTitles = totalTitles
        
        return titles
    end
    
    -- Hook C_PvP.GetAvailableTitles se existir
    if system.originalAPIs.GetAvailableTitles then
        C_PvP.GetAvailableTitles = function()
            local pvpTitles = system.originalAPIs.GetAvailableTitles() or {}
            
            for _, titleData in ipairs(pvpTitles) do
                if type(titleData) == "table" then
                    titleData.isAvailable = true
                    titleData.isEarned = true
                end
            end
            
            TitleDebugPrint("Unlocked", #pvpTitles, "PvP titles")
            return pvpTitles
        end
    end
    
    -- Hook IsTitleKnown
    if system.originalAPIs.IsTitleKnown then
        IsTitleKnown = function(titleID)
            for _, hiddenTitle in ipairs(system.hiddenTitles) do
                if hiddenTitle.id == titleID then
                    TitleDebugPrint("Reporting hidden title as known:", hiddenTitle.name)
                    return true
                end
            end
            return system.originalAPIs.IsTitleKnown(titleID)
        end
    end
    
    TitleDebugPrint("Title APIs hooked successfully")
end

-- Ativar sistema de títulos
function ClickMorphShowAllTitles.ActivateTitles()
    local system = ClickMorphShowAllTitles.titleSystem
    
    if system.isActive then
        print("|cfffff00ClickMorph Titles:|r System already active!")
        return
    end
    
    TitleDebugPrint("Activating ShowAll Titles system...")
    
    ClickMorphShowAllTitles.SaveOriginalAPIs()
    ClickMorphShowAllTitles.HookTitleAPIs()
    
    system.isActive = true
    ClickMorphShowAllTitles.RefreshTitlesUI()
    
    print("|cff00ff00ClickMorph Titles:|r All titles unlocked!")
    print("|cff00ff00ClickMorph:|r Open your Character panel -> Titles to see everything")
    
    TitleDebugPrint("Titles system activated successfully")
end

-- Refresh da UI de títulos
function ClickMorphShowAllTitles.RefreshTitlesUI()
    if PaperDollFrame and PaperDollFrame:IsShown() then
        if PaperDollTitlesPane then
            pcall(function()
                if PaperDollTitlesPane.Update then
                    PaperDollTitlesPane:Update()
                end
                if PaperDollTitlesPane.RefreshTitles then
                    PaperDollTitlesPane:RefreshTitles()
                end
            end)
            TitleDebugPrint("Titles UI refreshed")
        end
    end
end

-- Reverter sistema de títulos
function ClickMorphShowAllTitles.RevertTitles()
    local system = ClickMorphShowAllTitles.titleSystem
    
    if not system.isActive then
        print("|cfffff00ClickMorph Titles:|r No titles system active to revert")
        return
    end
    
    TitleDebugPrint("Reverting title APIs...")
    
    if system.originalAPIs.GetKnownTitles then
        GetKnownTitles = system.originalAPIs.GetKnownTitles
    end
    if system.originalAPIs.GetAvailableTitles then
        C_PvP.GetAvailableTitles = system.originalAPIs.GetAvailableTitles
    end
    if system.originalAPIs.IsTitleKnown then
        IsTitleKnown = system.originalAPIs.IsTitleKnown
    end
    
    wipe(system.originalAPIs)
    wipe(system.hiddenTitles)
    system.isActive = false
    system.unlockedTitles = 0
    
    ClickMorphShowAllTitles.RefreshTitlesUI()
    
    print("|cff00ff00ClickMorph Titles:|r All title APIs restored to original state")
    TitleDebugPrint("Titles revert completed")
end

-- Status do sistema de títulos
function ClickMorphShowAllTitles.ShowStatus()
    local system = ClickMorphShowAllTitles.titleSystem
    
    print("|cff00ff00=== TITLES SYSTEM STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Debug Mode:", system.debugMode and "ON" or "OFF")
    print("APIs Hooked:", next(system.originalAPIs) and "YES" or "NO")
    
    if system.isActive then
        print("Unlocked Titles:", system.unlockedTitles)
        print("Hidden Titles Found:", #system.hiddenTitles)
        
        if #system.hiddenTitles > 0 then
            print("\nFirst 5 hidden titles found:")
            for i = 1, math.min(5, #system.hiddenTitles) do
                local title = system.hiddenTitles[i]
                print(string.format("  %d. %s (ID: %d)", i, title.name, title.id))
            end
            
            if #system.hiddenTitles > 5 then
                print("... and", (#system.hiddenTitles - 5), "more")
            end
        end
        
        print("\nHooked APIs:")
        for apiName, _ in pairs(system.originalAPIs) do
            print("  ✓", apiName)
        end
    end
end

-- Comandos de títulos
SLASH_CLICKMORPH_TITLES1 = "/cmtitles"
SlashCmdList.CLICKMORPH_TITLES = function(arg)
    local command = string.lower(arg or "")
    
    if command == "on" or command == "" then
        ClickMorphShowAllTitles.ActivateTitles()
    elseif command == "off" then
        ClickMorphShowAllTitles.RevertTitles()
    elseif command == "status" then
        ClickMorphShowAllTitles.ShowStatus()
    elseif command == "refresh" then
        ClickMorphShowAllTitles.RefreshTitlesUI()
        print("|cff00ff00ClickMorph Titles:|r Titles UI refreshed")
    elseif command == "debug" then
        ClickMorphShowAllTitles.titleSystem.debugMode = not ClickMorphShowAllTitles.titleSystem.debugMode
        print("|cff00ff00ClickMorph Titles:|r Debug mode", ClickMorphShowAllTitles.titleSystem.debugMode and "ON" or "OFF")
    else
        print("|cff00ff00ClickMorph Titles Commands:|r")
        print("/cmtitles on - Activate title unlock")
        print("/cmtitles off - Revert to original")
        print("/cmtitles status - Show system status")
        print("/cmtitles refresh - Refresh titles UI")
        print("/cmtitles debug - Toggle debug mode")
    end
end

print("|cff00ff00ClickMorph ShowAll Titles|r loaded!")
print("Use |cffffcc00/cmtitles on|r to unlock all titles")