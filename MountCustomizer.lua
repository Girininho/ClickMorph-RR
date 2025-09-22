-- MountCustomizer.lua - Sistema de preview 3D e customização de montarias
-- Interface com modelo 3D e sistema .customize integrado

ClickMorphMountCustomizer = {}

-- Sistema de customização de montarias
ClickMorphMountCustomizer.customizerSystem = {
    isActive = false,
    selectedMount = nil,
    selectedCustomization = nil,
    debugMode = false,
    searchText = "",
    currentDisplayID = nil,
    currentCustomizeString = "",
    previewModel = nil
}

-- Debug print
local function CustomizerDebugPrint(...)
    if ClickMorphMountCustomizer.customizerSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cffff6600Mount:|r", table.concat(args, " "))
    end
end

-- ============================================================================
-- BASE DE DADOS DE MONTARIAS COM CUSTOMIZAÇÕES CONHECIDAS
-- ============================================================================

ClickMorphMountCustomizer.MOUNT_DATABASE = {
    -- Dirigível do Imersor (exemplo que você mencionou)
    {
        name = "Dirigível do Imersor",
        baseDisplayID = 55297, -- ID base da montaria
        icon = "Interface\\Icons\\INV_Mount_Dirigible",
        category = "Mecânica",
        customizations = {
            {
                name = "Padrão Azul",
                customizeString = "1:0",
                description = "Coloração azul padrão",
                previewIcon = "Interface\\Icons\\INV_Mount_Dirigible"
            },
            {
                name = "Vermelho Imperial",
                customizeString = "1:1", 
                description = "Pintura vermelha imperial",
                previewIcon = "Interface\\Icons\\INV_Mount_Dirigible_Red"
            },
            {
                name = "Verde Jade",
                customizeString = "1:2",
                description = "Acabamento verde jade",
                previewIcon = "Interface\\Icons\\INV_Mount_Dirigible_Green"
            },
            {
                name = "Dourado Real",
                customizeString = "1:3",
                description = "Ornamentação dourada",
                previewIcon = "Interface\\Icons\\INV_Mount_Dirigible_Gold"
            },
            {
                name = "Roxo Místico", 
                customizeString = "1:4",
                description = "Tonalidade roxa mística",
                previewIcon = "Interface\\Icons\\INV_Mount_Dirigible_Purple"
            }
            -- Continuaria com as ~20+ variações...
        }
    },
    -- Dragão de Arenito
    {
        name = "Dragão de Arenito",
        baseDisplayID = 59569,
        icon = "Interface\\Icons\\INV_DragonPet_4",
        category = "Dragão",
        transformsPlayer = true, -- Flag especial para montarias que transformam
        customizations = {
            {
                name = "Arenito Clássico",
                customizeString = "0:0",
                description = "Forma padrão de arenito",
                previewIcon = "Interface\\Icons\\INV_DragonPet_4"
            },
            {
                name = "Arenito Dourado",
                customizeString = "0:1", 
                description = "Variação com tons dourados",
                previewIcon = "Interface\\Icons\\INV_DragonPet_4_Gold"
            },
            {
                name = "Arenito Negro",
                customizeString = "0:2",
                description = "Versão escura intimidante",
                previewIcon = "Interface\\Icons\\INV_DragonPet_4_Black"
            }
        }
    },
    -- Outros exemplos...
    {
        name = "Cavalo Espectral",
        baseDisplayID = 25159,
        icon = "Interface\\Icons\\Ability_Mount_Dreadsteed",
        category = "Espectral",
        customizations = {
            {
                name = "Chamas Azuis",
                customizeString = "2:0",
                description = "Chamas espectrais azuis",
                previewIcon = "Interface\\Icons\\Ability_Mount_Dreadsteed"
            },
            {
                name = "Chamas Verdes", 
                customizeString = "2:1",
                description = "Chamas fantasmagóricas verdes",
                previewIcon = "Interface\\Icons\\Ability_Mount_Dreadsteed_Green"
            }
        }
    }
}

