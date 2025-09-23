-- MountShop.lua
-- Sistema de customização de mounts estilo barbershop integrado ao wardrobe

ClickMorphMountShop = {}

-- Sistema do Mount Shop
ClickMorphMountShop.mountShopSystem = {
    contentFrame = nil,
    previewComponent = nil,
    mountsList = nil,
    customizationPanel = nil,
    selectedMount = nil,
    currentCustomization = "",
    availableCustomizations = {},
    isInitialized = false
}

-- Base de dados de mounts customizáveis (expandir conforme descobrir mais)
ClickMorphMountShop.CUSTOMIZABLE_MOUNTS = {
    -- Dirigível do Imersor (exemplo que você mencionou)
    {
        name = "Dirigível do Imersor",
        mountID = 55297,
        baseDisplayID = 55297,
        icon = "Interface\\Icons\\INV_Mount_Dirigible",
        rarity = 4,
        customizations = {
            {
                name = "Azul Padrão",
                customizeString = "1:0",
                description = "Coloração azul padrão do dirigível",
                previewColor = {0.2, 0.4, 0.8}
            },
            {
                name = "Vermelho Imperial",
                customizeString = "1:1",
                description = "Pintura vermelha imperial",
                previewColor = {0.8, 0.2, 0.2}
            },
            {
                name = "Verde Jade",
                customizeString = "1:2", 
                description = "Acabamento verde jade",
                previewColor = {0.2, 0.8, 0.2}
            },
            {
                name = "Dourado Real",
                customizeString = "1:3",
                description = "Ornamentação dourada",
                previewColor = {0.8, 0.8, 0.2}
            },
            {
                name = "Púrpura Místico",
                customizeString = "1:4",
                description = "Tons púrpura místicos",
                previewColor = {0.8, 0.2, 0.8}
            }
        }
    },
    
    -- Prototipo de Dragão (exemplo genérico)
    {
        name = "Proto-Drake Customizável",
        mountID = 32857,
        baseDisplayID = 32857,
        icon = "Interface\\Icons\\Ability_Mount_Drake_Proto",
        rarity = 5,
        customizations = {
            {
                name = "Escamas Azuis",
                customizeString = "2:0",
                description = "Escamas azul gélido",
                previewColor = {0.2, 0.5, 0.9}
            },
            {
                name = "Escamas Vermelhas",
                customizeString = "2:1", 
                description = "Escamas vermelho fogo",
                previewColor = {0.9, 0.3, 0.2}
            },
            {
                name = "Escamas Verdes",
                customizeString = "2:2",
                description = "Escamas verde natureza",
                previewColor = {0.3, 0.8, 0.3}
            }
        }
    },
    
    -- Cavalo Mecânico (placeholder)
    {
        name = "Cavalo Mecânico",
        mountID = 68057,
        baseDisplayID = 68057,
        icon = "Interface\\Icons\\INV_Mount_MechaStrider",
        rarity = 3,
        customizations = {
            {
                name = "Chassi Padrão",
                customizeString = "3:0",
                description = "Chassi metálico padrão",
                previewColor = {0.7, 0.7, 0.7}
            },
            {
                name = "Chassi Dourado",
                customizeString = "3:1",
                description = "Chassi com acabamento dourado",
                previewColor = {0.9, 0.8, 0.3}
            }
        }
    }
}

-- Debug print
local function MountShopDebugPrint(...)
    if ClickMorphCustomWardrobe and ClickMorphCustomWardrobe.wardrobeSystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cffff6600MountShop:|r", table.concat(args, " "))
    end
end

-- =============================================================================
-- MOUNT SHOP WARDROBE CONTENT
-- =============================================================================

