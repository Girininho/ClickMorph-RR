-- SaveHubPreview.lua
-- SaveHub com sistema de preview 3D dos saves

ClickMorphSaveHubPreview = {}

-- Sistema de preview integrado ao SaveHub
ClickMorphSaveHubPreview.previewSystem = {
    mainFrame = nil,
    previewModel = nil,
    savesList = nil,
    selectedSave = nil,
    isVisible = false,
    position = {x = 0, y = 0},
    settings = {
        autoPreview = true,
        showTooltips = true,
        frameSize = {width = 600, height = 400},
        modelSize = {width = 250, height = 300},
        debugMode = false
    }
}

-- Debug print
local function PreviewDebugPrint(...)
    if ClickMorphSaveHubPreview.previewSystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cffff3366Preview:|r", message)
    end
end

-- Criar modelo 3D para preview
function ClickMorphSaveHubPreview.CreatePreviewModel(parent)
    local system = ClickMorphSaveHubPreview.previewSystem
    
    PreviewDebugPrint("Creating 3D preview model")
    
    -- Frame container do modelo
    local modelContainer = CreateFrame("Frame", nil, parent)
    modelContainer:SetSize(system.settings.modelSize.width, system.settings.modelSize.height)
    modelContainer:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    
    -- Background do modelo
    local modelBg = modelContainer:CreateTexture(nil, "BACKGROUND")
    modelBg:SetAllPoints()
    modelBg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
    
    -- Borda do modelo
    local modelBorder = CreateFrame("Frame", nil, modelContainer, "DialogBorderTemplate")
    modelBorder:SetAllPoints()
    
    -- Modelo 3D
    local modelFrame = CreateFrame("PlayerModel", nil, modelContainer)
    modelFrame:SetSize(system.settings.modelSize.width - 20, system.settings.modelSize.height - 40)
    modelFrame:SetPoint("CENTER", modelContainer, "CENTER", 0, -10)
    
    -- Configurar modelo
    modelFrame:SetUnit("player")
    modelFrame:SetFacing(0.5)
    modelFrame:SetModelScale(1.0)
    
    -- Controles do modelo
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    
    -- Rotação com mouse drag
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
    
    -- Zoom com mouse wheel
    modelFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScale = self:GetModelScale()
        local newScale = currentScale + (delta * 0.1)
        newScale = math.max(0.3, math.min(2.5, newScale))
        self:SetModelScale(newScale)
        PreviewDebugPrint("Model scale:", newScale)
    end)
    
    -- Labels informativos
    local titleLabel = modelContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", modelContainer, "TOP", 0, -5)
    titleLabel:SetText("Save Preview")
    titleLabel:SetTextColor(1, 1, 1)
    
    local instructionLabel = modelContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructionLabel:SetPoint("BOTTOM", modelContainer, "BOTTOM", 0, 5)
    instructionLabel:SetText("Drag: Rotate | Wheel: Zoom")
    instructionLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Botões de controle do modelo
    local controlFrame = CreateFrame("Frame", nil, modelContainer)
    controlFrame:SetSize(200, 25)
    controlFrame:SetPoint("BOTTOM", modelContainer, "BOTTOM", 0, 30)
    
    -- Botão Reset View
    local resetViewBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    resetViewBtn:SetSize(60, 20)
    resetViewBtn:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
    resetViewBtn:SetText("Reset")
    resetViewBtn:SetScript("OnClick", function()
        modelFrame:SetFacing(0.5)
        modelFrame:SetModelScale(1.0)
        PreviewDebugPrint("Model view reset")
    end)
    
    -- Botão Apply Save
    local applyBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(80, 20)
    applyBtn:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
    applyBtn:SetText("Apply Save")
    applyBtn:SetScript("OnClick", function()
        if system.selectedSave then
            ClickMorphSaveHub.LoadSave(system.selectedSave.name)
            print("|cffff3366Preview:|r Applied save: " .. system.selectedSave.name)
        end
    end)
    
    -- Salvar referências
    system.previewModel = modelFrame
    system.modelContainer = modelContainer
    system.titleLabel = titleLabel
    system.applyBtn = applyBtn
    
    PreviewDebugPrint("3D preview model created successfully")
    return modelFrame
