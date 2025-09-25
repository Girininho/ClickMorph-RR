-- Immediate Compatibility Fix - Aplicar ANTES de qualquer coisa carregar
-- Este arquivo deve ser o PRIMEIRO a ser carregado no .toc

-- =============================================================================
-- INICIALIZAÇÃO IMEDIATA DOS SISTEMAS
-- =============================================================================

-- Criar estruturas base IMEDIATAMENTE
_G.ClickMorphCustomWardrobe = _G.ClickMorphCustomWardrobe or {}
_G.ClickMorphCustomWardrobe.wardrobeSystem = _G.ClickMorphCustomWardrobe.wardrobeSystem or {
    config = {},
    settings = {},
    tabs = {},
    tabPanels = {},
    isVisible = false,
    currentTab = 1,
    mainFrame = nil
}

-- Sincronizar settings e config
local function SyncConfigSettings()
    local system = _G.ClickMorphCustomWardrobe.wardrobeSystem
    
    -- Estrutura padrão
    local defaults = {
        frameSize = {width = 832, height = 588},
        previewSize = {width = 338, height = 424},
        gridSize = {width = 464, height = 424},
        showTooltips = true,
        autoPreview = true,
        debugMode = false,
        enableShowAll = false,
        autoEnableShowAll = false,
        magicReset = true,
        smartDiscovery = true,
        autoSaveSlots = true,
        enablePauldrons = true,
        chatOutput = true
    }
    
    -- Garantir que ambos existem e são iguais
    system.settings = system.settings or CopyTable(defaults)
    system.config = system.config or CopyTable(defaults)
    
    -- Sincronizar se um tem mais dados que o outro
    for key, value in pairs(system.settings) do
        if system.config[key] == nil then
            system.config[key] = value
        end
    end
    
    for key, value in pairs(system.config) do
        if system.settings[key] == nil then
            system.settings[key] = value
        end
    end
end

-- Aplicar sync imediatamente
SyncConfigSettings()

-- =============================================================================
-- CRIAR SISTEMAS DEPENDENTES
-- =============================================================================

-- MorphCatalogue system
_G.ClickMorphMorphCatalogue = _G.ClickMorphMorphCatalogue or {}
_G.ClickMorphMorphCatalogue.catalogueSystem = _G.ClickMorphMorphCatalogue.catalogueSystem or {
    settings = {
        debugMode = false,
        showTooltips = true,
        autoPreview = true
    }
}

-- MountShop system
_G.ClickMorphMountShop = _G.ClickMorphMountShop or {}
_G.ClickMorphMountShop.mountShopSystem = _G.ClickMorphMountShop.mountShopSystem or {
    settings = {
        debugMode = false,
        showTooltips = true,
        autoPreview = true
    }
}

-- =============================================================================
-- CRIAR APIs FALTANDO
-- =============================================================================

-- =============================================================================
-- CRIAR APIs FALTANDO (MAIS ROBUSTAS)
-- =============================================================================

-- =============================================================================
-- FORÇA CRIAÇÃO DAS APIs EM MÚLTIPLOS LOCAIS
-- =============================================================================

-- Função para forçar criação das APIs
local function ForceCreateAPIs()
    -- Garantir que ClickMorphCustomWardrobe existe
    if not _G.ClickMorphCustomWardrobe then
        _G.ClickMorphCustomWardrobe = {}
    end
    
    -- Garantir que wardrobeSystem existe
    if not _G.ClickMorphCustomWardrobe.wardrobeSystem then
        _G.ClickMorphCustomWardrobe.wardrobeSystem = {
            config = {},
            settings = {},
            tabs = {},
            tabPanels = {},
            isVisible = false,
            currentTab = 1,
            mainFrame = nil
        }
    end
    
    -- FORÇAR API a existir
    _G.ClickMorphCustomWardrobe.API = _G.ClickMorphCustomWardrobe.API or {}
    
    -- RegisterTabContent FORÇADO
    _G.ClickMorphCustomWardrobe.API.RegisterTabContent = function(tabName, contentFunction)
        _G.ClickMorphCustomWardrobe.registeredTabs = _G.ClickMorphCustomWardrobe.registeredTabs or {}
        _G.ClickMorphCustomWardrobe.registeredTabs[tabName] = contentFunction
        print("|cff00ff00ClickMorph:|r Tab content registered for", tabName)
    end

    -- CreatePreview3D FORÇADO
    _G.ClickMorphCustomWardrobe.API.CreatePreview3D = function(parent, position, size)
        local preview = CreateFrame("Frame", nil, parent)
        preview:SetSize(size.width or 300, size.height or 300)
        
        local point = position.point or "CENTER"
        local relativeTo = position.relativeTo or "CENTER" 
        local x = position.x or 0
        local y = position.y or 0
        
        if parent and parent.GetName and parent:GetName() then
            preview:SetPoint(point, parent, relativeTo, x, y)
        else
            preview:SetPoint(point, UIParent, "CENTER", x, y)
        end
        
        local bg = preview:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        local text = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("3D Preview\n(Coming Soon)")
        text:SetTextColor(0.7, 0.7, 0.7)
        
        return preview
    end

    -- CreateFilterSystem FORÇADO
    _G.ClickMorphCustomWardrobe.API.CreateFilterSystem = function(parent, position, size)
        local filter = CreateFrame("Frame", nil, parent)
        filter:SetSize(size.width or 180, size.height or 300)
        filter:SetPoint(position.point or "TOPLEFT", parent, position.relativeTo or "TOPLEFT", position.x or 0, position.y or 0)
        
        local bg = filter:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)
        
        local text = filter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Filter System\n(Coming Soon)")
        text:SetTextColor(0.7, 0.7, 0.7)
        
        return filter
    end

    -- CreateAssetGrid FORÇADO
    _G.ClickMorphCustomWardrobe.API.CreateAssetGrid = function(parent, position, size)
        local grid = CreateFrame("Frame", nil, parent)
        grid:SetSize(size.width or 380, size.height or 300)
        grid:SetPoint(position.point or "CENTER", parent, position.relativeTo or "CENTER", position.x or 0, position.y or 0)
        
        grid.buttonsPerRow = 6
        grid.buttonSize = 56
        grid.buttonSpacing = 60
        
        local bg = grid:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        local text = grid:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Asset Grid\n(Coming Soon)")
        text:SetTextColor(0.7, 0.7, 0.7)
        
        return grid
    end
    
    -- Sincronizar settings
    SyncConfigSettings()
