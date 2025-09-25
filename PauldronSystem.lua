-- PauldronSystem.lua - HÍBRIDO CORRIGIDO
-- Estratégia dupla: HandleModifiedItemClick + morpher.item com versão correta

ClickMorphPauldron = {}
ClickMorphPauldron.config = {
    enabled = true,
    debugMode = false,
    showMessages = true
}

local function DebugPrint(...)
    if ClickMorphPauldron.config.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cff9999ff[Pauldron]|r", table.concat(args, " "))
    end
end

-- Pegar versão correta usando a lógica do Wardrobe (EXATAMENTE como CM.MorphTransmogItem faz)
function ClickMorphPauldron.GetVersionFromWardrobe(itemID)
    DebugPrint("WARDROBE VERSION DETECTION for itemID:", itemID)
    
    -- Método 1: Verificar se estamos no Wardrobe e pegar do modelo ativo
    local wardrobeFrame = WardrobeCollectionFrame
    if wardrobeFrame and wardrobeFrame.ItemsCollectionFrame then
        for _, model in pairs(wardrobeFrame.ItemsCollectionFrame.Models) do
            if model:IsShown() and model:IsMouseOver() and model.visualInfo then
                local visualID = model.visualInfo.visualID
                DebugPrint("Found active model - visualID:", visualID)
                
                -- Usar EXATAMENTE a mesma lógica do CM.MorphTransmogItem
                local sources = C_TransmogCollection.GetAllAppearanceSources(visualID)
                
                if sources and #sources > 0 then
                    local sourceInfo = C_TransmogCollection.GetSourceInfo(sources[1])
                    if sourceInfo and sourceInfo.itemID == itemID then
                        local detectedModID = sourceInfo.itemModID or 0
                        DebugPrint("WARDROBE SUCCESS: itemID matches, modID:", detectedModID)
                        return detectedModID
                    else
                        DebugPrint("ItemID mismatch - sourceInfo.itemID:", sourceInfo and sourceInfo.itemID, "expected:", itemID)
                    end
                end
            end
        end
    end
    
    -- Método 2: Fallback - tentar encontrar sourceInfo diretamente pelo itemID
    DebugPrint("FALLBACK: Searching sourceInfo by itemID:", itemID)
    
    -- Iterar pelas categorias para encontrar o item
    for categoryID = 1, 20 do
        local appearances = C_TransmogCollection.GetCategoryAppearances(categoryID)
        if appearances then
            for _, appearance in ipairs(appearances) do
                if appearance.visualID then
                    local sources = C_TransmogCollection.GetAllAppearanceSources(appearance.visualID)
                    if sources then
                        for _, source in ipairs(sources) do
                            -- source pode ser um número (sourceID) ou uma tabela
                            local sourceID = type(source) == "table" and source.sourceID or source
                            local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
                            if sourceInfo and sourceInfo.itemID == itemID then
                                local modID = sourceInfo.itemModID or 0
                                DebugPrint("FALLBACK SUCCESS: Found itemID in category", categoryID, "modID:", modID)
                                return modID
                            end
                        end
                    end
                end
            end
        end
    end
    
    DebugPrint("WARDROBE DETECTION FAILED: No version found for itemID", itemID)
    return 0
end

-- Executar comando personalizado
function ClickMorphPauldron.ExecuteCustomCommand(itemID, side, version)
    DebugPrint("ExecuteCustomCommand - ItemID:", itemID, "Side:", side, "Version:", version)
    
    local command = ""
    local message = ""
    
    if side == "both" then
        message = "Both shoulders"
        if version > 0 then
            command = string.format(".item 3 %d %d 0", itemID, version)
        else
            command = string.format(".item 3 %d 0 0", itemID)
        end
        
        -- Reset primeiro para "both"
        if iMorphChatHandler then
            iMorphChatHandler(".reset")
            C_Timer.After(0.1, function()
                iMorphChatHandler(command)
            end)
        else
            SendChatMessage(".reset", "SAY")
            C_Timer.After(0.1, function()
                SendChatMessage(command, "SAY")
            end)
        end
        
    elseif side == "right_split" then
        message = "Right shoulder only"
        if version > 0 then
            command = string.format(".item 3 %d %d 1", itemID, version)
        else
            command = string.format(".item 3 %d 0 1", itemID)
        end
        
        -- Aplicar diretamente para split
        if iMorphChatHandler then
            iMorphChatHandler(command)
        else
            SendChatMessage(command, "SAY")
        end
        
    elseif side == "left_invisible" then
        message = "Left shoulder invisible"
        command = ".item 3 1371 0 0"
        
        if iMorphChatHandler then
            iMorphChatHandler(command)
        else
            SendChatMessage(command, "SAY")
        end
    end
    
    DebugPrint("Executed command:", command)
    
    if ClickMorphPauldron.config.showMessages then
        local versionText = version > 0 and (" v" .. version) or ""
        print("|cff00ff00Pauldron:|r " .. message .. " (ID: " .. itemID .. versionText .. ")")
    end
end

