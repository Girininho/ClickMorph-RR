-- CustomWardrobe.lua
-- Framework base para o sistema de wardrobe customizado

ClickMorphCustomWardrobe = {}

-- Sistema principal do wardrobe
ClickMorphCustomWardrobe.wardrobeSystem = {
    mainFrame = nil,
    activeTab = nil,
    isVisible = false,
    position = {x = 0, y = 0},
    
    -- Tabs disponíveis
    tabs = {
        saveHub = {id = 1, name = "Save Hub", icon = "Interface\\Icons\\INV_Misc_Book_09"},
        morphCatalogue = {id = 2, name = "Morph Catalogue", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01"},
        mountShop = {id = 3, name = "Mount Shop", icon = "Interface\\Icons\\Ability_Mount_RidingHorse"}
    },
    
    -- Componentes compartilhados
    components = {
        preview3D = nil,
        filterSystem = nil,
        assetGrid = nil
    },
    
    settings = {
        frameSize = {width = 832, height = 588}, -- Mesmo tamanho que Wardrobe Blizzard
        previewSize = {width = 338, height = 424},
        gridSize = {width = 464, height = 424},
        showTooltips = true,
        autoPreview = true,
        debugMode = false
    }
}

-- Debug print
local function WardrobeDebugPrint(...)
    if ClickMorphCustomWardrobe.wardrobeSystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff00ffffWardrobe:|r", message)
    end
end

-- =============================================================================
-- FRAMEWORK BASE - MAIN INTERFACE
-- =============================================================================

-- Criar interface principal
function ClickMorphCustomWardrobe.CreateMainInterface()
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    if system.mainFrame then
        WardrobeDebugPrint("Main interface already exists")
        return system.mainFrame
    end
    
    WardrobeDebugPrint("Creating main wardrobe interface")
    
    -- Frame principal (mesmo estilo que Collections)
    local mainFrame = CreateFrame("Frame", "ClickMorphCustomWardrobeFrame", UIParent, "ButtonFrameTemplate")
    mainFrame:SetSize(system.settings.frameSize.width, system.settings.frameSize.height)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", system.position.x, system.position.y)
    mainFrame:SetFrameStrata("HIGH")
    
    -- Título da janela
    mainFrame.TitleText:SetText("ClickMorph Wardrobe")
    
    -- Tornar movível
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Salvar posição
        local point, _, _, x, y = self:GetPoint()
        system.position.x = x
        system.position.y = y
    end)
    
    -- Botão fechar customizado
    mainFrame:SetScript("OnHide", function()
        system.isVisible = false
        WardrobeDebugPrint("Wardrobe hidden")
    end)
    
    -- Criar sistema de tabs
    ClickMorphCustomWardrobe.CreateTabSystem(mainFrame)
    
    -- Criar área de conteúdo principal
    local contentFrame = CreateFrame("Frame", nil, mainFrame)
    contentFrame:SetSize(system.settings.frameSize.width - 40, system.settings.frameSize.height - 100)
    contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -80)
    system.contentFrame = contentFrame
    
    -- Salvar referência
    system.mainFrame = mainFrame
    
    WardrobeDebugPrint("Main wardrobe interface created")
    return mainFrame
end

-- Criar sistema de tabs
function ClickMorphCustomWardrobe.CreateTabSystem(parent)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    WardrobeDebugPrint("Creating tab system")
    
    -- Frame das tabs
    local tabFrame = CreateFrame("Frame", nil, parent)
    tabFrame:SetSize(system.settings.frameSize.width - 40, 40)
    tabFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -40)
    
    system.tabButtons = {}
    local tabIndex = 1
    
    -- Criar botões de tab
    for tabKey, tabData in pairs(system.tabs) do
        local tabButton = CreateFrame("Button", nil, tabFrame, "CharacterFrameTabButtonTemplate")
        tabButton:SetSize(120, 32)
        tabButton:SetPoint("LEFT", tabFrame, "LEFT", (tabIndex - 1) * 125, 0)
        
        -- Configurar tab
        tabButton:SetText(tabData.name)
        tabButton.tabKey = tabKey
        tabButton.tabData = tabData
        
        -- Ícone da tab (opcional)
        if tabData.icon then
            tabButton.icon = tabButton:CreateTexture(nil, "ARTWORK")
            tabButton.icon:SetSize(16, 16)
            tabButton.icon:SetPoint("LEFT", tabButton, "LEFT", 5, 0)
            tabButton.icon:SetTexture(tabData.icon)
        end
        
        -- Script de clique
        tabButton:SetScript("OnClick", function(self)
            ClickMorphCustomWardrobe.SelectTab(self.tabKey)
        end)
        
        system.tabButtons[tabKey] = tabButton
        tabIndex = tabIndex + 1
    end
    
    -- Selecionar primeira tab por padrão
    ClickMorphCustomWardrobe.SelectTab("saveHub")
