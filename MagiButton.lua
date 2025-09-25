-- ========================================
-- MagiButton.lua - UNIFIED VERSION
-- Sistema unificado do MagiButton - PREVINE DUPLICAÇÕES
-- ========================================

-- Prevenir carregamento duplo
if ClickMorphMagiButton and ClickMorphMagiButton.__initialized then 
    return 
end

ClickMorphMagiButton = {__initialized = true}

-- Sistema do MagiButton
ClickMorphMagiButton.buttonSystem = {
    button = nil,
    isVisible = true,
    position = {x = 0, y = -200}, -- Posição padrão longe do centro
    
    -- Estado temporário para o toggle
    temporaryState = {
        isTemporaryReset = false, -- se está em estado "reset temporário"
        savedMorph = nil, -- morph que estava antes do reset temporário
        autoRestoreTimer = nil, -- timer para auto-restore
        autoRestoreDelay = 300 -- 5 minutos em segundos
    },
    
    -- Configurações
    settings = {
        autoRestoreTimeout = true, -- auto-restore após timeout
        showTooltips = true,
        buttonSize = 36, -- Será atualizado dinamicamente baseado em ClickMorphMagiButtonSV.buttonSize
        debugMode = false
    }
}

-- Saved Variables
ClickMorphMagiButtonSV = ClickMorphMagiButtonSV or {
    position = {x = 0, y = -200},
    settings = {
        autoRestoreTimeout = true,
        showTooltips = true,
        debugMode = false
    },
    currentIcon = 1, -- Índice do ícone atual
    buttonSize = 2 -- 1=Pequeno (30), 2=Médio (36), 3=Grande (42)
}

-- Lista de ícones disponíveis
local iconOptions = {
    {texture = "Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy", name = "Swiss Army Tool"},
    {texture = "Interface\\Icons\\INV_Misc_Gear_01", name = "Gear"},  
    {texture = "Interface\\Icons\\INV_Misc_Enggizmos_19", name = "Engineering Tool"},
    {texture = "Interface\\Icons\\Spell_Magic_FeatherFall", name = "Magic Feather"},
    {texture = "Interface\\Icons\\INV_Misc_Rune_01", name = "Magic Rune"}
}

-- Tamanhos disponíveis
local sizeOptions = {
    {size = 30, name = "Small"},
    {size = 36, name = "Medium"},
    {size = 42, name = "Large"}
}

-- Debug print
local function MagiDebugPrint(...)
    if ClickMorphMagiButton.buttonSystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff9933ffMagiButton:|r", message)
    end
end

-- Debug detalhado do botão
function ClickMorphMagiButton.DebugButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    if not system.button then
        print("|cff9933ffMagiButton Debug:|r Button not created!")
        return
    end
    
    local button = system.button
    local icon = button.icon
    local backdrop = button.backdrop
    
    print("|cff9933ff=== MAGI BUTTON DEBUG ===|r")
    
    -- Button info
    print("BUTTON:")
    print("  Size:", button:GetWidth(), "x", button:GetHeight())
    print("  Position:", button:GetLeft(), button:GetBottom(), "to", button:GetRight(), button:GetTop())
    print("  Center:", (button:GetLeft() + button:GetRight())/2, (button:GetBottom() + button:GetTop())/2)
    print("  Frame Level:", button:GetFrameLevel())
    print("  Frame Strata:", button:GetFrameStrata())
    
    -- Icon info
    if icon then
        print("ICON:")
        print("  Size:", icon:GetWidth(), "x", icon:GetHeight())
        print("  Position:", icon:GetLeft(), icon:GetBottom(), "to", icon:GetRight(), icon:GetTop())
        print("  Center:", (icon:GetLeft() + icon:GetRight())/2, (icon:GetBottom() + icon:GetTop())/2)
        print("  Draw Layer:", icon:GetDrawLayer())
        print("  Alpha:", icon:GetAlpha())
        print("  Vertex Color:", icon:GetVertexColor())
        local texCoords = {icon:GetTexCoord()}
        print("  TexCoord:", unpack(texCoords))
        print("  Texture:", icon:GetTexture())
    else
        print("ICON: Not found!")
    end
    
    -- Backdrop info
    if backdrop then
        print("BACKDROP:")
        print("  Size:", backdrop:GetWidth(), "x", backdrop:GetHeight())
        print("  Position:", backdrop:GetLeft(), backdrop:GetBottom(), "to", backdrop:GetRight(), backdrop:GetTop())
        print("  Center:", (backdrop:GetLeft() + backdrop:GetRight())/2, (backdrop:GetBottom() + backdrop:GetTop())/2)
        print("  Draw Layer:", backdrop:GetDrawLayer())
        print("  Alpha:", backdrop:GetAlpha())
        local r, g, b, a = backdrop:GetVertexColor()
        print("  Color:", r, g, b, a)
    else
        print("BACKDROP: Not found!")
    end
    
    -- Settings info
    print("SETTINGS:")
    print("  buttonSize setting:", system.settings.buttonSize)
    print("  Saved size index:", ClickMorphMagiButtonSV.buttonSize)
    print("  Current size option:", sizeOptions[ClickMorphMagiButtonSV.buttonSize or 2].name)
    
    -- Check overlaps
    if icon and backdrop then
        local iconCenterX = (icon:GetLeft() + icon:GetRight())/2
        local iconCenterY = (icon:GetBottom() + icon:GetTop())/2
        local backdropCenterX = (backdrop:GetLeft() + backdrop:GetRight())/2
        local backdropCenterY = (backdrop:GetBottom() + backdrop:GetTop())/2
        
        print("ALIGNMENT:")
        print("  Icon center:", iconCenterX, iconCenterY)
        print("  Backdrop center:", backdropCenterX, backdropCenterY)
        print("  Offset:", iconCenterX - backdropCenterX, iconCenterY - backdropCenterY)
        
        if math.abs(iconCenterX - backdropCenterX) > 1 or math.abs(iconCenterY - backdropCenterY) > 1 then
            print("  WARNING: Not centered!")
        else
            print("  OK: Centered")
        end
    end
