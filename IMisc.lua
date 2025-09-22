-- IMisc.lua - Sistema inteligente de pauldrons com detecção automática
-- Auto-detecção de slot + hotkeys para split morphing

ClickMorphIMisc = {}

-- Sistema de pauldrons inteligente
ClickMorphIMisc.pauldronSystem = {
    isActive = false,
    autoDetectionEnabled = true,
    debugMode = false,
    hotkeysEnabled = true,
    leftShoulderKey = "CTRL", -- Padrão Ctrl+Click
    rightShoulderKey = "ALT", -- Padrão Alt+Click (você mencionou Alt+Shift, podemos ajustar)
    currentHookedFrame = nil
}

-- Debug print
local function PauldronDebugPrint(...)
    if ClickMorphIMisc.pauldronSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cffcc9900Pauldron:|r", table.concat(args, " "))
    end
end

-- Base de dados de slots conhecidos de pauldrons
ClickMorphIMisc.PAULDRON_SLOTS = {
    [3] = "Shoulder", -- Slot padrão de ombros
    -- Adicionar outros slots se necessário
}

-- Detectar se um item é pauldron pelo ID ou slot
function ClickMorphIMisc.IsPauldronItem(itemID, slotID)
    -- Método 1: Verificar slot
    if slotID and ClickMorphIMisc.PAULDRON_SLOTS[slotID] then
        PauldronDebugPrint("Item detected as pauldron by slot:", slotID)
        return true
    end
    
    -- Método 2: Verificar item info (se disponível)
    if itemID then
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
        
        if itemEquipLoc == "INVTYPE_SHOULDER" then
            PauldronDebugPrint("Item detected as pauldron by equipLoc:", itemID)
            return true
        end
    end
    
    return false
end

-- Hook de clique inteligente para pauldrons
function ClickMorphIMisc.SetupPauldronClickHooks()
    local system = ClickMorphIMisc.pauldronSystem
    
    if not system.hotkeysEnabled then
        PauldronDebugPrint("Hotkeys disabled, skipping hook setup")
        return
    end
    
    PauldronDebugPrint("Setting up pauldron click hooks...")
    
    -- Hook para itens no CharacterFrame
    ClickMorphIMisc.HookCharacterSlots()
    
    -- Hook para itens no inventory/bags
    ClickMorphIMisc.HookInventoryItems()
    
    -- Hook para itens em links de chat
    ClickMorphIMisc.HookChatLinks()
    
    PauldronDebugPrint("Pauldron hooks setup complete")
end

-- Hook slots do personagem
function ClickMorphIMisc.HookCharacterSlots()
    local shoulderSlot = _G["CharacterShoulderSlot"]
    
    if shoulderSlot and not shoulderSlot._pauldronHooked then
        shoulderSlot:HookScript("OnClick", function(self, button, down)
            ClickMorphIMisc.HandlePauldronClick(self, button)
        end)
        
        shoulderSlot._pauldronHooked = true
        PauldronDebugPrint("Hooked CharacterShoulderSlot")
    end
end

-- Hook itens do inventário
function ClickMorphIMisc.HookInventoryItems()
    -- Hook para quando itens são clicados em bags
    local originalUseContainerItem = UseContainerItem
    
    UseContainerItem = function(bagID, slotID, onSelf, reagentBankAccessible)
        local itemID = GetContainerItemID(bagID, slotID)
        
        if itemID and ClickMorphIMisc.IsPauldronItem(itemID) then
            local modifiers = ClickMorphIMisc.GetCurrentModifiers()
            
            if modifiers.ctrl or modifiers.alt then
                ClickMorphIMisc.HandlePauldronMorph(itemID, modifiers)
                return -- Interceptar o clique
            end
        end
        
        -- Chamar função original se não interceptou
        return originalUseContainerItem(bagID, slotID, onSelf, reagentBankAccessible)
    end
    
    PauldronDebugPrint("Hooked UseContainerItem for inventory pauldrons")
end

-- Hook links de chat
function ClickMorphIMisc.HookChatLinks()
    local originalSetItemRef = SetItemRef
    
    SetItemRef = function(link, text, button, chatFrame)
        local itemID = tonumber(string.match(link, "item:(%d+)"))
        
        if itemID and ClickMorphIMisc.IsPauldronItem(itemID) then
            local modifiers = ClickMorphIMisc.GetCurrentModifiers()
            
            if modifiers.ctrl or modifiers.alt then
                ClickMorphIMisc.HandlePauldronMorph(itemID, modifiers)
                return
            end
        end
        
        return originalSetItemRef(link, text, button, chatFrame)
    end
    
    PauldronDebugPrint("Hooked SetItemRef for chat link pauldrons")
end

