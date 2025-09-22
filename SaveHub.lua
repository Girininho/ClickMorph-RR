-- SaveHub.lua
-- Sistema de Save/Load com interface gráfica integrada na aba iMorph
-- Foco em facilidade de uso - sem comandos de chat

ClickMorphSaveHub = {}

-- Dados salvos (persistentes entre sessões)
ClickMorphSaveHubSV = ClickMorphSaveHubSV or {
    savedMorphs = {}, 
    maxSlots = 12,    -- 3 linhas x 4 colunas = layout organizado
    debugMode = false
}

-- Sistema do SaveHub
ClickMorphSaveHub.system = {
    isActive = false,
    uiFrame = nil,
    slotButtons = {},
    selectedSlot = nil
}

-- Debug print específico do SaveHub
local function SaveHubDebugPrint(...)
    if ClickMorphSaveHubSV.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff00ffccSaveHub:|r", message)
    end
end

-- Estrutura de um morph salvo
function ClickMorphSaveHub.CreateEmptyMorphSlot()
    return {
        slotName = "Empty",
        race = nil,
        gender = nil,
        items = {},
        timestamp = 0,
        playerName = "",
        realmName = "",
        description = "",
        previewIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    }
end

-- Inicializar slots se não existirem
function ClickMorphSaveHub.InitializeSaveSlots()
    if not ClickMorphSaveHubSV.savedMorphs then
        ClickMorphSaveHubSV.savedMorphs = {}
    end
    
    for i = 1, ClickMorphSaveHubSV.maxSlots do
        if not ClickMorphSaveHubSV.savedMorphs[i] then
            ClickMorphSaveHubSV.savedMorphs[i] = ClickMorphSaveHub.CreateEmptyMorphSlot()
        end
    end
    
    SaveHubDebugPrint("Initialized", ClickMorphSaveHubSV.maxSlots, "save slots")
end

-- Capturar morph atual (integração com MagiButton)
function ClickMorphSaveHub.CaptureCurrentMorph()
    local currentMorph = ClickMorphSaveHub.CreateEmptyMorphSlot()
    
    -- Integrar com MagiButton se disponível
    if ClickMorphMagiButton and ClickMorphMagiButton.system.currentMorph then
        local magiMorph = ClickMorphMagiButton.system.currentMorph
        currentMorph.race = magiMorph.race
        currentMorph.gender = magiMorph.gender
        currentMorph.items = CopyTable(magiMorph.items or {})
    end
    
    -- Dados básicos
    currentMorph.timestamp = time()
    currentMorph.playerName = UnitName("player")
    currentMorph.realmName = GetRealmName()
    currentMorph.slotName = "Current Morph"
    
    -- Tentar determinar ícone baseado no morph
    currentMorph.previewIcon = ClickMorphSaveHub.GeneratePreviewIcon(currentMorph)
    
    SaveHubDebugPrint("Captured current morph")
    return currentMorph
end

-- Gerar ícone de preview baseado no morph
function ClickMorphSaveHub.GeneratePreviewIcon(morph)
    local defaultIcons = {
        "Interface\\Icons\\Achievement_Character_Human_Male",
        "Interface\\Icons\\Achievement_Character_Orc_Male", 
        "Interface\\Icons\\Achievement_Character_Dwarf_Male",
        "Interface\\Icons\\Achievement_Character_Nightelf_Male",
        "Interface\\Icons\\Achievement_Character_Undead_Male",
        "Interface\\Icons\\Achievement_Character_Tauren_Male",
        "Interface\\Icons\\Achievement_Character_Gnome_Male",
        "Interface\\Icons\\Achievement_Character_Troll_Male",
        "Interface\\Icons\\Achievement_Character_Goblin_Male",
        "Interface\\Icons\\Achievement_Character_Bloodelf_Male",
        "Interface\\Icons\\Achievement_Character_Draenei_Male",
        "Interface\\Icons\\Achievement_Character_Worgen_Male"
    }
    
    if morph.race and morph.race > 0 and morph.race <= #defaultIcons then
        return defaultIcons[morph.race]
    end
    
    -- Fallback baseado em items equipados
    if morph.items and morph.items[1] then -- Helm
        return "Interface\\Icons\\INV_Helmet_74"
    elseif morph.items and morph.items[5] then -- Chest
        return "Interface\\Icons\\INV_Chest_Cloth_17"
    end
    
    return "Interface\\Icons\\Achievement_General_StayClassy"
