-- ThirdPartyHooks.lua
-- Sistema de integração automática com addons de terceiros (BetterWardrobe, etc)
-- Adicione este arquivo ao ClickMorph.toc DEPOIS do ClickMorph.lua

ClickMorphThirdPartyHooks = {}

-- Lista de addons suportados e suas estruturas
local SUPPORTED_ADDONS = {
    ["BetterWardrobe"] = {
        detection = "BetterWardrobeCollectionFrame",
        mainFrame = "BetterWardrobeCollectionFrame",
        models = {
            "SetsCollectionFrame.Model",
            "ItemsCollectionFrame.Models",
            "Model", -- fallback
        },
        description = "Better Wardrobe and Transmog"
    },
    ["WardrobeEnhanced"] = {
        detection = "WardrobeEnhanced",
        mainFrame = "WardrobeCollectionFrame", -- usa o frame padrão
        models = {
            "SetsCollectionFrame.Model",
            "ItemsCollectionFrame.Models"
        },
        description = "Wardrobe Enhanced"
    },
    ["TransmogOutfits"] = {
        detection = "TransmogOutfitsFrame",
        mainFrame = "TransmogOutfitsFrame",
        models = {
            "Model",
            "PreviewModel"
        },
        description = "Transmog Outfits"
    }
}

-- Sistema de debug
local function THookDebugPrint(...)
    if ClickMorphThirdPartyHooks.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff00ccffThirdParty:|r", message)
    end
end

ClickMorphThirdPartyHooks.debugMode = false

-- Função para aplicar hook em um modelo específico
local function HookModel(model, addonName, modelPath)
    if not model or not model.HookScript then
        THookDebugPrint("Invalid model for", addonName, modelPath)
        return false
    end
    
    -- Verificar se já tem hook
    if model._ClickMorphHooked then
        THookDebugPrint("Model already hooked:", addonName, modelPath)
        return true
    end
    
    -- Aplicar hook
    model:HookScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
            THookDebugPrint("Alt+Shift+Click detected on", addonName, "model")
            
            -- Tentar diferentes funções de morph baseado no contexto
            if CM and CM.MorphTransmogSet then
                CM.MorphTransmogSet()
                print("|cff00ff00ClickMorph:|r Alt+Shift+Click on " .. addonName .. " - Transmog Set!")
            elseif CM and CM.MorphTransmogItem then
                CM.MorphTransmogItem(self)
                print("|cff00ff00ClickMorph:|r Alt+Shift+Click on " .. addonName .. " - Transmog Item!")
            else
                print("|cffff6666ClickMorph:|r No morph function available")
            end
            
            -- Bloquear content tracking se disponível
            if CM and CM.SetTrackingBlock then
                CM:SetTrackingBlock(true)
            end
        end
    end)
    
    model._ClickMorphHooked = true
    THookDebugPrint("Successfully hooked model:", addonName, modelPath)
    return true
end

-- Função para tentar hookear um addon específico
function ClickMorphThirdPartyHooks.HookAddon(addonName)
    local config = SUPPORTED_ADDONS[addonName]
    if not config then
        THookDebugPrint("Addon not supported:", addonName)
        return false
    end
    
    -- Verificar se o addon está presente
    local detectionFrame = _G[config.detection]
    if not detectionFrame then
        THookDebugPrint("Addon not detected:", addonName, "- looking for", config.detection)
        return false
    end
    
    THookDebugPrint("Detected addon:", addonName)
    
    -- Obter frame principal
    local mainFrame = _G[config.mainFrame]
    if not mainFrame then
        THookDebugPrint("Main frame not found for", addonName, "- looking for", config.mainFrame)
        return false
    end
    
    local hooksApplied = 0
    
    -- Tentar hookear cada modelo definido
    for _, modelPath in ipairs(config.models) do
        local parts = {}
        for part in string.gmatch(modelPath, "[^%.]+") do
            table.insert(parts, part)
        end
        
        -- Navegar pela estrutura
        local current = mainFrame
        local fullPath = config.mainFrame
        
        for i, part in ipairs(parts) do
            if current[part] then
                current = current[part]
                fullPath = fullPath .. "." .. part
            else
                THookDebugPrint("Path not found:", fullPath .. "." .. part)
                current = nil
                break
            end
        end
        
        if current then
            if type(current) == "table" and current[1] then
                -- É uma tabela de modelos (como Models)
                for i, model in pairs(current) do
                    if HookModel(model, addonName, fullPath .. "[" .. i .. "]") then
                        hooksApplied = hooksApplied + 1
                    end
                end
            elseif current.HookScript then
                -- É um modelo individual
                if HookModel(current, addonName, fullPath) then
                    hooksApplied = hooksApplied + 1
                end
            else
                THookDebugPrint("Invalid model at path:", fullPath)
            end
        end
    end
    
    if hooksApplied > 0 then
        print("|cff00ff00ClickMorph:|r Integrated with " .. config.description .. " (" .. hooksApplied .. " models)")
        return true
    else
        THookDebugPrint("No models hooked for", addonName)
        return false
    end
end