end

-- =============================================================================
-- LIMPEZA DE BOTÕES ANTIGOS
-- =============================================================================

-- IMPORTANTE: Destruir qualquer botão antigo que possa existir
local function DestroyOldButtons()
    -- Destruir botão antigo do Commands.lua
    local oldButton = _G["ClickMorphMagicResetButton"] or _G["magicResetButton"]
    if oldButton then
        oldButton:Hide()
        oldButton:SetParent(nil)
        oldButton = nil
        MagiDebugPrint("Destroyed old Magic Reset Button")
    end
    
    -- Destruir implementações antigas do MagiButton
    local oldMagiButton = _G["ClickMorphMagiButton_Old"] or _G["ClickMorphMagiButtonFrame"]
    if oldMagiButton then
        oldMagiButton:Hide()
        oldMagiButton:SetParent(nil)
        oldMagiButton = nil
        MagiDebugPrint("Destroyed old MagiButton implementation")
    end
    
    -- Limpar variáveis globais antigas
    _G["magicResetButton"] = nil
    _G["ClickMorphMagicResetButton"] = nil
    _G["ClickMorphMagiButtonFrame"] = nil
    
    MagiDebugPrint("Button cleanup completed")
end

-- =============================================================================
-- CORE FUNCTIONS
-- =============================================================================

-- Obter morph atual do SaveHub
function ClickMorphMagiButton.GetCurrentSavedMorph()
    -- Método 1: Tentar SaveHub primeiro
    if ClickMorphSaveHub and ClickMorphSaveHub.saveSystem then
        local session = ClickMorphSaveHub.saveSystem.session
        local currentMorph = session.lastAppliedMorph or session.currentMorph
        if currentMorph then
            MagiDebugPrint("Found morph via SaveHub:", currentMorph.name or currentMorph.id)
            return currentMorph
        end
    end
    
    -- Método 2: Verificar IMorphInfo se disponível
    if IMorphInfo then
        local hasActiveMorph = false
        local morphData = {name = "Active Morph", id = "unknown"}
        
        -- Verificar se há morph ativo através de qualquer campo do IMorphInfo
        if IMorphInfo.model and IMorphInfo.model ~= nil then
            hasActiveMorph = true
            morphData.id = IMorphInfo.model
            morphData.name = "Model " .. IMorphInfo.model
        elseif IMorphInfo.race and IMorphInfo.race ~= nil then
            hasActiveMorph = true
            morphData.id = IMorphInfo.race
            morphData.name = "Race " .. IMorphInfo.race
        elseif IMorphInfo.items and next(IMorphInfo.items) then
            hasActiveMorph = true
            morphData.name = "Item Morph"
        elseif IMorphInfo.itemset and IMorphInfo.itemset ~= nil then
            hasActiveMorph = true
            morphData.id = IMorphInfo.itemset
            morphData.name = "ItemSet " .. IMorphInfo.itemset
        elseif IMorphInfo.transmog and IMorphInfo.transmog ~= nil then
            hasActiveMorph = true
            morphData.id = IMorphInfo.transmog
            morphData.name = "Transmog " .. IMorphInfo.transmog
        end
        
        if hasActiveMorph then
            MagiDebugPrint("Found morph via IMorphInfo:", morphData.name)
            return morphData
        end
    end
    
    MagiDebugPrint("No active morph detected")
    return nil
end

-- Salvar morph atual temporariamente
function ClickMorphMagiButton.SaveCurrentMorphTemporary()
    local currentMorph = ClickMorphMagiButton.GetCurrentSavedMorph()
    
    if currentMorph then
        ClickMorphMagiButton.buttonSystem.temporaryState.savedMorph = currentMorph
        MagiDebugPrint("Saved morph temporarily:", currentMorph.name or "Unnamed")
        return true
    end
    
    MagiDebugPrint("No current morph to save")
    return false
