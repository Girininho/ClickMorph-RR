-- ClickMorph ShowAll System
-- Sistema dedicado para unlock de transmog e mounts
-- VERSÃO COM SUPORTE A MOUNTS UNOBTAINABLE (Tyrael's Charger, etc.)

ClickMorphShowAll = {}

-- Sistema principal de unlock
ClickMorphShowAll.unlockSystem = {
    isActive = false,
    originalAPIs = {},
    timer = nil,
    unobtainableMounts = {}, -- Cache das mounts filtradas
    unobtainableBuilt = false -- Flag para evitar reconstruir
}

-- Sistema de debug
ClickMorphShowAll.debugMode = false
ClickMorphShowAll.debugLog = {}
local MAX_DEBUG_LINES = 30

local function DebugPrint(...)
    if ClickMorphShowAll.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        
        table.insert(ClickMorphShowAll.debugLog, message)
        
        if #ClickMorphShowAll.debugLog > MAX_DEBUG_LINES then
            table.remove(ClickMorphShowAll.debugLog, 1)
        end
        
        print("|cffff9900ShowAll:|r", message)
    end
end

-- CORREÇÃO: Construir lista de mounts unobtainable SEM DUPLICATAS
function ClickMorphShowAll.BuildUnobtainableList()
    local system = ClickMorphShowAll.unlockSystem
    
    if system.unobtainableBuilt and #system.unobtainableMounts > 0 then 
        DebugPrint("Unobtainable list already built with", #system.unobtainableMounts, "mounts")
        return 
    end
    
    DebugPrint("Building unobtainable mounts list (avoiding duplicates)...")
    
    -- Limpar lista anterior
    wipe(system.unobtainableMounts)
    
    local allMountIDs = C_MountJournal.GetMountIDs()
    local displayedMounts = {}
    local originalNumDisplayed = system.originalAPIs.GetNumDisplayedMounts and 
                                system.originalAPIs.GetNumDisplayedMounts() or 
                                C_MountJournal.GetNumDisplayedMounts()
    
    DebugPrint("Total mounts in game:", #allMountIDs)
    DebugPrint("Originally displayed:", originalNumDisplayed)
    
    -- IMPORTANTE: Mapear TODAS as mounts que aparecem na lista displayed original
    for i = 1, originalNumDisplayed do
        local getMountFunc = system.originalAPIs.GetDisplayedMountInfo or C_MountJournal.GetDisplayedMountInfo
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = getMountFunc(i)
        if mountID then
            displayedMounts[mountID] = true
            DebugPrint("Marking as already displayed: ID", mountID, "Name:", name)
        end
    end
    
    -- Encontrar mounts que existem mas NÃO estão displayed (as verdadeiras "unobtainable")
    local addedCount = 0
    for _, mountID in ipairs(allMountIDs) do
        if not displayedMounts[mountID] then
            local getMountInfoFunc = system.originalAPIs.GetMountInfoByID or C_MountJournal.GetMountInfoByID
            local name = getMountInfoFunc(mountID)
            if name then -- Mount existe e tem nome válido
                table.insert(system.unobtainableMounts, mountID)
                addedCount = addedCount + 1
                DebugPrint("Added truly unobtainable mount:", name, "(ID:", mountID, ")")
            end
        else
            DebugPrint("Skipping already displayed mount ID:", mountID)
        end
    end
    
    system.unobtainableBuilt = true
    
    -- Verificar se Tyrael está na lista
    local tyrael439Found = false
    for _, mountID in ipairs(system.unobtainableMounts) do
        if mountID == 439 then
            tyrael439Found = true
            break
        end
    end
    
    local totalFound = #system.unobtainableMounts

    
    DebugPrint("Unobtainable list built successfully with", totalFound, "mounts, no duplicates")
    
    return totalFound
end

-- VERSÃO ESTÁVEL: Sistema de pesquisa otimizado
function ClickMorphShowAll.CreateSmartSearchSystem()
    local system = ClickMorphShowAll.unlockSystem
    
    -- Hook no sistema de pesquisa do WoW
    if not system.originalAPIs.SetSearch then
        system.originalAPIs.SetSearch = C_MountJournal.SetSearch
        
        C_MountJournal.SetSearch = function(searchText)
            DebugPrint("Search initiated for:", searchText or "empty")
            
            -- Chamar pesquisa original primeiro
            local result = system.originalAPIs.SetSearch(searchText)
            
            -- Aguardar um pouco para a pesquisa original processar
            C_Timer.After(0.05, function()
                if searchText and searchText ~= "" and string.len(searchText) > 0 then
                    ClickMorphShowAll.CreateCustomSearchResults(searchText)
                else
                    -- Sem pesquisa, limpar lista customizada
                    DebugPrint("Search cleared - resetting to full list")
                    system.customSearchResults = nil
                    
                    -- FORÇAR refresh completo do Mount Journal
                    ClickMorphShowAll.ForceRefreshMountJournal()
                end
            end)
            
            return result
        end
        
        DebugPrint("Smart search system hooked")
    end
end

-- NOVO: Função para forçar refresh completo do Mount Journal
function ClickMorphShowAll.ForceRefreshMountJournal()
    if MountJournal and MountJournal:IsShown() then
        DebugPrint("Force refreshing Mount Journal...")
        
        -- Múltiplos métodos de refresh para garantir
        if MountJournal_UpdateMountList then
            MountJournal_UpdateMountList()
        end
        
        if MountJournal_FullUpdate then
            MountJournal_FullUpdate(MountJournal)
        end
        
        -- NOVO: Forçar update do contador na janela
        ClickMorphShowAll.UpdateMountCounter()
        
        -- Refresh do filtro também
        if MountJournal.searchBox then
            local currentText = MountJournal.searchBox:GetText()
            if currentText == "" then
                -- Se a busca está vazia, forçar clear
                MountJournal.searchBox:SetText("")
                MountJournal.searchBox:ClearFocus()
            end
        end
        
        DebugPrint("Mount Journal force refresh completed")
    end
end

-- CORREÇÃO ESPECÍFICA: Atualizar contador na UI (parte superior)
function ClickMorphShowAll.UpdateMountCounter()
    if not MountJournal then return end
    
    local currentCount = C_MountJournal.GetNumDisplayedMounts()
    local totalCount = #C_MountJournal.GetMountIDs()
    
    -- Procurar por elementos de texto que mostram números
    local function UpdateTextElement(frame, newText)
        if frame and frame.SetText then
            local currentText = frame:GetText()
            if currentText and (currentText == "1422" or currentText:match("1422")) then
                frame:SetText(tostring(newText))
                DebugPrint("Updated counter from", currentText, "to", newText)
                return true
            end
        end
        return false
    end
    
    -- Buscar em vários locais possíveis do contador
    local locations = {
        MountJournal.LeftInset,
        MountJournal.RightInset, 
        MountJournal,
        CollectionsJournal and CollectionsJournal.MountJournal,
    }
    
    for _, frame in ipairs(locations) do
        if frame then
            -- Procurar no frame principal
            if UpdateTextElement(frame, currentCount) then return end
            
            -- Procurar em children
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                if UpdateTextElement(child, currentCount) then return end
                
                -- Procurar em text elements
                if child.text then
                    if UpdateTextElement(child.text, currentCount) then return end
                end
                
                -- Procurar em FontStrings
                local regions = {child:GetRegions()}
                for _, region in ipairs(regions) do
                    if region.GetText then
                        if UpdateTextElement(region, currentCount) then return end
                    end
                end
            end
        end
    end
    
    DebugPrint("Mount counter element not found automatically")
end

-- Sistema de Proteção de Scroll - Solução Definitiva (desabilita scroll automático)
function ClickMorphShowAll.EnableScrollPositionProtection()
    if not MountJournal then
        DebugPrint("MountJournal not found for scroll protection")
        return
    end
    
    -- Verificar se temos ScrollBox (WoW moderno)
    local scrollBox = MountJournal.ScrollBox
    if not scrollBox then
        DebugPrint("ScrollBox not found - trying legacy protection")
        ClickMorphShowAll.EnableLegacyScrollProtection()
        return
    end
    
    -- Verificar se já foi protegido
    if scrollBox._clickMorphScrollProtected then
        DebugPrint("Modern scroll protection already active")
        return
    end
    
    DebugPrint("Disabling automatic scroll-to-selection functions...")
    
    -- Salvar funções originais para restaurar depois se necessário
    scrollBox._originalScrollFunctions = {
        ScrollToElementDataIndex = scrollBox.ScrollToElementDataIndex,
        ScrollToElementData = scrollBox.ScrollToElementData,
        ScrollToFrame = scrollBox.ScrollToFrame,
        ScrollToElementDataByPredicate = scrollBox.ScrollToElementDataByPredicate
    }
    
    -- Desabilitar funções de scroll automático
    scrollBox.ScrollToElementDataIndex = function() end
    scrollBox.ScrollToElementData = function() end
    scrollBox.ScrollToFrame = function() end
    scrollBox.ScrollToElementDataByPredicate = function() end
    
    -- Marcar como protegido
    scrollBox._clickMorphScrollProtected = true
    
    
    DebugPrint("Modern scroll protection activated - disabled auto-scroll functions")
end

-- Função para WoW mais antigo (fallback)
function ClickMorphShowAll.EnableLegacyScrollProtection()
    -- Para versões mais antigas que não têm ScrollBox
    if MountJournal.scrollFrame or MountJournal.ListScrollFrame then
        print("|cfffff00ClickMorph:|r Legacy WoW detected - scroll protection may be limited")
        DebugPrint("Legacy scroll protection attempted")
    else
        print("|cffff0000ClickMorph:|r Could not find scroll elements for protection")
        DebugPrint("No scroll elements found for protection")
    end
end

-- NOVO: Comando para forçar update do contador manualmente
SLASH_CLICKMORPH_UPDATECOUNTER1 = "/cmupdatecounter"
SlashCmdList.CLICKMORPH_UPDATECOUNTER = function()
    local currentCount = C_MountJournal.GetNumDisplayedMounts()
    print("|cff00ff00Forcing counter update to:|r", currentCount)
    
    ClickMorphShowAll.UpdateMountCounter()
    
    -- Também tentar método alternativo
    if MountJournal then
        -- Forçar refresh completo
        if MountJournal_UpdateMountList then
            MountJournal_UpdateMountList()
        end
        
        -- Procurar manualmente por "1422" na interface
        local function FindAndReplace1422(frame, depth)
            if depth > 4 then return end
            
            if frame.GetText then
                local text = frame:GetText()
                if text == "1422" then
                    frame:SetText(tostring(currentCount))
                    print("|cff00ff00SUCCESS:|r Updated counter element to", currentCount)
                    return true
                end
            end
            
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                if FindAndReplace1422(child, depth + 1) then
                    return true
                end
            end
            
            local regions = {frame:GetRegions()}
            for _, region in ipairs(regions) do
                if region.GetText then
                    local text = region:GetText()
                    if text == "1422" then
                        region:SetText(tostring(currentCount))
                        print("|cff00ff00SUCCESS:|r Updated counter region to", currentCount)
                        return true
                    end
                end
            end
            
            return false
        end
        
        if not FindAndReplace1422(MountJournal, 0) then
            print("|cffff0000FAIL:|r Could not find counter element with '1422'")
            print("Try opening/closing the Mount Journal and run this command again")
        end
    end
end

-- NOVO: Hook no evento de abrir o Mount Journal para refresh automático
function ClickMorphShowAll.HookMountJournalEvents()
    local system = ClickMorphShowAll.unlockSystem
    
    -- Criar frame para escutar eventos
    if not system.eventFrame then
        system.eventFrame = CreateFrame("Frame")
        system.eventFrame:RegisterEvent("ADDON_LOADED")
        system.eventFrame:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
        
        system.eventFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "ADDON_LOADED" then
                local addonName = ...
                if addonName == GetAddOnMetadata("ClickMorph", "Title") or addonName == "Blizzard_Collections" then
                    DebugPrint("Collections UI loaded, hooking mount journal show")
                    ClickMorphShowAll.HookMountJournalShow()
                end
            elseif event == "MOUNT_JOURNAL_SEARCH_UPDATED" then
                DebugPrint("Mount journal search updated, refreshing counter")
                C_Timer.After(0.1, function()
                    ClickMorphShowAll.UpdateMountCounter()
                end)
            end
        end)
        
        DebugPrint("Mount Journal event frame created")
    end
end

-- NOVO: Hook na função de mostrar o Mount Journal
function ClickMorphShowAll.HookMountJournalShow()
    if MountJournal then
        -- Hook no OnShow do MountJournal
        if not MountJournal.ClickMorphHooked then
            local originalOnShow = MountJournal:GetScript("OnShow")
            
            MountJournal:SetScript("OnShow", function(self)
                DebugPrint("Mount Journal opened - forcing refresh")
                
                -- Chamar OnShow original se existir
                if originalOnShow then
                    originalOnShow(self)
                end
                
                -- Aguardar um pouco e forçar refresh
                C_Timer.After(0.2, function()
                    ClickMorphShowAll.ForceRefreshMountJournal()
                end)
            end)
            
            MountJournal.ClickMorphHooked = true
            DebugPrint("Mount Journal OnShow hooked")
        end
    end
    
    -- Também hook no Collections Journal
    if CollectionsJournal then
        if not CollectionsJournal.ClickMorphHooked then
            local originalOnShow = CollectionsJournal:GetScript("OnShow")
            
            CollectionsJournal:SetScript("OnShow", function(self)
                DebugPrint("Collections Journal opened")
                
                -- Chamar OnShow original se existir
                if originalOnShow then
                    originalOnShow(self)
                end
                
                -- Se a aba de mounts estiver selecionada, refresh
                if PanelTemplates_GetSelectedTab(self) == 1 then -- Tab 1 = Mounts
                    C_Timer.After(0.3, function()
                        ClickMorphShowAll.ForceRefreshMountJournal()
                    end)
                end
            end)
            
            CollectionsJournal.ClickMorphHooked = true
            DebugPrint("Collections Journal OnShow hooked")
        end
    end
end

-- VERSÃO OTIMIZADA: Criar resultados de pesquisa com melhor performance
function ClickMorphShowAll.CreateCustomSearchResults(searchText)
    local system = ClickMorphShowAll.unlockSystem
    
    if not searchText or searchText == "" then 
        system.customSearchResults = nil
        DebugPrint("Search cleared, custom results reset")
        return 
    end
    
    ClickMorphShowAll.BuildUnobtainableList()
    
    local searchLower = string.lower(searchText)
    local customResults = {}
    
    -- Primeiro: adicionar resultados originais da pesquisa
    local originalCount = system.originalAPIs.GetNumDisplayedMounts()
    DebugPrint("Original search returned", originalCount, "results")
    
    for i = 1, originalCount do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = 
            system.originalAPIs.GetDisplayedMountInfo(i)
        if mountID then
            table.insert(customResults, mountID)
            DebugPrint("Added original search result:", name, "(ID:", mountID, ")")
        end
    end
    
    -- Segundo: procurar matches nas mounts unobtainable
    local matchingUnobtainable = {}
    for _, mountID in ipairs(system.unobtainableMounts) do
        local name = system.originalAPIs.GetMountInfoByID(mountID)
        if name and string.find(string.lower(name), searchLower, 1, true) then
            table.insert(customResults, mountID)
            table.insert(matchingUnobtainable, {id = mountID, name = name})
            DebugPrint("Added unobtainable match to search results:", name, "(ID:", mountID, ")")
        end
    end
    
    -- Salvar resultados customizados
    system.customSearchResults = customResults
    
    DebugPrint("Custom search results created:", #customResults, "total mounts")
    
    -- Aguardar um pouco e então forçar refresh
    C_Timer.After(0.1, function()
        ClickMorphShowAll.ForceRefreshMountJournal()
        
        -- Informar no chat APÓS o refresh
        if #matchingUnobtainable > 0 then
            print("|cff00ff00ClickMorph:|r Added " .. #matchingUnobtainable .. " hidden mounts to search!")
            for _, mount in ipairs(matchingUnobtainable) do
                print("  • " .. mount.name .. " (ID: " .. mount.id .. ")")
            end
            print("|cffffff00Total: " .. #customResults .. " mounts shown|r")
        end
    end)
end

-- Popup de confirmação
function ClickMorphShowAll.ShowConfirmation()
    StaticPopup_Show("CLICKMORPH_SHOWALL_CONFIRM")
end

StaticPopupDialogs["CLICKMORPH_SHOWALL_CONFIRM"] = {
    text = "This will unlock ALL transmog appearances and mounts available in the game.\n\n|cffff6b6bWarning:|r This may cause temporary lag while loading.\n\nContinue?",
    button1 = "Load All Items",
    button2 = "Cancel",
    OnAccept = function()
        print("|cff00ff00ClickMorph:|r Starting safe unlock process...")
        ClickMorphShowAll.StartUnlock()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Função principal de unlock
function ClickMorphShowAll.StartUnlock()
    local system = ClickMorphShowAll.unlockSystem
    
    if system.isActive then
        print("|cff00ff00ClickMorph:|r Unlock system already active!")
        return
    end
    
    DebugPrint("Starting unlock process...")
    
    -- Criar barra de progresso
    local progressFrame = ClickMorphShowAll.CreateProgressBar()
    
    -- Processo de unlock em etapas
    local progress = 0
    local progressTimer
    progressTimer = C_Timer.NewTicker(0.5, function()
        progress = progress + 14 -- Agora são 8 etapas (14% * 7 + 2% = 100%)
        ClickMorphShowAll.UpdateProgress(progressFrame, progress)
        
        if progress == 14 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Preparing APIs...")
            ClickMorphShowAll.SaveOriginalAPIs()
        elseif progress == 28 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Scanning Unobtainable Mounts...")
            ClickMorphShowAll.BuildUnobtainableList()
        elseif progress == 42 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Unlocking Transmog...")
            ClickMorphShowAll.HookTransmogAPIs()
        elseif progress == 56 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Unlocking Mounts...")
            ClickMorphShowAll.HookMountAPIs()
        elseif progress == 70 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Expanding Mount List...")
            ClickMorphShowAll.HookMountDisplayAPIs()
        elseif progress == 84 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Setting Up Smart Search...")
            ClickMorphShowAll.CreateSmartSearchSystem()
        elseif progress == 98 then
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Hooking UI Events...")
            ClickMorphShowAll.HookMountJournalEvents()
        elseif progress >= 100 then
            if progressTimer then
                progressTimer:Cancel()
                progressTimer = nil
            end
            ClickMorphShowAll.UpdateProgressText(progressFrame, "Unlock Complete!")
            
            C_Timer.After(2, function()
                progressFrame:Hide()
                ClickMorphShowAll.RefreshUI()
                ClickMorphShowAll.CompleteUnlock()
            end)
        end
    end)
end

-- Criar barra de progresso
function ClickMorphShowAll.CreateProgressBar()
    local progressFrame = CreateFrame("Frame", "ClickMorphShowAllProgress", UIParent, "BasicFrameTemplateWithInset")
    progressFrame:SetSize(400, 120)
    progressFrame:SetPoint("CENTER", UIParent, "CENTER")
    progressFrame:SetFrameStrata("DIALOG")
    
    local titleText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("TOP", progressFrame, "TOP", 0, -20)
    titleText:SetText("Safe Unlock in Progress...")
    progressFrame.titleText = titleText
    
    local statusBar = CreateFrame("StatusBar", nil, progressFrame)
    statusBar:SetSize(360, 20)
    statusBar:SetPoint("CENTER", progressFrame, "CENTER", 0, -20)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetStatusBarColor(0.2, 0.8, 0.2)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(0)
    progressFrame.statusBar = statusBar
    
    local progressText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER", statusBar, "CENTER")
    progressText:SetText("0%")
    progressFrame.progressText = progressText
    
    progressFrame:Show()
    return progressFrame
end

-- Atualizar progresso
function ClickMorphShowAll.UpdateProgress(frame, value)
    if frame and frame.statusBar and frame.progressText then
        frame.statusBar:SetValue(value)
        frame.progressText:SetText(value .. "%")
    end
end

function ClickMorphShowAll.UpdateProgressText(frame, text)
    if frame and frame.titleText then
        frame.titleText:SetText(text)
    end
end

-- Salvar APIs originais
function ClickMorphShowAll.SaveOriginalAPIs()
    local system = ClickMorphShowAll.unlockSystem
    
    if not system.originalAPIs.GetMountInfoByID then
        system.originalAPIs.GetMountInfoByID = C_MountJournal.GetMountInfoByID
        system.originalAPIs.GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo
        system.originalAPIs.GetNumDisplayedMounts = C_MountJournal.GetNumDisplayedMounts
        system.originalAPIs.GetAllAppearanceSources = C_TransmogCollection.GetAllAppearanceSources
        system.originalAPIs.GetAppearanceSources = C_TransmogCollection.GetAppearanceSources
        system.originalAPIs.GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances
        system.originalAPIs.NeedsFanfare = C_MountJournal.NeedsFanfare
        
        DebugPrint("Original APIs saved successfully")
    end
end

-- Hook das APIs de Transmog
function ClickMorphShowAll.HookTransmogAPIs()
    local system = ClickMorphShowAll.unlockSystem
    
    -- Hook GetAllAppearanceSources
    C_TransmogCollection.GetAllAppearanceSources = function(visualID)
        local sources = system.originalAPIs.GetAllAppearanceSources(visualID)
        
        if sources and type(sources) == "table" and #sources > 0 then
            for _, source in ipairs(sources) do
                if type(source) == "table" then
                    source.isCollected = true
                    source.isUsable = true
                    source.isValidAppearanceForPlayer = true
                end
            end
            return sources
        end
        
        -- Fallback seguro
        return {{
            sourceID = visualID or 0,
            isCollected = true,
            isUsable = true,
            isValidAppearanceForPlayer = true,
            visualID = visualID or 0
        }}
    end
    
    -- Hook GetAppearanceSources
    C_TransmogCollection.GetAppearanceSources = function(visualID)
        return C_TransmogCollection.GetAllAppearanceSources(visualID)
    end
    
    -- Hook GetCategoryAppearances (limitado para evitar lag)
    C_TransmogCollection.GetCategoryAppearances = function(categoryID)
        local appearances = system.originalAPIs.GetCategoryAppearances(categoryID) or {}
        
        -- Adicionar algumas aparências extras (controlado)
        for visualID = 1, 300 do
            table.insert(appearances, {
                isCollected = true,
                isUsable = true,
                visualID = visualID,
                sourceID = visualID,
                uiOrder = visualID,
                isValidAppearanceForPlayer = true
            })
        end
        
        DebugPrint("Category", categoryID, "expanded to", #appearances, "appearances")
        return appearances
    end
    
    DebugPrint("Transmog APIs hooked successfully")
end

-- Hook das APIs de Mount (APENAS UNLOCK, SEM MODIFICAR DISPLAY)
function ClickMorphShowAll.HookMountAPIs()
    local system = ClickMorphShowAll.unlockSystem
    
    -- Hook GetMountInfoByID
    C_MountJournal.GetMountInfoByID = function(mountID)
        if not mountID or type(mountID) ~= "number" then
            return nil
        end
        
        local success, name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountIDReturn = 
            pcall(system.originalAPIs.GetMountInfoByID, mountID)
        
        if not success then
            return nil
        end
        
        if name then
            DebugPrint("Unlocking existing mount:", name, "(ID:", mountID, ")")
            -- Forçar: usable=true, shouldHideOnChar=false, collected=true
            return name, spellID, icon, isActive, true, sourceType, isFavorite, isFactionSpecific, faction, false, true, mountIDReturn
        else
            return nil
        end
    end
    
    -- Hook ULTRA SEGURO do NeedsFanfare (previne stack overflow)
    C_MountJournal.NeedsFanfare = function(mountID)
        -- Validações rigorosas
        if not mountID then
            DebugPrint("NeedsFanfare called with nil mountID")
            return false
        end
        
        if type(mountID) ~= "number" then
            DebugPrint("NeedsFanfare called with invalid type:", type(mountID))
            return false
        end
        
        -- Verificar se a mount existe ANTES de chamar original
        local success, mountExists = pcall(system.originalAPIs.GetMountInfoByID, mountID)
        if not success or not mountExists then
            DebugPrint("NeedsFanfare: Mount", mountID, "does not exist, returning false")
            return false
        end
        
        -- Chamar função original com proteção total contra loops
        if system.originalAPIs.NeedsFanfare then
            local fanfareSuccess, result = pcall(system.originalAPIs.NeedsFanfare, mountID)
            if fanfareSuccess then
                DebugPrint("NeedsFanfare success for mount", mountID, ":", result)
                return result
            else
                DebugPrint("NeedsFanfare error for mount", mountID, ":", result)
                return false
            end
        else
            DebugPrint("Original NeedsFanfare not available")
            return false
        end
    end
    
    DebugPrint("Mount APIs hooked safely - WoW 11.x compatible, no fake mounts created")
end

-- NOVO: Hook das APIs de Display para incluir mounts unobtainable
function ClickMorphShowAll.HookMountDisplayAPIs()
    local system = ClickMorphShowAll.unlockSystem
    
    -- CORREÇÃO: Hook GetNumDisplayedMounts (forçar sempre verificar unobtainable)
    C_MountJournal.GetNumDisplayedMounts = function()
        -- IMPORTANTE: Sempre garantir que a lista unobtainable está construída
        if system.isActive then
            ClickMorphShowAll.BuildUnobtainableList()
        end
        
        -- Se temos resultados de pesquisa customizados, usar eles
        if system.customSearchResults then
            DebugPrint("Using custom search results count:", #system.customSearchResults)
            return #system.customSearchResults
        end
        
        local originalCount = system.originalAPIs.GetNumDisplayedMounts()
        
        -- Se há uma pesquisa ativa, usar apenas o resultado original
        local searchText = MountJournal and MountJournal.searchBox and MountJournal.searchBox:GetText()
        if searchText and searchText ~= "" and string.len(searchText) > 0 then
            DebugPrint("Search active, using original count:", originalCount)
            return originalCount
        end
        
        -- CORREÇÃO: Forçar retorno do total expandido se sistema ativo
        if system.isActive and #system.unobtainableMounts > 0 then
            local totalCount = originalCount + #system.unobtainableMounts
            DebugPrint("Sistema ativo - returning expanded count:", totalCount, "original:", originalCount, "unobtainable:", #system.unobtainableMounts)
            return totalCount
        end
        
        -- Fallback para original
        DebugPrint("Fallback to original count:", originalCount)
        return originalCount
    end
    
    -- Hook GetDisplayedMountInfo (versão simples que funcionava)
    C_MountJournal.GetDisplayedMountInfo = function(displayIndex)
        -- Se temos resultados de pesquisa customizados, usar eles
        if system.customSearchResults then
            if displayIndex <= #system.customSearchResults then
                local mountID = system.customSearchResults[displayIndex]
                DebugPrint("Using custom search result at position", displayIndex, "mountID", mountID)
                return C_MountJournal.GetMountInfoByID(mountID)
            else
                return nil
            end
        end
        
        local originalCount = system.originalAPIs.GetNumDisplayedMounts()
        
        -- Se há uma pesquisa ativa, usar apenas resultados originais
        local searchText = MountJournal and MountJournal.searchBox and MountJournal.searchBox:GetText()
        if searchText and searchText ~= "" and string.len(searchText) > 0 then
            local success, name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = 
                pcall(system.originalAPIs.GetDisplayedMountInfo, displayIndex)
            
            if success and name then
                -- Aplicar unlock: usable=true, shouldHideOnChar=false, collected=true
                return name, spellID, icon, isActive, true, sourceType, isFavorite, isFactionSpecific, faction, false, true, mountID
            else
                return nil
            end
        end
        
        -- Sem pesquisa - versão que funcionava antes
        if displayIndex <= originalCount then
            -- Posição normal, usar função original com unlock
            local success, name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = 
                pcall(system.originalAPIs.GetDisplayedMountInfo, displayIndex)
            
            if success and name then
                -- Aplicar unlock: usable=true, shouldHideOnChar=false, collected=true
                return name, spellID, icon, isActive, true, sourceType, isFavorite, isFactionSpecific, faction, false, true, mountID
            else
                return nil
            end
        else
            -- Posição extra, mapear para mount unobtainable
            ClickMorphShowAll.BuildUnobtainableList()
            local unobtainableIndex = displayIndex - originalCount
            
            if unobtainableIndex <= #system.unobtainableMounts then
                local mountID = system.unobtainableMounts[unobtainableIndex]
                DebugPrint("Mapping display position", displayIndex, "to unobtainable mount ID", mountID)
                
                -- Usar GetMountInfoByID (que já está hooked para unlock)
                return C_MountJournal.GetMountInfoByID(mountID)
            end
        end
        
        return nil
    end
    
    -- Hook GetDisplayedMountAllCreatureDisplayInfo (versão simples)
    if C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo then
        if not system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo then
            system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo = C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo
        end
        
        C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo = function(displayIndex)
            local originalCount = system.originalAPIs.GetNumDisplayedMounts()
            
            -- Se temos resultados de pesquisa customizados, usar eles
            if system.customSearchResults then
                if displayIndex <= #system.customSearchResults then
                    local mountID = system.customSearchResults[displayIndex]
                    local name, spellID = system.originalAPIs.GetMountInfoByID(mountID)
                    if name and spellID then
                        return { creatureDisplayInfoID = spellID, uiModelSceneID = 290 }
                    end
                end
                return nil
            end
            
            -- Se há uma pesquisa ativa, usar apenas resultados originais
            local searchText = MountJournal and MountJournal.searchBox and MountJournal.searchBox:GetText()
            if searchText and searchText ~= "" and string.len(searchText) > 0 then
                return system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo(displayIndex)
            end
            
            -- Sem pesquisa
            if displayIndex <= originalCount then
                -- Posição original, usar função padrão
                return system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo(displayIndex)
            else
                -- Posição extra para unobtainable
                local unobtainableIndex = displayIndex - originalCount
                if unobtainableIndex <= #system.unobtainableMounts then
                    local mountID = system.unobtainableMounts[unobtainableIndex]
                    local name, spellID = system.originalAPIs.GetMountInfoByID(mountID)
                    if name and spellID then
                        return { creatureDisplayInfoID = spellID, uiModelSceneID = 290 }
                    end
                end
            end
            
            return nil
        end
        
        DebugPrint("GetDisplayedMountAllCreatureDisplayInfo hooked (simple version)")
    end
    
    local originalDisplayed = system.originalAPIs.GetNumDisplayedMounts()
    local totalUnobtainable = #system.unobtainableMounts
    
    DebugPrint("Mount display APIs hooked - unobtainable mounts now accessible")
end

-- Refresh da UI com contador atualizado
function ClickMorphShowAll.RefreshUI()
    DebugPrint("Starting UI refresh...")
    
    -- Refresh Mount Journal se estiver aberto
    if MountJournal and MountJournal:IsShown() then
        pcall(function()
            if MountJournal_UpdateMountList then
                MountJournal_UpdateMountList()
                DebugPrint("MountJournal_UpdateMountList called")
            end
            
            if MountJournal_FullUpdate then
                MountJournal_FullUpdate(MountJournal)
                DebugPrint("MountJournal_FullUpdate called")
            end
            
            -- Atualizar contador após refresh
            ClickMorphShowAll.UpdateMountCounter()
        end)
    end
    
    -- Refresh Wardrobe se estiver aberto
    if WardrobeCollectionFrame and WardrobeCollectionFrame:IsShown() then
        local itemsFrame = WardrobeCollectionFrame.ItemsCollectionFrame
        if itemsFrame then
            pcall(function()
                if itemsFrame.RefreshVisualsList then
                    itemsFrame:RefreshVisualsList()
                    DebugPrint("Wardrobe RefreshVisualsList called")
                end
                if itemsFrame.UpdateItems then
                    itemsFrame:UpdateItems()
                    DebugPrint("Wardrobe UpdateItems called")
                end
            end)
        end
    end
    
    DebugPrint("UI refresh completed")
end

-- Completar unlock com verificação de hooks
function ClickMorphShowAll.CompleteUnlock()
    local system = ClickMorphShowAll.unlockSystem
    system.isActive = true
    
    -- NOVA: Verificação automática se hooks estão funcionando
    C_Timer.After(1, function()
        ClickMorphShowAll.VerifyHooksWorking()
    end)
    
    local totalMounts = C_MountJournal.GetNumDisplayedMounts()
    local unobtainableCount = #system.unobtainableMounts
    
print("|cff00ff00ClickMorph ShowAll:|r Successfully activated!")
print("|cff00ff00ClickMorph:|r " .. totalMounts .. " mounts unlocked (" .. unobtainableCount .. " previously hidden)")
print("|cff00ff00ClickMorph:|r Use '/cm revert' to restore original state")
    
    DebugPrint("Unlock system activated successfully")
    
    -- Auto-enable scroll protection and alphabetical sorting after completion
    C_Timer.After(0.5, function()
        ClickMorphShowAll.ForceRefreshMountJournal()
        
        -- Ativar proteção de scroll após UI estar carregada
        C_Timer.After(1, function()
            ClickMorphShowAll.EnableScrollPositionProtection()
        end)
        
    end)
end

-- NOVA: Verificar se hooks estão funcionando e ativar ordenação alfabética
function ClickMorphShowAll.VerifyHooksWorking()
    local system = ClickMorphShowAll.unlockSystem
    
    if not system.isActive then return end
    
    local originalCount = system.originalAPIs.GetNumDisplayedMounts()
    local currentCount = C_MountJournal.GetNumDisplayedMounts()
    local expectedCount = originalCount + #system.unobtainableMounts
    
    DebugPrint("Hook verification: original=" .. originalCount .. ", current=" .. currentCount .. ", expected=" .. expectedCount)
    
    -- Se hooks não estão funcionando
    if currentCount ~= expectedCount then
        print("|cffff9900ClickMorph:|r Hooks may have failed, auto-fixing...")
        
        -- Tentar rehook automaticamente
        ClickMorphShowAll.HookMountDisplayAPIs()
        
        -- Verificar novamente
        C_Timer.After(0.5, function()
            local newCount = C_MountJournal.GetNumDisplayedMounts()
            if newCount == expectedCount then
                print("|cff00ff00ClickMorph:|r Auto-fix successful! Now showing " .. newCount .. " mounts")
                ClickMorphShowAll.ForceRefreshMountJournal()
                
                -- NOVO: Ativar ordenação alfabética após auto-fix
                C_Timer.After(1, function()
                    ClickMorphShowAll.EnableAlphabeticalSorting()
                end)
            else
                print("|cffff0000ClickMorph:|r Auto-fix failed. Use '/cmforcerefresh' manually")
            end
        end)
    else
        DebugPrint("Hooks working correctly!")
        
        -- NOVO: Ativar ordenação alfabética se hooks estão OK
        C_Timer.After(0.5, function()
            ClickMorphShowAll.EnableAlphabeticalSorting()
        end)
    end
end

-- NOVA: Ativar ordenação alfabética de forma segura (COM PROTEÇÃO ANTI-REFRESH)
function ClickMorphShowAll.EnableAlphabeticalSorting()
    local system = ClickMorphShowAll.unlockSystem
    
    if not system.isActive then return end
    
    -- NOVA: Variável de controle para evitar recriação desnecessária
    local mountListLocked = false
    
    -- Criar lista ordenada alfabeticamente (COM PROTEÇÃO MÁXIMA CONTRA REFRESH)
    local function CreateSortedMountList()
        -- CRÍTICO: Se lista já foi criada e travada, NUNCA recriar
        if system.sortedMountList and #system.sortedMountList > 0 and mountListLocked then
            DebugPrint("Using LOCKED cached sorted mount list:", #system.sortedMountList, "mounts")
            return system.sortedMountList
        end
        
        -- Se chegou aqui, precisa criar/recriar
        if mountListLocked then
            DebugPrint("WARNING: Forced recreation of locked mount list!")
        else
            DebugPrint("Creating alphabetically sorted mount list (building cache)...")
        end
        
        -- NOVA: Função para criar chave de ordenação inteligente
        local function CreateSortKey(name)
            if not name then return "" end
            
            local sortKey = string.lower(name)
            
            -- NOVO: Normalizar acentos para ordenação correta
            local accentMap = {
                ["á"] = "a", ["à"] = "a", ["ã"] = "a", ["â"] = "a", ["ä"] = "a",
                ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
                ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i",
                ["ó"] = "o", ["ò"] = "o", ["õ"] = "o", ["ô"] = "o", ["ö"] = "o",
                ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
                ["ç"] = "c", ["ñ"] = "n"
            }
            
            -- Aplicar mapeamento de acentos
            for accented, plain in pairs(accentMap) do
                sortKey = sortKey:gsub(accented, plain)
            end
            
            -- Remover artigos no início para ordenação correta
            local articles = {
                "^de ", "^da ", "^do ", "^das ", "^dos ",
                "^the ", "^of ", "^a ", "^an "
            }
            
            for _, article in ipairs(articles) do
                sortKey = sortKey:gsub(article, "")
            end
            
            -- Remover espaços extras
            sortKey = sortKey:gsub("^%s+", ""):gsub("%s+$", "")
            
            return sortKey
        end
        
        local allMounts = {}
        local originalDisplayed = system.originalAPIs.GetNumDisplayedMounts()
        
        -- Adicionar mounts originais
        for i = 1, originalDisplayed do
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = 
                system.originalAPIs.GetDisplayedMountInfo(i)
            if mountID and name then
                table.insert(allMounts, {
                    mountID = mountID,
                    name = name,
                    sortKey = CreateSortKey(name),
                    source = "ORIGINAL"
                })
            end
        end
        
        -- Adicionar mounts unobtainable
        for _, mountID in ipairs(system.unobtainableMounts) do
            local name = system.originalAPIs.GetMountInfoByID(mountID)
            if name then
                table.insert(allMounts, {
                    mountID = mountID,
                    name = name,
                    sortKey = CreateSortKey(name),
                    source = "UNOBTAINABLE"
                })
            end
        end
        
        -- Ordenar alfabeticamente
        table.sort(allMounts, function(a, b)
            return a.sortKey < b.sortKey
        end)
        
        -- Criar lista final e TRAVAR
        system.sortedMountList = {}
        for i, mount in ipairs(allMounts) do
            system.sortedMountList[i] = mount.mountID
        end
        
        -- CRÍTICO: Travar a lista para evitar recriação
        mountListLocked = true
        
        local totalCount = #system.sortedMountList
        DebugPrint("Mount cache LOCKED - no more recreation allowed")
        
        return system.sortedMountList
    end -- FIM da função CreateSortedMountList
    
    
    -- NOVA: Hook ainda mais restritivo para evitar mudanças
    local stableHookCount = 0
    
    -- Backup dos hooks atuais
    system.basicHooks = {
        GetNumDisplayedMounts = C_MountJournal.GetNumDisplayedMounts,
        GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo,
        GetDisplayedMountAllCreatureDisplayInfo = C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo
    }
    
    -- Hook super estável para GetNumDisplayedMounts
    C_MountJournal.GetNumDisplayedMounts = function()
        stableHookCount = stableHookCount + 1
        DebugPrint("GetNumDisplayedMounts called #" .. stableHookCount)
        
        if system.customSearchResults then
            return #system.customSearchResults
        end
        
        local searchText = MountJournal and MountJournal.searchBox and MountJournal.searchBox:GetText()
        if searchText and searchText ~= "" and string.len(searchText) > 0 then
            return system.originalAPIs.GetNumDisplayedMounts()
        end
        
        -- SEMPRE retornar o mesmo número
        local sortedList = CreateSortedMountList()
        return #sortedList
    end
    
    -- Hook super estável para GetDisplayedMountInfo
    C_MountJournal.GetDisplayedMountInfo = function(displayIndex)
        DebugPrint("GetDisplayedMountInfo called for index", displayIndex)
        
        if system.customSearchResults then
            if displayIndex <= #system.customSearchResults then
                local mountID = system.customSearchResults[displayIndex]
                return C_MountJournal.GetMountInfoByID(mountID)
            else
                return nil
            end
        end
        
        local searchText = MountJournal and MountJournal.searchBox and MountJournal.searchBox:GetText()
        if searchText and searchText ~= "" and string.len(searchText) > 0 then
            local success, name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = 
                pcall(system.originalAPIs.GetDisplayedMountInfo, displayIndex)
            
            if success and name then
                return name, spellID, icon, isActive, true, sourceType, isFavorite, isFactionSpecific, faction, false, true, mountID
            else
                return nil
            end
        end
        
        -- SEMPRE usar a mesma lista travada
        local sortedList = CreateSortedMountList()
        if displayIndex > 0 and displayIndex <= #sortedList then
            local mountID = sortedList[displayIndex]
            if mountID then
                return C_MountJournal.GetMountInfoByID(mountID)
            end
        end
        
        return nil
    end
    
    -- Hook GetDisplayedMountAllCreatureDisplayInfo
    C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo = function(displayIndex)
        if system.customSearchResults then
            if displayIndex <= #system.customSearchResults then
                local mountID = system.customSearchResults[displayIndex]
                local name, spellID = system.originalAPIs.GetMountInfoByID(mountID)
                if name and spellID then
                    return { creatureDisplayInfoID = spellID, uiModelSceneID = 290 }
                end
            end
            return nil
        end
        
        local searchText = MountJournal and MountJournal.searchBox and MountJournal.searchBox:GetText()
        if searchText and searchText ~= "" and string.len(searchText) > 0 then
            return system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo(displayIndex)
        end
        
        -- SEMPRE usar a mesma lista travada
        local sortedList = CreateSortedMountList()
        if displayIndex > 0 and displayIndex <= #sortedList then
            local mountID = sortedList[displayIndex]
            if mountID then
                local name, spellID = system.originalAPIs.GetMountInfoByID(mountID)
                if name and spellID then
                    return { creatureDisplayInfoID = spellID, uiModelSceneID = 290 }
                end
            end
        end
        
        return nil
    end
end

-- Reverter APIs para estado original
function ClickMorphShowAll.RevertAPIs()
    local system = ClickMorphShowAll.unlockSystem
    
    if not system.isActive then
        print("|cff00ff00ClickMorph:|r No unlock system active to revert")
        return
    end
    
    DebugPrint("Starting API revert process...")
    
    if system.originalAPIs and next(system.originalAPIs) then
        -- Restaurar todas as APIs que realmente hookamos
        if system.originalAPIs.GetMountInfoByID then
            C_MountJournal.GetMountInfoByID = system.originalAPIs.GetMountInfoByID
            DebugPrint("GetMountInfoByID reverted")
        end
        if system.originalAPIs.GetDisplayedMountInfo then
            C_MountJournal.GetDisplayedMountInfo = system.originalAPIs.GetDisplayedMountInfo
            DebugPrint("GetDisplayedMountInfo reverted")
        end
        if system.originalAPIs.GetNumDisplayedMounts then
            C_MountJournal.GetNumDisplayedMounts = system.originalAPIs.GetNumDisplayedMounts
            DebugPrint("GetNumDisplayedMounts reverted")
        end
        if system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo then
            C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo = system.originalAPIs.GetDisplayedMountAllCreatureDisplayInfo
            DebugPrint("GetDisplayedMountAllCreatureDisplayInfo reverted")
        end
        if system.originalAPIs.NeedsFanfare then
            C_MountJournal.NeedsFanfare = system.originalAPIs.NeedsFanfare
            DebugPrint("NeedsFanfare reverted")
        end
        if system.originalAPIs.GetAllAppearanceSources then
            C_TransmogCollection.GetAllAppearanceSources = system.originalAPIs.GetAllAppearanceSources
            DebugPrint("GetAllAppearanceSources reverted")
        end
        if system.originalAPIs.GetAppearanceSources then
            C_TransmogCollection.GetAppearanceSources = system.originalAPIs.GetAppearanceSources
            DebugPrint("GetAppearanceSources reverted")
        end
        if system.originalAPIs.GetCategoryAppearances then
            C_TransmogCollection.GetCategoryAppearances = system.originalAPIs.GetCategoryAppearances
            DebugPrint("GetCategoryAppearances reverted")
        end
        if system.originalAPIs.SetSearch then
            C_MountJournal.SetSearch = system.originalAPIs.SetSearch
            DebugPrint("SetSearch reverted")
        end
        
        -- Limpar referências
        wipe(system.originalAPIs)
        wipe(system.unobtainableMounts)
        system.unobtainableBuilt = false
        system.customSearchResults = nil
        system.sortedMountList = nil -- NOVO: Limpar lista ordenada
        system.isActive = false
        
        -- Refresh limpo
        ClickMorphShowAll.RefreshUI()
        
        print("|cff00ff00ClickMorph:|r All APIs restored to original state")
        DebugPrint("API revert completed successfully")
    else
        print("|cff00ff00ClickMorph:|r No APIs to revert")
        DebugPrint("No APIs found to revert")
    end
end

-- Sistema de limpeza de emergência
function ClickMorphShowAll.EmergencyCleanup()
    print("|cffff0000ClickMorph ShowAll:|r Performing emergency cleanup...")
    
    local system = ClickMorphShowAll.unlockSystem
    
    -- Reverter APIs
    ClickMorphShowAll.RevertAPIs()
    
    -- Fechar progress frame se existir
    local progressFrame = _G["ClickMorphShowAllProgress"]
    if progressFrame then
        progressFrame:Hide()
        DebugPrint("Emergency: Progress frame hidden")
    end
    
    -- Reset completo do sistema
    system.isActive = false
    wipe(system.originalAPIs)
    wipe(system.unobtainableMounts)
    system.unobtainableBuilt = false
    system.customSearchResults = nil
    system.sortedMountList = nil -- NOVO: Limpar lista ordenada
    
    -- Limpar event frame
    if system.eventFrame then
        system.eventFrame:UnregisterAllEvents()
        system.eventFrame = nil
    end
    
    print("|cffff0000ClickMorph ShowAll:|r Emergency cleanup completed")
    DebugPrint("Emergency cleanup finished")
end

-- Slash commands and additional functions continue...
SLASH_CLICKMORPH_TESTTYRAELS1 = "/testtyraels"
SlashCmdList.CLICKMORPH_TESTTYRAELS = function()
    print("|cff00ff00=== Testing Tyrael's Charger in expanded list ===|r")
    
    local totalMounts = C_MountJournal.GetNumDisplayedMounts()
    print("Total displayed mounts:", totalMounts)
    
    -- Procurar Tyrael na lista expandida
    for i = 1, totalMounts do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = 
            C_MountJournal.GetDisplayedMountInfo(i)
        if mountID == 439 then
            print("|cff00ff00SUCCESS:|r Tyrael found at position " .. i)
            print("Mount name: " .. (name or "nil"))
            print("Collected: " .. (isCollected and "YES" or "NO"))
            print("Usable: " .. (isUsable and "YES" or "NO"))
            return
        end
    end
    
    print("|cffff0000FAIL:|r Tyrael still not found in expanded list")
    
    -- Debug: mostrar informações adicionais
    local system = ClickMorphShowAll.unlockSystem
    if system.isActive then
        print("ShowAll system: ACTIVE")
        print("Unobtainable mounts found: " .. #system.unobtainableMounts)
        
        -- Verificar se Tyrael está na lista de unobtainable
        for i, mountID in ipairs(system.unobtainableMounts) do
            if mountID == 439 then
                print("Tyrael IS in unobtainable list at index " .. i)
                break
            end
        end
    else
        print("ShowAll system: NOT ACTIVE")
        print("Run the unlock first with your main command")
    end
end

-- Debug commands for ShowAll
SLASH_CLICKMORPH_SHOWALL_DEBUG1 = "/cmshowdebug"
SlashCmdList.CLICKMORPH_SHOWALL_DEBUG = function(arg)
    local command = string.lower(arg or "")
    
    if command == "on" then
        ClickMorphShowAll.debugMode = true
        print("|cff00ff00ShowAll:|r Debug mode ON")
    elseif command == "off" then
        ClickMorphShowAll.debugMode = false
        print("|cff00ff00ShowAll:|r Debug mode OFF")
    elseif command == "log" then
        ClickMorphShowAll.ShowDebugLog()
    elseif command == "status" then
        ClickMorphShowAll.ShowStatus()
    elseif command == "unobtainable" then
        ClickMorphShowAll.ShowUnobtainableInfo()
    else
        print("|cff00ff00ShowAll Debug:|r")
        print("/cmshowdebug on - Enable debug")
        print("/cmshowdebug off - Disable debug")
        print("/cmshowdebug log - Show debug log")
        print("/cmshowdebug status - Show system status")
        print("/cmshowdebug unobtainable - Show unobtainable mounts info")
    end
end

-- NOVO: Mostrar informações sobre mounts unobtainable
function ClickMorphShowAll.ShowUnobtainableInfo()
    local system = ClickMorphShowAll.unlockSystem
    
    print("|cff00ff00=== UNOBTAINABLE MOUNTS INFO ===|r")
    
    if not system.unobtainableBuilt then
        print("Unobtainable list not built yet. Building now...")
        ClickMorphShowAll.BuildUnobtainableList()
    end
    
    local totalUnobtainable = #system.unobtainableMounts
    print("Total unobtainable mounts found: " .. totalUnobtainable)
    
    if totalUnobtainable == 0 then
        print("No unobtainable mounts found. This might indicate an issue.")
        return
    end
    
    -- Verificar Tyrael especificamente
    local tyraelFound = false
    local tyraelIndex = 0
    for i, mountID in ipairs(system.unobtainableMounts) do
        if mountID == 439 then
            tyraelFound = true
            tyraelIndex = i
            break
        end
    end
    
    print("Tyrael's Charger (ID 439): " .. (tyraelFound and ("Found at index " .. tyraelIndex) or "NOT FOUND"))
    
    -- Mostrar primeiras 10 mounts unobtainable como exemplo
    print("\nFirst 10 unobtainable mounts:")
    for i = 1, math.min(10, totalUnobtainable) do
        local mountID = system.unobtainableMounts[i]
        local name = system.originalAPIs.GetMountInfoByID(mountID)
        print(string.format("  %d. ID %d - %s", i, mountID, name or "Unknown"))
    end
    
    if totalUnobtainable > 10 then
        print("... and " .. (totalUnobtainable - 10) .. " more")
    end
    
    -- Informações sobre display expansion
    if system.isActive then
        local originalCount = system.originalAPIs.GetNumDisplayedMounts()
        local totalCount = C_MountJournal.GetNumDisplayedMounts()
        print("\nMount Journal Display:")
        print("  Original displayed: " .. originalCount)
        print("  Now displayed: " .. totalCount)
        print("  Expansion: +" .. (totalCount - originalCount))
    else
        print("\nShowAll system not active - run unlock first")
    end
end

-- Mostrar log de debug
function ClickMorphShowAll.ShowDebugLog()
    if not ClickMorphShowAll.debugLog or #ClickMorphShowAll.debugLog == 0 then
        print("|cff00ff00ShowAll:|r No debug log available")
        return
    end
    
    print("|cff00ff00ShowAll Debug Log:|r (" .. #ClickMorphShowAll.debugLog .. " entries)")
    print("----------------------------------------")
    for i, line in ipairs(ClickMorphShowAll.debugLog) do
        print(string.format("[%d] %s", i, line))
    end
    print("----------------------------------------")
end

-- Mostrar status do sistema
function ClickMorphShowAll.ShowStatus()
    local system = ClickMorphShowAll.unlockSystem
    
    print("|cff00ff00=== SHOWALL SYSTEM STATUS ===|r")
    print("Active: " .. (system.isActive and "YES" or "NO"))
    print("Debug Mode: " .. (ClickMorphShowAll.debugMode and "ON" or "OFF"))
    print("APIs Hooked: " .. (next(system.originalAPIs) and "YES" or "NO"))
    print("Unobtainable List Built: " .. (system.unobtainableBuilt and "YES" or "NO"))
    print("Unobtainable Mounts Found: " .. #system.unobtainableMounts)
    
    if system.isActive then
        print("\nHooked APIs:")
        for apiName, _ in pairs(system.originalAPIs) do
            print("  ✓ " .. apiName)
        end
        
        -- Testar algumas APIs
        print("\nAPI Tests:")
        local testMount = C_MountJournal.GetMountInfoByID(1)
        print("  Mount ID 1: " .. (testMount and "Found" or "Not found"))
        
        local testSources = C_TransmogCollection.GetAllAppearanceSources(1000)
        print("  Transmog sources: " .. (testSources and #testSources or 0))
        
        -- Test mount display expansion
        local totalDisplayed = C_MountJournal.GetNumDisplayedMounts()
        local originalDisplayed = system.originalAPIs.GetNumDisplayedMounts()
        print("  Mount display expansion: " .. originalDisplayed .. " -> " .. totalDisplayed)
    end
end

-- Comando de limpeza de emergência
SLASH_CLICKMORPH_SHOWALL_CLEAN1 = "/cmshowclean"
SlashCmdList.CLICKMORPH_SHOWALL_CLEAN = function()
    ClickMorphShowAll.EmergencyCleanup()
end

-- Comando para testar mount específica por ID
SLASH_CLICKMORPH_TESTMOUNT1 = "/cmtestmount"
SlashCmdList.CLICKMORPH_TESTMOUNT = function(arg)
    local mountID = tonumber(arg)
    if not mountID then
        print("|cff00ff00Test Mount:|r Usage: /cmtestmount <mountID>")
        print("Example: /cmtestmount 376")
        print("Example: /cmtestmount 439 (Tyrael's Charger)")
        return
    end
    
    print("|cff00ff00=== Testing Mount ID " .. mountID .. " ===|r")
    
    -- Test com API original se disponível
    local system = ClickMorphShowAll.unlockSystem
    if system.originalAPIs.GetMountInfoByID then
        local origName = system.originalAPIs.GetMountInfoByID(mountID)
        print("Original API result: " .. (origName or "Mount not found"))
    end
    
    -- Test com API atual (possivelmente hooked)
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountIDReturn = 
        C_MountJournal.GetMountInfoByID(mountID)
    
    if name then
        print("Current API result: " .. name)
        print("SpellID: " .. (spellID or "nil"))
        print("Collected: " .. (isCollected and "YES" or "NO"))
        print("Usable: " .. (isUsable and "YES" or "NO"))
        print("ShouldHideOnChar: " .. (shouldHideOnChar and "YES" or "NO"))
        
        -- Se ShowAll estiver ativo, deveria estar unlocked
        if system.isActive then
            print("|cff00ff00Status:|r Should be unlocked by ShowAll system")
        else
            print("|cff00ff00Status:|r ShowAll system not active")
        end
        
        -- Verificar se está na lista displayed
        local totalDisplayed = C_MountJournal.GetNumDisplayedMounts()
        local foundInDisplay = false
        local displayPosition = 0
        
        for i = 1, totalDisplayed do
            local displayName, _, _, _, _, _, _, _, _, _, _, displayMountID = C_MountJournal.GetDisplayedMountInfo(i)
            if displayMountID == mountID then
                foundInDisplay = true
                displayPosition = i
                break
            end
        end
        
        if foundInDisplay then
            print("Found in display list at position: " .. displayPosition)
            if system.isActive then
                local originalCount = system.originalAPIs.GetNumDisplayedMounts()
                if displayPosition > originalCount then
                    print("Position is BEYOND original list - this is an UNOBTAINABLE mount!")
                else
                    print("Position is in original list - this is a normal mount")
                end
            end
        else
            print("NOT found in current display list")
        end
        
    else
        print("|cffff0000Error:|r Mount ID " .. mountID .. " not found")
    end
end

-- Additional utility commands
SLASH_CLICKMORPH_FORCEREFRESH1 = "/cmforcerefresh"
SlashCmdList.CLICKMORPH_FORCEREFRESH = function()
    print("|cff00ff00ClickMorph:|r Forcing complete UI refresh...")
    ClickMorphShowAll.ForceRefreshMountJournal()
    print("|cff00ff00ClickMorph:|r Refresh completed")
end

SLASH_CLICKMORPH_ALPHABETICAL1 = "/cmalpha"
SlashCmdList.CLICKMORPH_ALPHABETICAL = function(arg)
    local system = ClickMorphShowAll.unlockSystem
    
    if not system.isActive then
        print("|cffff0000ERRO:|r Sistema ShowAll não está ativo!")
        return
    end
    
    local command = string.lower(arg or "")
    
    if command == "on" or command == "" then
        print("|cff00ff00ClickMorph:|r Activating alphabetical sorting...")
        ClickMorphShowAll.EnableAlphabeticalSorting()
    elseif command == "off" then
        print("|cff00ff00ClickMorph:|r Disabling alphabetical sorting...")
        
        if system.basicHooks then
            -- Restaurar hooks básicos (que funcionam)
            C_MountJournal.GetNumDisplayedMounts = system.basicHooks.GetNumDisplayedMounts
            C_MountJournal.GetDisplayedMountInfo = system.basicHooks.GetDisplayedMountInfo
            C_MountJournal.GetDisplayedMountAllCreatureDisplayInfo = system.basicHooks.GetDisplayedMountAllCreatureDisplayInfo
            
            -- Limpar lista ordenada
            system.sortedMountList = nil
            
            ClickMorphShowAll.ForceRefreshMountJournal()
            print("|cff00ff00ClickMorph:|r Alphabetical sorting disabled. Back to original order + unobtainable at end")
        else
            print("|cffff0000ERRO:|r No basic hooks to restore!")
        end
    else
        print("|cff00ff00Usage:|r")
        print("/cmalpha on  - Enable alphabetical sorting")
        print("/cmalpha off - Disable alphabetical sorting")
    end
end

-- Função para desabilitar a proteção (restaurar comportamento original)
function ClickMorphShowAll.DisableScrollProtection()
    if not MountJournal or not MountJournal.ScrollBox then
        return
    end
    
    local scrollBox = MountJournal.ScrollBox
    if not scrollBox._clickMorphScrollProtected then
        print("|cfffff00ClickMorph:|r Scroll protection is not active")
        return
    end
    
    -- Restaurar funções originais
    if scrollBox._originalScrollFunctions then
        scrollBox.ScrollToElementDataIndex = scrollBox._originalScrollFunctions.ScrollToElementDataIndex
        scrollBox.ScrollToElementData = scrollBox._originalScrollFunctions.ScrollToElementData
        scrollBox.ScrollToFrame = scrollBox._originalScrollFunctions.ScrollToFrame
        scrollBox.ScrollToElementDataByPredicate = scrollBox._originalScrollFunctions.ScrollToElementDataByPredicate
        
        scrollBox._originalScrollFunctions = nil
    end
    
    scrollBox._clickMorphScrollProtected = nil
    
    print("|cff00ff00ClickMorph:|r Scroll protection disabled - auto-scroll restored")
    DebugPrint("Scroll protection disabled, original functions restored")
end

-- Comando para controlar a proteção de scroll
SLASH_CLICKMORPH_SCROLLPROTECT1 = "/cmscrollprotect"
SlashCmdList.CLICKMORPH_SCROLLPROTECT = function(arg)
    local command = string.lower(arg or "")
    
    if command == "on" or command == "" then
        ClickMorphShowAll.EnableScrollPositionProtection()
    elseif command == "off" then
        ClickMorphShowAll.DisableScrollProtection()
    elseif command == "toggle" then
        if MountJournal and MountJournal.ScrollBox and MountJournal.ScrollBox._clickMorphScrollProtected then
            ClickMorphShowAll.DisableScrollProtection()
        else
            ClickMorphShowAll.EnableScrollPositionProtection()
        end
    else
        print("|cff00ff00ClickMorph Scroll Protection:|r")
        print("/cmscrollprotect on - Enable scroll protection")
        print("/cmscrollprotect off - Disable scroll protection")
        print("/cmscrollprotect toggle - Toggle on/off")
    end
end

print("|cff00ff00ClickMorph ShowAll System|r loaded!")
print("Enhanced with |cffffff00UNOBTAINABLE MOUNTS SUPPORT|r!")
print("Use |cffffcc00/cm showall|r to unlock all mounts with auto-sorting")
print("Use |cffffcc00/cmalpha on/off|r to toggle alphabetical sorting")
print("Use |cffffcc00/testtyraels|r to test Tyrael's Charger")
print("Use |cffffcc00/cmforcerefresh|r if hooks fail")