-- Detectar modificadores atuais
function ClickMorphIMisc.GetCurrentModifiers()
    return {
        ctrl = IsControlKeyDown(),
        alt = IsAltKeyDown(),
        shift = IsShiftKeyDown()
    }
end

-- Handler principal de cliques em pauldrons
function ClickMorphIMisc.HandlePauldronClick(frame, button)
    local system = ClickMorphIMisc.pauldronSystem
    
    if not system.hotkeysEnabled then return end
    
    local modifiers = ClickMorphIMisc.GetCurrentModifiers()
    local itemID = nil
    
    -- Tentar obter ID do item
    if frame and frame.GetInventorySlot then
        local slotID = frame:GetInventorySlot()
        itemID = GetInventoryItemID("player", slotID)
    end
    
    if itemID and ClickMorphIMisc.IsPauldronItem(itemID) then
        ClickMorphIMisc.HandlePauldronMorph(itemID, modifiers)
    end
end

-- Handler de morph de pauldron
function ClickMorphIMisc.HandlePauldronMorph(itemID, modifiers, mouseButton)
    local system = ClickMorphIMisc.pauldronSystem
    
    if not system.autoDetectionEnabled then return end
    
    local displayID = ClickMorphIMisc.GetItemDisplayID(itemID)
    if not displayID then
        PauldronDebugPrint("Could not get display ID for item:", itemID)
        return
    end
    
    local morphCmd = ""
    local description = ""
    
    -- Determinar ação baseado nos modificadores e botão do mouse
    if modifiers.ctrl and not modifiers.alt and not modifiers.shift then
        -- Ctrl+Click = Ombro esquerdo (split 0)
        morphCmd = string.format(".morphitem 3 %d 0", displayID)
        description = "left shoulder"
    elseif modifiers.alt and not modifiers.ctrl and not modifiers.shift then
        -- Alt+Click = Ombro direito (split 1)
        morphCmd = string.format(".morphitem 3 %d 1", displayID)
        description = "right shoulder"
    elseif modifiers.alt and modifiers.shift and not modifiers.ctrl then
        if mouseButton == "MiddleButton" then
            -- Alt+Shift+MiddleClick = Clear ambos os ombros
            morphCmd = ".morphitem 3 0"
            description = "clear both shoulders"
        else
            -- Alt+Shift+Click = Ambos os ombros (sem split)
            morphCmd = string.format(".morphitem 3 %d", displayID)
            description = "both shoulders"
        end
    else
        -- Combinação não reconhecida, não interceptar
        return
    end
    
    PauldronDebugPrint("Pauldron action:", description)
    PauldronDebugPrint("Item ID:", itemID, "Display ID:", displayID)
    PauldronDebugPrint("Command:", morphCmd)
    
    SendChatMessage(morphCmd, "SAY")
    
    if description == "clear both shoulders" then
        print("|cff00ff00Pauldron System:|r Cleared both shoulders")
    else
        print("|cff00ff00Pauldron System:|r Morphed " .. description .. " to item " .. itemID)
    end
    
    -- Integrar com MagiButton
    if ClickMorphMagiButton and ClickMorphMagiButton.system then
        if description == "clear both shoulders" then
            ClickMorphMagiButton.system.currentMorph.pauldron = nil
        else
            ClickMorphMagiButton.system.currentMorph.pauldron = {
                itemID = itemID,
                displayID = displayID,
                side = description,
                slot = 3
            }
        end
    end
end

-- Obter Display ID de um item
function ClickMorphIMisc.GetItemDisplayID(itemID)
    -- Método 1: Tentar via item info
    local itemName, itemLink = GetItemInfo(itemID)
    if itemLink then
        -- Extrair display ID do link (se disponível)
        local displayID = tonumber(string.match(itemLink, "item:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:(%d+)"))
        if displayID and displayID > 0 then
            PauldronDebugPrint("Got display ID from item link:", displayID)
            return displayID
        end
    end
    
    -- Método 2: Usar ID do item como fallback (pode funcionar em alguns servidores)
    PauldronDebugPrint("Using item ID as display ID fallback:", itemID)
    return itemID
end