-- Criar conteúdo do Mount Shop no wardrobe
function ClickMorphMountShop.CreateMountShopContent(parent)
    local system = ClickMorphMountShop.mountShopSystem
    
    MountShopDebugPrint("Creating Mount Shop wardrobe content")
    
    if system.isInitialized then
        MountShopDebugPrint("Mount Shop already initialized, refreshing")
        ClickMorphMountShop.RefreshMountShop()
        return system.contentFrame
    end
    
    -- Frame principal do conteúdo
    local contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetAllPoints()
    system.contentFrame = contentFrame
    
    -- Título da seção
    local titleFrame = CreateFrame("Frame", nil, contentFrame)
    titleFrame:SetSize(792, 30)
    titleFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    
    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleFrame, "LEFT", 0, 0)
    title:SetText("Mount Shop - Customize Your Mounts")
    title:SetTextColor(1, 1, 1)
    
    -- Subtitle/info
    local subtitle = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("RIGHT", titleFrame, "RIGHT", 0, 0)
    subtitle:SetText("Barbershop-style mount customization")
    subtitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Criar componentes específicos do Mount Shop
    ClickMorphMountShop.CreateMountShopComponents(contentFrame)
    
    -- Popular com dados iniciais
    ClickMorphMountShop.PopulateMountShop()
    
    system.isInitialized = true
    MountShopDebugPrint("Mount Shop wardrobe content created")
    
    return contentFrame
end

-- Criar componentes específicos do Mount Shop
function ClickMorphMountShop.CreateMountShopComponents(parent)
    local system = ClickMorphMountShop.mountShopSystem
    
    -- Lista de mounts (lado esquerdo)
    ClickMorphMountShop.CreateMountsList(parent)
    
    -- Preview 3D (centro-direita)
    system.previewComponent = ClickMorphCustomWardrobe.API.CreatePreview3D(parent, {
        point = "TOP",
        relativeTo = "TOP",
        x = 100,
        y = -40
    }, {width = 300, height = 320})
    
    -- Painel de customização (lado direito)
    ClickMorphMountShop.CreateCustomizationPanel(parent)
    
    -- Botões de ação (parte inferior)
    ClickMorphMountShop.CreateActionButtons(parent)
    
    MountShopDebugPrint("Mount Shop components created")
end