-- ============================================================================
-- SISTEMA DE PREVIEW 3D
-- ============================================================================

-- Criar modelo 3D para preview
function ClickMorphMountCustomizer.CreatePreviewModel(parent)
    local system = ClickMorphMountCustomizer.customizerSystem
    
    local modelFrame = CreateFrame("PlayerModel", nil, parent)
    modelFrame:SetSize(200, 200)
    modelFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 200, -50)
    
    -- Background do modelo
    local modelBg = modelFrame:CreateTexture(nil, "BACKGROUND")
    modelBg:SetAllPoints()
    modelBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Controles do modelo
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    
    -- Rotação com mouse
    modelFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.rotating = true
            self:SetScript("OnUpdate", function(self)
                if self.rotating then
                    local x, y = GetCursorPosition()
                    local scale = self:GetEffectiveScale()
                    self:SetFacing(self:GetFacing() + (x / scale - (self.lastX or x / scale)) * 0.01)
                    self.lastX = x / scale
                    self.lastY = y / scale
                end
            end)
        end
    end)
    
    modelFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.rotating = false
            self:SetScript("OnUpdate", nil)
        end
    end)
    
    -- Zoom com scroll
    modelFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentDistance = self:GetModelScale()
        local newDistance = currentDistance + (delta * -0.1)
        newDistance = math.max(0.1, math.min(3.0, newDistance))
        self:SetModelScale(newDistance)
    end)
    
    system.previewModel = modelFrame
    CustomizerDebugPrint("Preview model created")
    
    return modelFrame
end

-- Atualizar preview do modelo
function ClickMorphMountCustomizer.UpdatePreview(displayID, customizeString)
    local system = ClickMorphMountCustomizer.customizerSystem
    
    if not system.previewModel then
        CustomizerDebugPrint("No preview model available")
        return
    end
    
    CustomizerDebugPrint("Updating preview - DisplayID:", displayID, "Customize:", customizeString or "none")
    
    -- Definir modelo base
    system.previewModel:SetDisplayInfo(displayID)
    
    -- Se tem customização, tentar aplicar
    if customizeString and customizeString ~= "" then
        -- Aqui seria ideal ter uma API para aplicar customização no modelo
        -- Como não temos, pelo menos definimos o modelo base
        CustomizerDebugPrint("Would apply customization:", customizeString)
    end
    
    -- Reset posição e zoom
    system.previewModel:SetFacing(0)
    system.previewModel:SetModelScale(1.0)
    system.previewModel:SetPosition(0, 0, 0)
    
    system.currentDisplayID = displayID
    system.currentCustomizeString = customizeString
end

-- ============================================================================
-- APLICAÇÃO DE CUSTOMIZAÇÕES
-- ============================================================================

-- Aplicar customização usando .customize
function ClickMorphMountCustomizer.ApplyCustomization(mountData, customizationData)
    if not mountData or not customizationData then
        print("|cffff0000Mount Customizer:|r Invalid data")
        return false
    end
    
    CustomizerDebugPrint("Applying customization:", customizationData.name)
    CustomizerDebugPrint("DisplayID:", mountData.baseDisplayID, "Customize:", customizationData.customizeString)
    
    -- Comando .customize para aplicar
    local customizeCmd = string.format(".customize %d %s", mountData.baseDisplayID, customizationData.customizeString)
    SendChatMessage(customizeCmd, "SAY")
    
    print("|cff00ff00Mount Customizer:|r Applied " .. customizationData.name .. " to " .. mountData.name)
    
    -- Integrar com MagiButton
    if ClickMorphMagiButton and ClickMorphMagiButton.system then
        ClickMorphMagiButton.system.currentMorph.mountCustom = {
            displayID = mountData.baseDisplayID,
            customizeString = customizationData.customizeString,
            name = mountData.name .. " (" .. customizationData.name .. ")"
        }
    end
    
    -- Verificar se montaria transforma player
    if mountData.transformsPlayer then
        print("|cffffff00Mount Customizer:|r This mount transforms the player!")
        -- Aqui poderíamos ter lógica especial para montarias que transformam
    end
    
    return true
