-- WeaponSystem.lua v3 - HÍBRIDO (baseado no PauldronSystem)
-- Estratégia: HandleModifiedItemClick + morpher.item com versão correta

ClickMorphWeapon = {}
ClickMorphWeapon.config = {
    enabled = true,
    debugMode = false,
    showMessages = true
}

ClickMorphWeapon.processing = false
ClickMorphWeapon.lastClickedModel = nil -- Guardar último modelo clicado

local function DebugPrint(...)
    if ClickMorphWeapon.config.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cff00ccff[Weapon]|r", table.concat(args, " "))
    end
end

-- Pegar versão do item clicado (USA ITEMLINK quando disponível)
function ClickMorphWeapon.GetVersionFromItemLink(itemID, itemLink)
    if not itemLink then return 0 end
    
    DebugPrint("Trying GetVersionFromItemLink for:", itemLink)
    
    local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
    if sourceID then
        local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
        if sourceInfo and sourceInfo.itemID == itemID then
            DebugPrint("SUCCESS via ItemLink - ModID:", sourceInfo.itemModID)
            return sourceInfo.itemModID or 0
        end
    end
    
    return 0
end

-- Pegar versão do Wardrobe (USA MODELO CLICADO)
function ClickMorphWeapon.GetVersionFromWardrobe(itemID)
    DebugPrint("VERSION DETECTION for itemID:", itemID)
    
    -- Método 1: Usar o último modelo clicado (MAIS PRECISO)
    if ClickMorphWeapon.lastClickedModel and ClickMorphWeapon.lastClickedModel.visualInfo then
        local visualID = ClickMorphWeapon.lastClickedModel.visualInfo.visualID
        local sources = C_TransmogCollection.GetAllAppearanceSources(visualID)
        
        if sources and #sources > 0 then
            local sourceInfo = C_TransmogCollection.GetSourceInfo(sources[1])
            if sourceInfo and sourceInfo.itemID == itemID then
                local modID = sourceInfo.itemModID or 0
                DebugPrint("✅ LAST CLICKED MODEL - ItemID:", itemID, "ModID:", modID, "VisualID:", visualID)
                return modID
            else
                DebugPrint("Last clicked model itemID mismatch - expected:", itemID, "got:", sourceInfo and sourceInfo.itemID)
            end
        end
    else
        DebugPrint("No lastClickedModel or visualInfo")
    end
    
    -- Método 2: Fallback - procurar nos modelos visíveis
    DebugPrint("Fallback: Searching visible models...")
    
    local wardrobeFrame = BetterWardrobeCollectionFrame or WardrobeCollectionFrame
    
    if not wardrobeFrame or not wardrobeFrame.ItemsCollectionFrame then
        DebugPrint("No wardrobe frame found")
        return 0
    end
    
    local itemsFrame = wardrobeFrame.ItemsCollectionFrame
    if not itemsFrame.Models then
        DebugPrint("No models in ItemsCollectionFrame")
        return 0
    end
    
    for _, model in pairs(itemsFrame.Models) do
        if model.visualInfo then
            local visualID = model.visualInfo.visualID
            local sources = C_TransmogCollection.GetAllAppearanceSources(visualID)
            
            if sources and #sources > 0 then
                local sourceInfo = C_TransmogCollection.GetSourceInfo(sources[1])
                if sourceInfo and sourceInfo.itemID == itemID then
                    local modID = sourceInfo.itemModID or 0
                    DebugPrint("FALLBACK SUCCESS: Found in visible models - ItemID:", itemID, "ModID:", modID, "VisualID:", visualID)
                    return modID
                end
            end
        end
    end
    
    DebugPrint("FAILED: ItemID not found")
    return 0
end