end

-- Atualizar preview com dados do save
function ClickMorphSaveHubPreview.UpdatePreview(saveData)
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if not system.previewModel or not saveData then
        PreviewDebugPrint("Cannot update preview: missing model or save data")
        return
    end
    
    PreviewDebugPrint("Updating preview for save:", saveData.name)
    
    -- Atualizar título
    if system.titleLabel then
        system.titleLabel:SetText(saveData.name)
    end
    
    -- Tentar aplicar morph no modelo de preview
    local morph = saveData.morph
    if morph and morph.displayID then
        if morph.type == "creature" then
            -- Preview de creature morph
            system.previewModel:SetDisplayInfo(morph.displayID)
            PreviewDebugPrint("Applied creature displayID:", morph.displayID)
            
        elseif morph.type == "item" and morph.slot then
            -- Preview de item morph é mais complexo
            -- Por enquanto, mostrar player normal com equipment
            system.previewModel:SetUnit("player")
            
            -- TODO: Tentar aplicar item visual se possível
            PreviewDebugPrint("Item morph preview - showing player with equipment")
            
        else
            -- Fallback: mostrar player normal
            system.previewModel:SetUnit("player")
            PreviewDebugPrint("Fallback: showing player model")
        end
    end
    
    -- Aplicar transmog se disponível
    if saveData.transmog then
        -- TODO: Implementar preview de transmog
        -- Isso é mais complexo e requer APIs específicas
        PreviewDebugPrint("Transmog preview not yet implemented")
    end
    
    -- Marcar save como selecionado
    system.selectedSave = saveData
end

-- Criar lista de saves com preview
function ClickMorphSaveHubPreview.CreateSavesList(parent)
    local system = ClickMorphSaveHubPreview.previewSystem
    
    PreviewDebugPrint("Creating saves list")
    
    -- Frame da lista
    local listContainer = CreateFrame("Frame", nil, parent)
    listContainer:SetSize(320, 350)
    listContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    
    -- Background da lista
    local listBg = listContainer:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints()
    listBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Borda da lista
    local listBorder = CreateFrame("Frame", nil, listContainer, "DialogBorderTemplate")
    listBorder:SetAllPoints()
    
    -- Título da lista
    local listTitle = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    listTitle:SetPoint("TOP", listContainer, "TOP", 0, -5)
    listTitle:SetText("Saved Morphs")
    
    -- ScrollFrame para a lista
    local scrollFrame = CreateFrame("ScrollFrame", nil, listContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(280, 280)
    scrollFrame:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 10, -30)
    
    -- Content frame do scroll
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(280, 1) -- Height será ajustada dinamicamente
    scrollFrame:SetScrollChild(scrollContent)
    
    -- Botões de controle da lista
    local controlFrame = CreateFrame("Frame", nil, listContainer)
    controlFrame:SetSize(280, 25)
    controlFrame:SetPoint("BOTTOM", listContainer, "BOTTOM", 0, 10)
    
    -- Botão Refresh
    local refreshBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(60, 20)
    refreshBtn:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        ClickMorphSaveHubPreview.RefreshSavesList()
    end)
    
    -- Botão Delete Selected
    local deleteBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(80, 20)
    deleteBtn:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        if system.selectedSave then
            ClickMorphSaveHub.DeleteSave(system.selectedSave.name)
            ClickMorphSaveHubPreview.RefreshSavesList()
            ClickMorphSaveHubPreview.ClearPreview()
        end
    end)
    
    -- Salvar referências
    system.savesList = {
        container = listContainer,
        scrollFrame = scrollFrame,
        scrollContent = scrollContent,
        buttons = {},
        refreshBtn = refreshBtn,
        deleteBtn = deleteBtn
    }
    
    PreviewDebugPrint("Saves list created successfully")
    return listContainer
end

