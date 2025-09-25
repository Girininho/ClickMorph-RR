-- ClickMorph SaveHub Wardrobe - FIXED VERSION
-- Sistema CORRIGIDO para unlock de wardrobe sem erros

ClickMorphShowAllWardrobe = ClickMorphShowAllWardrobe or {}

-- Sistema de wardrobe com validação
ClickMorphShowAllWardrobe.wardrobeSystem = {
    isActive = false,
    originalAPIs = {},
    debugMode = false,
    settingsIntegrated = false,
    configKey = "enableWardrobeShowAll",
    mountCache = {},
    lastRefresh = 0,
    activeSearch = false,
    searchMountIDs = {}
}

-- Sistema de debug seguro
local function WardrobeDebugPrint(...)
    if ClickMorphShowAllWardrobe.wardrobeSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" and type(args[i]) ~= "number" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff9966ffSaveWardrobe:|r", message)
    end
end

-- ========================================
-- CORREÇÃO 1: HOOK SEGURO DE GetAppearanceSourceInfo
-- ========================================
function ClickMorphShowAllWardrobe:HookAppearanceSourceInfo()
    local system = self.wardrobeSystem
    
    if not system.originalAPIs.GetAppearanceSourceInfo then
        system.originalAPIs.GetAppearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo
    end
    
    C_TransmogCollection.GetAppearanceSourceInfo = function(sourceID)
        -- Validar parâmetro de entrada
        if not sourceID or type(sourceID) ~= "number" then
            WardrobeDebugPrint("GetAppearanceSourceInfo: Invalid sourceID", tostring(sourceID))
            return nil
        end
        
        -- Chamar API original com segurança
        local success, info = pcall(system.originalAPIs.GetAppearanceSourceInfo, sourceID)
        
        if not success then
            WardrobeDebugPrint("GetAppearanceSourceInfo: Error calling original API for", sourceID)
            return nil
        end
        
        -- CORREÇÃO: Verificar se info é uma tabela válida
        if type(info) ~= "table" then
            WardrobeDebugPrint("GetAppearanceSourceInfo: Original API returned", type(info), "for sourceID", sourceID)
            
            -- Retornar estrutura válida como fallback
            if info then
                return {
                    sourceID = sourceID,
                    isCollected = true,
                    isUsable = true,
                    name = "Unknown Source",
                    quality = 1,
                    visualID = sourceID
                }
            end
            return nil
        end
        
        -- Se é uma tabela válida, aplicar unlock
        if info then
            info.isCollected = true
            info.isUsable = true
            info.isValidAppearanceForPlayer = true
            info.hasNoSourceInfo = false
            WardrobeDebugPrint("GetAppearanceSourceInfo: Unlocked sourceID", sourceID, "name:", info.name or "unnamed")
        end
        
        return info
    end
    
    WardrobeDebugPrint("GetAppearanceSourceInfo hooked safely")
end