-- Executar comando de arma
function ClickMorphWeapon.ExecuteWeaponCommand(itemID, slot, modID)
    if not iMorphChatHandler then
        print("|cffff0000Weapon:|r iMorph not available")
        return
    end
    
    DebugPrint("ExecuteWeaponCommand - ItemID:", itemID, "Slot:", slot, "ModID:", modID)
    
    if slot == "reset" then
        iMorphChatHandler(".item 16 0")
        C_Timer.After(0.05, function()
            iMorphChatHandler(".item 17 0")
        end)
        C_Timer.After(0.1, function()
            iMorphChatHandler(".item 18 0")
        end)
        
        if ClickMorphWeapon.config.showMessages then
            print("|cff00ff00Weapon:|r All weapons reset")
        end
        return
    end
    
    local slotNum, slotName
    if slot == "mainhand" then
        slotNum, slotName = 16, "Main Hand"
    elseif slot == "offhand" then
        slotNum, slotName = 17, "Off Hand"
    elseif slot == "ranged" then
        slotNum, slotName = 18, "Ranged"
    end
    
    local command = modID > 0 
        and string.format(".item %d %d %d 0", slotNum, itemID, modID)
        or string.format(".item %d %d 0 0", slotNum, itemID)
    
    DebugPrint("Executing:", command)
    iMorphChatHandler(command)
    
    if ClickMorphWeapon.config.showMessages then
        print("|cff00ff00Weapon:|r", slotName, "- ItemID:", itemID, "ModID:", modID)
    end
end