-- Função específica para BetterWardrobe (mais robusta)
function ClickMorphThirdPartyHooks.HookBetterWardrobe()
    if not BetterWardrobeCollectionFrame then
        print("|cffff6666ClickMorph:|r BetterWardrobe not detected")
        return false
    end
    
    local hooksApplied = 0
    
    -- BetterWardrobe Sets Frame
    if BetterWardrobeCollectionFrame.SetsCollectionFrame and 
       BetterWardrobeCollectionFrame.SetsCollectionFrame.Model then
        
        local model = BetterWardrobeCollectionFrame.SetsCollectionFrame.Model
        if HookModel(model, "BetterWardrobe", "SetsCollectionFrame.Model") then
            hooksApplied = hooksApplied + 1
        end
    end
    
    -- BetterWardrobe Items Frame
    if BetterWardrobeCollectionFrame.ItemsCollectionFrame and 
       BetterWardrobeCollectionFrame.ItemsCollectionFrame.Models then
        
        local models = BetterWardrobeCollectionFrame.ItemsCollectionFrame.Models
        for i, model in pairs(models) do
            if HookModel(model, "BetterWardrobe", "ItemsCollectionFrame.Models[" .. i .. "]") then
                hooksApplied = hooksApplied + 1
            end
        end
    end
    
    -- Verificar se BetterWardrobe tem frames adicionais
    local extraFrames = {
        "ExtraSetsTab",
        "SavedSetsTab",
        "DressingRoomFrame"
    }
    
    for _, frameName in ipairs(extraFrames) do
        local frame = BetterWardrobeCollectionFrame[frameName]
        if frame and frame.Model and frame.Model.HookScript then
            if HookModel(frame.Model, "BetterWardrobe", frameName .. ".Model") then
                hooksApplied = hooksApplied + 1
            end
        end
    end
    
    if hooksApplied > 0 then
        print("|cff00ff00ClickMorph:|r Successfully integrated with BetterWardrobe (" .. hooksApplied .. " models)")
        return true
    else
        print("|cffff6666ClickMorph:|r Failed to integrate with BetterWardrobe")
        return false
    end
end

-- Função para detectar e hookear todos os addons suportados
function ClickMorphThirdPartyHooks.HookAllAddons()
    THookDebugPrint("Scanning for supported third-party addons...")
    
    local detected = {}
    local hooked = {}
    
    for addonName, config in pairs(SUPPORTED_ADDONS) do
        if _G[config.detection] then
            table.insert(detected, addonName)
            if ClickMorphThirdPartyHooks.HookAddon(addonName) then
                table.insert(hooked, addonName)
            end
        end
    end
    
    THookDebugPrint("Scan complete. Detected:", #detected, "Hooked:", #hooked)
    
    if #hooked > 0 then
        print("|cff00ff00ClickMorph:|r Integrated with " .. #hooked .. " third-party addon(s)")
    elseif #detected > 0 then
        print("|cffff6666ClickMorph:|r Found " .. #detected .. " supported addon(s) but failed to integrate")
    else
        THookDebugPrint("No supported third-party addons detected")
    end
    
    return #hooked > 0
end

-- Auto-scan com retry
function ClickMorphThirdPartyHooks.Initialize()
    THookDebugPrint("Initializing third-party hooks system...")
    
    -- Primeiro scan imediato
    ClickMorphThirdPartyHooks.HookAllAddons()
    
    -- Retry após 2 segundos (para addons que carregam tarde)
    C_Timer.After(2, function()
        THookDebugPrint("Retry scan for late-loading addons...")
        ClickMorphThirdPartyHooks.HookAllAddons()
    end)
    
    -- Retry final após 5 segundos
    C_Timer.After(5, function()
        THookDebugPrint("Final scan for third-party addons...")
        ClickMorphThirdPartyHooks.HookAllAddons()
    end)
end

-- Comando para debug e teste manual
SLASH_CLICKMORPH_THIRDPARTY1 = "/cmthird"
SlashCmdList.CLICKMORPH_THIRDPARTY = function(arg)
    local command = string.lower(arg or "")
    
    if command == "debug" then
        ClickMorphThirdPartyHooks.debugMode = not ClickMorphThirdPartyHooks.debugMode
        print("|cff00ccffThirdParty:|r Debug mode", ClickMorphThirdPartyHooks.debugMode and "ON" or "OFF")
        
    elseif command == "scan" then
        print("|cff00ccffThirdParty:|r Manual scan...")
        ClickMorphThirdPartyHooks.HookAllAddons()
        
    elseif command == "better" or command == "betterwardrobe" then
        print("|cff00ccffThirdParty:|r Manual BetterWardrobe hook...")
        ClickMorphThirdPartyHooks.HookBetterWardrobe()
        
    elseif command == "list" then
        print("|cff00ccffThirdParty:|r Supported addons:")
        for name, config in pairs(SUPPORTED_ADDONS) do
            local detected = _G[config.detection] and "|cff00ff00YES|r" or "|cffff6666NO|r"
            print("  " .. config.description .. " (" .. name .. "): " .. detected)
        end
        
    else
        print("|cff00ccffClickMorph Third-Party Integration:|r")
        print("/cmthird scan - Scan for supported addons")
        print("/cmthird better - Force BetterWardrobe integration")
        print("/cmthird list - Show supported addons")
        print("/cmthird debug - Toggle debug mode")
        print("")
        print("Supported: BetterWardrobe, WardrobeEnhanced, TransmogOutfits")
    end
end

-- Event frame para inicialização
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "ClickMorph" then
        -- Aguardar um pouco para outros addons carregarem
        C_Timer.After(1, function()
            ClickMorphThirdPartyHooks.Initialize()
        end)
        
    elseif event == "PLAYER_LOGIN" then
        -- Scan final após login
        C_Timer.After(3, function()
            THookDebugPrint("Post-login scan...")
            ClickMorphThirdPartyHooks.HookAllAddons()
        end)
    end
end)

THookDebugPrint("ThirdPartyHooks.lua loaded successfully")
print("|cff00ccffClickMorph Third-Party Integration:|r Loaded!")
print("Use |cffffcc00/cmthird|r for manual control and testing")