end

-- Aplicar reset temporário
function ClickMorphMagiButton.ApplyTemporaryReset()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    -- Salvar morph atual
    if not ClickMorphMagiButton.SaveCurrentMorphTemporary() then
        return false
    end
    
    -- CORRIGIDO: Aplicar reset usando método correto
    if ResetIds then
        ResetIds() -- Função direta do iMorph
    else
        -- Fallback: simular digitação no chat editbox
        local editBox = ChatEdit_ChooseBoxForSend()
        if editBox then
            editBox:SetText(".reset")
            ChatEdit_SendText(editBox, 1)
        end
    end
    
    -- Marcar estado temporário
    tempState.isTemporaryReset = true
    
    -- Iniciar timer de auto-restore se configurado
    if ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout then
        ClickMorphMagiButton.StartAutoRestoreTimer()
    end
    
    -- Atualizar aparência do botão
    ClickMorphMagiButton.UpdateButtonAppearance()
    
    MagiDebugPrint("Applied temporary reset")
    return true
end

-- Restaurar morph temporário
function ClickMorphMagiButton.RestoreTemporaryMorph()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    if not tempState.isTemporaryReset or not tempState.savedMorph then
        MagiDebugPrint("No temporary morph to restore")
        return false
    end
    
    -- Restaurar através do SaveHub se disponível
    if ClickMorphSaveHub and ClickMorphSaveHub.API then
        ClickMorphSaveHub.API.ApplyMorph(tempState.savedMorph)
    end
    
    -- Limpar estado temporário
    tempState.isTemporaryReset = false
    ClickMorphMagiButton.CancelAutoRestoreTimer()
    
    -- Atualizar aparência do botão
    ClickMorphMagiButton.UpdateButtonAppearance()
    
    print("|cff9933ffMagiButton:|r Morph restored!")
    MagiDebugPrint("Restored temporary morph:", tempState.savedMorph.name or "Unnamed")
    
    tempState.savedMorph = nil
    return true
end

-- Cancelar reset temporário
function ClickMorphMagiButton.CancelTemporaryReset()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    tempState.isTemporaryReset = false
    tempState.savedMorph = nil
    ClickMorphMagiButton.CancelAutoRestoreTimer()
    ClickMorphMagiButton.UpdateButtonAppearance()
    
    print("|cff9933ffMagiButton:|r Temporary reset canceled!")
    MagiDebugPrint("Temporary reset canceled")
end

-- =============================================================================
-- TIMER FUNCTIONS
-- =============================================================================

-- Iniciar timer de auto-restore
function ClickMorphMagiButton.StartAutoRestoreTimer()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    ClickMorphMagiButton.CancelAutoRestoreTimer() -- Cancelar timer existente
    
    tempState.autoRestoreTimer = C_Timer.NewTimer(tempState.autoRestoreDelay, function()
        MagiDebugPrint("Auto-restore timer expired, restoring morph")
        ClickMorphMagiButton.RestoreTemporaryMorph()
    end)
    
    MagiDebugPrint("Auto-restore timer started:", tempState.autoRestoreDelay, "seconds")
end

-- Cancelar timer de auto-restore
function ClickMorphMagiButton.CancelAutoRestoreTimer()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    if tempState.autoRestoreTimer then
        tempState.autoRestoreTimer:Cancel()
        tempState.autoRestoreTimer = nil
        MagiDebugPrint("Auto-restore timer canceled")
    end
end

-- =============================================================================
-- BUTTON CREATION & UI
-- =============================================================================

-- Carregar posição salva
function ClickMorphMagiButton.LoadSavedSettings()
    if ClickMorphMagiButtonSV then
        ClickMorphMagiButton.buttonSystem.position = ClickMorphMagiButtonSV.position or {x = 0, y = -200}
        
        -- Carregar settings
        local savedSettings = ClickMorphMagiButtonSV.settings or {}
        for key, value in pairs(savedSettings) do
            if ClickMorphMagiButton.buttonSystem.settings[key] ~= nil then
                ClickMorphMagiButton.buttonSystem.settings[key] = value
            end
        end
        
        -- Carregar ícone atual
        ClickMorphMagiButtonSV.currentIcon = ClickMorphMagiButtonSV.currentIcon or 1
        
        -- Carregar tamanho do botão
        ClickMorphMagiButtonSV.buttonSize = ClickMorphMagiButtonSV.buttonSize or 2
        local sizeData = sizeOptions[ClickMorphMagiButtonSV.buttonSize] or sizeOptions[2]
        ClickMorphMagiButton.buttonSystem.settings.buttonSize = sizeData.size
    end
end