-- Criar botão individual de save na lista
function ClickMorphSaveHubPreview.CreateSaveButton(parent, index, saveData)
    local system = ClickMorphSaveHubPreview.previewSystem
    
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(260, 40)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * 45)
    
    -- Background do botão
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    
    -- Highlight
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.3, 0.5, 0.8, 0.3)
    
    -- Ícone do save (baseado no tipo de morph)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(32, 32)
    button.icon:SetPoint("LEFT", button, "LEFT", 5, 0)
    
    -- Definir ícone baseado no tipo
    if saveData.morph.type == "creature" then
        button.icon:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_01")
    elseif saveData.morph.type == "item" then
        button.icon:SetTexture("Interface\\Icons\\INV_Chest_Plate06")
    else
        button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Nome do save
    button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.nameText:SetPoint("LEFT", button.icon, "RIGHT", 8, 5)
    button.nameText:SetText(saveData.name)
    button.nameText:SetJustifyH("LEFT")
    button.nameText:SetWidth(180)
    
    -- Info do save
    button.infoText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.infoText:SetPoint("LEFT", button.icon, "RIGHT", 8, -8)
    button.infoText:SetTextColor(0.7, 0.7, 0.7)
    button.infoText:SetJustifyH("LEFT")
    button.infoText:SetWidth(180)
    
    local infoText = string.format("%s %s | %s", 
        saveData.morph.type or "unknown",
        saveData.morph.displayID or "?",
        date("%m/%d %H:%M", saveData.timestamp)
    )
    button.infoText:SetText(infoText)
    
    -- Indicador de favorito
    if saveData.favorite then
        button.starIcon = button:CreateTexture(nil, "OVERLAY")
        button.starIcon:SetSize(16, 16)
        button.starIcon:SetPoint("TOPRIGHT", button, "TOPRIGHT", -5, -5)
        button.starIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    end
    
    -- Dados do save
    button.saveData = saveData
    
    -- Clique para selecionar e preview
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            -- Selecionar save e atualizar preview
            ClickMorphSaveHubPreview.SelectSave(self.saveData)
            
        elseif mouseButton == "RightButton" then
            -- Menu de contexto
            ClickMorphSaveHubPreview.ShowSaveContextMenu(self.saveData)
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        if system.settings.showTooltips then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.saveData.name, 1, 1, 1)
            GameTooltip:AddLine(self.saveData.description or "No description", 0.8, 0.8, 0.8, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Type: " .. (self.saveData.morph.type or "unknown"), 0.5, 0.8, 1)
            GameTooltip:AddLine("Display ID: " .. (self.saveData.morph.displayID or "?"), 0.5, 0.8, 1)
            GameTooltip:AddLine("Zone: " .. (self.saveData.zone or "Unknown"), 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Left-Click: Preview", 0, 1, 0)
            GameTooltip:AddLine("Right-Click: Options", 1, 1, 0)
            GameTooltip:Show()
        end
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return button
end

-- Selecionar save e atualizar preview
function ClickMorphSaveHubPreview.SelectSave(saveData)
    local system = ClickMorphSaveHubPreview.previewSystem
    
    PreviewDebugPrint("Selecting save:", saveData.name)
    
    -- Atualizar seleção visual nos botões
    for _, button in pairs(system.savesList.buttons) do
        if button.saveData == saveData then
            button.bg:SetColorTexture(0.3, 0.5, 0.8, 0.7) -- Azul selecionado
        else
            button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5) -- Cinza normal
        end
    end
    
    -- Atualizar preview
    ClickMorphSaveHubPreview.UpdatePreview(saveData)
    
    -- Auto-preview se habilitado
    if system.settings.autoPreview then
        -- Pode implementar preview automático aqui
    end
end

-- Menu de contexto para save
function ClickMorphSaveHubPreview.ShowSaveContextMenu(saveData)
    local menu = {
        {
            text = saveData.name,
            isTitle = true,
        },
        {
            text = "Load Save",
            func = function()
                ClickMorphSaveHub.LoadSave(saveData.name)
            end,
        },
        {
            text = "Toggle Favorite",
            func = function()
                ClickMorphSaveHub.ToggleFavorite(saveData.name)
                ClickMorphSaveHubPreview.RefreshSavesList()
            end,
        },
        {
            text = "Export Save",
            func = function()
                local exportString = ClickMorphSaveHub.ExportSave(saveData.name)
                if exportString then
                    print("|cffff3366Preview:|r Export string:")
                    print(exportString)
                end
            end,
        },
        {
            text = "Delete Save",
            func = function()
                ClickMorphSaveHub.DeleteSave(saveData.name)
                ClickMorphSaveHubPreview.RefreshSavesList()
                ClickMorphSaveHubPreview.ClearPreview()
            end,
        }
    }
    
    local contextMenu = CreateFrame("Frame", "SaveHubPreviewContextMenu", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, contextMenu, "cursor", 0, 0, "MENU")
end

-- Refresh da lista de saves
function ClickMorphSaveHubPreview.RefreshSavesList()
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if not system.savesList then return end
    
    PreviewDebugPrint("Refreshing saves list")
    
    -- Limpar botões existentes
    for _, button in pairs(system.savesList.buttons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(system.savesList.buttons)
    
    -- Obter saves do SaveHub
    local saves = {}
    if ClickMorphSaveHub and ClickMorphSaveHub.saveSystem.saves then
        for name, data in pairs(ClickMorphSaveHub.saveSystem.saves) do
            table.insert(saves, data)
        end
    end
    
    -- Ordenar por timestamp (mais recente primeiro)
    table.sort(saves, function(a, b) return a.timestamp > b.timestamp end)
    
    -- Criar botões para cada save
    for i, saveData in ipairs(saves) do
        local button = ClickMorphSaveHubPreview.CreateSaveButton(system.savesList.scrollContent, i, saveData)
        table.insert(system.savesList.buttons, button)
    end
    
    -- Ajustar altura do scroll content
    local contentHeight = #saves * 45
    system.savesList.scrollContent:SetHeight(math.max(contentHeight, 280))
    
    PreviewDebugPrint("Refreshed list with", #saves, "saves")
end

-- Limpar preview
function ClickMorphSaveHubPreview.ClearPreview()
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if system.previewModel then
        system.previewModel:SetUnit("player")
        system.previewModel:SetFacing(0.5)
        system.previewModel:SetModelScale(1.0)
    end
    
    if system.titleLabel then
        system.titleLabel:SetText("No Preview")
    end
    
    system.selectedSave = nil
    PreviewDebugPrint("Preview cleared")
end

-- Criar interface principal
function ClickMorphSaveHubPreview.CreateMainInterface()
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if system.mainFrame then
        PreviewDebugPrint("Main interface already exists")
        return system.mainFrame
    end
    
    PreviewDebugPrint("Creating main preview interface")
    
    -- Frame principal
    local mainFrame = CreateFrame("Frame", "ClickMorphSaveHubPreview", UIParent)
    mainFrame:SetSize(system.settings.frameSize.width, system.settings.frameSize.height)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", system.position.x, system.position.y)
    mainFrame:SetFrameStrata("HIGH")
    
    -- Background
    mainFrame.bg = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.bg:SetAllPoints()
    mainFrame.bg:SetColorTexture(0, 0, 0, 0.8)
    
    -- Borda
    local border = CreateFrame("Frame", nil, mainFrame, "DialogBorderTemplate")
    border:SetAllPoints()
    
    -- Título da janela
    local titleBar = CreateFrame("Frame", nil, mainFrame)
    titleBar:SetSize(system.settings.frameSize.width - 20, 30)
    titleBar:SetPoint("TOP", mainFrame, "TOP", 0, -5)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", titleBar, "CENTER")
    title:SetText("SaveHub Preview")
    
    -- Botão fechar
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function()
        ClickMorphSaveHubPreview.HideInterface()
    end)
    
    -- Tornar movível
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            mainFrame:StartMoving()
        end
    end)
    titleBar:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            mainFrame:StopMovingOrSizing()
            -- Salvar posição
            local point, _, _, x, y = mainFrame:GetPoint()
            system.position.x = x
            system.position.y = y
        end
    end)
    
    -- Criar componentes
    ClickMorphSaveHubPreview.CreateSavesList(mainFrame)
    ClickMorphSaveHubPreview.CreatePreviewModel(mainFrame)
    
    -- Salvar referência
    system.mainFrame = mainFrame
    
    -- Inicializar com dados
    ClickMorphSaveHubPreview.RefreshSavesList()
    
    PreviewDebugPrint("Main interface created successfully")
    return mainFrame