-- HOOK HÍBRIDO (igual PauldronSystem)
function ClickMorphWeapon.InstallHybridHook()
    local morpher = CM:CanMorph(true)
    if not morpher or not morpher.item then
        DebugPrint("❌ Morpher not available")
        return false
    end
    
    if ClickMorphWeapon.originalMorpherItem then
        DebugPrint("Hybrid hook already installed")
        return true
    end
    
    DebugPrint("Installing hybrid hook system...")
    
    -- HOOK 1: HandleModifiedItemClick para Shift e Ctrl+Alt+Shift
    if not ClickMorphWeapon.originalHandleModifiedItemClick then
        ClickMorphWeapon.originalHandleModifiedItemClick = HandleModifiedItemClick
        
        HandleModifiedItemClick = function(item)
            DebugPrint("🎯 HandleModifiedItemClick intercepted - Item:", item)
            
            -- Bloquear se processando
            if ClickMorphWeapon.processing then
                DebugPrint("🚫 BLOCKING HandleModifiedItemClick - processing active")
                return
            end
            
            -- Verificar se é arma
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
            
            if success and itemID and equipLoc and ClickMorphWeapon.config.enabled then
                local isWeapon = equipLoc == "INVTYPE_WEAPON" or 
                                equipLoc == "INVTYPE_WEAPONMAINHAND" or 
                                equipLoc == "INVTYPE_WEAPONOFFHAND" or
                                equipLoc == "INVTYPE_2HWEAPON" or
                                equipLoc == "INVTYPE_RANGED" or
                                equipLoc == "INVTYPE_RANGEDRIGHT"
                
                if isWeapon then
                    local isAlt = IsAltKeyDown() or false
                    local isShift = IsShiftKeyDown() or false
                    local isCtrl = IsControlKeyDown() or false
                    
                    local isShiftOnly = isShift and not isAlt and not isCtrl
                    local isCtrlAltShift = isCtrl and isAlt and isShift
                    local isCtrlShift = isCtrl and isShift and not isAlt
                    
                    DebugPrint("EARLY - Alt:", isAlt, "Shift:", isShift, "Ctrl:", isCtrl)
                    DebugPrint("EARLY - Shift only:", isShiftOnly, "Ctrl+Alt+Shift:", isCtrlAltShift, "Ctrl+Shift:", isCtrlShift)
                    
                    -- INTERCEPTAR: Shift, Ctrl+Alt+Shift, Ctrl+Shift
                    if isShiftOnly or isCtrlAltShift or isCtrlShift then
                        DebugPrint("✅ EARLY INTERCEPT - Handling weapon click")
                        
                        ClickMorphWeapon.processing = true
                        
                        -- SALVAR O ITEM COMO "ÚLTIMO CLICADO" para detecção posterior
                        ClickMorphWeapon.lastClickedItemID = itemID
                        ClickMorphWeapon.lastClickedItemLink = itemLink
                        
                        -- TENTAR CAPTURAR VERSÃO DO ITEMLINK PRIMEIRO
                        local correctVersion = ClickMorphWeapon.GetVersionFromItemLink(itemID, itemLink)
                        
                        -- Se falhou, tentar pelo Wardrobe
                        if correctVersion == 0 then
                            correctVersion = ClickMorphWeapon.GetVersionFromWardrobe(itemID)
                        end
                        
                        if isShiftOnly then
                            DebugPrint("Executing SHIFT ONLY (Off Hand) with version:", correctVersion)
                            ClickMorphWeapon.ExecuteWeaponCommand(itemID, "offhand", correctVersion)
                        elseif isCtrlAltShift then
                            DebugPrint("Executing CTRL+ALT+SHIFT (Ranged) with version:", correctVersion)
                            ClickMorphWeapon.ExecuteWeaponCommand(itemID, "ranged", correctVersion)
                        elseif isCtrlShift then
                            DebugPrint("Executing CTRL+SHIFT (Reset)")
                            ClickMorphWeapon.ExecuteWeaponCommand(0, "reset", 0)
                        end
                        
                        C_Timer.After(0.5, function()
                            ClickMorphWeapon.processing = false
                        end)
                        
                        return -- BLOQUEAR ClickMorph original
                    end
                end
            end
            
            return ClickMorphWeapon.originalHandleModifiedItemClick(item)
        end
        
        DebugPrint("✅ HandleModifiedItemClick hook installed")
    end
    
    -- HOOK 2: morpher.item para Alt+Shift (Main Hand)
    ClickMorphWeapon.originalMorpherItem = morpher.item
    
    morpher.item = function(unit, slotID, itemID, itemModID)
        DebugPrint("🎯 morpher.item intercepted - SlotID:", slotID, "ItemID:", itemID, "ModID:", itemModID)
        
        -- Detectar slots de arma (16=MH, 17=OH, 18=Ranged)
        if (slotID == 16 or slotID == 17 or slotID == 18) and ClickMorphWeapon.config.enabled then
            local isAlt = IsAltKeyDown() or false
            local isShift = IsShiftKeyDown() or false
            local isCtrl = IsControlKeyDown() or false
            
            local isAltShift = isAlt and isShift and not isCtrl
            
            DebugPrint("MORPHER - Alt:", isAlt, "Shift:", isShift, "Ctrl:", isCtrl)
            DebugPrint("MORPHER - Alt+Shift:", isAltShift)
            
            if isAltShift then
                DebugPrint("✅ MORPHER INTERCEPT - Alt+Shift+Click (Main Hand)")
                
                ClickMorphWeapon.processing = true
                
                -- DELAY para OnMouseDown executar primeiro
                C_Timer.After(0.05, function()
                    -- Tentar pegar itemLink
                    local itemLink = select(2, C_Item.GetItemInfo(itemID))
                    
                    -- Método 1: Tentar via itemLink primeiro
                    local finalVersion = 0
                    if itemLink then
                        finalVersion = ClickMorphWeapon.GetVersionFromItemLink(itemID, itemLink)
                        DebugPrint("ItemLink detection result:", finalVersion)
                    end
                    
                    -- Método 2: Usar o modID que veio do morpher
                    if finalVersion == 0 then
                        finalVersion = itemModID or 0
                        DebugPrint("Using morpher detected version:", finalVersion)
                    end
                    
                    -- Método 3: Se ainda é 0, tentar detecção manual do Wardrobe
                    if finalVersion == 0 then
                        DebugPrint("Version still 0, trying manual detection...")
                        finalVersion = ClickMorphWeapon.GetVersionFromWardrobe(itemID)
                    end
                    
                    ClickMorphWeapon.ExecuteWeaponCommand(itemID, "mainhand", finalVersion)
                    
                    C_Timer.After(0.5, function()
                        ClickMorphWeapon.processing = false
                    end)
                end)
                
                return -- BLOQUEAR execução original
            end
        end
        
        return ClickMorphWeapon.originalMorpherItem(unit, slotID, itemID, itemModID)
    end
    
    DebugPrint("✅ morpher.item hook installed")
    DebugPrint("✅ Hybrid hook system ready!")
    return true