end

-- Reset customização
function ClickMorphMountCustomizer.ResetCustomization()
    CustomizerDebugPrint("Resetting mount customization")
    
    SendChatMessage(".reset", "SAY")
    print("|cff00ff00Mount Customizer:|r Reset to normal form")
    
    local system = ClickMorphMountCustomizer.customizerSystem
    system.selectedMount = nil
    system.selectedCustomization = nil
    
    if system.previewModel then
        system.previewModel:ClearModel()
    end
end

-- ============================================================================
-- DESCOBERTA DINÂMICA DE CUSTOMIZAÇÕES (EXPERIMENTAL)
-- ============================================================================

--[[
-- Descobrir customizações automaticamente testando combinações
function ClickMorphMountCustomizer.DiscoverCustomizations(displayID, maxSlots, maxOptions)
    CustomizerDebugPrint("=== DESCOBERTA: DisplayID", displayID, "===")
    
    local discoveredCustomizations = {}
    
    -- Testar slots de customização (geralmente 0-5)
    for slot = 0, (maxSlots or 5) do
        -- Testar opções para cada slot (geralmente 0-20)
        for option = 0, (maxOptions or 20) do
            local customizeString = string.format("%d:%d", slot, option)
            
            -- Comando de teste
            local testCmd = string.format(".customize %d %s", displayID, customizeString)
            
            CustomizerDebugPrint("Testing:", testCmd)
            
            -- DESCOMENTE para testar de verdade
            -- SendChatMessage(testCmd, "SAY")
            -- C_Timer.After(0.5, function()
            --     -- Aqui verificaria se a customização teve efeito
            --     table.insert(discoveredCustomizations, {
            --         name = "Custom " .. slot .. ":" .. option,
            --         customizeString = customizeString,
            --         slot = slot,
            --         option = option
            --     })
            -- end)
            
            -- Delay para não sobrecarregar
            C_Timer.After((slot * maxOptions + option) * 0.1, function() end)
        end
    end
    
    return discoveredCustomizations
end

-- Validar se customização tem efeeto visual
function ClickMorphMountCustomizer.ValidateCustomization(displayID, customizeString)
    -- Método 1: Comparar modelos antes/depois
    local beforeModel = ClickMorphMountCustomizer.CreateTempModel(displayID)
    
    -- Aplicar customização
    local afterModel = ClickMorphMountCustomizer.CreateTempModel(displayID, customizeString)
    
    -- Comparar (simplificado)
    local isDifferent = beforeModel:GetModelFileID() ~= afterModel:GetModelFileID()
    
    -- Cleanup
    beforeModel:SetParent(nil)
    afterModel:SetParent(nil)
    
    return isDifferent
end

-- Criar modelo temporário para validação
function ClickMorphMountCustomizer.CreateTempModel(displayID, customizeString)
    local tempModel = CreateFrame("PlayerModel", nil, UIParent)
    tempModel:SetSize(1, 1) -- Invisível
    tempModel:SetPoint("CENTER")
    tempModel:SetDisplayInfo(displayID)
    
    -- Aplicar customização se fornecida
    if customizeString then
        -- Aqui aplicaria a customização no modelo
        CustomizerDebugPrint("Applied customization to temp model:", customizeString)
    end
    
    return tempModel
end
--]]

-- ============================================================================
-- INTERFACE DO MOUNT CUSTOMIZER
-- ============================================================================