end

-- Mostrar/esconder interface
function ClickMorphSaveHubPreview.ShowInterface()
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if not system.mainFrame then
        ClickMorphSaveHubPreview.CreateMainInterface()
    end
    
    system.mainFrame:Show()
    system.isVisible = true
    
    -- Refresh dados ao mostrar
    ClickMorphSaveHubPreview.RefreshSavesList()
    
    PreviewDebugPrint("Interface shown")
end

function ClickMorphSaveHubPreview.HideInterface()
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if system.mainFrame then
        system.mainFrame:Hide()
        system.isVisible = false
    end
    
    PreviewDebugPrint("Interface hidden")
end

function ClickMorphSaveHubPreview.ToggleInterface()
    local system = ClickMorphSaveHubPreview.previewSystem
    
    if system.isVisible then
        ClickMorphSaveHubPreview.HideInterface()
    else
        ClickMorphSaveHubPreview.ShowInterface()
    end
end

-- Comandos do sistema de preview
SLASH_CLICKMORPH_PREVIEW1 = "/cmpreview"
SlashCmdList.CLICKMORPH_PREVIEW = function(arg)
    local command = string.lower(arg or "")
    
    if command == "show" or command == "" then
        ClickMorphSaveHubPreview.ShowInterface()
        
    elseif command == "hide" then
        ClickMorphSaveHubPreview.HideInterface()
        
    elseif command == "toggle" then
        ClickMorphSaveHubPreview.ToggleInterface()
        
    elseif command == "refresh" then
        ClickMorphSaveHubPreview.RefreshSavesList()
        print("|cffff3366Preview:|r Saves list refreshed")
        
    elseif command == "debug" then
        ClickMorphSaveHubPreview.previewSystem.settings.debugMode = not ClickMorphSaveHubPreview.previewSystem.settings.debugMode
        print("|cffff3366Preview:|r Debug mode", ClickMorphSaveHubPreview.previewSystem.settings.debugMode and "ON" or "OFF")
        
    else
        print("|cffff3366SaveHub Preview Commands:|r")
        print("/cmpreview show - Show preview interface")
        print("/cmpreview hide - Hide preview interface")
        print("/cmpreview toggle - Toggle preview interface")
        print("/cmpreview refresh - Refresh saves list")
        print("/cmpreview debug - Toggle debug mode")
        print("")
        print("|cffccccccInterface Features:|r")
        print("• 3D preview of saved morphs")
        print("• Click saves to preview")
        print("• Right-click for save options")
        print("• Drag model to rotate, scroll to zoom")
    end