end

-- Reset do sistema
function ClickMorphWeapon.ResetHybridHook()
    local morpher = CM:CanMorph(true)
    if ClickMorphWeapon.originalMorpherItem and morpher then
        morpher.item = ClickMorphWeapon.originalMorpherItem
        ClickMorphWeapon.originalMorpherItem = nil
    end
    
    if ClickMorphWeapon.originalHandleModifiedItemClick then
        HandleModifiedItemClick = ClickMorphWeapon.originalHandleModifiedItemClick
        ClickMorphWeapon.originalHandleModifiedItemClick = nil
    end
    
    ClickMorphWeapon.processing = false
    DebugPrint("Hybrid hook system reset")
end

-- Comandos
SLASH_CLICKMORPH_WEAPON1 = "/weapon"
SLASH_CLICKMORPH_WEAPON2 = "/cmweapon"

SlashCmdList.CLICKMORPH_WEAPON = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    local command = args[1] or "help"
    
    if command == "toggle" then
        ClickMorphWeapon.config.enabled = not ClickMorphWeapon.config.enabled
        print("|cff00ff00Weapon:|r", ClickMorphWeapon.config.enabled and "ENABLED" or "DISABLED")
        
    elseif command == "debug" then
        ClickMorphWeapon.config.debugMode = not ClickMorphWeapon.config.debugMode
        print("|cff00ff00Weapon:|r Debug mode", ClickMorphWeapon.config.debugMode and "ON" or "OFF")
        
    elseif command == "msg" or command == "messages" then
        ClickMorphWeapon.config.showMessages = not ClickMorphWeapon.config.showMessages
        print("|cff00ff00Weapon:|r Messages:", ClickMorphWeapon.config.showMessages and "ON" or "OFF")
        
    elseif command == "install" then
        if ClickMorphWeapon.InstallHybridHook() then
            print("|cff00ff00Weapon:|r Hybrid hook installed!")
        else
            print("|cffff0000Weapon:|r Failed to install hybrid hook")
        end
        
    elseif command == "reset" then
        ClickMorphWeapon.ResetHybridHook()
        print("|cff00ff00Weapon:|r Hybrid hook reset")
        
    elseif command == "test" then
        local slot = args[2] or "mainhand"
        local itemID = tonumber(args[3]) or 32837
        local modID = tonumber(args[4]) or 0
        
        print("|cff00ff00Weapon:|r Testing", slot, "ItemID:", itemID, "ModID:", modID)
        ClickMorphWeapon.ExecuteWeaponCommand(itemID, slot, modID)
        
    elseif command == "status" then
        print("|cff00ff00=== Weapon Hybrid Status ===|r")
        print("Enabled:", ClickMorphWeapon.config.enabled)
        print("Debug:", ClickMorphWeapon.config.debugMode)
        print("Messages:", ClickMorphWeapon.config.showMessages)
        print("HandleModifiedItemClick hook:", ClickMorphWeapon.originalHandleModifiedItemClick ~= nil)
        print("morpher.item hook:", ClickMorphWeapon.originalMorpherItem ~= nil)
        
        if ClickMorphWeapon.originalMorpherItem and ClickMorphWeapon.originalHandleModifiedItemClick then
            print("|cff00ff00✅ Hybrid system ready!|r")
        else
            print("|cffff0000❌ Hybrid hooks not installed - run /weapon install|r")
        end
        
    else
        print("|cff00ff00Weapon Hybrid Commands:|r")
        print("/weapon toggle - Enable/disable")
        print("/weapon debug - Toggle debug")
        print("/weapon messages - Toggle messages")
        print("/weapon install - Install hybrid hooks")
        print("/weapon reset - Reset hybrid hooks")
        print("/weapon test <slot> <itemID> <modID>")
        print("/weapon status - Show status")
        print("")
        print("|cffffcc00Hybrid Strategy:|r")
        print("|cffaaff00Alt+Shift:|r Main Hand (via morpher.item)")
        print("|cffaaff00Shift:|r Off Hand (via HandleModifiedItemClick)")
        print("|cffaaff00Ctrl+Alt+Shift:|r Ranged (via HandleModifiedItemClick)")
        print("|cffaaff00Ctrl+Shift:|r Reset ALL (via HandleModifiedItemClick)")
        print("|cffccccccAll with correct version detection|r")
    end