-- Criar interface principal
function ClickMorphMountCustomizer.CreateMountCustomizerContent(parentFrame)
    local system = ClickMorphMountCustomizer.customizerSystem
    
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Mount Customizer")
    
    -- Lista de montarias (lado esquerdo)
    local mountList = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    mountList:SetSize(180, 300)
    mountList:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    local mountListChild = CreateFrame("Frame", nil, mountList)
    mountList:SetScrollChild(mountListChild)
    mountListChild:SetSize(160, 1000)
    system.mountListChild = mountListChild
    
    -- Preview model (centro)
    local previewModel = ClickMorphMountCustomizer.CreatePreviewModel(content)
    
    -- Customizações (lado direito)
    local customizationFrame = CreateFrame("Frame", nil, content)
    customizationFrame:SetSize(180, 300)
    customizationFrame:SetPoint("TOPLEFT", previewModel, "TOPRIGHT", 10, 0)
    
    local customLabel = customizationFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    customLabel:SetPoint("TOPLEFT", 0, 0)
    customLabel:SetText("Customizations:")
    
    local customizationList = CreateFrame("ScrollFrame", nil, customizationFrame, "UIPanelScrollFrameTemplate")
    customizationList:SetSize(160, 250)
    customizationList:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 0, -10)
    
    local customListChild = CreateFrame("Frame", nil, customizationList)
    customizationList:SetScrollChild(customListChild)
    customListChild:SetSize(140, 1000)
    system.customListChild = customListChild
    
    -- Info panel (embaixo)
    local infoFrame = CreateFrame("Frame", nil, content)
    infoFrame:SetSize(390, 60)
    infoFrame:SetPoint("BOTTOM", content, "BOTTOM", 0, 10)
    
    local infoBg = infoFrame:CreateTexture(nil, "BACKGROUND")
    infoBg:SetAllPoints()
    infoBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Info da customização selecionada
    local selectedInfo = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    selectedInfo:SetPoint("TOPLEFT", 10, -5)
    selectedInfo:SetText("Select a mount and customization")
    system.selectedInfo = selectedInfo
    
    local selectedDesc = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectedDesc:SetPoint("TOPLEFT", selectedInfo, "BOTTOMLEFT", 0, -5)
    selectedDesc:SetWidth(280)
    selectedDesc:SetJustifyH("LEFT")
    system.selectedDesc = selectedDesc
    
    -- Botões de ação
    local applyBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(70, 25)
    applyBtn:SetPoint("RIGHT", infoFrame, "RIGHT", -10, 0)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        if system.selectedMount and system.selectedCustomization then
            ClickMorphMountCustomizer.ApplyCustomization(system.selectedMount, system.selectedCustomization)
        end
    end)
    
    local resetBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(60, 25)
    resetBtn:SetPoint("RIGHT", applyBtn, "LEFT", -5, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        ClickMorphMountCustomizer.ResetCustomization()
    end)
    
    -- ============================================================================
    -- BOTÃO EXPERIMENTAL PARA DESCOBERTA (descomente para testar)
    -- ============================================================================
    --[[
    local discoverBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    discoverBtn:SetSize(80, 25)
    discoverBtn:SetPoint("RIGHT", resetBtn, "LEFT", -5, 0)
    discoverBtn:SetText("Discover")
    discoverBtn:SetScript("OnClick", function()
        if system.selectedMount then
            local discoveries = ClickMorphMountCustomizer.DiscoverCustomizations(
                system.selectedMount.baseDisplayID, 5, 20
            )
            print("|cff00ff00Mount Customizer:|r Started discovery for", system.selectedMount.name)
        end
    end)
    --]]
    
    system.isActive = true
    system.contentFrame = content
    
    -- Povoar listas iniciais
    ClickMorphMountCustomizer.PopulateMountList()
    
    CustomizerDebugPrint("Mount Customizer interface created")
    return content
end