-- ESTRATÉGIA HÍBRIDA CORRIGIDA
function ClickMorphPauldron.InstallHybridHook()
    local morpher = CM:CanMorph(true)
    if not morpher or not morpher.item then
        DebugPrint("❌ Morpher not available")
        return false
    end
    
    if ClickMorphPauldron.originalMorpherItem then
        DebugPrint("Hybrid hook already installed")
        return true
    end
    
    DebugPrint("Installing hybrid hook system...")
    
    -- HOOK 1: HandleModifiedItemClick para Shift+Click e Ctrl+Shift+Click
    if not ClickMorphPauldron.originalHandleModifiedItemClick then
        ClickMorphPauldron.originalHandleModifiedItemClick = HandleModifiedItemClick
        
        HandleModifiedItemClick = function(item)
            DebugPrint("🎯 HandleModifiedItemClick intercepted - Item:", item)
            
            -- Se estamos processando, bloquear
            if ClickMorphPauldron.processingPauldron then
                DebugPrint("🚫 BLOCKING HandleModifiedItemClick - processing active")
                return
            end
            
            -- Verificar se é ombreira
            local success, itemID, itemLink, equipLoc = pcall(function()
                if type(item) == "string" then
                    local id = tonumber(item:match("item:(%d+)"))
                    local loc = select(9, GetItemInfo(id))
                    return id, item, loc
                else
                    local link, _, _, _, _, _, _, loc = select(2, GetItemInfo(item))
                    return item, link, loc
                end
            end)
            
            if success and itemID and equipLoc == "INVTYPE_SHOULDER" and ClickMorphPauldron.config.enabled then
                local isAltKeyDown = IsAltKeyDown() or false
                local isShiftKeyDown = IsShiftKeyDown() or false
                local isControlKeyDown = IsControlKeyDown() or false
                
                local isAltShift = isAltKeyDown and isShiftKeyDown and not isControlKeyDown
                local isShiftOnly = isShiftKeyDown and not isAltKeyDown and not isControlKeyDown
                local isCtrlShift = isControlKeyDown and isShiftKeyDown and not isAltKeyDown
                
                DebugPrint("EARLY - Alt:", isAltKeyDown, "Shift:", isShiftKeyDown, "Ctrl:", isControlKeyDown)
                DebugPrint("EARLY - Alt+Shift:", isAltShift, "Shift only:", isShiftOnly, "Ctrl+Shift:", isCtrlShift)
                
                -- INTERCEPTAR apenas Shift+Click e Ctrl+Shift+Click
                if isShiftOnly or isCtrlShift then
                    DebugPrint("✅ EARLY INTERCEPT - Handling", isShiftOnly and "Shift+Click" or "Ctrl+Shift+Click")
                    
                    ClickMorphPauldron.processingPauldron = true
                    
                    -- CAPTURAR VERSÃO usando lógica do Wardrobe (como CM.MorphTransmogItem)
                    local correctVersion = ClickMorphPauldron.GetVersionFromWardrobe(itemID)
                    
                    if isShiftOnly then
                        DebugPrint("Executing SHIFT ONLY with captured version:", correctVersion)
                        ClickMorphPauldron.ExecuteCustomCommand(itemID, "right_split", correctVersion)
                    elseif isCtrlShift then
                        DebugPrint("Executing CTRL+SHIFT")
                        ClickMorphPauldron.ExecuteCustomCommand(itemID, "left_invisible", 0)
                    end
                    
                    C_Timer.After(0.5, function()
                        ClickMorphPauldron.processingPauldron = false
                    end)
                    
                    return -- BLOQUEAR ClickMorph original
                end
            end
            
            return ClickMorphPauldron.originalHandleModifiedItemClick(item)
        end
        
        DebugPrint("✅ HandleModifiedItemClick hook installed")
    end
    
    -- HOOK 2: morpher.item para Alt+Shift+Click
    ClickMorphPauldron.originalMorpherItem = morpher.item
    
    morpher.item = function(unit, slotID, itemID, itemModID)
        DebugPrint("🎯 morpher.item intercepted - SlotID:", slotID, "ItemID:", itemID, "ModID:", itemModID)
        
        if slotID == 3 and ClickMorphPauldron.config.enabled then
            local isAltKeyDown = IsAltKeyDown() or false
            local isShiftKeyDown = IsShiftKeyDown() or false
            local isControlKeyDown = IsControlKeyDown() or false
            
            local isAltShift = isAltKeyDown and isShiftKeyDown and not isControlKeyDown
            
            DebugPrint("MORPHER - Alt:", isAltKeyDown, "Shift:", isShiftKeyDown, "Ctrl:", isControlKeyDown)
            DebugPrint("MORPHER - Alt+Shift:", isAltShift)
            
            if isAltShift then
                DebugPrint("✅ MORPHER INTERCEPT - Alt+Shift+Click")
                
                ClickMorphPauldron.processingPauldron = true
                
                local finalVersion = itemModID or 0
                DebugPrint("Using morpher detected version:", finalVersion)
                
                ClickMorphPauldron.ExecuteCustomCommand(itemID, "both", finalVersion)
                
                C_Timer.After(0.5, function()
                    ClickMorphPauldron.processingPauldron = false
                end)
                
                return -- BLOQUEAR execução original
            end
        end
        
        return ClickMorphPauldron.originalMorpherItem(unit, slotID, itemID, itemModID)
    end
    
    DebugPrint("✅ morpher.item hook installed")
    DebugPrint("✅ Hybrid hook system ready!")
    return true