-- Trocar tamanho do botão
function ClickMorphMagiButton.CycleSize()
    local system = ClickMorphMagiButton.buttonSystem
    
    if not system.button then
        print("|cff9933ffMagiButton:|r Button not created yet!")
        return
    end
    
    -- Próximo tamanho na lista
    ClickMorphMagiButtonSV.buttonSize = (ClickMorphMagiButtonSV.buttonSize % #sizeOptions) + 1
    local sizeData = sizeOptions[ClickMorphMagiButtonSV.buttonSize]
    
    -- Atualizar tamanho do botão
    system.settings.buttonSize = sizeData.size
    system.button:SetSize(sizeData.size, sizeData.size)
    
    -- Reajustar ícone
    system.button.icon:SetSize(sizeData.size - 10, sizeData.size - 10)
    
    print("|cff9933ffMagiButton:|r Size changed to: " .. sizeData.name .. " (" .. sizeData.size .. "px)")
end

-- Trocar ícone do botão
function ClickMorphMagiButton.CycleIcon()
    local system = ClickMorphMagiButton.buttonSystem
    
    if not system.button or not system.button.icon then
        print("|cff9933ffMagiButton:|r Button not created yet!")
        return
    end
    
    -- Próximo ícone na lista
    ClickMorphMagiButtonSV.currentIcon = (ClickMorphMagiButtonSV.currentIcon % #iconOptions) + 1
    local iconData = iconOptions[ClickMorphMagiButtonSV.currentIcon]
    
    -- Atualizar ícone com alinhamento correto
    system.button.icon:SetTexture(iconData.texture)
    system.button.icon:SetVertexColor(1, 1, 1, 1)
    system.button.icon:SetTexCoord(0, 1, 0, 1)
    
    print("|cff9933ffMagiButton:|r Icon changed to: " .. iconData.name)
end

-- Salvar configurações
function ClickMorphMagiButton.SaveSettings()
    if not ClickMorphMagiButtonSV then
        ClickMorphMagiButtonSV = {}
    end
    
    ClickMorphMagiButtonSV.position = ClickMorphMagiButton.buttonSystem.position
    ClickMorphMagiButtonSV.settings = ClickMorphMagiButton.buttonSystem.settings
end

-- Criar o botão físico - VERSÃO ÚNICA
function ClickMorphMagiButton.CreateButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    -- IMPORTANTE: Verificar se já existe
    if system.button then
        MagiDebugPrint("Button already exists, skipping creation")
        return system.button
    end
    
    -- Limpar botões antigos ANTES de criar o novo
    DestroyOldButtons()
    
    MagiDebugPrint("Creating NEW unified MagiButton")
    
    -- Carregar configurações salvas
    ClickMorphMagiButton.LoadSavedSettings()
    
    -- Criar frame do botão com nome único
    local button = CreateFrame("Button", "ClickMorphMagiButtonUnified", UIParent)
    button:SetSize(system.settings.buttonSize, system.settings.buttonSize)
    button:SetPoint("CENTER", UIParent, "CENTER", system.position.x, system.position.y)
    
    -- CORRIGIDO: Remover texturas de fundo sem passar nil
    -- Botão será apenas o ícone, sem fundo
    -- (Não chamar SetNormalTexture(nil) pois causa erro)
    
    -- Background circular opcional (sutil) - CORRIGIDO
    local backdrop = button:CreateTexture(nil, "BACKGROUND")
    backdrop:SetSize(system.settings.buttonSize, system.settings.buttonSize) -- Mesmo tamanho que o botão
    backdrop:SetPoint("CENTER", button, "CENTER")
    backdrop:SetColorTexture(0.1, 0.1, 0.1, 0.4) -- Fundo escuro sutil
    button.backdrop = backdrop
    
    -- Ícone - CORRIGIDO: Layer mais alta que o backdrop
    local icon = button:CreateTexture(nil, "OVERLAY") -- MUDOU: ARTWORK → OVERLAY
    icon:SetSize(system.settings.buttonSize - 6, system.settings.buttonSize - 6) -- Margem de 6px
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    
    -- Usar ícone salvo ou padrão (Swiss Army)
    local iconIndex = ClickMorphMagiButtonSV.currentIcon or 1
    local iconData = iconOptions[iconIndex] or iconOptions[1]
    icon:SetTexture(iconData.texture)
    
    -- CORRIGIDO: TexCoord e qualidade do ícone
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Cortar bordas uniformemente
    button.icon = icon
    
    -- Configurar interação
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("AnyUp")
    
    -- Scripts
    button:SetScript("OnClick", ClickMorphMagiButton.OnButtonClick)
    button:SetScript("OnEnter", ClickMorphMagiButton.OnButtonEnter)
    button:SetScript("OnLeave", ClickMorphMagiButton.OnButtonLeave)
    button:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Salvar nova posição
        local point, _, relativePoint, xOffset, yOffset = self:GetPoint()
        system.position.x = xOffset
        system.position.y = yOffset
        ClickMorphMagiButton.SaveSettings()
        MagiDebugPrint("Button moved to:", xOffset, yOffset)
    end)
    
    -- Salvar referência
    system.button = button
    
    -- Configurar visibilidade inicial
    if system.isVisible then
        button:Show()
    else
        button:Hide()
    end
    
    -- Atualizar aparência inicial
    ClickMorphMagiButton.UpdateButtonAppearance()
    
    MagiDebugPrint("Button created successfully at position:", system.position.x, system.position.y)
    return button
end

-- Click handler do botão
function ClickMorphMagiButton.OnButtonClick(self, mouseButton)
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    if mouseButton == "LeftButton" then
        -- Left-click: toggle entre morph e reset temporário
        if tempState.isTemporaryReset then
            -- Está em reset -> restaurar morph
            if not ClickMorphMagiButton.RestoreTemporaryMorph() then
                print("|cff9933ffMagiButton:|r Nothing to restore.")
            end
        else
            -- Não está em reset -> aplicar reset temporário
            if ClickMorphMagiButton.ApplyTemporaryReset() then
                print("|cff9933ffMagiButton:|r Showing real character. Click again to restore morph!")
            else
                print("|cff9933ffMagiButton:|r No morph to temporarily hide.")
            end
        end
        
    elseif mouseButton == "RightButton" then
        -- Right-click: menu de opções
        ClickMorphMagiButton.ShowContextMenu()
        
    elseif mouseButton == "MiddleButton" then
        -- Middle-click: reset permanente (limpa tudo)
        ClickMorphMagiButton.PermanentReset()
    end
end

-- Reset permanente (limpa morph e estado temporário)
function ClickMorphMagiButton.PermanentReset()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    MagiDebugPrint("Permanent reset requested")
    
    -- CORRIGIDO: Usar o método correto do iMorph
    if ResetIds then
        ResetIds() -- Função direta do iMorph
    else
        -- Fallback: simular digitação no chat editbox
        local editBox = ChatEdit_ChooseBoxForSend()
        if editBox then
            editBox:SetText(".reset")
            ChatEdit_SendText(editBox, 1)
        end
    end
    
    -- Limpar estado temporário
    tempState.isTemporaryReset = false
    tempState.savedMorph = nil
    ClickMorphMagiButton.CancelAutoRestoreTimer()
    
    -- Limpar SaveHub session se disponível
    if ClickMorphSaveHub and ClickMorphSaveHub.saveSystem then
        ClickMorphSaveHub.saveSystem.session.currentMorph = nil
    end
    
    -- Atualizar aparência do botão
    ClickMorphMagiButton.UpdateButtonAppearance()
    
    print("|cff9933ffMagiButton:|r Permanent reset applied!")
end

-- Atualizar aparência visual do botão
function ClickMorphMagiButton.UpdateButtonAppearance()
    local button = ClickMorphMagiButton.buttonSystem.button
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    if not button then return end
    
    if tempState.isTemporaryReset then
        -- Estado "reset temporário" - botão com cor diferente
        button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        button:SetAlpha(0.8)
        
        -- Efeito visual de "pulsing"
        if not button.pulseAnimation then
            button.pulseAnimation = button:CreateAnimationGroup()
            local pulse = button.pulseAnimation:CreateAnimation("Alpha")
            pulse:SetFromAlpha(0.8)
            pulse:SetToAlpha(1.0)
            pulse:SetDuration(1)
            pulse:SetSmoothing("IN_OUT")
            button.pulseAnimation:SetLooping("BOUNCE")
        end
        button.pulseAnimation:Play()
        
    else
        -- Estado normal - botão com aparência padrão
        button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        button:SetAlpha(1.0)
        
        -- Parar animação
        if button.pulseAnimation then
            button.pulseAnimation:Stop()
        end
    end
end

-- Tooltip do botão
function ClickMorphMagiButton.OnButtonEnter(button)
    local settings = ClickMorphMagiButton.buttonSystem.settings
    
    if not settings.showTooltips then return end
    
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    
    if tempState.isTemporaryReset then
        GameTooltip:SetText("MagiButton", 1, 1, 1)
        GameTooltip:AddLine("Currently showing real character", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Left-Click: Restore morph", 0, 1, 0)
        GameTooltip:AddLine("Right-Click: Options menu", 1, 1, 0)
        GameTooltip:AddLine("Middle-Click: Permanent reset", 1, 0.5, 0)
        
        if tempState.savedMorph then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Saved: " .. (tempState.savedMorph.name or "Unknown Morph"), 0.5, 0.5, 1)
        end
        
        -- Mostrar tempo restante do auto-restore se ativo
        if settings.autoRestoreTimeout and tempState.autoRestoreTimer then
            GameTooltip:AddLine("Auto-restore in " .. settings.autoRestoreTimeout .. "s", 1, 1, 0)
        end
    else
        GameTooltip:SetText("MagiButton", 1, 1, 1)
        GameTooltip:AddLine("Toggle between morph and real character", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Left-Click: Hide morph temporarily", 0, 1, 0)
        GameTooltip:AddLine("Right-Click: Options menu", 1, 1, 0)
        GameTooltip:AddLine("Middle-Click: Permanent reset", 1, 0.5, 0)
        
        -- Mostrar morph atual se disponível
        local currentMorph = ClickMorphMagiButton.GetCurrentSavedMorph()
        if currentMorph then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Current: " .. (currentMorph.name or "Unknown Morph"), 0.5, 0.5, 1)
        end
    end
    
    GameTooltip:Show()
end

function ClickMorphMagiButton.OnButtonLeave()
    GameTooltip:Hide()
end

-- =============================================================================
-- VISIBILITY CONTROLS
-- =============================================================================

function ClickMorphMagiButton.ShowButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    if not system.button then
        ClickMorphMagiButton.CreateButton()
    else
        system.button:Show()
    end
    
    system.isVisible = true
    ClickMorphMagiButton.SaveSettings()
    print("|cff9933ffMagiButton:|r Button shown!")
end

function ClickMorphMagiButton.HideButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    if system.button then
        system.button:Hide()
    end
    
    system.isVisible = false
    ClickMorphMagiButton.SaveSettings()
    print("|cff9933ffMagiButton:|r Button hidden!")
end

function ClickMorphMagiButton.ToggleVisibility()
    local system = ClickMorphMagiButton.buttonSystem
    
    if system.isVisible then
        ClickMorphMagiButton.HideButton()
    else
        ClickMorphMagiButton.ShowButton()
    end
end

-- =============================================================================
-- CONTEXT MENU - SIMPLES SEM EASYMENU
-- =============================================================================

-- Criar menu contextual simples
function ClickMorphMagiButton.CreateSimpleMenu()
    local menuFrame = CreateFrame("Frame", "MagiButtonSimpleMenu", UIParent, "BackdropTemplate")
    menuFrame:SetSize(160, 140) -- Aumentado para comportar mais uma opção
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    menuFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.9)
    menuFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    menuFrame:SetFrameStrata("DIALOG")
    menuFrame:Hide()
    
    -- Botão: Toggle Visibility
    local btnToggle = CreateFrame("Button", nil, menuFrame)
    btnToggle:SetSize(140, 20)
    btnToggle:SetPoint("TOP", menuFrame, "TOP", 0, -10)
    btnToggle:SetNormalFontObject("GameFontNormalSmall")
    btnToggle:SetText("Toggle Visibility")
    btnToggle:SetScript("OnClick", function()
        ClickMorphMagiButton.ToggleVisibility()
        menuFrame:Hide()
    end)
    
    -- Botão: Permanent Reset
    local btnReset = CreateFrame("Button", nil, menuFrame)
    btnReset:SetSize(140, 20)
    btnReset:SetPoint("TOP", btnToggle, "BOTTOM", 0, -5)
    btnReset:SetNormalFontObject("GameFontNormalSmall")
    btnReset:SetText("Permanent Reset")
    btnReset:SetScript("OnClick", function()
        ClickMorphMagiButton.PermanentReset()
        menuFrame:Hide()
    end)
    
    -- Botão: Settings Toggle
    local btnSettings = CreateFrame("Button", nil, menuFrame)
    btnSettings:SetSize(140, 20)
    btnSettings:SetPoint("TOP", btnReset, "BOTTOM", 0, -5)
    btnSettings:SetNormalFontObject("GameFontNormalSmall")
    btnSettings:SetText("Auto-Restore: ON")
    btnSettings:SetScript("OnClick", function()
        ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout = not ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout
        ClickMorphMagiButton.SaveSettings()
        btnSettings:SetText("Auto-Restore: " .. (ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout and "ON" or "OFF"))
        print("|cff9933ffMagiButton:|r Auto-restore timeout", ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout and "ON" or "OFF")
    end)
    
    -- Botão: Change Size
    local btnSize = CreateFrame("Button", nil, menuFrame)
    btnSize:SetSize(140, 20)
    btnSize:SetPoint("TOP", btnSettings, "BOTTOM", 0, -5)
    btnSize:SetNormalFontObject("GameFontNormalSmall")
    local currentSize = sizeOptions[ClickMorphMagiButtonSV.buttonSize or 2]
    btnSize:SetText("Size: " .. (currentSize and currentSize.name or "Medium"))
    btnSize:SetScript("OnClick", function()
        ClickMorphMagiButton.CycleSize()
        local newSize = sizeOptions[ClickMorphMagiButtonSV.buttonSize]
        btnSize:SetText("Size: " .. newSize.name)
        menuFrame:Hide()
    end)
    
    -- Botão: Change Icon
    local btnIcon = CreateFrame("Button", nil, menuFrame)
    btnIcon:SetSize(140, 20)
    btnIcon:SetPoint("TOP", btnSize, "BOTTOM", 0, -5)
    btnIcon:SetNormalFontObject("GameFontNormalSmall")
    btnIcon:SetText("Change Icon")
    btnIcon:SetScript("OnClick", function()
        ClickMorphMagiButton.CycleIcon()
        menuFrame:Hide()
    end)
    
    -- Estilo dos botões
    local buttons = {btnToggle, btnReset, btnSettings, btnSize, btnIcon}
    for _, btn in pairs(buttons) do
        btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        btn:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        btn:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        btn:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
    end
    
    -- Fechar menu ao clicar fora - CORRIGIDO
    menuFrame:SetScript("OnShow", function()
        C_Timer.After(0.1, function()
            menuFrame:SetScript("OnUpdate", function(self)
                -- Método compatível para detectar clique fora
                if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
                    local mouseX, mouseY = GetCursorPosition()
                    local scale = UIParent:GetEffectiveScale()
                    local frameX = self:GetLeft() * scale
                    local frameY = self:GetBottom() * scale
                    local frameRight = self:GetRight() * scale
                    local frameTop = self:GetTop() * scale
                    
                    -- Se clicou fora do menu, fechar
                    if mouseX < frameX or mouseX > frameRight or mouseY < frameY or mouseY > frameTop then
                        self:Hide()
                        self:SetScript("OnUpdate", nil)
                    end
                end
            end)
        end)
    end)
    
    return menuFrame
end

function ClickMorphMagiButton.ShowContextMenu()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    -- Criar menu se não existir
    if not ClickMorphMagiButton.contextMenu then
        ClickMorphMagiButton.contextMenu = ClickMorphMagiButton.CreateSimpleMenu()
    end
    
    local menu = ClickMorphMagiButton.contextMenu
    
    -- Posicionar próximo ao cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale + 10, y/scale - 10)
    
    -- Mostrar menu
    menu:Show()
end

-- =============================================================================
-- STATUS & DEBUG
-- =============================================================================

function ClickMorphMagiButton.ShowStatus()
    local system = ClickMorphMagiButton.buttonSystem
    local tempState = system.temporaryState
    
    print("|cff9933ff=== MAGI BUTTON STATUS ===|r")
    print("Button Visible:", system.isVisible and "YES" or "NO")
    print("Button Created:", system.button and "YES" or "NO")
    print("Temporary Reset:", tempState.isTemporaryReset and "ACTIVE" or "INACTIVE")
    print("Auto-Restore Timer:", tempState.autoRestoreTimer and "RUNNING" or "STOPPED")
    print("Debug Mode:", system.settings.debugMode and "ON" or "OFF")
    
    if system.button then
        print("Position: " .. system.position.x .. ", " .. system.position.y)
    end
    
    -- Verificar duplicatas
    local duplicates = {}
    for name, obj in pairs(_G) do
        if type(obj) == "table" and obj.GetObjectType and pcall(obj.GetObjectType, obj) then
            if obj:GetObjectType() == "Button" and name:find("Magic") then
                table.insert(duplicates, name)
            end
        end
    end
    
    if #duplicates > 0 then
        print("Potential duplicates found:", table.concat(duplicates, ", "))
    else
        print("No duplicates detected!")
    end
end

-- =============================================================================
-- COMMANDS & API
-- =============================================================================

-- Comandos do MagiButton
SLASH_CLICKMORPH_MAGIBUTTON1 = "/cmbutton"
SlashCmdList.CLICKMORPH_MAGIBUTTON = function(arg)
    local command = string.lower(arg or "")
    
    if command == "show" or command == "" then
        ClickMorphMagiButton.ShowButton()
        
    elseif command == "hide" then
        ClickMorphMagiButton.HideButton()
        
    elseif command == "toggle" then
        ClickMorphMagiButton.ToggleVisibility()
        
    elseif command == "reset" then
        ClickMorphMagiButton.PermanentReset()
        
    elseif command == "status" then
        ClickMorphMagiButton.ShowStatus()
        
    elseif command == "debug" then
        ClickMorphMagiButton.buttonSystem.settings.debugMode = not ClickMorphMagiButton.buttonSystem.settings.debugMode
        ClickMorphMagiButton.SaveSettings()
        print("|cff9933ffMagiButton:|r Debug mode", ClickMorphMagiButton.buttonSystem.settings.debugMode and "ON" or "OFF")
        
    elseif command == "debuginfo" or command == "info" then
        ClickMorphMagiButton.DebugButton()
        
    elseif command == "testmorph" then
        local currentMorph = ClickMorphMagiButton.GetCurrentSavedMorph()
        if currentMorph then
            print("|cff9933ffMagiButton:|r MORPH DETECTED:", currentMorph.name or currentMorph.id or "unknown")
        else
            print("|cff9933ffMagiButton:|r NO MORPH DETECTED")
        end
        
    elseif command == "cleanup" then
        DestroyOldButtons()
        print("|cff9933ffMagiButton:|r Cleanup completed!")
        
    elseif command == "icon" then
        ClickMorphMagiButton.CycleIcon()
        
    elseif command == "size" then
        ClickMorphMagiButton.CycleSize()
        
    else
        print("|cff9933ffMagiButton Commands:|r")
        print("/cmbutton show - Show the MagiButton")
        print("/cmbutton hide - Hide the MagiButton") 
        print("/cmbutton toggle - Toggle button visibility")
        print("/cmbutton reset - Permanent reset (clear all morphs)")
        print("/cmbutton status - Show system status")
        print("/cmbutton debug - Toggle debug mode")
        print("/cmbutton debuginfo - Show detailed position/size info")
        print("/cmbutton cleanup - Remove old/duplicate buttons")
        print("/cmbutton icon - Cycle through icon options")
        print("/cmbutton size - Cycle through size options (Small/Medium/Large)")
        print("")
        print("|cffccccccLeft-Click: Toggle between morph and real character|r")
        print("|cffccccccRight-Click: Options menu|r")
        print("|cffccccccMiddle-Click: Permanent reset|r")
        print("|cffccccccDrag to move the button|r")
    end
end

-- Public API para outros módulos
ClickMorphMagiButton.API = {
    -- Notificar que um morph foi aplicado
    OnMorphApplied = function(morphData)
        local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
        
        -- Se estava em reset temporário, cancelar porque um novo morph foi aplicado
        if tempState.isTemporaryReset then
            MagiDebugPrint("New morph applied while in temporary reset, canceling temporary state")
            tempState.isTemporaryReset = false
            tempState.savedMorph = nil
            ClickMorphMagiButton.CancelAutoRestoreTimer()
            ClickMorphMagiButton.UpdateButtonAppearance()
        end
    end,
    
    -- Obter estado atual
    GetState = function()
        return ClickMorphMagiButton.buttonSystem.temporaryState.isTemporaryReset
    end,
    
    -- Reset permanente
    PermanentReset = ClickMorphMagiButton.PermanentReset,
    
    -- Controle de visibilidade
    Show = ClickMorphMagiButton.ShowButton,
    Hide = ClickMorphMagiButton.HideButton,
    Toggle = ClickMorphMagiButton.ToggleVisibility
}

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Inicialização com proteção contra duplicação
local function InitializeMagiButton()
    -- Verificar se já foi inicializado
    if ClickMorphMagiButton.__initialized and ClickMorphMagiButton.buttonSystem.button then
        MagiDebugPrint("MagiButton already initialized, skipping...")
        return
    end
    
    MagiDebugPrint("Initializing unified MagiButton...")
    
    -- Event frame para inicialização
    local eventFrame = CreateFrame("Frame", "ClickMorphMagiButtonEventFrame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            MagiDebugPrint("ClickMorph loaded")
            
        elseif event == "PLAYER_LOGIN" then
            -- Delay para garantir que tudo carregou
            C_Timer.After(2, function()
                -- Limpar botões antigos primeiro
                DestroyOldButtons()
                
                -- Criar o novo botão unificado
                ClickMorphMagiButton.CreateButton()
                MagiDebugPrint("MagiButton ready and unified!")
                print("|cff9933ffClickMorph MagiButton Enhanced|r loaded!")
                print("Use |cffffcc00/cmbutton show|r to display the unified magic button")
            end)
            
            -- Unregister events after initialization
            self:UnregisterAllEvents()
        end
    end)
end

-- IMPORTANTE: Só inicializar se não foi inicializado ainda
if not ClickMorphMagiButton.__initialized then
    InitializeMagiButton()
end

-- =============================================================================
-- CLEANUP COMMANDS.LUA INTEGRATION
-- =============================================================================

-- Desabilitar completamente a função antiga do Commands.lua
if ClickMorphCommands then
    -- Sobrescrever funções antigas para evitar conflitos
    ClickMorphCommands.CreateMagicResetButton = function()
        MagiDebugPrint("Old CreateMagicResetButton called - redirecting to new MagiButton")
        ClickMorphMagiButton.ShowButton()
    end
    
    ClickMorphCommands.HideMagicResetButton = function()
        MagiDebugPrint("Old HideMagicResetButton called - redirecting to new MagiButton")
        ClickMorphMagiButton.HideButton()
    end
    
    -- Limpar variáveis antigas
    ClickMorphCommands.magicResetButton = nil
end

print("|cff9933ffClickMorph MagiButton Enhanced|r - Unified version loaded!")
print("|cffccccccNo more duplicates! Old 'Magic Reset Button' disabled.|r")
MagiDebugPrint("MagiButton.lua loaded successfully - UNIFIED VERSION")