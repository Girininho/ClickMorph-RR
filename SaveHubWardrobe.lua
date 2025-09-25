-- SaveHubWardrobe.lua
-- Sistema ShowAll: Montarias 100% funcionais + Wardrobe (stub seguro)
-- CORRIGIDO: Hooks mais robustos e integração com sistema principal

ClickMorphShowAllWardrobe = {}

ClickMorphShowAllWardrobe.wardrobeSystem = {
    isActive = false,
    originalAPIs = {},
    debugMode = false,
    
    -- Cache para melhor performance
    mountCache = {},
    lastRefresh = 0,
    
    -- Sistema de pesquisa inteligente
    customSearchResults = nil,
    searchMountIDs = {},
    activeSearch = false
}

-------------------------------------------------
-- Debug print
-------------------------------------------------
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
        print("|cff9966ff[Wardrobe]:|r", message)
    end
end

-------------------------------------------------
-- SISTEMA DE MONTARIAS MELHORADO
-------------------------------------------------

-- Lista de mounts importantes para forçar (incluindo Tyrael e outras hidden)
local IMPORTANT_MOUNTS = {
    439,  -- Tyrael's Charger
    460,  -- Grand Black War Mammoth (Alliance)
    461,  -- Grand Black War Mammoth (Horde)
    363,  -- Reins of the Violet Proto-Drake
    142,  -- Swift Zhevra (Collector's Edition)
    15,   -- Swift Frostwolf (Horde PvP)
}

function ClickMorphShowAllWardrobe:ActivateMounts()
    local system = self.wardrobeSystem
    
    WardrobeDebugPrint("Activating mount system...")
    
    -- Backup APIs originais apenas uma vez
    if not system.originalAPIs.GetNumMounts then
        system.originalAPIs.GetNumMounts = C_MountJournal.GetNumMounts
        system.originalAPIs.GetMountIDs = C_MountJournal.GetMountIDs
        system.originalAPIs.GetMountInfoByID = C_MountJournal.GetMountInfoByID
        system.originalAPIs.GetMountInfoExtraByID = C_MountJournal.GetMountInfoExtraByID
        system.originalAPIs.GetNumDisplayedMounts = C_MountJournal.GetNumDisplayedMounts
        system.originalAPIs.GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo
        
        WardrobeDebugPrint("Original APIs backed up")
    end

    -- HOOK 1: GetNumMounts - sempre reporta todas como coletadas
    C_MountJournal.GetNumMounts = function()
        local numMounts = system.originalAPIs.GetNumMounts()
        WardrobeDebugPrint("GetNumMounts called, returning:", numMounts, "all collected")
        return numMounts, true -- segundo valor = todas coletadas
    end

    -- HOOK 2: GetMountIDs - garante que mounts importantes estão na lista
    C_MountJournal.GetMountIDs = function()
        local ids = system.originalAPIs.GetMountIDs() or {}
        local originalCount = #ids
        
        -- Adicionar mounts importantes se não estiverem
        for _, importantID in ipairs(IMPORTANT_MOUNTS) do
            if not tContains(ids, importantID) then
                table.insert(ids, importantID)
                WardrobeDebugPrint("Added missing important mount:", importantID)
            end
        end
        
        WardrobeDebugPrint("GetMountIDs: expanded from", originalCount, "to", #ids, "mounts")
        return ids
    end

    -- HOOK 3: GetMountInfoByID - força todas como coletadas e usáveis
    C_MountJournal.GetMountInfoByID = function(mountID)
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
              isFactionSpecific, faction, hideOnChar, isCollected, mountID2, isSteady =
              system.originalAPIs.GetMountInfoByID(mountID)

        -- Forçar como coletada e usável
        isCollected = true
        isUsable = true
        hideOnChar = false

        -- Se não tem nome, gerar um baseado no ID
        if not name or name == "" then
            name = "Hidden Mount " .. tostring(mountID)
            icon = icon or 134400 -- Ícone padrão
            spellID = spellID or 0
        end

        WardrobeDebugPrint("GetMountInfoByID:", mountID, "->", name, "collected:", isCollected)
        
        return name, spellID, icon, isActive, isUsable, sourceType or 0, isFavorite,
               isFactionSpecific, faction, hideOnChar, isCollected,
               mountID2 or mountID, isSteady
    end

    -- HOOK 4: GetMountInfoExtraByID - corrige dados extras
    C_MountJournal.GetMountInfoExtraByID = function(mountID)
        local creatureDisplayInfoID, descriptionText, sourceText, isSelfMount,
              mountType, uiModelSceneID, animID, spellVisualKitID =
              system.originalAPIs.GetMountInfoExtraByID(mountID)

        -- Garantir que tem pelo menos um scene ID válido
        if not uiModelSceneID or uiModelSceneID == 0 then
            uiModelSceneID = 256 -- Scene ID padrão
        end

        return creatureDisplayInfoID, descriptionText, sourceText, isSelfMount,
               mountType, uiModelSceneID, animID, spellVisualKitID
    end
    
    -- HOOK 5: Forçar exibição de todas as mounts no journal
    self:SetupMountJournalHooks()
    
    WardrobeDebugPrint("Mount system activated successfully")
end

function ClickMorphShowAllWardrobe:SetupMountJournalHooks()
    local system = self.wardrobeSystem
    
    -- SISTEMA DE PESQUISA INTELIGENTE (baseado no ShowAll.lua que funciona)
    system.customSearchResults = nil
    system.searchMountIDs = {}
    system.activeSearch = false
    
    -- Hook sistema de pesquisa primeiro
    if not system.originalAPIs.SetSearch then
        system.originalAPIs.SetSearch = C_MountJournal.SetSearch
        
        C_MountJournal.SetSearch = function(searchText)
            WardrobeDebugPrint("Search initiated for:", searchText or "empty")
            
            -- Chamar pesquisa original
            local result = system.originalAPIs.SetSearch(searchText)
            
            -- Processar pesquisa customizada
            if searchText and searchText ~= "" and string.len(searchText) > 0 then
                system.activeSearch = true
                wipe(system.searchMountIDs)
                
                local searchLower = string.lower(searchText)
                local allIDs = C_MountJournal.GetMountIDs()
                
                -- Pesquisar em TODAS as mounts (incluindo hidden)
                for _, mountID in ipairs(allIDs) do
                    local name = C_MountJournal.GetMountInfoByID(mountID)
                    if name and string.find(string.lower(name), searchLower, 1, true) then
                        table.insert(system.searchMountIDs, mountID)
                        WardrobeDebugPrint("Search match:", name, "(ID:", mountID, ")")
                    end
                end
                
                WardrobeDebugPrint("Search found", #system.searchMountIDs, "matches for:", searchText)
            else
                system.activeSearch = false
                wipe(system.searchMountIDs)
                WardrobeDebugPrint("Search cleared")
            end
            
            -- Force refresh após search
            C_Timer.After(0.05, function()
                ClickMorphShowAllWardrobe:RefreshMountJournal()
            end)
            
            return result
        end
    end
    
    -- Hook search box diretamente (como no ShowAll.lua funcional)
    C_Timer.After(0.5, function()
        if MountJournal and MountJournal.searchBox then
            WardrobeDebugPrint("Hooking search box directly")
            
            -- Hook no texto mudando
            MountJournal.searchBox:HookScript("OnTextChanged", function(self)
                local text = self:GetText():trim():lower()
                if #text > 0 then
                    system.activeSearch = true
                    wipe(system.searchMountIDs)
                    
                    local allIDs = C_MountJournal.GetMountIDs()
                    for _, mountID in ipairs(allIDs) do
                        local name = C_MountJournal.GetMountInfoByID(mountID)
                        if name and string.find(string.lower(name), text, 1, true) then
                            table.insert(system.searchMountIDs, mountID)
                        end
                    end
                    
                    WardrobeDebugPrint("Direct search found", #system.searchMountIDs, "matches")
                    ClickMorphShowAllWardrobe:RefreshMountJournal()
                else
                    system.activeSearch = false
                    wipe(system.searchMountIDs)
                end
            end)
            
            -- Hook clear functions
            local function ClearSearch()
                system.activeSearch = false
                wipe(system.searchMountIDs)
                WardrobeDebugPrint("Search cleared via button/hide")
            end
            
            if MountJournal.searchBox.clearButton then
                MountJournal.searchBox.clearButton:HookScript("OnClick", ClearSearch)
            end
            MountJournal.searchBox:HookScript("OnHide", ClearSearch)
            
            WardrobeDebugPrint("Search box hooks installed")
        end
    end)
    
    -- Hook GetNumDisplayedMounts com sistema de pesquisa
    C_MountJournal.GetNumDisplayedMounts = function()
        if system.activeSearch then
            local count = #system.searchMountIDs
            WardrobeDebugPrint("GetNumDisplayedMounts (search):", count)
            return count
        end
        
        local allIDs = C_MountJournal.GetMountIDs()
        local count = #allIDs
        WardrobeDebugPrint("GetNumDisplayedMounts (all):", count)
        return count
    end
    
    -- Hook GetDisplayedMountInfo com sistema de pesquisa
    C_MountJournal.GetDisplayedMountInfo = function(displayIndex)
        local mountID
        
        if system.activeSearch then
            mountID = system.searchMountIDs[displayIndex]
            if mountID then
                WardrobeDebugPrint("GetDisplayedMountInfo (search):", displayIndex, "-> ID", mountID)
            end
        else
            local allIDs = C_MountJournal.GetMountIDs()
            mountID = allIDs[displayIndex]
            if mountID then
                WardrobeDebugPrint("GetDisplayedMountInfo (all):", displayIndex, "-> ID", mountID)
            end
        end
        
        if not mountID then
            WardrobeDebugPrint("GetDisplayedMountInfo: no mount at index", displayIndex)
            return nil
        end
        
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
              isFactionSpecific, faction, hideOnChar, isCollected, mountID2, isSteady =
              C_MountJournal.GetMountInfoByID(mountID)
        
        return name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
               isFactionSpecific, faction, hideOnChar, isCollected, mountID, isSteady
    end
    
    WardrobeDebugPrint("Smart search system + display hooks installed")
end

function ClickMorphShowAllWardrobe:DeactivateMounts()
    local system = self.wardrobeSystem
    
    WardrobeDebugPrint("Deactivating mount system...")
    
    -- Restaurar APIs originais
    if system.originalAPIs.GetNumMounts then
        C_MountJournal.GetNumMounts = system.originalAPIs.GetNumMounts
    end
    if system.originalAPIs.GetMountIDs then
        C_MountJournal.GetMountIDs = system.originalAPIs.GetMountIDs
    end
    if system.originalAPIs.GetMountInfoByID then
        C_MountJournal.GetMountInfoByID = system.originalAPIs.GetMountInfoByID
    end
    if system.originalAPIs.GetMountInfoExtraByID then
        C_MountJournal.GetMountInfoExtraByID = system.originalAPIs.GetMountInfoExtraByID
    end
    if system.originalAPIs.GetNumDisplayedMounts then
        C_MountJournal.GetNumDisplayedMounts = system.originalAPIs.GetNumDisplayedMounts
    end
    if system.originalAPIs.GetDisplayedMountInfo then
        C_MountJournal.GetDisplayedMountInfo = system.originalAPIs.GetDisplayedMountInfo
    end
    
    WardrobeDebugPrint("Mount APIs restored")
end

-- Forçar refresh do Mount Journal quando necessário
function ClickMorphShowAllWardrobe:RefreshMountJournal()
    WardrobeDebugPrint("Forcing Mount Journal refresh...")
    
    -- Refresh via eventos se possível
    if MountJournal and MountJournal:IsVisible() then
        MountJournal_UpdateMountList()
        WardrobeDebugPrint("Mount Journal refreshed via UpdateMountList")
    end
    
    -- Também disparar evento de mudança
    if C_MountJournal then
        pcall(function()
            -- Força recalcular lista
            local _ = C_MountJournal.GetNumDisplayedMounts()
        end)
    end
end

-- Hook eventos do Collections UI
local function SetupCollectionsHooks()
    WardrobeDebugPrint("Setting up Collections UI hooks...")
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_Collections" then
            WardrobeDebugPrint("Collections addon loaded, setting up hooks")
            
            -- Hook a função de update das mounts
            if MountJournal_UpdateMountList then
                hooksecurefunc("MountJournal_UpdateMountList", function()
                    WardrobeDebugPrint("MountJournal_UpdateMountList called")
                    ClickMorphShowAllWardrobe:RefreshMountJournal()
                end)
            end
            
            -- Hook quando Collections abre
            if CollectionsJournal then
                CollectionsJournal:HookScript("OnShow", function()
                    WardrobeDebugPrint("Collections Journal opened")
                    C_Timer.After(0.1, function()
                        ClickMorphShowAllWardrobe:RefreshMountJournal()
                    end)
                end)
            end
        end
    end)
end

-- Inicializar hooks quando addon carregar
SetupCollectionsHooks()

-------------------------------------------------
-- Wardrobe (stub seguro)
-------------------------------------------------
function ClickMorphShowAllWardrobe:ActivateWardrobe()
    local system = self.wardrobeSystem
    if system.isActive then
        print("|cff00ff00ClickMorph Wardrobe:|r Already active!")
        return
    end

    WardrobeDebugPrint("Activating wardrobe stubs...")

    -- Salvar APIs originais do transmog
    if not system.originalAPIs.GetCategoryAppearances then
        system.originalAPIs.GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances
        system.originalAPIs.GetAppearanceSources = C_TransmogCollection.GetAppearanceSources
        system.originalAPIs.GetAppearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo
    end

    -- Stub seguro: só adiciona debug por enquanto
    C_TransmogCollection.GetCategoryAppearances = function(categoryID)
        local apps = system.originalAPIs.GetCategoryAppearances(categoryID) or {}
        WardrobeDebugPrint("GetCategoryAppearances called for category", categoryID, "- returned", #apps, "appearances")
        return apps
    end

    C_TransmogCollection.GetAppearanceSourceInfo = function(sourceID)
        local info = system.originalAPIs.GetAppearanceSourceInfo(sourceID)
        if info then
            WardrobeDebugPrint("GetAppearanceSourceInfo called for source", sourceID, "- found:", info.name or "unnamed")
        end
        return info
    end

    C_TransmogCollection.GetAppearanceSources = function(appID)
        local srcs = system.originalAPIs.GetAppearanceSources(appID) or {}
        WardrobeDebugPrint("GetAppearanceSources called for appearance", appID, "- returned", #srcs, "sources")
        return srcs
    end

    -- Ativar sistema de montarias
    self:ActivateMounts()

    system.isActive = true
    print("|cff00ff00ClickMorph Wardrobe:|r Activated (Mounts unlocked, Wardrobe stubbed safely)")
    WardrobeDebugPrint("Wardrobe system fully activated")
end

function ClickMorphShowAllWardrobe:RevertWardrobe()
    local system = self.wardrobeSystem
    if not system.isActive then 
        print("|cff00ff00ClickMorph Wardrobe:|r System not active")
        return 
    end

    WardrobeDebugPrint("Reverting wardrobe system...")

    -- Desativar montarias
    self:DeactivateMounts()

    -- Restaurar wardrobe APIs
    if system.originalAPIs.GetCategoryAppearances then
        C_TransmogCollection.GetCategoryAppearances = system.originalAPIs.GetCategoryAppearances
    end
    if system.originalAPIs.GetAppearanceSources then
        C_TransmogCollection.GetAppearanceSources = system.originalAPIs.GetAppearanceSources
    end
    if system.originalAPIs.GetAppearanceSourceInfo then
        C_TransmogCollection.GetAppearanceSourceInfo = system.originalAPIs.GetAppearanceSourceInfo
    end

    -- Limpar cache
    wipe(system.mountCache)
    system.lastRefresh = 0

    system.isActive = false
    print("|cff00ff00ClickMorph Wardrobe:|r Reverted to original APIs")
    WardrobeDebugPrint("Wardrobe system reverted successfully")
end

-------------------------------------------------
-- Comandos Slash
-------------------------------------------------
SLASH_CLICKMORPH_WARDROBE1 = "/cmwardrobe"
SlashCmdList.CLICKMORPH_WARDROBE = function(arg)
    local cmd = string.lower(arg or "")
    
    if cmd == "on" or cmd == "" then
        ClickMorphShowAllWardrobe:ActivateWardrobe()
        
    elseif cmd == "off" then
        ClickMorphShowAllWardrobe:RevertWardrobe()
        
    elseif cmd == "debug" then
        ClickMorphShowAllWardrobe.wardrobeSystem.debugMode = not ClickMorphShowAllWardrobe.wardrobeSystem.debugMode
        local status = ClickMorphShowAllWardrobe.wardrobeSystem.debugMode and "ON" or "OFF"
        print("|cff9966ffWardrobe Debug:|r", status)
        
    elseif cmd == "refresh" then
        ClickMorphShowAllWardrobe:RefreshMountJournal()
        print("|cff00ff00ClickMorph Wardrobe:|r Mount Journal refreshed")
        
    elseif cmd == "search" then
        -- Teste do sistema de pesquisa
        local system = ClickMorphShowAllWardrobe.wardrobeSystem
        print("|cff9966ff=== Search System Test ===|r")
        print("Active Search:", system.activeSearch and "YES" or "NO")
        print("Search Results:", #system.searchMountIDs)
        
        if MountJournal and MountJournal.searchBox then
            local searchText = MountJournal.searchBox:GetText()
            print("Current Search:", searchText ~= "" and searchText or "None")
        end
        
    elseif cmd == "test" then
        -- Teste rápido do sistema
        local system = ClickMorphShowAllWardrobe.wardrobeSystem
        print("|cff00ff00=== Wardrobe System Test ===|r")
        print("Active:", system.isActive and "YES" or "NO")
        print("APIs hooked:", (next(system.originalAPIs) ~= nil) and "YES" or "NO")
        
        if system.isActive then
            local numMounts = C_MountJournal.GetNumDisplayedMounts()
            print("Displayed mounts:", numMounts)
            
            -- Teste específico do Tyrael
            local tyrael = C_MountJournal.GetMountInfoByID(439)
            print("Tyrael found:", tyrael and "YES" or "NO")
        end
        
        
    elseif cmd == "status" then
        local system = ClickMorphShowAllWardrobe.wardrobeSystem
        print("|cff9966ff=== ClickMorph Wardrobe Status ===|r")
        print("System Active: " .. (system.isActive and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("Debug Mode: " .. (system.debugMode and "|cff00ff00ON|r" or "|cffccccccOFF|r"))
        print("APIs Hooked: " .. ((next(system.originalAPIs) ~= nil) and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("Mount Cache: " .. #system.mountCache .. " entries")
        
    else
        print("|cff9966ff=== ClickMorph Wardrobe Commands ===|r")
        print("|cffffcc00/cmwardrobe on|r - Unlock mounts + activate wardrobe stubs")
        print("|cffffcc00/cmwardrobe off|r - Revert to normal")
        print("|cffffcc00/cmwardrobe debug|r - Toggle debug mode")
        print("|cffffcc00/cmwardrobe refresh|r - Force Mount Journal refresh")
        print("|cffffcc00/cmwardrobe search|r - Test search system")
        print("|cffffcc00/cmwardrobe test|r - Quick system test")
        print("|cffffcc00/cmwardrobe status|r - Show system status")
        print("")
        print("|cffccccccThis system forces ALL mounts to show as collected|r")
        print("|cffccccccincluding hidden ones like Tyrael's Charger|r")
    end
end

-------------------------------------------------
-- INTEGRAÇÃO COM SISTEMA PRINCIPAL (se existir)
-------------------------------------------------

-- Tentar integrar com o sistema ShowAll principal se ele existir
local function TryIntegrateWithMainSystem()
    if ClickMorphShowAll and ClickMorphShowAll.unlockSystem then
        WardrobeDebugPrint("Found main ShowAll system, integrating...")
        
        -- Adicionar comando integrado
        SLASH_CLICKMORPH_SHOWALL_WARDROBE1 = "/cm"
        SLASH_CLICKMORPH_SHOWALL_WARDROBE2 = "/cmshowall"
        
        SlashCmdList.CLICKMORPH_SHOWALL_WARDROBE = function(arg)
            local cmd = string.lower(arg or "")
            
            if cmd == "showall" or cmd == "wardrobe" then
                ClickMorphShowAllWardrobe:ActivateWardrobe()
            else
                -- Passar para o sistema principal se existir
                if SlashCmdList.CLICKMORPH_SHOWALL then
                    SlashCmdList.CLICKMORPH_SHOWALL(arg)
                else
                    ClickMorphShowAllWardrobe:ActivateWardrobe()
                end
            end
        end
        
        WardrobeDebugPrint("Integration with main system complete")
    else
        WardrobeDebugPrint("No main ShowAll system found, running standalone")
    end
end

-- Tentar integração após delay
C_Timer.After(1, TryIntegrateWithMainSystem)

-------------------------------------------------
-- Inicialização
-------------------------------------------------
print("|cff9966ff=== ClickMorph ShowAll Wardrobe ===|r")
print("|cff00ff00Mount system:|r Enhanced with important mount discovery")
print("|cff00ff00Wardrobe system:|r Safe stub implementation")
print("|cffffcc00Commands:|r /cmwardrobe on/off/debug/test/status")
print("|cffcccccc(Auto-integration with main /cm system if available)|r")

WardrobeDebugPrint("SaveHubWardrobe.lua loaded successfully")