end

-- Aplicar múltiplas vezes para garantir
ForceCreateAPIs()
C_Timer.After(0.1, ForceCreateAPIs)
C_Timer.After(0.5, ForceCreateAPIs)
C_Timer.After(1, ForceCreateAPIs)

-- =============================================================================
-- DEBUG FUNCTIONS UNIVERSAIS
-- =============================================================================

-- Função de debug que funciona com qualquer sistema
_G.MountShopDebugPrint = _G.MountShopDebugPrint or function(...)
    local system = _G.ClickMorphMountShop and _G.ClickMorphMountShop.mountShopSystem
    if system and system.settings and system.settings.debugMode then
        print("|cff00ffffMountShop:|r", ...)
    end
end

_G.CatalogueDebugPrint = _G.CatalogueDebugPrint or function(...)
    local system = _G.ClickMorphMorphCatalogue and _G.ClickMorphMorphCatalogue.catalogueSystem
    if system and system.settings and system.settings.debugMode then
        print("|cff00ffffCatalogue:|r", ...)
    end
end

_G.WardrobeDebugPrint = _G.WardrobeDebugPrint or function(...)
    local system = _G.ClickMorphCustomWardrobe and _G.ClickMorphCustomWardrobe.wardrobeSystem
    if system and system.settings and system.settings.debugMode then
        print("|cff00ffffWardrobe:|r", ...)
    end
end

-- =============================================================================
-- COMANDO /CM OVERRIDE IMEDIATO
-- =============================================================================

-- Handler melhorado para /cm que substitui completamente o original
local function EnhancedClickMorphHandler(msg)
    local command = string.lower(msg or "")
    
    if command == "" then
        -- Abrir wardrobe diretamente
        if ClickMorphCustomWardrobe and ClickMorphCustomWardrobe.Show then
            ClickMorphCustomWardrobe.Show()
        else
            print("|cff00ff00ClickMorph:|r Wardrobe system loading... try again in a moment.")
        end
        return
        
    elseif command == "settings" then
        -- Abrir settings tab
        if ClickMorphCustomWardrobe and ClickMorphCustomWardrobe.Show and ClickMorphCustomWardrobe.SelectTab then
            ClickMorphCustomWardrobe.Show()
            ClickMorphCustomWardrobe.SelectTab(4)
        else
            print("|cff00ff00ClickMorph:|r Settings panel loading... try again in a moment.")
        end
        return
        
    elseif command == "showall" then
        -- Toggle ShowAll
        if ClickMorphShowAllWardrobe then
            if ClickMorphShowAllWardrobe.wardrobeSystem.isActive then
                ClickMorphShowAllWardrobe.RevertWardrobe()
                print("|cff00ff00ClickMorph:|r ShowAll deactivated")
            else
                ClickMorphShowAllWardrobe.ActivateWardrobe()
                print("|cff00ff00ClickMorph:|r ShowAll activated!")
            end
        else
            print("|cffff0000ClickMorph:|r ShowAll system not available!")
        end
        return
        
    elseif command == "help" then
        -- Menu de ajuda
        print("|cff00ff00=== ClickMorph Retail Remaster ===|r")
        print("|cffffcc00/cm|r - Open enhanced wardrobe interface")
        print("|cffffcc00/cm settings|r - Open settings panel") 
        print("|cffffcc00/cm showall|r - Toggle wardrobe unlock")
        print("|cffffcc00/cm reset|r - Reset appearance")
        print("|cffffcc00/cm debug|r - Show system status")
        print("")
        print("|cffccccccEnhanced interface with tabs and ShowAll integration|r")
        return
        
    else
        -- Para outros comandos, tentar chamar handler original se existir
        if _G.ClickMorphOriginalHandler then
            _G.ClickMorphOriginalHandler(msg)
        else
            print("|cffff0000ClickMorph:|r Unknown command. Use |cffffcc00/cm help|r for available commands.")
        end
        return
    end