end

-- Instalar hooks nos modelos do Wardrobe
function ClickMorphWeapon.InstallModelHooks()
    local wardrobeFrame = BetterWardrobeCollectionFrame or WardrobeCollectionFrame
    if not wardrobeFrame or not wardrobeFrame.ItemsCollectionFrame then
        DebugPrint("No wardrobe frame found for model hooks")
        return 0
    end
    
    local itemsFrame = wardrobeFrame.ItemsCollectionFrame
    if not itemsFrame.Models then
        DebugPrint("No models in ItemsCollectionFrame")
        return 0
    end
    
    local hooked = 0
    for _, model in pairs(itemsFrame.Models) do
        if model and not model.WeaponSystemClickHooked then
            -- Hook SetItemTransmogInfo (chamada quando modelo é clicado)
            if model.SetItemTransmogInfo then
                hooksecurefunc(model, "SetItemTransmogInfo", function(self, info)
                    if info and info.appearanceID then
                        ClickMorphWeapon.lastClickedAppearanceID = info.appearanceID
                        ClickMorphWeapon.lastClickedModel = self
                        DebugPrint("SetItemTransmogInfo - AppearanceID:", info.appearanceID)
                    end
                end)
            end
            
            -- Fallback: Hook OnMouseDown
            if model.SetScript then
                model:HookScript("OnMouseDown", function(self)
                    ClickMorphWeapon.lastClickedModel = self
                    if self.visualInfo then
                        DebugPrint("OnMouseDown - VisualID:", self.visualInfo.visualID)
                    end
                end)
            end
            
            model.WeaponSystemClickHooked = true
            hooked = hooked + 1
        end
    end
    
    DebugPrint("Hooked", hooked, "models for click detection")
    return hooked
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
    
    DebugPrint("Initializing Hybrid Weapon System...")
    
    -- Instalar hooks nos modelos (se já existirem)
    ClickMorphWeapon.InstallModelHooks()
    
    -- Hook para reinstalar quando Wardrobe abrir
    local wardrobeFrame = BetterWardrobeCollectionFrame or WardrobeCollectionFrame
    if wardrobeFrame and not wardrobeFrame.WeaponSystemOnShowHooked then
        wardrobeFrame:HookScript("OnShow", function()
            DebugPrint("Wardrobe opened - reinstalling model hooks")
            C_Timer.After(0.5, function()
                ClickMorphWeapon.InstallModelHooks()
            end)
        end)
        wardrobeFrame.WeaponSystemOnShowHooked = true
        DebugPrint("OnShow hook installed on Wardrobe")
    end
    
    if ClickMorphWeapon.InstallHybridHook() then
        print("|cff00ff00ClickMorph Weapon - Hybrid System|r loaded!")
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