end

-- Selecionar tab
function ClickMorphCustomWardrobe.SelectTab(tabKey)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    if not system.tabs[tabKey] then
        WardrobeDebugPrint("Invalid tab:", tabKey)
        return
    end
    
    WardrobeDebugPrint("Selecting tab:", tabKey)
    
    -- Atualizar visual das tabs
    for key, button in pairs(system.tabButtons) do
        if key == tabKey then
            PanelTemplates_SelectTab(button)
        else
            PanelTemplates_DeselectTab(button)
        end
    end
    
    -- Limpar conteúdo anterior
    if system.contentFrame then
        for _, child in pairs({system.contentFrame:GetChildren()}) do
            child:Hide()
        end
    end
    
    -- Carregar conteúdo da tab
    system.activeTab = tabKey
    ClickMorphCustomWardrobe.LoadTabContent(tabKey)
end

-- Carregar conteúdo específico da tab
function ClickMorphCustomWardrobe.LoadTabContent(tabKey)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    WardrobeDebugPrint("Loading content for tab:", tabKey)
    
    if tabKey == "saveHub" then
        ClickMorphCustomWardrobe.CreateSaveHubContent(system.contentFrame)
        
    elseif tabKey == "morphCatalogue" then
        ClickMorphCustomWardrobe.CreateMorphCatalogueContent(system.contentFrame)
        
    elseif tabKey == "mountShop" then
        ClickMorphCustomWardrobe.CreateMountShopContent(system.contentFrame)
    end
end

-- =============================================================================
-- COMPONENTES REUTILIZÁVEIS - PREVIEW 3D
-- =============================================================================