end

-- Salvar morph em slot específico
function ClickMorphSaveHub.SaveToSlot(slotIndex, customName)
    ClickMorphSaveHub.InitializeSaveSlots()
    
    if slotIndex < 1 or slotIndex > ClickMorphSaveHubSV.maxSlots then
        return false
    end
    
    local currentMorph = ClickMorphSaveHub.CaptureCurrentMorph()
    if customName and customName ~= "" then
        currentMorph.slotName = customName
    else
        currentMorph.slotName = "Morph " .. slotIndex
    end
    
    ClickMorphSaveHubSV.savedMorphs[slotIndex] = currentMorph
    
    -- Update UI se disponível
    ClickMorphSaveHub.UpdateSlotButton(slotIndex)
    
    print("|cff00ff00SaveHub:|r Saved morph to slot " .. slotIndex)
    SaveHubDebugPrint("Saved morph to slot", slotIndex)
    return true
end

-- Aplicar slot como pauldron específico (integração com IMisc)
function ClickMorphSaveHub.ApplySlotAsPauldron(slotIndex, side)
    if slotIndex < 1 or slotIndex > ClickMorphSaveHubSV.maxSlots then
        return false
    end
    
    local slot = ClickMorphSaveHubSV.savedMorphs[slotIndex]
    if slot.timestamp == 0 then
        print("|cffff0000SaveHub:|r Slot " .. slotIndex .. " is empty")
        return false
    end
    
    -- Procurar por pauldron (slot 3) no morph salvo
    local pauldronData = nil
    if slot.items and slot.items[3] then
        pauldronData = slot.items[3]
    end
    
    if not pauldronData or not pauldronData.entry then
        print("|cffff0000SaveHub:|r No pauldron found in '" .. slot.slotName .. "'")
        return false
    end
    
    -- Aplicar pauldron no lado especificado
    local split = side == "left" and 0 or 1
    local pauldronCmd = string.format(".morph item 3 %d %d", pauldronData.entry, split)
    SendChatMessage(pauldronCmd, "SAY")
    
    print("|cff00ff00SaveHub:|r Applied " .. side .. " pauldron from '" .. slot.slotName .. "'")
    SaveHubDebugPrint("Applied pauldron", pauldronData.entry, "to", side, "side")
    
    return true
end

-- Carregar morph de slot
function ClickMorphSaveHub.LoadFromSlot(slotIndex)
    if slotIndex < 1 or slotIndex > ClickMorphSaveHubSV.maxSlots then
        return false
    end
    
    local slot = ClickMorphSaveHubSV.savedMorphs[slotIndex]
    if slot.timestamp == 0 then
        print("|cffff0000SaveHub:|r Slot " .. slotIndex .. " is empty")
        return false
    end
    
    print("|cff00ff00SaveHub:|r Loading '" .. slot.slotName .. "'")
    SaveHubDebugPrint("Loading morph from slot", slotIndex)
    
    -- Aplicar race/gender
    if slot.race then
        local raceCmd = string.format(".morph race %d %d", slot.race, slot.gender or 0)
        SendChatMessage(raceCmd, "SAY")
    end
    
    -- Aplicar items com delay
    if slot.items then
        local delay = 0
        for slotNum, itemData in pairs(slot.items) do
            if itemData and itemData.entry then
                C_Timer.After(delay * 0.15, function()
                    local itemCmd = string.format(".morph item %d %d %d", 
                        slotNum, itemData.entry, itemData.split or 0)
                    SendChatMessage(itemCmd, "SAY")
                end)
                delay = delay + 1
            end
        end
    end
    
    -- Update MagiButton se disponível
    if ClickMorphMagiButton and ClickMorphMagiButton.system then
        ClickMorphMagiButton.system.currentMorph = CopyTable(slot)
    end
    
    return true
end

-- Limpar slot
function ClickMorphSaveHub.ClearSlot(slotIndex)
    if slotIndex < 1 or slotIndex > ClickMorphSaveHubSV.maxSlots then
        return false
    end
    
    ClickMorphSaveHubSV.savedMorphs[slotIndex] = ClickMorphSaveHub.CreateEmptyMorphSlot()
    ClickMorphSaveHub.UpdateSlotButton(slotIndex)
    
    print("|cff00ff00SaveHub:|r Cleared slot " .. slotIndex)
    return true