-- ========================================
-- CORREÇÃO 2: HOOK SEGURO DE GetCategoryAppearances  
-- ========================================
function ClickMorphShowAllWardrobe:HookCategoryAppearances()
    local system = self.wardrobeSystem
    
    if not system.originalAPIs.GetCategoryAppearances then
        system.originalAPIs.GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances
    end
    
    C_TransmogCollection.GetCategoryAppearances = function(categoryID, transmogLocation)
        -- CORREÇÃO: Validar parâmetros obrigatórios
        if not categoryID or type(categoryID) ~= "number" then
            WardrobeDebugPrint("GetCategoryAppearances: Invalid categoryID", tostring(categoryID))
            return {} -- Retornar tabela vazia em vez de nil
        end
        
        -- Chamar API original com validação
        local success, appearances = pcall(system.originalAPIs.GetCategoryAppearances, categoryID, transmogLocation)
        
        if not success then
            WardrobeDebugPrint("GetCategoryAppearances: Error calling original API for category", categoryID)
            return {}
        end
        
        -- Garantir que é uma tabela
        if type(appearances) ~= "table" then
            WardrobeDebugPrint("GetCategoryAppearances: Original API returned", type(appearances), "for category", categoryID)
            return {}
        end
        
        -- Aplicar unlock a todas as appearances
        for i, appearance in ipairs(appearances) do
            if type(appearance) == "table" then
                appearance.isCollected = true
                appearance.isUsable = true
                appearance.isValidAppearanceForPlayer = true
                appearance.hasNoSourceInfo = false
                appearance.isHideVisual = false
            end
        end
        
        WardrobeDebugPrint("GetCategoryAppearances: Category", categoryID, "returned", #appearances, "appearances (all unlocked)")
        return appearances
    end
    
    WardrobeDebugPrint("GetCategoryAppearances hooked safely")
end

-- ========================================
-- SISTEMA DE MOUNTS (mantido do original)
-- ========================================
function ClickMorphShowAllWardrobe:ActivateMounts()
    -- Delegar para o sistema principal ShowAll se disponível
    if ClickMorphShowAll and ClickMorphShowAll.unlockSystem then
        if not ClickMorphShowAll.unlockSystem.isActive then
            WardrobeDebugPrint("Activating main ShowAll mount system...")
            if ClickMorphShowAll.StartUnlock then
                ClickMorphShowAll.StartUnlock()
            end
        else
            WardrobeDebugPrint("Main ShowAll system already active")
        end
        return
    end
    
    WardrobeDebugPrint("Main ShowAll system not found, using basic mount unlock stub")
    
    -- Fallback básico para mounts
    local system = self.wardrobeSystem
    if not system.originalAPIs.GetNumDisplayedMounts then
        system.originalAPIs.GetNumDisplayedMounts = C_MountJournal.GetNumDisplayedMounts
        system.originalAPIs.GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo
        system.originalAPIs.GetMountInfoByID = C_MountJournal.GetMountInfoByID
    end
    
    -- Hook básico para mostrar mais mounts
    C_MountJournal.GetMountInfoByID = function(mountID)
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountIDReturn = 
            system.originalAPIs.GetMountInfoByID(mountID)
        
        if name then
            -- Aplicar unlock básico
            return name, spellID, icon, isActive, true, sourceType, isFavorite, isFactionSpecific, faction, false, true, mountIDReturn
        end
        
        return name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountIDReturn
    end
    
    WardrobeDebugPrint("Basic mount unlock activated")
end

function ClickMorphShowAllWardrobe:DeactivateMounts()
    if ClickMorphShowAll and ClickMorphShowAll.unlockSystem and ClickMorphShowAll.unlockSystem.isActive then
        WardrobeDebugPrint("Deactivating main ShowAll system...")
        if ClickMorphShowAll.RevertAPIs then
            ClickMorphShowAll.RevertAPIs()
        end
        return
    end
    
    -- Restaurar APIs básicas de mount
    local system = self.wardrobeSystem
    if system.originalAPIs.GetNumDisplayedMounts then
        C_MountJournal.GetNumDisplayedMounts = system.originalAPIs.GetNumDisplayedMounts
        C_MountJournal.GetDisplayedMountInfo = system.originalAPIs.GetDisplayedMountInfo
        C_MountJournal.GetMountInfoByID = system.originalAPIs.GetMountInfoByID
    end
    
    WardrobeDebugPrint("Basic mount APIs restored")
end

-- ========================================
-- ATIVAÇÃO E DESATIVAÇÃO PRINCIPAL
-- ========================================
-- CORREÇÃO: Função sem self
function ClickMorphShowAllWardrobe.ActivateWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.isActive then
        WardrobeDebugPrint("Wardrobe system already active")
        return
    end
    
    WardrobeDebugPrint("Activating wardrobe system with safe hooks...")
    
    -- Aplicar hooks seguros
    ClickMorphShowAllWardrobe.HookAppearanceSourceInfo()
    ClickMorphShowAllWardrobe.HookCategoryAppearances()
    
    -- Ativar sistema de montarias
    ClickMorphShowAllWardrobe.ActivateMounts()
    
    system.isActive = true
    print("|cff00ff00ClickMorph SaveHub Wardrobe:|r Activated safely!")
    print("|cffffff00Features:|r Unlocked appearances • Enhanced mount access")
    
    WardrobeDebugPrint("Wardrobe system fully activated")
end

function ClickMorphShowAllWardrobe:RevertWardrobe()
    local system = self.wardrobeSystem
    
    if not system.isActive then
        print("|cffffffff00ClickMorph SaveHub Wardrobe:|r System not active")
        return
    end
    
    WardrobeDebugPrint("Reverting wardrobe system...")
    
    -- Desativar mounts
    self:DeactivateMounts()
    
    -- Restaurar APIs de transmog
    if system.originalAPIs.GetAppearanceSourceInfo then
        C_TransmogCollection.GetAppearanceSourceInfo = system.originalAPIs.GetAppearanceSourceInfo
    end
    if system.originalAPIs.GetCategoryAppearances then
        C_TransmogCollection.GetCategoryAppearances = system.originalAPIs.GetCategoryAppearances
    end
    
    -- Limpar cache
    wipe(system.mountCache)
    system.lastRefresh = 0
    
    system.isActive = false
    print("|cff00ff00ClickMorph SaveHub Wardrobe:|r Reverted to original state")
    WardrobeDebugPrint("Wardrobe system reverted successfully")
end

-- ========================================
-- REFRESH DA UI
-- ========================================
function ClickMorphShowAllWardrobe:RefreshMountJournal()
    if MountJournal and MountJournal:IsShown() then
        local success = pcall(function()
            if MountJournal_UpdateMountList then
                MountJournal_UpdateMountList()
            end
            if MountJournal_FullUpdate then
                MountJournal_FullUpdate(MountJournal)
            end
        end)
        
        if success then
            WardrobeDebugPrint("Mount Journal refreshed successfully")
        else
            WardrobeDebugPrint("Error refreshing Mount Journal")
        end
    end
end

-- ========================================
-- INTEGRAÇÃO COM CONFIG (callback para Commands.lua)
-- ========================================
function ClickMorphShowAllWardrobe.OnConfigToggle(enabled)
    WardrobeDebugPrint("Config toggle received:", enabled and "ON" or "OFF")
    
    if enabled then
        ClickMorphShowAllWardrobe.ActivateWardrobe()
    else
        ClickMorphShowAllWardrobe.RevertWardrobe()
    end
end

-- ========================================
-- COMANDOS SLASH SEGUROS
-- ========================================
SLASH_CLICKMORPH_SAVEWARDROBE1 = "/cmwardrobe"
SlashCmdList.CLICKMORPH_SAVEWARDROBE = function(arg)
    local cmd = string.lower(arg or "")
    
    if cmd == "on" or cmd == "" then
        ClickMorphShowAllWardrobe.ActivateWardrobe()
        
    elseif cmd == "off" then
        ClickMorphShowAllWardrobe.RevertWardrobe()
        
    elseif cmd == "status" then
        local system = ClickMorphShowAllWardrobe.wardrobeSystem
        print("|cff00ff00=== SaveHub Wardrobe Status ===|r")
        print("Active:", system.isActive and "|cff00ff00YES|r" or "|cffccccccNO|r")
        print("Debug Mode:", system.debugMode and "|cffffcc00ON|r" or "|cffccccccOFF|r")
        print("Config Integration:", system.settingsIntegrated and "|cff00ff00YES|r" or "|cffccccccNO|r")
        
        if system.isActive then
            print("Hooked APIs:")
            for apiName, _ in pairs(system.originalAPIs) do
                print("  ✓", apiName)
            end
        end
        
    elseif cmd == "debug" then
        ClickMorphShowAllWardrobe.wardrobeSystem.debugMode = not ClickMorphShowAllWardrobe.wardrobeSystem.debugMode
        print("|cff00ff00SaveHub Wardrobe:|r Debug mode", ClickMorphShowAllWardrobe.wardrobeSystem.debugMode and "ON" or "OFF")
        
    elseif cmd == "refresh" then
        ClickMorphShowAllWardrobe.RefreshMountJournal()
        print("|cff00ff00SaveHub Wardrobe:|r UI refreshed")
        
    else
        print("|cff00ff00SaveHub Wardrobe Commands:|r")
        print("/cmwardrobe on - Activate safe wardrobe unlock")
        print("/cmwardrobe off - Revert to original")
        print("/cmwardrobe status - Show system status")
        print("/cmwardrobe debug - Toggle debug mode")
        print("/cmwardrobe refresh - Refresh UI")
        print("")
        print("|cffccccccSafe wardrobe unlock with proper error handling|r")
    end
end

-- ========================================
-- API PÚBLICA PARA INTEGRAÇÃO COM MENU /cm
-- ========================================
ClickMorphShowAllWardrobe.API = {
    OnToggle = ClickMorphShowAllWardrobe.OnConfigToggle,
    IsActive = function()
        return ClickMorphShowAllWardrobe.wardrobeSystem.isActive
    end,
    GetConfigKey = function()
        return ClickMorphShowAllWardrobe.wardrobeSystem.configKey
    end,
    GetStatus = function()
        return {
            isActive = ClickMorphShowAllWardrobe.wardrobeSystem.isActive,
            isIntegrated = ClickMorphShowAllWardrobe.wardrobeSystem.settingsIntegrated,
            debugMode = ClickMorphShowAllWardrobe.wardrobeSystem.debugMode
        }
    end
}

-- ========================================
-- INICIALIZAÇÃO SEGURA
-- ========================================
local function Initialize()
    WardrobeDebugPrint("Initializing SaveHub Wardrobe system...")
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            WardrobeDebugPrint("ClickMorph loaded")
            
        elseif event == "PLAYER_LOGIN" then
            WardrobeDebugPrint("Player login completed")
        end
    end)
end

Initialize()

print("|cff00ff00ClickMorph SaveHub Wardrobe|r loaded!")
print("Safe wardrobe unlock with error handling - Use |cffffcc00/cmwardrobe on|r")
WardrobeDebugPrint("SaveHubWardrobe.lua loaded successfully")