-- Criar lista de mounts
function ClickMorphMountShop.CreateMountsList(parent)
    local system = ClickMorphMountShop.mountShopSystem
    
    -- Container da lista
    local mountsListContainer = CreateFrame("Frame", nil, parent)
    mountsListContainer:SetSize(200, 320)
    mountsListContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -40)
    
    -- Background
    local listBg = mountsListContainer:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints()
    listBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Borda
    local listBorder = CreateFrame("Frame", nil, mountsListContainer, "InsetFrameTemplate")
    listBorder:SetAllPoints()
    
    -- Título da lista
    local listTitle = mountsListContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listTitle:SetPoint("TOP", mountsListContainer, "TOP", 0, -10)
    listTitle:SetText("Available Mounts")
    
    -- ScrollFrame para mounts
    local scrollFrame = CreateFrame("ScrollFrame", nil, mountsListContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(170, 280)
    scrollFrame:SetPoint("TOPLEFT", mountsListContainer, "TOPLEFT", 10, -30)
    
    -- Content frame
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(170, 1)
    scrollFrame:SetScrollChild(scrollContent)
    
    -- Salvar referências
    system.mountsList = {
        container = mountsListContainer,
        scrollFrame = scrollFrame,
        scrollContent = scrollContent,
        buttons = {}
    }
    
    MountShopDebugPrint("Mounts list created")
end

-- Criar painel de customização
function ClickMorphMountShop.CreateCustomizationPanel(parent)
    local system = ClickMorphMountShop.mountShopSystem
    
    -- Container do painel
    local customizationContainer = CreateFrame("Frame", nil, parent)
    customizationContainer:SetSize(200, 320)
    customizationContainer:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -40)
    
    -- Background
    local panelBg = customizationContainer:CreateTexture(nil, "BACKGROUND")
    panelBg:SetAllPoints()
    panelBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Borda
    local panelBorder = CreateFrame("Frame", nil, customizationContainer, "InsetFrameTemplate")
    panelBorder:SetAllPoints()
    
    -- Título do painel
    local panelTitle = customizationContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panelTitle:SetPoint("TOP", customizationContainer, "TOP", 0, -10)
    panelTitle:SetText("Customization")
    
    -- ScrollFrame para opções
    local scrollFrame = CreateFrame("ScrollFrame", nil, customizationContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(170, 280)
    scrollFrame:SetPoint("TOPLEFT", customizationContainer, "TOPLEFT", 10, -30)
    
    -- Content frame
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(170, 1)
    scrollFrame:SetScrollChild(scrollContent)
    
    -- Salvar referências
    system.customizationPanel = {
        container = customizationContainer,
        title = panelTitle,
        scrollFrame = scrollFrame,
        scrollContent = scrollContent,
        buttons = {}
    }
    
    MountShopDebugPrint("Customization panel created")
end

-- Criar botões de ação
function ClickMorphMountShop.CreateActionButtons(parent)
    local system = ClickMorphMountShop.mountShopSystem
    
    -- Frame dos botões
    local actionFrame = CreateFrame("Frame", nil, parent)
    actionFrame:SetSize(792, 40)
    actionFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 10)
    
    -- Botão Apply
    local applyBtn = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(100, 30)
    applyBtn:SetPoint("CENTER", actionFrame, "CENTER", -60, 0)
    applyBtn:SetText("Apply Mount")
    applyBtn:SetScript("OnClick", function()
        ClickMorphMountShop.ApplyCurrentMount()
    end)
    
    -- Botão Reset
    local resetBtn = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(80, 30)
    resetBtn:SetPoint("CENTER", actionFrame, "CENTER", 50, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        ClickMorphMountShop.ResetMount()
    end)
    
    -- Botão Random
    local randomBtn = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")
    randomBtn:SetSize(100, 30)
    randomBtn:SetPoint("CENTER", actionFrame, "CENTER", 150, 0)
    randomBtn:SetText("Random All")
    randomBtn:SetScript("OnClick", function()
        ClickMorphMountShop.RandomizeMount()
    end)
    
    -- Botão Save Preset
    local savePresetBtn = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")
    savePresetBtn:SetSize(90, 30)
    savePresetBtn:SetPoint("CENTER", actionFrame, "CENTER", -170, 0)
    savePresetBtn:SetText("Save Preset")
    savePresetBtn:SetScript("OnClick", function()
        ClickMorphMountShop.SaveCurrentPreset()
    end)
    
    -- Salvar referências
    system.actionButtons = {
        apply = applyBtn,
        reset = resetBtn,
        random = randomBtn,
        savePreset = savePresetBtn
    }
    
    MountShopDebugPrint("Action buttons created")
end

-- =============================================================================
-- MOUNT MANAGEMENT
-- =============================================================================

-- Popular Mount Shop com dados
function ClickMorphMountShop.PopulateMountShop()
    local system = ClickMorphMountShop.mountShopSystem
    
    MountShopDebugPrint("Populating Mount Shop with data")
    
    -- Popular lista de mounts
    ClickMorphMountShop.PopulateMountsList()
    
    MountShopDebugPrint("Mount Shop populated")
end

