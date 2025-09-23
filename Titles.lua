-- Titles.lua
-- Sistema completo para unlock de todos os títulos disponíveis no jogo

ClickMorphShowAllTitles = {}

-- Sistema de títulos
ClickMorphShowAllTitles.titleSystem = {
    isActive = false,
    originalAPIs = {},
    unlockedTitles = 0,
    hiddenTitles = {},
    debugMode = false,
    titlesBuilt = false
}

-- Base de dados de títulos hidden/unobtainable
ClickMorphShowAllTitles.HIDDEN_TITLES = {
    -- Títulos de desenvolvedor/GM
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    -- Títulos de teste/beta
    500, 501, 502, 503, 504, 505,
    -- Títulos de eventos únicos/removidos
    100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
    -- Títulos de PvP seasons antigas
    200, 201, 202, 203, 204, 205, 206, 207, 208, 209,
    -- Títulos de guild/server específicos
    300, 301, 302, 303, 304, 305,
    -- Títulos unused de várias expansões
    400, 401, 402, 403, 404, 405, 406, 407, 408, 409
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
        
        -- APIs de informação de título
        if GetTitleName then
            system.originalAPIs.GetTitleName = GetTitleName
        end
        
        TitleDebugPrint("Original title APIs saved successfully")
    end
end

-- Descobrir títulos hidden/unobtainable
function ClickMorphShowAllTitles.BuildHiddenTitlesList()
    local system = ClickMorphShowAllTitles.titleSystem
    
    if system.titlesBuilt then
        TitleDebugPrint("Hidden titles list already built with", #system.hiddenTitles, "titles")
        return system.hiddenTitles
    end
    
    TitleDebugPrint("Building hidden titles list...")
    wipe(system.hiddenTitles)
    
    -- Começar com base hardcoded
    for _, titleID in ipairs(ClickMorphShowAllTitles.HIDDEN_TITLES) do
        table.insert(system.hiddenTitles, titleID)
    end
    
    -- Pegar títulos já disponíveis para mapear gaps
    local knownTitles = {}
    local originalTitles = system.originalAPIs.GetKnownTitles() or {}
    
    TitleDebugPrint("Originally known titles:", #originalTitles)
    
    for i, titleID in ipairs(originalTitles) do
        knownTitles[titleID] = true
    end
    
    -- Descobrir títulos através de PvP se disponível
    if system.originalAPIs.GetAvailableTitles then
        local pvpTitles = system.originalAPIs.GetAvailableTitles() or {}
        TitleDebugPrint("Found", #pvpTitles, "PvP titles")
        
        for _, titleData in ipairs(pvpTitles) do
            if titleData.titleID and not knownTitles[titleData.titleID] then
                table.insert(system.hiddenTitles, titleData.titleID)
                knownTitles[titleData.titleID] = true
            end
        end
    end
    
    -- Descobrir títulos através de achievements
    local achievementTitlesFound = 0
    for achievementID = 1, 15000 do -- Range comum de achievements
        if achievementTitlesFound > 100 then break end -- Limite para performance
        
        local _, achievementName, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = GetAchievementInfo(achievementID)
        if achievementName then
            local rewardType, rewardID = GetAchievementReward(achievementID)
            if rewardType and rewardType == "title" and rewardID then
                if not knownTitles[rewardID] then
                    table.insert(system.hiddenTitles, rewardID)
                    knownTitles[rewardID] = true
                    achievementTitlesFound = achievementTitlesFound + 1
                    TitleDebugPrint("Found title", rewardID, "from achievement", achievementID)
                end
            end
        end
        
        -- Performance throttle
        if achievementID % 500 == 0 then
            coroutine.yield()
        end
    end
    
    -- Descobrir gaps nos titleIDs
    local maxKnownTitleID = 0
    for titleID in pairs(knownTitles) do
        if titleID > maxKnownTitleID then
            maxKnownTitleID = titleID
        end
    end
    
    local gapsFound = 0
    local maxGaps = 200 -- Limite para não sobrecarregar
    
    for titleID = 1, maxKnownTitleID do
        if not knownTitles[titleID] and gapsFound < maxGaps then
            -- Verificar se é um título válido tentando obter nome
            local titleName = GetTitleName(titleID)
            if titleName and titleName ~= "" then
                table.insert(system.hiddenTitles, titleID)
                gapsFound = gapsFound + 1
                TitleDebugPrint("Found hidden title ID:", titleID, "named:", titleName)
            end
        end
    end
    
    TitleDebugPrint("Discovered", gapsFound, "additional hidden titles via gap analysis")
    
    -- Remover duplicatas e ordenar
    local uniqueTitles = {}
    local seenTitles = {}
    for _, titleID in ipairs(system.hiddenTitles) do
        if not seenTitles[titleID] then
            table.insert(uniqueTitles, titleID)
            seenTitles[titleID] = true
        end
    end
    table.sort(uniqueTitles)
    
    system.hiddenTitles = uniqueTitles
    system.titlesBuilt = true
    
    TitleDebugPrint("Hidden titles list built with", #system.hiddenTitles, "total titles")
    return system.hiddenTitles
end

-- Instalar hooks do sistema de títulos
function ClickMorphShowAllTitles.InstallTitleHooks()
    local system = ClickMorphShowAllTitles.titleSystem
    
    TitleDebugPrint("Installing title hooks...")
    
    -- Hook GetKnownTitles - EXPANDE A LISTA
    GetKnownTitles = function()
        local originalTitles = system.originalAPIs.GetKnownTitles() or {}
        local expandedTitles = {}
        
        -- Adicionar títulos originais
        for _, titleID in ipairs(originalTitles) do
            table.insert(expandedTitles, titleID)
        end
        
        -- Adicionar títulos hidden
        local hiddenTitles = ClickMorphShowAllTitles.BuildHiddenTitlesList()
        for _, titleID in ipairs(hiddenTitles) do
            table.insert(expandedTitles, titleID)
        end
        
        TitleDebugPrint("GetKnownTitles expanded from", #originalTitles, "to", #expandedTitles)
        return expandedTitles
    end
    
    -- Hook IsTitleKnown - SEMPRE RETORNA TRUE
    if system.originalAPIs.IsTitleKnown then
        IsTitleKnown = function(titleID)
            TitleDebugPrint("IsTitleKnown called for title", titleID, "- returning TRUE")
            return true
        end
    end
    
    -- Hook GetAvailableTitles (PvP) se disponível
    if system.originalAPIs.GetAvailableTitles and C_PvP then
        C_PvP.GetAvailableTitles = function()
            local originalTitles = system.originalAPIs.GetAvailableTitles() or {}
            
            -- Adicionar títulos hidden como disponíveis
            local hiddenTitles = ClickMorphShowAllTitles.BuildHiddenTitlesList()
            for _, titleID in ipairs(hiddenTitles) do
                local titleName = GetTitleName(titleID) or ("Hidden Title " .. titleID)
                table.insert(originalTitles, {
                    titleID = titleID,
                    name = titleName,
                    isKnown = true
                })
            end
            
            TitleDebugPrint("GetAvailableTitles expanded to", #originalTitles, "titles")
            return originalTitles
        end
    end
    
    system.isActive = true
    TitleDebugPrint("Title hooks installed successfully")
end

-- Ativar sistema de títulos
function ClickMorphShowAllTitles.ActivateTitles()
    local system = ClickMorphShowAllTitles.titleSystem
    
    if system.isActive then
        TitleDebugPrint("Title system already active")
        print("|cff00ff00ClickMorph Titles:|r System already active!")
        return
    end
    
    TitleDebugPrint("Activating title unlock system...")
    
    -- Salvar APIs originais
    ClickMorphShowAllTitles.SaveOriginalAPIs()
    
    -- Instalar hooks
    ClickMorphShowAllTitles.InstallTitleHooks()
    
    -- Construir lista de títulos hidden (async para não travar)
    C_Timer.After(0.1, function()
        ClickMorphShowAllTitles.BuildHiddenTitlesList()
        
        local titleCount = #system.hiddenTitles
        system.unlockedTitles = titleCount
        
        print("|cff00ff00ClickMorph Titles:|r Unlocked " .. titleCount .. " hidden titles!")
        print("|cff00ff00ClickMorph Titles:|r All titles are now available for selection!")
        TitleDebugPrint("Title activation complete")
        
        -- Refresh da UI de títulos se estiver aberta
        if PaperDollFrame and PaperDollFrame:IsVisible() then
            CharacterTitleDropDown_Initialize()
        end
    end)
end

-- Reverter sistema de títulos
function ClickMorphShowAllTitles.RevertTitles()
    local system = ClickMorphShowAllTitles.titleSystem
    
    if not system.isActive then
        print("|cff00ff00ClickMorph Titles:|r System not active")
        return
    end
    
    TitleDebugPrint("Reverting title system to original state...")
    
    -- Restaurar APIs originais
    if system.originalAPIs.GetKnownTitles then
        GetKnownTitles = system.originalAPIs.GetKnownTitles
    end
    if system.originalAPIs.IsTitleKnown then
        IsTitleKnown = system.originalAPIs.IsTitleKnown
    end
    if system.originalAPIs.GetAvailableTitles and C_PvP then
        C_PvP.GetAvailableTitles = system.originalAPIs.GetAvailableTitles
    end
    
    -- Limpar sistema
    wipe(system.originalAPIs)
    wipe(system.hiddenTitles)
    
    system.isActive = false
    system.unlockedTitles = 0
    system.titlesBuilt = false
    
    print("|cff00ff00ClickMorph Titles:|r All title APIs restored to original state")
    TitleDebugPrint("Title revert completed")
    
    -- Refresh da UI de títulos
    if PaperDollFrame and PaperDollFrame:IsVisible() then
        CharacterTitleDropDown_Initialize()
    end
end

-- Status do sistema de títulos
function ClickMorphShowAllTitles.ShowStatus()
    local system = ClickMorphShowAllTitles.titleSystem
    
    print("|cff00ff00=== TITLES SYSTEM STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Debug Mode:", system.debugMode and "ON" or "OFF")
    print("APIs Hooked:", next(system.originalAPIs) and "YES" or "NO")
    
    if system.isActive then
        print("Unlocked Hidden Titles:", system.unlockedTitles)
        print("Hidden Titles Loaded:", #system.hiddenTitles)
        print("Titles Cache Built:", system.titlesBuilt and "YES" or "NO")
        
        print("\nHooked APIs:")
        for apiName, _ in pairs(system.originalAPIs) do
            print("  ✓", apiName)
        end
    end
end

-- Refresh da interface de títulos
function ClickMorphShowAllTitles.RefreshTitles()
    TitleDebugPrint("Refreshing title interface...")
    
    -- Refresh do dropdown de títulos no character frame
    if CharacterTitleDropDown then
        UIDropDownMenu_Initialize(CharacterTitleDropDown, CharacterTitleDropDown_Initialize)
        UIDropDownMenu_SetSelectedValue(CharacterTitleDropDown, GetCurrentTitle())
    end
    
    -- Refresh de outros elementos de título se existirem
    if PaperDollFrame and PaperDollFrame:IsVisible() then
        PaperDollFrame_UpdateStats()
    end
    
    TitleDebugPrint("Title interface refreshed")
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
        ClickMorphShowAllTitles.RefreshTitles()
        print("|cff00ff00ClickMorph Titles:|r Title interface refreshed")
    elseif command == "rebuild" then
        -- Rebuildar cache de títulos
        ClickMorphShowAllTitles.titleSystem.titlesBuilt = false
        ClickMorphShowAllTitles.BuildHiddenTitlesList()
        print("|cff00ff00ClickMorph Titles:|r Rebuilt hidden titles cache")
    elseif command == "debug" then
        ClickMorphShowAllTitles.titleSystem.debugMode = not ClickMorphShowAllTitles.titleSystem.debugMode
        print("|cff00ff00ClickMorph Titles:|r Debug mode", ClickMorphShowAllTitles.titleSystem.debugMode and "ON" or "OFF")
    elseif command == "list" then
        -- Listar alguns títulos para teste
        local hiddenTitles = ClickMorphShowAllTitles.BuildHiddenTitlesList()
        print("|cff00ff00ClickMorph Titles:|r Sample of unlocked titles:")
        for i = 1, math.min(10, #hiddenTitles) do
            local titleID = hiddenTitles[i]
            local titleName = GetTitleName(titleID) or ("Title " .. titleID)
            print("  " .. titleID .. ": " .. titleName)
        end
        if #hiddenTitles > 10 then
            print("  ... and " .. (#hiddenTitles - 10) .. " more titles")
        end
    else
        print("|cff00ff00ClickMorph Titles Commands:|r")
        print("/cmtitles on - Activate title unlock (show all titles)")
        print("/cmtitles off - Revert to original titles")
        print("/cmtitles status - Show detailed system status")
        print("/cmtitles refresh - Refresh title interface")
        print("/cmtitles rebuild - Rebuild hidden titles cache")
        print("/cmtitles list - Show sample of unlocked titles")
        print("/cmtitles debug - Toggle debug mode")
        print("")
        print("|cffccccccThis system unlocks hidden/unobtainable titles")
        print("and makes all titles available for selection.|r")
    end
end

-- Inicialização
local function Initialize()
    TitleDebugPrint("Initializing ShowAll Titles system...")
    
    -- Event frame para inicialização
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            TitleDebugPrint("ClickMorph loaded, titles system ready")
        elseif event == "PLAYER_LOGIN" then
            C_Timer.After(2, function()
                TitleDebugPrint("Player login completed, titles system ready")
                if ClickMorphShowAllTitles.titleSystem.isActive then
                    ClickMorphShowAllTitles.RefreshTitles()
                end
            end)
        end
    end)
end

Initialize()

print("|cff00ff00ClickMorph ShowAll Titles|r loaded!")
print("Use |cffffcc00/cmtitles on|r to unlock all titles")
print("Use |cffffcc00/cmtitles list|r to see sample unlocked titles")
TitleDebugPrint("Titles.lua loaded successfully")