-- Criar interface de configuração
function ClickMorphIMisc.CreatePauldronContent(parentFrame)
    local system = ClickMorphIMisc.pauldronSystem
    
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Pauldron Tools")
    
    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(380)
    desc:SetText("Intelligent pauldron morphing with automatic detection and hotkeys")
    desc:SetJustifyH("LEFT")
    
    -- Auto-detection toggle
    local autoDetectCheck = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    autoDetectCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    autoDetectCheck.Text:SetText("Enable Auto-Detection")
    autoDetectCheck:SetChecked(system.autoDetectionEnabled)
    autoDetectCheck:SetScript("OnClick", function(self)
        system.autoDetectionEnabled = self:GetChecked()
        PauldronDebugPrint("Auto-detection:", system.autoDetectionEnabled and "ON" or "OFF")
    end)
    
    -- Hotkeys toggle
    local hotkeysCheck = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    hotkeysCheck:SetPoint("TOPLEFT", autoDetectCheck, "BOTTOMLEFT", 0, -10)
    hotkeysCheck.Text:SetText("Enable Hotkey System")
    hotkeysCheck:SetChecked(system.hotkeysEnabled)
    hotkeysCheck:SetScript("OnClick", function(self)
        system.hotkeysEnabled = self:GetChecked()
        if system.hotkeysEnabled then
            ClickMorphIMisc.SetupPauldronClickHooks()
        end
        PauldronDebugPrint("Hotkeys:", system.hotkeysEnabled and "ON" or "OFF")
    end)
    
    -- Instructions
    local instructionsTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    instructionsTitle:SetPoint("TOPLEFT", hotkeysCheck, "BOTTOMLEFT", 0, -20)
    instructionsTitle:SetText("Hotkey Instructions:")
    
    local instructions = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", instructionsTitle, "BOTTOMLEFT", 0, -5)
    instructions:SetWidth(380)
    instructions:SetJustifyH("LEFT")
    instructions:SetText(
        "• Ctrl+Click on pauldron = Morph LEFT shoulder only (split 0)\n" ..
        "• Alt+Click on pauldron = Morph RIGHT shoulder only (split 1)\n" ..
        "• Alt+Shift+Click on pauldron = Morph BOTH shoulders (no split)\n" ..
        "• Alt+Shift+MiddleClick on pauldron = CLEAR both shoulders\n" ..
        "• Works on character slots, inventory items, and chat links\n" ..
        "• Auto-detects pauldron items by slot and equipment type"
    )
    
    -- Current settings display
    local settingsFrame = CreateFrame("Frame", nil, content)
    settingsFrame:SetSize(380, 80)
    settingsFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -20)
    
    local settingsBg = settingsFrame:CreateTexture(nil, "BACKGROUND")
    settingsBg:SetAllPoints()
    settingsBg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    
    local settingsTitle = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    settingsTitle:SetPoint("TOPLEFT", 10, -5)
    settingsTitle:SetText("Current Settings:")
    
    local settingsText = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    settingsText:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -5)
    settingsText:SetWidth(360)
    settingsText:SetJustifyH("LEFT")
    system.settingsText = settingsText
    
    -- Test buttons
    local testLeftBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    testLeftBtn:SetSize(80, 25)
    testLeftBtn:SetPoint("TOPLEFT", settingsFrame, "BOTTOMLEFT", 0, -10)
    testLeftBtn:SetText("Test Left")
    testLeftBtn:SetScript("OnClick", function()
        local testCmd = ".morphitem 3 12345 0" -- ID de teste
        print("|cff00ff00Pauldron Test:|r " .. testCmd)
        SendChatMessage(testCmd, "SAY")
    end)
    
    local testRightBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    testRightBtn:SetSize(80, 25)
    testRightBtn:SetPoint("LEFT", testLeftBtn, "RIGHT", 5, 0)
    testRightBtn:SetText("Test Right")
    testRightBtn:SetScript("OnClick", function()
        local testCmd = ".morphitem 3 12345 1" -- ID de teste
        print("|cff00ff00Pauldron Test:|r " .. testCmd)
        SendChatMessage(testCmd, "SAY")
    end)
    
    local testBothBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    testBothBtn:SetSize(80, 25)
    testBothBtn:SetPoint("LEFT", testRightBtn, "RIGHT", 5, 0)
    testBothBtn:SetText("Test Both")
    testBothBtn:SetScript("OnClick", function()
        local testCmd = ".morphitem 3 12345" -- ID de teste, sem split
        print("|cff00ff00Pauldron Test:|r " .. testCmd)
        SendChatMessage(testCmd, "SAY")
    end)
    
    local clearBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 25)
    clearBtn:SetPoint("LEFT", testBothBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        SendChatMessage(".morphitem 3 0", "SAY")
        print("|cff00ff00Pauldron System:|r Cleared both shoulders")
    end)
    
    -- Update settings display
    local function UpdateSettingsDisplay()
        local text = string.format(
            "Auto-Detection: %s\nHotkeys: %s\nLeft Shoulder Key: %s+Click\nRight Shoulder Key: %s+Click",
            system.autoDetectionEnabled and "Enabled" or "Disabled",
            system.hotkeysEnabled and "Enabled" or "Disabled",
            system.leftShoulderKey,
            system.rightShoulderKey
        )
        settingsText:SetText(text)
    end
    
    UpdateSettingsDisplay()
    
    system.isActive = true
    system.contentFrame = content
    
    -- Setup hooks if enabled
    if system.hotkeysEnabled then
        ClickMorphIMisc.SetupPauldronClickHooks()
    end
    
    PauldronDebugPrint("Pauldron system interface created")
    return content