-- Popular lista de mounts
function ClickMorphMountShop.PopulateMountsList()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.mountsList then return end
    
    -- Limpar botões existentes
    for _, button in pairs(system.mountsList.buttons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(system.mountsList.buttons)
    
    -- Criar botões para cada mount
    local yOffset = 0
    for i, mountData in ipairs(ClickMorphMountShop.CUSTOMIZABLE_MOUNTS) do
        local button = ClickMorphMountShop.CreateMountButton(system.mountsList.scrollContent, mountData, yOffset)
        table.insert(system.mountsList.buttons, button)
        yOffset = yOffset - 45
    end
    
    -- Ajustar altura do scroll content
    local contentHeight = #ClickMorphMountShop.CUSTOMIZABLE_MOUNTS * 45 + 20
    system.mountsList.scrollContent:SetHeight(math.max(contentHeight, 280))
    
    MountShopDebugPrint("Populated mounts list with", #ClickMorphMountShop.CUSTOMIZABLE_MOUNTS, "mounts")
end

-- Criar botão individual de mount
function ClickMorphMountShop.CreateMountButton(parent, mountData, yOffset)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(150, 40)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    
    -- Background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    
    -- Highlight
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.3, 0.5, 0.8, 0.3)
    
    -- Ícone
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(32, 32)
    button.icon:SetPoint("LEFT", button, "LEFT", 4, 0)
    button.icon:SetTexture(mountData.icon)
    
    -- Nome
    button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.nameText:SetPoint("LEFT", button.icon, "RIGHT", 5, 5)
    button.nameText:SetText(mountData.name)
    button.nameText:SetJustifyH("LEFT")
    button.nameText:SetWidth(100)
    
    -- Info adicional
    button.infoText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.infoText:SetPoint("LEFT", button.icon, "RIGHT", 5, -8)
    button.infoText:SetText(#mountData.customizations .. " variants")
    button.infoText:SetTextColor(0.7, 0.7, 0.7)
    button.infoText:SetJustifyH("LEFT")
    button.infoText:SetWidth(100)
    
    -- Borda de raridade
    if mountData.rarity then
        local r, g, b = ClickMorphCustomWardrobe.API.GetRarityColor(mountData.rarity)
        button.rarityBorder = button:CreateTexture(nil, "OVERLAY")
        button.rarityBorder:SetSize(36, 36)
        button.rarityBorder:SetPoint("CENTER", button.icon, "CENTER")
        button.rarityBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
        button.rarityBorder:SetVertexColor(r, g, b)
    end
    
    -- Dados do mount
    button.mountData = mountData
    
    -- Clique
    button:SetScript("OnClick", function(self)
        ClickMorphMountShop.SelectMount(self.mountData)
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        ClickMorphMountShop.ShowMountTooltip(self, self.mountData)
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return button
end

-- Tooltip de mount
function ClickMorphMountShop.ShowMountTooltip(button, mountData)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(mountData.name, 1, 1, 1)
    
    GameTooltip:AddLine("Customizable Mount", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Variants: " .. #mountData.customizations, 0.5, 0.8, 1)
    GameTooltip:AddLine("Mount ID: " .. mountData.mountID, 0.5, 0.8, 1)
    
    local rarityText = {"", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
    if mountData.rarity then
        local r, g, b = ClickMorphCustomWardrobe.API.GetRarityColor(mountData.rarity)
        GameTooltip:AddLine(rarityText[mountData.rarity] or "Unknown", r, g, b)
    end
    
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Click to select and customize", 0, 1, 0)
    
    GameTooltip:Show()
end

-- =============================================================================
-- CUSTOMIZATION SYSTEM
-- =============================================================================

-- Selecionar mount
function ClickMorphMountShop.SelectMount(mountData)
    local system = ClickMorphMountShop.mountShopSystem
    
    MountShopDebugPrint("Selecting mount:", mountData.name)
    
    system.selectedMount = mountData
    system.availableCustomizations = mountData.customizations
    system.currentCustomization = mountData.customizations[1].customizeString -- Padrão primeira opção
    
    -- Atualizar seleção visual
    ClickMorphMountShop.UpdateMountSelection()
    
    -- Atualizar preview
    ClickMorphMountShop.UpdateMountPreview()
    
    -- Popular painel de customização
    ClickMorphMountShop.PopulateCustomizationPanel()
    
    -- Atualizar título do painel
    if system.customizationPanel then
        system.customizationPanel.title:SetText(mountData.name)
    end
end

-- Atualizar seleção visual de mount
function ClickMorphMountShop.UpdateMountSelection()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.mountsList then return end
    
    -- Atualizar visual dos botões
    for _, button in pairs(system.mountsList.buttons) do
        if button.mountData == system.selectedMount then
            button.bg:SetColorTexture(0.3, 0.5, 0.8, 0.7) -- Azul selecionado
        else
            button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5) -- Cinza normal
        end
    end
end

-- Atualizar preview do mount
function ClickMorphMountShop.UpdateMountPreview()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.previewComponent or not system.selectedMount then
        return
    end
    
    MountShopDebugPrint("Updating mount preview with customization:", system.currentCustomization)
    
    -- TODO: Aplicar customização no preview
    -- Por enquanto, mostrar mount base
    system.previewComponent:UpdatePreview({
        name = system.selectedMount.name,
        type = "mount",
        displayID = system.selectedMount.baseDisplayID,
        mountID = system.selectedMount.mountID
    })
    
    -- Atualizar label com customização atual
    local customizationName = "Default"
    for _, custom in ipairs(system.availableCustomizations) do
        if custom.customizeString == system.currentCustomization then
            customizationName = custom.name
            break
        end
    end
    
    system.previewComponent.previewLabel:SetText(system.selectedMount.name .. " - " .. customizationName)
end

-- Popular painel de customização
function ClickMorphMountShop.PopulateCustomizationPanel()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.customizationPanel or not system.selectedMount then
        return
    end
    
    -- Limpar botões existentes
    for _, button in pairs(system.customizationPanel.buttons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(system.customizationPanel.buttons)
    
    -- Criar botões para cada customização
    local yOffset = 0
    for i, customData in ipairs(system.availableCustomizations) do
        local button = ClickMorphMountShop.CreateCustomizationButton(system.customizationPanel.scrollContent, customData, yOffset)
        table.insert(system.customizationPanel.buttons, button)
        yOffset = yOffset - 35
    end
    
    -- Ajustar altura do scroll content
    local contentHeight = #system.availableCustomizations * 35 + 20
    system.customizationPanel.scrollContent:SetHeight(math.max(contentHeight, 280))
    
    MountShopDebugPrint("Populated customization panel with", #system.availableCustomizations, "options")
end

-- Criar botão de customização
function ClickMorphMountShop.CreateCustomizationButton(parent, customData, yOffset)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(140, 30)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    
    -- Background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
    
    -- Highlight
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.3, 0.5, 0.8, 0.3)
    
    -- Color preview (se disponível)
    if customData.previewColor then
        button.colorPreview = button:CreateTexture(nil, "ARTWORK")
        button.colorPreview:SetSize(16, 16)
        button.colorPreview:SetPoint("LEFT", button, "LEFT", 5, 0)
        button.colorPreview:SetColorTexture(unpack(customData.previewColor))
        
        -- Borda do color preview
        button.colorBorder = button:CreateTexture(nil, "OVERLAY")
        button.colorBorder:SetSize(18, 18)
        button.colorBorder:SetPoint("CENTER", button.colorPreview, "CENTER")
        button.colorBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
        button.colorBorder:SetVertexColor(0.8, 0.8, 0.8)
    end
    
    -- Nome da customização
    button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.nameText:SetPoint("LEFT", button, "LEFT", customData.previewColor and 28 or 8, 0)
    button.nameText:SetText(customData.name)
    button.nameText:SetJustifyH("LEFT")
    button.nameText:SetWidth(100)
    
    -- Dados da customização
    button.customData = customData
    
    -- Clique
    button:SetScript("OnClick", function(self)
        ClickMorphMountShop.SelectCustomization(self.customData)
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        ClickMorphMountShop.ShowCustomizationTooltip(self, self.customData)
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return button
end

-- Tooltip de customização
function ClickMorphMountShop.ShowCustomizationTooltip(button, customData)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(customData.name, 1, 1, 1)
    
    if customData.description then
        GameTooltip:AddLine(customData.description, 0.8, 0.8, 0.8, true)
    end
    
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Customize String: " .. customData.customizeString, 0.5, 0.8, 1)
    GameTooltip:AddLine("Click to preview", 0, 1, 0)
    
    GameTooltip:Show()
end

-- Selecionar customização
function ClickMorphMountShop.SelectCustomization(customData)
    local system = ClickMorphMountShop.mountShopSystem
    
    MountShopDebugPrint("Selecting customization:", customData.name)
    
    system.currentCustomization = customData.customizeString
    
    -- Atualizar seleção visual
    ClickMorphMountShop.UpdateCustomizationSelection()
    
    -- Atualizar preview
    ClickMorphMountShop.UpdateMountPreview()
end

-- Atualizar seleção visual de customização
function ClickMorphMountShop.UpdateCustomizationSelection()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.customizationPanel then return end
    
    -- Atualizar visual dos botões
    for _, button in pairs(system.customizationPanel.buttons) do
        if button.customData.customizeString == system.currentCustomization then
            button.bg:SetColorTexture(0.3, 0.5, 0.8, 0.8) -- Azul selecionado
        else
            button.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8) -- Cinza normal
        end
    end
end

-- =============================================================================
-- ACTIONS
-- =============================================================================

-- Aplicar mount atual
function ClickMorphMountShop.ApplyCurrentMount()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.selectedMount or not system.currentCustomization then
        print("|cffff6600MountShop:|r No mount or customization selected")
        return
    end
    
    local command = ".customize " .. system.selectedMount.mountID .. " " .. system.currentCustomization
    
    MountShopDebugPrint("Applying mount with command:", command)
    
    SendChatMessage(command, "GUILD")
    
    -- Feedback
    local customizationName = "Default"
    for _, custom in ipairs(system.availableCustomizations) do
        if custom.customizeString == system.currentCustomization then
            customizationName = custom.name
            break
        end
    end
    
    print("|cffff6600MountShop:|r Applied " .. system.selectedMount.name .. " - " .. customizationName)
    
    -- Auto-save se disponível
    if ClickMorphSaveHub and ClickMorphSaveHub.API then
        ClickMorphSaveHub.API.AutoSave({
            type = "mount",
            mountID = system.selectedMount.mountID,
            customizeString = system.currentCustomization,
            command = command
        })
    end
end

-- Reset mount (voltar ao padrão)
function ClickMorphMountShop.ResetMount()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.selectedMount then
        print("|cffff6600MountShop:|r No mount selected")
        return
    end
    
    -- Voltar à primeira customização (padrão)
    if #system.availableCustomizations > 0 then
        system.currentCustomization = system.availableCustomizations[1].customizeString
        ClickMorphMountShop.UpdateCustomizationSelection()
        ClickMorphMountShop.UpdateMountPreview()
        
        print("|cffff6600MountShop:|r Reset to default customization")
    end
end

-- Randomizar mount e customização
function ClickMorphMountShop.RandomizeMount()
    local system = ClickMorphMountShop.mountShopSystem
    
    -- Mount aleatório
    local randomMount = ClickMorphMountShop.CUSTOMIZABLE_MOUNTS[math.random(#ClickMorphMountShop.CUSTOMIZABLE_MOUNTS)]
    
    -- Selecionar mount
    ClickMorphMountShop.SelectMount(randomMount)
    
    -- Customização aleatória
    if #system.availableCustomizations > 0 then
        local randomCustom = system.availableCustomizations[math.random(#system.availableCustomizations)]
        ClickMorphMountShop.SelectCustomization(randomCustom)
    end
    
    print("|cffff6600MountShop:|r Randomized to " .. randomMount.name)
end

-- Salvar preset atual
function ClickMorphMountShop.SaveCurrentPreset()
    local system = ClickMorphMountShop.mountShopSystem
    
    if not system.selectedMount or not system.currentCustomization then
        print("|cffff6600MountShop:|r No mount or customization selected")
        return
    end
    
    -- Encontrar nome da customização
    local customizationName = "Default"
    for _, custom in ipairs(system.availableCustomizations) do
        if custom.customizeString == system.currentCustomization then
            customizationName = custom.name
            break
        end
    end
    
    -- Salvar no SaveHub se disponível
    if ClickMorphSaveHub and ClickMorphSaveHub.API then
        local presetName = system.selectedMount.name .. " - " .. customizationName
        
        ClickMorphSaveHub.API.Save(presetName, {
            type = "mount",
            mountID = system.selectedMount.mountID,
            displayID = system.selectedMount.baseDisplayID,
            customizeString = system.currentCustomization,
            command = ".customize " .. system.selectedMount.mountID .. " " .. system.currentCustomization
        }, {
            description = "Mount preset from Mount Shop"
        })
        
        print("|cffff6600MountShop:|r Saved preset: " .. presetName)
    else
        print("|cffff6600MountShop:|r SaveHub not available - cannot save preset")
    end
end

-- =============================================================================
-- SMART DISCOVERY INTEGRATION
-- =============================================================================

-- Aprender mount customization do SmartDiscovery
function ClickMorphMountShop.LearnMountCustomization(mountID, customizeString, source)
    MountShopDebugPrint("Learning mount customization:", mountID, customizeString)
    
    -- Procurar mount existente
    for _, mountData in ipairs(ClickMorphMountShop.CUSTOMIZABLE_MOUNTS) do
        if mountData.mountID == mountID then
            -- Verificar se customização já existe
            local exists = false
            for _, custom in ipairs(mountData.customizations) do
                if custom.customizeString == customizeString then
                    exists = true
                    break
                end
            end
            
            -- Adicionar nova customização se não existir
            if not exists then
                table.insert(mountData.customizations, {
                    name = "Discovered " .. customizeString,
                    customizeString = customizeString,
                    description = "Discovered from " .. (source or "unknown source"),
                    previewColor = {0.8, 0.8, 0.8} -- Cor cinza padrão para descobertos
                })
                
                MountShopDebugPrint("Added new customization to existing mount")
                
                -- Refresh se estiver visualizando este mount
                local system = ClickMorphMountShop.mountShopSystem
                if system.selectedMount and system.selectedMount.mountID == mountID then
                    ClickMorphMountShop.PopulateCustomizationPanel()
                end
            end
            
            return
        end
    end
    
    -- Mount não existe, tentar obter info e adicionar
    local mountName, spellID, icon = "Unknown Mount " .. mountID, nil, "Interface\\Icons\\Ability_Mount_RidingHorse"
    
    if C_MountJournal and C_MountJournal.GetMountInfoByID then
        local name, spell, icn = C_MountJournal.GetMountInfoByID(mountID)
        if name then
            mountName = name
            spellID = spell
            icon = icn
        end
    end
    
    -- Adicionar novo mount descoberto
    local newMount = {
        name = mountName,
        mountID = mountID,
        baseDisplayID = mountID, -- Fallback
        icon = icon,
        rarity = 3, -- Assumir raro para descobertos
        customizations = {
            {
                name = "Discovered " .. customizeString,
                customizeString = customizeString,
                description = "Discovered from " .. (source or "unknown source"),
                previewColor = {0.8, 0.8, 0.8}
            }
        }
    }
    
    table.insert(ClickMorphMountShop.CUSTOMIZABLE_MOUNTS, newMount)
    MountShopDebugPrint("Added new discovered mount:", mountName)
    
    -- Refresh lista se Mount Shop estiver ativo
    local system = ClickMorphMountShop.mountShopSystem
    if system.isInitialized then
        ClickMorphMountShop.RefreshMountShop()
    end
end

-- Hook no SmartDiscovery para aprender customizações automaticamente
local function HookSmartDiscoveryForMounts()
    if ClickMorphSmartDiscovery and ClickMorphSmartDiscovery.LearnMountCustomization then
        local originalLearn = ClickMorphSmartDiscovery.LearnMountCustomization
        
        ClickMorphSmartDiscovery.LearnMountCustomization = function(mountID, metadata)
            -- Chamar função original
            originalLearn(mountID, metadata)
            
            -- Adicionar ao Mount Shop também
            if metadata and metadata.customizeString then
                ClickMorphMountShop.LearnMountCustomization(mountID, metadata.customizeString, metadata.source)
            end
        end
        
        MountShopDebugPrint("Hooked SmartDiscovery for mount learning")
    end
end

-- =============================================================================
-- MAIN FUNCTIONS
-- =============================================================================

-- Refresh do Mount Shop
function ClickMorphMountShop.RefreshMountShop()
    MountShopDebugPrint("Refreshing Mount Shop")
    
    ClickMorphMountShop.PopulateMountShop()
    
    -- Limpar seleção
    local system = ClickMorphMountShop.mountShopSystem
    system.selectedMount = nil
    system.currentCustomization = ""
    system.availableCustomizations = {}
    
    -- Limpar painel de customização
    if system.customizationPanel then
        system.customizationPanel.title:SetText("Customization")
        for _, button in pairs(system.customizationPanel.buttons) do
            button:Hide()
        end
    end
end

-- =============================================================================
-- INTEGRATION & REGISTRATION
-- =============================================================================

-- Registrar Mount Shop no framework de wardrobe
local function RegisterMountShopContent()
    if ClickMorphCustomWardrobe and ClickMorphCustomWardrobe.API then
        ClickMorphCustomWardrobe.API.RegisterTabContent("mountShop", ClickMorphMountShop.CreateMountShopContent)
        MountShopDebugPrint("Mount Shop content registered with Custom Wardrobe")
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Inicialização
local function InitializeMountShop()
    MountShopDebugPrint("Initializing Mount Shop integration...")
    
    -- Registrar content no framework
    RegisterMountShopContent()
    
    -- Hook SmartDiscovery se disponível
    if ClickMorphSmartDiscovery then
        HookSmartDiscoveryForMounts()
    else
        -- Tentar novamente após delay
        C_Timer.After(2, function()
            if ClickMorphSmartDiscovery then
                HookSmartDiscoveryForMounts()
            end
        end)
    end
    
    MountShopDebugPrint("Mount Shop integration ready")
end

-- Event frame para inicialização
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        C_Timer.After(1.5, InitializeMountShop)
    end
end)

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- API pública para Mount Shop
ClickMorphMountShop.API = {
    -- Content creation
    CreateContent = ClickMorphMountShop.CreateMountShopContent,
    
    -- Mount management
    SelectMount = ClickMorphMountShop.SelectMount,
    SelectCustomization = ClickMorphMountShop.SelectCustomization,
    RefreshMountShop = ClickMorphMountShop.RefreshMountShop,
    
    -- Actions
    ApplyCurrentMount = ClickMorphMountShop.ApplyCurrentMount,
    ResetMount = ClickMorphMountShop.ResetMount,
    RandomizeMount = ClickMorphMountShop.RandomizeMount,
    SaveCurrentPreset = ClickMorphMountShop.SaveCurrentPreset,
    
    -- Learning system
    LearnMountCustomization = ClickMorphMountShop.LearnMountCustomization,
    
    -- Data access
    GetCustomizableMounts = function()
        return ClickMorphMountShop.CUSTOMIZABLE_MOUNTS
    end
}

print("|cffff6600ClickMorph Mount Shop|r loaded!")
MountShopDebugPrint("MountShop.lua loaded successfully")