-- Criar sistema de preview 3D reutilizável
function ClickMorphCustomWardrobe.CreatePreview3D(parent, position, size)
    WardrobeDebugPrint("Creating 3D preview component")
    
    size = size or ClickMorphCustomWardrobe.wardrobeSystem.settings.previewSize
    
    -- Container do preview
    local previewContainer = CreateFrame("Frame", nil, parent)
    previewContainer:SetSize(size.width, size.height)
    if position then
        previewContainer:SetPoint(position.point or "TOPRIGHT", parent, position.relativeTo or "TOPRIGHT", position.x or -20, position.y or -20)
    else
        previewContainer:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, -20)
    end
    
    -- Background do preview
    local previewBg = previewContainer:CreateTexture(nil, "BACKGROUND")
    previewBg:SetAllPoints()
    previewBg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
    
    -- Borda estilo Blizzard
    local previewBorder = CreateFrame("Frame", nil, previewContainer, "InsetFrameTemplate")
    previewBorder:SetAllPoints()
    
    -- Modelo 3D
    local modelFrame = CreateFrame("PlayerModel", nil, previewContainer)
    modelFrame:SetSize(size.width - 20, size.height - 60)
    modelFrame:SetPoint("CENTER", previewContainer, "CENTER", 0, -10)
    
    -- Configurar modelo
    modelFrame:SetUnit("player")
    modelFrame:SetFacing(0.5)
    modelFrame:SetModelScale(1.0)
    
    -- Controles do modelo
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    
    -- Rotação
    modelFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isRotating = true
            self:SetScript("OnUpdate", function(self)
                if self.isRotating then
                    local x, y = GetCursorPosition()
                    local scale = self:GetEffectiveScale()
                    local deltaX = (x / scale) - (self.lastCursorX or (x / scale))
                    self:SetFacing(self:GetFacing() + deltaX * 0.02)
                    self.lastCursorX = x / scale
                end
            end)
        end
    end)
    
    modelFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.isRotating = false
            self:SetScript("OnUpdate", nil)
            self.lastCursorX = nil
        end
    end)
    
    -- Zoom
    modelFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScale = self:GetModelScale()
        local newScale = currentScale + (delta * 0.15)
        newScale = math.max(0.4, math.min(3.0, newScale))
        self:SetModelScale(newScale)
    end)
    
    -- Label do preview
    local previewLabel = previewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    previewLabel:SetPoint("TOP", previewContainer, "TOP", 0, -5)
    previewLabel:SetText("Preview")
    previewLabel:SetTextColor(1, 1, 1)
    
    -- Instruções
    local instructionLabel = previewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructionLabel:SetPoint("BOTTOM", previewContainer, "BOTTOM", 0, 8)
    instructionLabel:SetText("Drag: Rotate | Wheel: Zoom")
    instructionLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Botões de controle
    local controlFrame = CreateFrame("Frame", nil, previewContainer)
    controlFrame:SetSize(size.width - 40, 25)
    controlFrame:SetPoint("BOTTOM", previewContainer, "BOTTOM", 0, 30)
    
    -- Botão Reset
    local resetBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(50, 22)
    resetBtn:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        modelFrame:SetFacing(0.5)
        modelFrame:SetModelScale(1.0)
    end)
    
    -- Botão Apply
    local applyBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(60, 22)
    applyBtn:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        if previewContainer.currentData then
            ClickMorphCustomWardrobe.ApplyPreviewData(previewContainer.currentData)
        end
    end)
    
    -- API do preview
    previewContainer.modelFrame = modelFrame
    previewContainer.previewLabel = previewLabel
    previewContainer.applyBtn = applyBtn
    previewContainer.currentData = nil
    
    -- Função para atualizar preview
    previewContainer.UpdatePreview = function(self, data)
        self.currentData = data
        if data then
            self.previewLabel:SetText(data.name or "Unknown")
            
            if data.type == "creature" and data.displayID then
                self.modelFrame:SetDisplayInfo(data.displayID)
            elseif data.type == "item" then
                self.modelFrame:SetUnit("player")
                -- TODO: Aplicar item visual se possível
            else
                self.modelFrame:SetUnit("player")
            end
        end
    end
    
    WardrobeDebugPrint("3D preview component created")
    return previewContainer
end

-- =============================================================================
-- COMPONENTES REUTILIZÁVEIS - ASSET GRID
-- =============================================================================