end

-- Substituição imediata do comando /cm
local function OverrideClickMorphCommandImmediate()
    -- Salvar handler original se existir
    if SlashCmdList["CLICKMORPH"] then
        _G.ClickMorphOriginalHandler = SlashCmdList["CLICKMORPH"]
    end
    
    -- Substituir com nossa versão melhorada
    SlashCmdList["CLICKMORPH"] = EnhancedClickMorphHandler
    
    print("|cff00ff00ClickMorph:|r Enhanced command handler loaded! Type |cffffcc00/cm|r to open wardrobe.")
end

-- Aplicar override imediatamente
OverrideClickMorphCommandImmediate()

-- E reaplicar após um delay para garantir
C_Timer.After(1, OverrideClickMorphCommandImmediate)
C_Timer.After(3, OverrideClickMorphCommandImmediate)

-- =============================================================================
-- FORCE SYNC FUNCTION
-- =============================================================================

-- =============================================================================
-- FORÇA SYNC FUNCTION E COMANDOS DE TESTE
-- =============================================================================

_G.ClickMorphForceSync = function()
    SyncConfigSettings()
    ForceCreateAPIs()
    print("|cff00ff00ClickMorph:|r Force sync applied!")
end

-- Comando para forçar APIs
SLASH_CLICKMORPH_FORCE_APIS1 = "/cmfixapis"
SlashCmdList.CLICKMORPH_FORCE_APIS = function()
    ForceCreateAPIs()
    print("|cff00ff00ClickMorph:|r APIs force-created!")
    
    -- Testar se funcionou
    C_Timer.After(0.5, function()
        local cw = _G.ClickMorphCustomWardrobe
        if cw and cw.API then
            print("RegisterTabContent:", cw.API.RegisterTabContent and "OK" or "STILL MISSING")
            print("CreatePreview3D:", cw.API.CreatePreview3D and "OK" or "STILL MISSING")
            print("CreateFilterSystem:", cw.API.CreateFilterSystem and "OK" or "STILL MISSING")
            print("CreateAssetGrid:", cw.API.CreateAssetGrid and "OK" or "STILL MISSING")
        else
            print("ClickMorphCustomWardrobe.API still missing!")
        end
    end)
end

-- =============================================================================
-- COMANDO DE TESTE IMEDIATO
-- =============================================================================

SLASH_CLICKMORPH_IMMEDIATE_TEST1 = "/cmtest"
SlashCmdList.CLICKMORPH_IMMEDIATE_TEST = function()
    print("|cff00ff00Immediate Fix Test:|r")
    
    -- Testar CustomWardrobe
    local cw = _G.ClickMorphCustomWardrobe
    print("CustomWardrobe:", cw and "EXISTS" or "MISSING")
    if cw then
        print("  API:", cw.API and "OK" or "MISSING")
        if cw.API then
            print("    RegisterTabContent:", cw.API.RegisterTabContent and "OK" or "MISSING")
            print("    CreatePreview3D:", cw.API.CreatePreview3D and "OK" or "MISSING")
            print("    CreateFilterSystem:", cw.API.CreateFilterSystem and "OK" or "MISSING")
            print("    CreateAssetGrid:", cw.API.CreateAssetGrid and "OK" or "MISSING")
        end
        if cw.wardrobeSystem then
            local sys = cw.wardrobeSystem
            print("  wardrobeSystem:", sys and "OK" or "MISSING")
            print("  settings:", sys.settings and "OK" or "MISSING")
            print("  config:", sys.config and "OK" or "MISSING")
        end
    end
    
    -- Testar MorphCatalogue
    local mc = _G.ClickMorphMorphCatalogue
    print("MorphCatalogue:", mc and "EXISTS" or "MISSING")
    if mc and mc.catalogueSystem then
        print("  catalogueSystem.settings:", mc.catalogueSystem.settings and "OK" or "MISSING")
    end
    
    -- Testar MountShop
    local ms = _G.ClickMorphMountShop
    print("MountShop:", ms and "EXISTS" or "MISSING")
    if ms and ms.mountShopSystem then
        print("  mountShopSystem.settings:", ms.mountShopSystem.settings and "OK" or "MISSING")
    end
    
    -- Testar comando /cm
    print("Command /cm handler:", SlashCmdList["CLICKMORPH"] and "CUSTOM" or "MISSING")
    
    -- Testar debug functions
    print("Debug Functions:")
    print("  MountShopDebugPrint:", _G.MountShopDebugPrint and "OK" or "MISSING")
    print("  CatalogueDebugPrint:", _G.CatalogueDebugPrint and "OK" or "MISSING") 
    print("  WardrobeDebugPrint:", _G.WardrobeDebugPrint and "OK" or "MISSING")
end

print("|cff00ff00ClickMorph:|r Immediate compatibility fix loaded!")