-- Povoar lista de montarias
function ClickMorphMountCustomizer.PopulateMountList()
    local system = ClickMorphMountCustomizer.customizerSystem
    
    if not system.mountListChild then return end
    
    -- Limpar lista existente
    if system.mountButtons then
        for _, btn in pairs(system.mountButtons) do
            btn:SetParent(nil)
        end
    end
    system.mountButtons = {}
    
    -- Criar botões para cada montaria
    for i, mount in ipairs(ClickMorphMountCustomizer.MOUNT_DATABASE) do
        local btn = CreateFrame("Button", nil, system.mountListChild, "UIPanelButtonTemplate")
        btn:SetSize(150, 25)
        btn:SetPoint("TOPLEFT", 0, -(i-1) * 30)
        btn:SetText(mount.name)
        
        btn:SetScript("OnClick", function()
            ClickMorphMountCustomizer.SelectMount(mount)
        end)
        
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(mount.name)
            GameTooltip:AddLine("DisplayID: " .. mount.baseDisplayID, 0.6, 0.6, 1)
            GameTooltip:AddLine("Category: " .. mount.category, 0.8, 0.8, 0.8)
            GameTooltip:AddLine(#mount.customizations .. " customizations available", 0, 1, 0)
            if mount.transformsPlayer then
                GameTooltip:AddLine("Transforms Player!", 1, 0.5, 0)
            end
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(system.mountButtons, btn)
    end
    
    CustomizerDebugPrint("Populated mount list with", #ClickMorphMountCustomizer.MOUNT_DATABASE, "mounts")
end

-- Selecionar montaria
function ClickMorphMountCustomizer.SelectMount(mountData)
    local system = ClickMorphMountCustomizer.customizerSystem
    
    system.selectedMount = mountData
    system.selectedCustomization = nil
    
    CustomizerDebugPrint("Selected mount:", mountData.name)
    
    -- Atualizar preview com modelo base
    ClickMorphMountCustomizer.UpdatePreview(mountData.baseDisplayID)
    
    -- Povoar customizações
    ClickMorphMountCustomizer.PopulateCustomizationList(mountData.customizations)
    
    -- Atualizar info
    if system.selectedInfo then
        system.selectedInfo:SetText(mountData.name .. " - Select customization")
    end
    if system.selectedDesc then
        system.selectedDesc:SetText("Category: " .. mountData.category .. " | " .. #mountData.customizations .. " options available")
    end
end

-- Povoar lista de customizações
function ClickMorphMountCustomizer.PopulateCustomizationList(customizations)
    local system = ClickMorphMountCustomizer.customizerSystem
    
    if not system.customListChild then return end
    
    -- Limpar lista existente
    if system.customButtons then
        for _, btn in pairs(system.customButtons) do
            btn:SetParent(nil)
        end
    end
    system.customButtons = {}
    
    -- Criar botões para cada customização
    for i, custom in ipairs(customizations) do
        local btn = CreateFrame("Button", nil, system.customListChild, "UIPanelButtonTemplate")
        btn:SetSize(130, 25)
        btn:SetPoint("TOPLEFT", 0, -(i-1) * 30)
        btn:SetText(custom.name)
        
        btn:SetScript("OnClick", function()
            ClickMorphMountCustomizer.SelectCustomization(custom)
        end)
        
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(custom.name)
            GameTooltip:AddLine(custom.description, 1, 1, 1, true)
            GameTooltip:AddLine("Customize: " .. custom.customizeString, 0.6, 0.6, 1)
            GameTooltip:AddLine("Click to preview", 0, 1, 0)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(system.customButtons, btn)
    end
    
    CustomizerDebugPrint("Populated customization list with", #customizations, "options")
end

-- Selecionar customização
function ClickMorphMountCustomizer.SelectCustomization(customizationData)
    local system = ClickMorphMountCustomizer.customizerSystem
    
    system.selectedCustomization = customizationData
    
    CustomizerDebugPrint("Selected customization:", customizationData.name)
    
    -- Atualizar preview
    if system.selectedMount then
        ClickMorphMountCustomizer.UpdatePreview(system.selectedMount.baseDisplayID, customizationData.customizeString)
    end
    
    -- Atualizar info
    if system.selectedInfo then
        system.selectedInfo:SetText(system.selectedMount.name .. " - " .. customizationData.name)
    end
    if system.selectedDesc then
        system.selectedDesc:SetText(customizationData.description .. " | Command: .customize " .. system.selectedMount.baseDisplayID .. " " .. customizationData.customizeString)
    end
end

-- Status do sistema
function ClickMorphMountCustomizer.ShowStatus()
    local system = ClickMorphMountCustomizer.customizerSystem
    
    print("|cff00ff00=== MOUNT CUSTOMIZER STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Selected Mount:", system.selectedMount and system.selectedMount.name or "None")
    print("Selected Customization:", system.selectedCustomization and system.selectedCustomization.name or "None")
    print("Current DisplayID:", system.currentDisplayID or "None")
    print("Current Customize String:", system.currentCustomizeString ~= "" and system.currentCustomizeString or "None")
    
    local totalMounts = #ClickMorphMountCustomizer.MOUNT_DATABASE
    local totalCustomizations = 0
    for _, mount in ipairs(ClickMorphMountCustomizer.MOUNT_DATABASE) do
        totalCustomizations = totalCustomizations + #mount.customizations
    end
    
    print("Total Mounts:", totalMounts)
    print("Total Customizations:", totalCustomizations)
end

-- Comandos para mount customizer
SLASH_CLICKMORPH_MOUNT1 = "/cmmount"
SlashCmdList.CLICKMORPH_MOUNT = function(arg)
    local args = {}
    for word in arg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = string.lower(args[1] or "")
    
    if command == "reset" then
        ClickMorphMountCustomizer.ResetCustomization()
    elseif command == "status" then
        ClickMorphMountCustomizer.ShowStatus()
    elseif command == "debug" then
        ClickMorphMountCustomizer.customizerSystem.debugMode = not ClickMorphMountCustomizer.customizerSystem.debugMode
        print("|cff00ff00Mount Customizer:|r Debug mode", ClickMorphMountCustomizer.customizerSystem.debugMode and "ON" or "OFF")
    
    -- COMANDOS EXPERIMENTAIS (descomente para usar)
    --[[
    elseif command == "discover" then
        local displayID = tonumber(args[2])
        local maxSlots = tonumber(args[3]) or 5
        local maxOptions = tonumber(args[4]) or 20
        
        if displayID then
            print("|cff00ff00Mount Customizer:|r Starting discovery for DisplayID", displayID)
            ClickMorphMountCustomizer.DiscoverCustomizations(displayID, maxSlots, maxOptions)
        else
            print("|cffff0000Mount Customizer:|r Usage: /cmmount discover <displayID> [maxSlots] [maxOptions]")
        end
    elseif command == "test" then
        local displayID = tonumber(args[2])
        local customizeString = args[3]
        
        if displayID and customizeString then
            local cmd = string.format(".customize %d %s", displayID, customizeString)
            print("|cff00ff00Mount Customizer:|r Testing:", cmd)
            SendChatMessage(cmd, "SAY")
        else
            print("|cffff0000Mount Customizer:|r Usage: /cmmount test <displayID> <customizeString>")
        end
    --]]
    
    else
        print("|cff00ff00Mount Customizer Commands:|r")
        print("/cmmount reset - Reset customization")
        print("/cmmount status - Show system status")
        print("/cmmount debug - Toggle debug mode")
        
        -- COMANDOS EXPERIMENTAIS (descomente para mostrar)
        --print("/cmmount discover <displayID> [slots] [options] - Discover customizations")
        --print("/cmmount test <displayID> <customizeString> - Test specific customization")
        
        print("")
        print("Use the iMorph tab -> Mount Customizer for the full interface!")
    end
end

print("|cff00ff00ClickMorph Mount Customizer|r loaded!")
print("|cff00ff00Mount Customizer:|r 3D preview and .customize integration ready")