end

-- Criar interface gráfica para a aba iMorph
function ClickMorphSaveHub.CreateSaveHubContent(parentFrame)
    local system = ClickMorphSaveHub.system
    
    if system.uiFrame then
        return system.uiFrame
    end
    
    ClickMorphSaveHub.InitializeSaveSlots()
    
    -- Frame principal
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Morph Save Hub")
    
    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    subtitle:SetText("Click to Load • Right-click to Save • Alt+Shift+Right for Pauldron • Alt+Shift+Scroll to Clear")
    subtitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Área de slots (grid 4x3)
    local slotsFrame = CreateFrame("Frame", nil, content)
    slotsFrame:SetSize(320, 240) -- 4 slots * 80 width = 320
    slotsFrame:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    
    -- Criar botões de slot em grid
    system.slotButtons = {}
    local buttonSize = 75
    local spacing = 5
    
    for i = 1, ClickMorphSaveHubSV.maxSlots do
        local row = math.ceil(i / 4) - 1  -- 0, 1, 2
        local col = ((i - 1) % 4)         -- 0, 1, 2, 3
        
        local button = CreateFrame("Button", nil, slotsFrame)
        button:SetSize(buttonSize, buttonSize)
        button:SetPoint("TOPLEFT", col * (buttonSize + spacing), -row * (buttonSize + spacing))
        
        -- Background do botão
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\UI-EmptySlot")
        
        -- Ícone do morph salvo
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(buttonSize - 4, buttonSize - 4)
        icon:SetPoint("CENTER")
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon = icon
        
        -- Texto do nome
        local nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
        nameText:SetText("Empty")
        nameText:SetTextColor(0.6, 0.6, 0.6)
        button.nameText = nameText
        
        -- Número do slot
        local slotNumber = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slotNumber:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        slotNumber:SetText(tostring(i))
        slotNumber:SetTextColor(1, 1, 1)
        
        -- Scripts de interação
        button:SetScript("OnClick", function(self, mouseButton, isDown)
            local slotIndex = i
            
            if mouseButton == "LeftButton" then
                -- Click esquerdo = Load
                ClickMorphSaveHub.LoadFromSlot(slotIndex)
                
            elseif mouseButton == "RightButton" then
                if IsAltKeyDown() and IsShiftKeyDown() then
                    -- Alt + Shift + Right click = Apply as Right Pauldron
                    ClickMorphSaveHub.ApplySlotAsPauldron(slotIndex, "right")
                else
                    -- Right click = Save
                    ClickMorphSaveHub.ShowSaveDialog(slotIndex)
                end
            end
        end)
        
        -- Script para scroll wheel (clear)
        button:SetScript("OnMouseWheel", function(self, delta)
            local slotIndex = i
            if IsAltKeyDown() and IsShiftKeyDown() then
                -- Alt + Shift + Scroll = Clear slot
                StaticPopupDialogs["SAVEHUB_CLEAR_CONFIRM"] = {
                    text = "Clear slot " .. slotIndex .. "?",
                    button1 = "Yes",
                    button2 = "Cancel",
                    OnAccept = function()
                        ClickMorphSaveHub.ClearSlot(slotIndex)
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("SAVEHUB_CLEAR_CONFIRM")
            end
        end)
        
        -- Habilitar mouse wheel
        button:EnableMouseWheel(true)
        
        -- Tooltip
        button:SetScript("OnEnter", function(self)
            local slot = ClickMorphSaveHubSV.savedMorphs[i]
            local tooltip = GameTooltip
            tooltip:SetOwner(self, "ANCHOR_RIGHT")
            
            if slot.timestamp > 0 then
                tooltip:SetText(slot.slotName, 1, 1, 1)
                tooltip:AddLine("Saved: " .. date("%m/%d %H:%M", slot.timestamp), 0.8, 0.8, 0.8)
                if slot.playerName ~= "" then
                    tooltip:AddLine("By: " .. slot.playerName, 0.6, 0.8, 1)
                end
                tooltip:AddLine(" ")
                tooltip:AddLine("Click to Load", 0, 1, 0)
                tooltip:AddLine("Right-click to Save", 1, 1, 0)
                tooltip:AddLine("Alt+Shift+Right-click for Right Pauldron", 1, 0.8, 0.2)
                tooltip:AddLine("Alt+Shift+Scroll to Clear", 1, 0.5, 0.5)
            else
                tooltip:SetText("Empty Slot " .. i, 0.6, 0.6, 0.6)
                tooltip:AddLine("Right-click to save current morph", 1, 1, 0)
            end
            
            tooltip:Show()
        end)
        
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        system.slotButtons[i] = button
    end
    
    -- Botões de ação rápida
    local quickSaveBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    quickSaveBtn:SetSize(100, 25)
    quickSaveBtn:SetPoint("TOPLEFT", slotsFrame, "BOTTOMLEFT", 0, -20)
    quickSaveBtn:SetText("Quick Save")
    quickSaveBtn:SetScript("OnClick", function()
        ClickMorphSaveHub.QuickSave()
    end)
    
    local quickLoadBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    quickLoadBtn:SetSize(100, 25)
    quickLoadBtn:SetPoint("LEFT", quickSaveBtn, "RIGHT", 10, 0)
    quickLoadBtn:SetText("Quick Load")
    quickLoadBtn:SetScript("OnClick", function()
        ClickMorphSaveHub.QuickLoad()
    end)
    
    -- Status text
    local statusText = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statusText:SetPoint("TOPLEFT", quickSaveBtn, "BOTTOMLEFT", 0, -15)
    statusText:SetText("Ready")
    statusText:SetTextColor(0.8, 0.8, 0.8)
    system.statusText = statusText
    
    -- Update todos os slots
    for i = 1, ClickMorphSaveHubSV.maxSlots do
        ClickMorphSaveHub.UpdateSlotButton(i)
    end
    
    system.uiFrame = content
    SaveHubDebugPrint("SaveHub UI created with", ClickMorphSaveHubSV.maxSlots, "slots")
    
    return content
end

-- Update visual de um slot button
function ClickMorphSaveHub.UpdateSlotButton(slotIndex)
    local system = ClickMorphSaveHub.system
    local button = system.slotButtons[slotIndex]
    
    if not button then return end
    
    local slot = ClickMorphSaveHubSV.savedMorphs[slotIndex]
    
    if slot.timestamp > 0 then
        -- Slot ocupado
        button.icon:SetTexture(slot.previewIcon)
        button.icon:SetDesaturated(false)
        button.nameText:SetText(slot.slotName)
        button.nameText:SetTextColor(1, 1, 1)
    else
        -- Slot vazio  
        button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon:SetDesaturated(true)
        button.nameText:SetText("Empty")
        button.nameText:SetTextColor(0.6, 0.6, 0.6)
    end
end

-- Dialog para salvar com nome customizado
function ClickMorphSaveHub.ShowSaveDialog(slotIndex)
    StaticPopupDialogs["SAVEHUB_SAVE_DIALOG"] = {
        text = "Save current morph to slot " .. slotIndex .. "\n\nEnter name (optional):",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            ClickMorphSaveHub.SaveToSlot(slotIndex, name)
        end,
        EditBoxOnEnterPressed = function(self)
            local name = self:GetText()
            ClickMorphSaveHub.SaveToSlot(slotIndex, name)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("SAVEHUB_SAVE_DIALOG")
end

-- Quick Save (primeiro slot vazio)
function ClickMorphSaveHub.QuickSave()
    for i = 1, ClickMorphSaveHubSV.maxSlots do
        local slot = ClickMorphSaveHubSV.savedMorphs[i]
        if slot.timestamp == 0 then
            ClickMorphSaveHub.SaveToSlot(i, "Quick Save " .. i)
            return
        end
    end
    print("|cffff0000SaveHub:|r All slots are full!")
end

-- Quick Load (último usado)
function ClickMorphSaveHub.QuickLoad()
    local lastUsed = 0
    local lastTime = 0
    
    for i = 1, ClickMorphSaveHubSV.maxSlots do
        local slot = ClickMorphSaveHubSV.savedMorphs[i]
        if slot.timestamp > lastTime then
            lastTime = slot.timestamp
            lastUsed = i
        end
    end
    
    if lastUsed > 0 then
        ClickMorphSaveHub.LoadFromSlot(lastUsed)
    else
        print("|cffff0000SaveHub:|r No saved morphs to load!")
    end
end

print("|cff00ff00ClickMorph SaveHub System|r loaded!")
print("Integrated with iMorph tab - no chat commands needed!")