end

-- Integração com SaveHub original
if ClickMorphSaveHub then
    -- Hook para auto-refresh quando saves mudarem
    local originalSave = ClickMorphSaveHub.SaveCurrentMorph
    ClickMorphSaveHub.SaveCurrentMorph = function(...)
        local result = originalSave(...)
        -- Auto-refresh preview se estiver visível
        if ClickMorphSaveHubPreview.previewSystem.isVisible then
            ClickMorphSaveHubPreview.RefreshSavesList()
        end
        return result
    end
    
    local originalDelete = ClickMorphSaveHub.DeleteSave
    ClickMorphSaveHub.DeleteSave = function(...)
        local result = originalDelete(...)
        -- Auto-refresh preview se estiver visível
        if ClickMorphSaveHubPreview.previewSystem.isVisible then
            ClickMorphSaveHubPreview.RefreshSavesList()
        end
        return result
    end
    
    PreviewDebugPrint("Integrated with SaveHub successfully")
end

-- Inicialização
local function InitializePreview()
    PreviewDebugPrint("Initializing SaveHub Preview system...")
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            PreviewDebugPrint("ClickMorph loaded")
            
        elseif event == "PLAYER_LOGIN" then
            C_Timer.After(2, function()
                PreviewDebugPrint("SaveHub Preview ready")
            end)
        end
    end)
end

InitializePreview()

print("|cffff3366ClickMorph SaveHub Preview|r loaded!")
print("Use |cffffcc00/cmpreview|r to open the 3D preview interface")
PreviewDebugPrint("SaveHubPreview.lua loaded successfully")