end

-- Reset do sistema
function ClickMorphPauldron.ResetHybridHook()
    local morpher = CM:CanMorph(true)
    if ClickMorphPauldron.originalMorpherItem and morpher then
        morpher.item = ClickMorphPauldron.originalMorpherItem
        ClickMorphPauldron.originalMorpherItem = nil
    end
    
    if ClickMorphPauldron.originalHandleModifiedItemClick then
        HandleModifiedItemClick = ClickMorphPauldron.originalHandleModifiedItemClick
        ClickMorphPauldron.originalHandleModifiedItemClick = nil
    end
    
    ClickMorphPauldron.processingPauldron = false
    DebugPrint("Hybrid hook system reset")
end

-- Comandos
SLASH_PAULDRON1 = "/pauldron"
SlashCmdList.PAULDRON = function(msg)
    local args = {strsplit(" ", msg)}
    local command = args[1] and args[1]:lower() or ""
    
    if command == "toggle" then
        ClickMorphPauldron.config.enabled = not ClickMorphPauldron.config.enabled
        print("|cff00ff00Pauldron:|r", ClickMorphPauldron.config.enabled and "ENABLED" or "DISABLED")
        
    elseif command == "debug" then
        ClickMorphPauldron.config.debugMode = not ClickMorphPauldron.config.debugMode
        print("|cff00ff00Pauldron:|r Debug mode", ClickMorphPauldron.config.debugMode and "ON" or "OFF")
        
    elseif command == "install" then
        if ClickMorphPauldron.InstallHybridHook() then
            print("|cff00ff00Pauldron:|r Hybrid hook installed!")
        else
            print("|cffff0000Pauldron:|r Failed to install hybrid hook")
        end
        
    elseif command == "reset" then
        ClickMorphPauldron.ResetHybridHook()
        print("|cff00ff00Pauldron:|r Hybrid hook reset")
        
    elseif command == "test" then
        local side = args[2] or "both"
        local itemID = tonumber(args[3]) or 212000
        local version = tonumber(args[4]) or 0
        
        print("|cff00ff00Pauldron:|r Testing", side, "with ID", itemID, "version", version)
        ClickMorphPauldron.ExecuteCustomCommand(itemID, side, version)
        
    elseif command == "status" then
        print("|cff00ff00=== Pauldron Hybrid Status ===|r")
        print("Enabled:", ClickMorphPauldron.config.enabled)
        print("Debug:", ClickMorphPauldron.config.debugMode)
        print("HandleModifiedItemClick hook:", ClickMorphPauldron.originalHandleModifiedItemClick ~= nil)
        print("morpher.item hook:", ClickMorphPauldron.originalMorpherItem ~= nil)
        
        if ClickMorphPauldron.originalMorpherItem and ClickMorphPauldron.originalHandleModifiedItemClick then
            print("|cff00ff00✅ Hybrid system ready!|r")
        else
            print("|cffff0000❌ Hybrid hooks not installed - run /pauldron install|r")
        end
        
    else
        print("|cff00ff00Pauldron Hybrid Commands:|r")
        print("/pauldron toggle - Enable/disable")
        print("/pauldron debug - Toggle debug")
        print("/pauldron install - Install hybrid hooks")
        print("/pauldron reset - Reset hybrid hooks")
        print("/pauldron test <both|right_split|left_invisible> [itemID] [version]")
        print("/pauldron status - Show status")
        print("")
        print("|cffffcc00Hybrid Strategy:|r")
        print("|cffaaff00Alt+Shift+Click:|r Both shoulders (via morpher.item)")
        print("|cffaaff00Shift+Click:|r Right only (via HandleModifiedItemClick)")
        print("|cffaaff00Ctrl+Shift+Click:|r Left invisible (via HandleModifiedItemClick)")
        print("|cffccccccAll with correct version detection|r")
    end
end

-- Inicialização
local function Initialize()
    if not CM or not CM.CanMorph then
        DebugPrint("Waiting for ClickMorph...")
        C_Timer.After(1, Initialize)
        return
    end
    
    local morpher = CM:CanMorph(true)
    if not morpher or not morpher.item then
        DebugPrint("Waiting for morpher...")
        C_Timer.After(1, Initialize)
        return
    end
    
    DebugPrint("Initializing Hybrid Pauldron System...")
    
    if ClickMorphPauldron.InstallHybridHook() then
        print("|cff00ff00ClickMorph Pauldron - Hybrid Corrected|r loaded!")
        print("|cffccccccDual strategy with correct version detection|r")
    else
        C_Timer.After(2, Initialize)
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        C_Timer.After(2, Initialize)
    end
end)