end

-- Status do sistema
function ClickMorphIMisc.ShowPauldronStatus()
    local system = ClickMorphIMisc.pauldronSystem
    
    print("|cff00ff00=== PAULDRON SYSTEM STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Auto-Detection:", system.autoDetectionEnabled and "YES" or "NO")
    print("Hotkeys:", system.hotkeysEnabled and "YES" or "NO")
    print("Left Shoulder Key:", system.leftShoulderKey .. "+Click")
    print("Right Shoulder Key:", system.rightShoulderKey .. "+Click")
    print("Hooks Setup:", system.currentHookedFrame and "YES" or "NO")
end

-- Comandos para pauldron system
SLASH_CLICKMORPH_PAULDRON1 = "/cmpauldron"
SlashCmdList.CLICKMORPH_PAULDRON = function(arg)
    local args = {}
    for word in arg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = string.lower(args[1] or "")
    
    if command == "toggle" then
        ClickMorphIMisc.pauldronSystem.autoDetectionEnabled = not ClickMorphIMisc.pauldronSystem.autoDetectionEnabled
        print("|cff00ff00Pauldron System:|r Auto-detection", ClickMorphIMisc.pauldronSystem.autoDetectionEnabled and "ON" or "OFF")
    elseif command == "hotkeys" then
        ClickMorphIMisc.pauldronSystem.hotkeysEnabled = not ClickMorphIMisc.pauldronSystem.hotkeysEnabled
        print("|cff00ff00Pauldron System:|r Hotkeys", ClickMorphIMisc.pauldronSystem.hotkeysEnabled and "ON" or "OFF")
        if ClickMorphIMisc.pauldronSystem.hotkeysEnabled then
            ClickMorphIMisc.SetupPauldronClickHooks()
        end
    elseif command == "status" then
        ClickMorphIMisc.ShowPauldronStatus()
    elseif command == "debug" then
        ClickMorphIMisc.pauldronSystem.debugMode = not ClickMorphIMisc.pauldronSystem.debugMode
        print("|cff00ff00Pauldron System:|r Debug mode", ClickMorphIMisc.pauldronSystem.debugMode and "ON" or "OFF")
    elseif command == "test" then
        local action = args[2] or "left"
        local displayID = tonumber(args[3]) or 12345
        
        local testCmd = ""
        if action == "left" then
            testCmd = string.format(".morphitem 3 %d 0", displayID)
        elseif action == "right" then
            testCmd = string.format(".morphitem 3 %d 1", displayID)
        elseif action == "both" then
            testCmd = string.format(".morphitem 3 %d", displayID)
        elseif action == "clear" then
            testCmd = ".morphitem 3 0"
        else
            print("|cffff0000Pauldron System:|r Invalid action. Use: left, right, both, or clear")
            return
        end
        
        print("|cff00ff00Pauldron Test:|r " .. testCmd)
        SendChatMessage(testCmd, "SAY")
    else
        print("|cff00ff00Pauldron System Commands:|r")
        print("/cmpauldron toggle - Toggle auto-detection")
        print("/cmpauldron hotkeys - Toggle hotkey system")
        print("/cmpauldron status - Show system status")
        print("/cmpauldron debug - Toggle debug mode")
        print("/cmpauldron test <left|right|both|clear> [displayID] - Test shoulder morph")
        print("")
        print("Hotkey Combinations:")
        print("Ctrl+Click = Left shoulder only (split 0)")
        print("Alt+Click = Right shoulder only (split 1)")
        print("Alt+Shift+Click = Both shoulders (no split)")
        print("Alt+Shift+MiddleClick = Clear both shoulders")
    end
end

-- Ativação do sistema
local function InitializePauldronSystem()
    PauldronDebugPrint("Initializing Pauldron System...")
    
    if ClickMorphIMisc.pauldronSystem.hotkeysEnabled then
        ClickMorphIMisc.SetupPauldronClickHooks()
    end
    
    PauldronDebugPrint("Pauldron System initialized")
end

-- Event frame para inicialização
local pauldronEventFrame = CreateFrame("Frame")
pauldronEventFrame:RegisterEvent("ADDON_LOADED")
pauldronEventFrame:RegisterEvent("PLAYER_LOGIN")

pauldronEventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "ClickMorph" then
        InitializePauldronSystem()
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2, InitializePauldronSystem)
    end
end)

print("|cff00ff00ClickMorph Pauldron System|r loaded!")
print("|cffcc9900Pauldron System:|r Intelligent detection and hotkey morphing ready")