-- Criar grid de assets reutilizável
function ClickMorphCustomWardrobe.CreateAssetGrid(parent, position, size)
    WardrobeDebugPrint("Creating asset grid component")
    
    size = size or ClickMorphCustomWardrobe.wardrobeSystem.settings.gridSize
    
    -- Container do grid
    local gridContainer = CreateFrame("Frame", nil, parent)
    gridContainer:SetSize(size.width, size.height)
    if position then
        gridContainer:SetPoint(position.point or "TOPLEFT", parent, position.relativeTo or "TOPLEFT", position.x or 20, position.y or -20)
    else
        gridContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -20)
    end
    
    -- Background do grid
    local gridBg = gridContainer:CreateTexture(nil, "BACKGROUND")
    gridBg:SetAllPoints()
    gridBg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    
    -- Borda
    local gridBorder = CreateFrame("Frame", nil, gridContainer, "InsetFrameTemplate")
    gridBorder:SetAllPoints()
    
    -- ScrollFrame para o grid
    local scrollFrame = CreateFrame("ScrollFrame", nil, gridContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(size.width - 30, size.height - 20)
    scrollFrame:SetPoint("TOPLEFT", gridContainer, "TOPLEFT", 10, -10)
    
    -- Content frame do scroll
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(size.width - 50, 1)
    scrollFrame:SetScrollChild(scrollContent)
    
    -- API do grid
    gridContainer.scrollFrame = scrollFrame
    gridContainer.scrollContent = scrollContent
    gridContainer.buttons = {}
    gridContainer.buttonsPerRow = 8
    gridContainer.buttonSize = 50
    gridContainer.buttonSpacing = 55
    
    -- Função para criar botão de asset
    gridContainer.CreateAssetButton = function(self, index, assetData)
        local button = CreateFrame("Button", nil, self.scrollContent, "ItemButtonTemplate")
        button:SetSize(self.buttonSize, self.buttonSize)
        
        -- Posicionamento em grid
        local row = math.floor((index - 1) / self.buttonsPerRow)
        local col = (index - 1) % self.buttonsPerRow
        button:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", col * self.buttonSpacing, -row * self.buttonSpacing)
        
        -- Configurar ícone
        if assetData.icon then
            button.icon:SetTexture(assetData.icon)
        else
            -- Ícone padrão baseado no tipo
            if assetData.type == "creature" then
                button.icon:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_01")
            elseif assetData.type == "item" then
                button.icon:SetTexture("Interface\\Icons\\INV_Chest_Plate06")
            elseif assetData.type == "mount" then
                button.icon:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse")
            else
                button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
        end
        
        -- Cor da borda por raridade
        if assetData.rarity then
            local r, g, b = ClickMorphCustomWardrobe.GetRarityColor(assetData.rarity)
            if button.IconBorder then
                button.IconBorder:SetVertexColor(r, g, b)
                button.IconBorder:Show()
            end
        end
        
        -- Dados do asset
        button.assetData = assetData
        
        -- Tooltip
        button:SetScript("OnEnter", function(self)
            ClickMorphCustomWardrobe.ShowAssetTooltip(self, self.assetData)
        end)
        
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Clique
        button:SetScript("OnClick", function(self, mouseButton)
            ClickMorphCustomWardrobe.OnAssetButtonClick(self, mouseButton, self.assetData)
        end)
        
        return button
    end
    
    -- Função para popular grid
    gridContainer.PopulateGrid = function(self, assets)
        -- Limpar botões existentes
        for _, button in pairs(self.buttons) do
            button:Hide()
            button:SetParent(nil)
        end
        wipe(self.buttons)
        
        -- Criar novos botões
        for i, assetData in ipairs(assets) do
            local button = self:CreateAssetButton(i, assetData)
            table.insert(self.buttons, button)
        end
        
        -- Ajustar altura do scroll content
        local totalRows = math.ceil(#assets / self.buttonsPerRow)
        local contentHeight = totalRows * self.buttonSpacing + 20
        self.scrollContent:SetHeight(math.max(contentHeight, self.scrollFrame:GetHeight()))
        
        WardrobeDebugPrint("Grid populated with", #assets, "assets")
    end
    
    WardrobeDebugPrint("Asset grid component created")
    return gridContainer
end

-- =============================================================================
-- COMPONENTES REUTILIZÁVEIS - FILTER SYSTEM  
-- =============================================================================

-- Criar sistema de filtros
function ClickMorphCustomWardrobe.CreateFilterSystem(parent, position, size)
    WardrobeDebugPrint("Creating filter system component")
    
    size = size or {width = 200, height = 424}
    
    -- Container dos filtros
    local filterContainer = CreateFrame("Frame", nil, parent)
    filterContainer:SetSize(size.width, size.height)
    if position then
        filterContainer:SetPoint(position.point or "TOPLEFT", parent, position.relativeTo or "TOPLEFT", position.x or 20, position.y or -20)
    else
        filterContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -20)
    end
    
    -- Background
    local filterBg = filterContainer:CreateTexture(nil, "BACKGROUND")
    filterBg:SetAllPoints()
    filterBg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
    
    -- Borda
    local filterBorder = CreateFrame("Frame", nil, filterContainer, "InsetFrameTemplate")
    filterBorder:SetAllPoints()
    
    -- Título dos filtros
    local filterTitle = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterTitle:SetPoint("TOP", filterContainer, "TOP", 0, -10)
    filterTitle:SetText("Filters")
    
    -- Caixa de busca
    local searchFrame = CreateFrame("Frame", nil, filterContainer)
    searchFrame:SetSize(size.width - 20, 30)
    searchFrame:SetPoint("TOPLEFT", filterContainer, "TOPLEFT", 10, -30)
    
    local searchLabel = searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 0, -5)
    searchLabel:SetText("Search:")
    
    local searchBox = CreateFrame("EditBox", nil, searchFrame, "InputBoxTemplate")
    searchBox:SetSize(size.width - 30, 20)
    searchBox:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 5, -15)
    searchBox:SetAutoFocus(false)
    
    -- Checkboxes para filtros
    local filtersFrame = CreateFrame("Frame", nil, filterContainer)
    filtersFrame:SetSize(size.width - 20, size.height - 100)
    filtersFrame:SetPoint("TOPLEFT", filterContainer, "TOPLEFT", 10, -70)
    
    -- API do filter system
    filterContainer.searchBox = searchBox
    filterContainer.filtersFrame = filtersFrame
    filterContainer.checkboxes = {}
    filterContainer.currentFilters = {}
    filterContainer.onFilterChanged = nil -- Callback function
    
    -- Função para criar checkbox
    filterContainer.CreateCheckbox = function(self, text, key, defaultValue)
        local checkbox = CreateFrame("CheckButton", nil, self.filtersFrame, "ChatConfigCheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox.Text:SetText(text)
        checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkbox:SetChecked(defaultValue or false)
        
        checkbox:SetScript("OnClick", function()
            self.currentFilters[key] = checkbox:GetChecked()
            if self.onFilterChanged then
                self.onFilterChanged(self.currentFilters, self.searchBox:GetText())
            end
        end)
        
        self.checkboxes[key] = checkbox
        return checkbox
    end
    
    -- Função para posicionar checkboxes
    filterContainer.ArrangeCheckboxes = function(self)
        local yOffset = 0
        for _, checkbox in pairs(self.checkboxes) do
            checkbox:SetPoint("TOPLEFT", self.filtersFrame, "TOPLEFT", 0, yOffset)
            yOffset = yOffset - 25
        end
    end
    
    -- Script da search box
    searchBox:SetScript("OnTextChanged", function(self)
        if filterContainer.onFilterChanged then
            filterContainer.onFilterChanged(filterContainer.currentFilters, self:GetText())
        end
    end)
    
    WardrobeDebugPrint("Filter system component created")
    return filterContainer
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Obter cor por raridade
function ClickMorphCustomWardrobe.GetRarityColor(rarity)
    local colors = {
        [1] = {0.6, 0.6, 0.6},      -- Poor (Grey)
        [2] = {1.0, 1.0, 1.0},      -- Common (White)
        [3] = {0.12, 1.0, 0.0},     -- Uncommon (Green)
        [4] = {0.0, 0.44, 0.87},    -- Rare (Blue)
        [5] = {0.64, 0.21, 0.93},   -- Epic (Purple)
        [6] = {1.0, 0.5, 0.0}       -- Legendary (Orange)
    }
    return unpack(colors[rarity] or colors[2])
end

-- Mostrar tooltip de asset
function ClickMorphCustomWardrobe.ShowAssetTooltip(button, assetData)
    if not ClickMorphCustomWardrobe.wardrobeSystem.settings.showTooltips then
        return
    end
    
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(assetData.name or "Unknown", 1, 1, 1)
    
    if assetData.description then
        GameTooltip:AddLine(assetData.description, 0.8, 0.8, 0.8, true)
    end
    
    GameTooltip:AddLine(" ", 1, 1, 1)
    
    if assetData.type then
        GameTooltip:AddLine("Type: " .. assetData.type, 0.5, 0.8, 1)
    end
    
    if assetData.displayID then
        GameTooltip:AddLine("Display ID: " .. assetData.displayID, 0.5, 0.8, 1)
    end
    
    if assetData.source then
        GameTooltip:AddLine("Source: " .. assetData.source, 0.7, 0.7, 0.7)
    end
    
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Left-Click: Preview", 0, 1, 0)
    GameTooltip:AddLine("Right-Click: Apply", 1, 1, 0)
    
    GameTooltip:Show()
end

-- Clique em botão de asset
function ClickMorphCustomWardrobe.OnAssetButtonClick(button, mouseButton, assetData)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    if mouseButton == "LeftButton" then
        -- Preview
        if system.components.preview3D then
            system.components.preview3D:UpdatePreview(assetData)
        end
        
    elseif mouseButton == "RightButton" then
        -- Apply direto
        ClickMorphCustomWardrobe.ApplyPreviewData(assetData)
    end
end

-- Aplicar dados do preview
function ClickMorphCustomWardrobe.ApplyPreviewData(data)
    if not data then return end
    
    WardrobeDebugPrint("Applying preview data:", data.name)
    
    local command = ""
    
    if data.type == "creature" and data.displayID then
        command = ".morph " .. data.displayID
    elseif data.type == "item" and data.itemID then
        command = ".morphitem " .. (data.slot or 0) .. " " .. data.itemID
        if data.modID then
            command = command .. " " .. data.modID
        end
    elseif data.command then
        command = data.command
    end
    
    if command ~= "" then
        SendChatMessage(command, "GUILD")
        print("|cff00ffffWardrobe:|r Applied " .. (data.name or "morph"))
        
        -- Auto-save se disponível
        if ClickMorphSaveHub and ClickMorphSaveHub.API then
            ClickMorphSaveHub.API.AutoSave(data)
        end
    end
end

-- =============================================================================
-- INTERFACE CONTROL
-- =============================================================================

-- Mostrar wardrobe
function ClickMorphCustomWardrobe.Show()
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    if not system.mainFrame then
        ClickMorphCustomWardrobe.CreateMainInterface()
    end
    
    system.mainFrame:Show()
    system.isVisible = true
    
    WardrobeDebugPrint("Wardrobe shown")
end

-- Esconder wardrobe
function ClickMorphCustomWardrobe.Hide()
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    if system.mainFrame then
        system.mainFrame:Hide()
        system.isVisible = false
    end
    
    WardrobeDebugPrint("Wardrobe hidden")
end

-- Toggle wardrobe
function ClickMorphCustomWardrobe.Toggle()
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    if system.isVisible then
        ClickMorphCustomWardrobe.Hide()
    else
        ClickMorphCustomWardrobe.Show()
    end
end

-- Comandos do wardrobe
SLASH_CLICKMORPH_WARDROBE1 = "/cm"
SlashCmdList.CLICKMORPH_WARDROBE = function(arg)
    local command = string.lower(arg or "")
    
    if command == "" or command == "show" then
        ClickMorphCustomWardrobe.Show()
        
    elseif command == "hide" then
        ClickMorphCustomWardrobe.Hide()
        
    elseif command == "toggle" then
        ClickMorphCustomWardrobe.Toggle()
        
    elseif command == "savehub" then
        ClickMorphCustomWardrobe.Show()
        ClickMorphCustomWardrobe.SelectTab("saveHub")
        
    elseif command == "catalogue" then
        ClickMorphCustomWardrobe.Show()
        ClickMorphCustomWardrobe.SelectTab("morphCatalogue")
        
    elseif command == "mounts" then
        ClickMorphCustomWardrobe.Show()
        ClickMorphCustomWardrobe.SelectTab("mountShop")
        
    elseif command == "debug" then
        ClickMorphCustomWardrobe.wardrobeSystem.settings.debugMode = not ClickMorphCustomWardrobe.wardrobeSystem.settings.debugMode
        print("|cff00ffffWardrobe:|r Debug mode", ClickMorphCustomWardrobe.wardrobeSystem.settings.debugMode and "ON" or "OFF")
        
    else
        print("|cff00ffffClickMorph Wardrobe Commands:|r")
        print("/cm - Open main wardrobe interface")
        print("/cm savehub - Open Save Hub tab")
        print("/cm catalogue - Open Morph Catalogue tab")
        print("/cm mounts - Open Mount Shop tab")
        print("/cm debug - Toggle debug mode")
        print("")
        print("|cffccccccCustom Wardrobe System with 3D Preview|r")
        print("|cffccccccSeparate from Blizzard UI - Zero conflicts!|r")
    end
end

-- =============================================================================
-- TAB CONTENT PLACEHOLDERS - To be implemented by specific modules
-- =============================================================================

-- Save Hub content (será implementado pelo SaveHubPreview.lua)
function ClickMorphCustomWardrobe.CreateSaveHubContent(parent)
    WardrobeDebugPrint("Creating Save Hub content")
    
    -- Placeholder - será substituído pela implementação real
    local placeholder = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeholder:SetPoint("CENTER", parent, "CENTER", 0, 0)
    placeholder:SetText("Save Hub - Coming Soon!")
    placeholder:SetTextColor(1, 1, 0)
    
    -- TODO: Integrar com SaveHubPreview.lua existente
    return placeholder
end

-- Morph Catalogue content (será implementado por MorphCatalogue.lua)
function ClickMorphCustomWardrobe.CreateMorphCatalogueContent(parent)
    WardrobeDebugPrint("Creating Morph Catalogue content")
    
    -- Placeholder - será substituído pela implementação real
    local placeholder = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeholder:SetPoint("CENTER", parent, "CENTER", 0, 0)
    placeholder:SetText("Morph Catalogue - Coming Soon!")
    placeholder:SetTextColor(1, 1, 0)
    
    -- TODO: Implementar sistema completo de catalogação
    return placeholder
end

-- Mount Shop content (será implementado por MountShop.lua)
function ClickMorphCustomWardrobe.CreateMountShopContent(parent)
    WardrobeDebugPrint("Creating Mount Shop content")
    
    -- Placeholder - será substituído pela implementação real
    local placeholder = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeholder:SetPoint("CENTER", parent, "CENTER", 0, 0)
    placeholder:SetText("Mount Shop - Coming Soon!")
    placeholder:SetTextColor(1, 1, 0)
    
    -- TODO: Implementar sistema de mount customization
    return placeholder
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- API pública para outros módulos
ClickMorphCustomWardrobe.API = {
    -- Interface control
    Show = ClickMorphCustomWardrobe.Show,
    Hide = ClickMorphCustomWardrobe.Hide,
    Toggle = ClickMorphCustomWardrobe.Toggle,
    SelectTab = ClickMorphCustomWardrobe.SelectTab,
    
    -- Componentes reutilizáveis
    CreatePreview3D = ClickMorphCustomWardrobe.CreatePreview3D,
    CreateAssetGrid = ClickMorphCustomWardrobe.CreateAssetGrid,
    CreateFilterSystem = ClickMorphCustomWardrobe.CreateFilterSystem,
    
    -- Utilities
    GetRarityColor = ClickMorphCustomWardrobe.GetRarityColor,
    ApplyPreviewData = ClickMorphCustomWardrobe.ApplyPreviewData,
    
    -- Registration para tab content
    RegisterTabContent = function(tabKey, contentFunction)
        if tabKey == "saveHub" then
            ClickMorphCustomWardrobe.CreateSaveHubContent = contentFunction
        elseif tabKey == "morphCatalogue" then
            ClickMorphCustomWardrobe.CreateMorphCatalogueContent = contentFunction
        elseif tabKey == "mountShop" then
            ClickMorphCustomWardrobe.CreateMountShopContent = contentFunction
        end
        WardrobeDebugPrint("Registered content for tab:", tabKey)
    end
}

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Inicialização
local function Initialize()
    WardrobeDebugPrint("Initializing Custom Wardrobe system...")
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            WardrobeDebugPrint("ClickMorph loaded, Custom Wardrobe ready")
            
        elseif event == "PLAYER_LOGIN" then
            C_Timer.After(2, function()
                WardrobeDebugPrint("Custom Wardrobe system ready for use")
            end)
        end
    end)
end

Initialize()

print("|cff00ffffClickMorph Custom Wardrobe Framework|r loaded!")
print("Use |cffffcc00/cm|r to open the custom wardrobe interface")
WardrobeDebugPrint("CustomWardrobe.lua loaded successfully")