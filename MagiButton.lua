-- MagiButton.lua
-- Sistema melhorado do MagiButton com toggle temporário de morph

ClickMorphMagiButton = {}

-- Sistema do MagiButton
ClickMorphMagiButton.buttonSystem = {
    button = nil,
    isVisible = true,
    position = {x = 0, y = 0},
    
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
        buttonSize = 32,
        debugMode = false
    }
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

-- Obter morph atual do SaveHub
function ClickMorphMagiButton.GetCurrentSavedMorph()
    if ClickMorphSaveHub and ClickMorphSaveHub.saveSystem then
        local session = ClickMorphSaveHub.saveSystem.session
        return session.lastAppliedMorph or session.currentMorph
    end
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

-- Restaurar morph salvo temporariamente
function ClickMorphMagiButton.RestoreTemporarySavedMorph()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    local savedMorph = tempState.savedMorph
    
    if not savedMorph then
        MagiDebugPrint("No temporary morph to restore")
        return false
    end
    
    MagiDebugPrint("Restoring temporary morph:", savedMorph.name or "Unnamed")
    
    -- Usar SaveHub API para aplicar o morph salvo
    if ClickMorphSaveHub and ClickMorphSaveHub.ApplyMorphFromSave then
        ClickMorphSaveHub.ApplyMorphFromSave(savedMorph)
    else
        -- Fallback: aplicar comando diretamente
        local morph = savedMorph.morph
        if morph and morph.displayID then
            local command = morph.command or (".morph " .. morph.displayID)
            SendChatMessage(command, "GUILD")
        end
    end
    
    return true
end

-- Aplicar reset temporário
function ClickMorphMagiButton.ApplyTemporaryReset()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    MagiDebugPrint("Applying temporary reset")
    
    -- Salvar morph atual
    if ClickMorphMagiButton.SaveCurrentMorphTemporary() then
        -- Aplicar reset
        SendChatMessage(".reset", "GUILD")
        
        -- Marcar estado temporário
        tempState.isTemporaryReset = true
        
        -- Iniciar timer de auto-restore se configurado
        if ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout then
            ClickMorphMagiButton.StartAutoRestoreTimer()
        end
        
        -- Atualizar aparência do botão
        ClickMorphMagiButton.UpdateButtonAppearance()
        
        return true
    end
    
    return false
end

-- Cancelar reset temporário (restaurar morph)
function ClickMorphMagiButton.CancelTemporaryReset()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    MagiDebugPrint("Canceling temporary reset")
    
    -- Restaurar morph
    if ClickMorphMagiButton.RestoreTemporarySavedMorph() then
        -- Limpar estado temporário
        tempState.isTemporaryReset = false
        tempState.savedMorph = nil
        
        -- Cancelar timer
        ClickMorphMagiButton.CancelAutoRestoreTimer()
        
        -- Atualizar aparência do botão
        ClickMorphMagiButton.UpdateButtonAppearance()
        
        return true
    end
    
    return false
end

-- Timer de auto-restore
function ClickMorphMagiButton.StartAutoRestoreTimer()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    local delay = ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout
    
    -- Cancelar timer existente
    ClickMorphMagiButton.CancelAutoRestoreTimer()
    
    MagiDebugPrint("Starting auto-restore timer:", delay, "seconds")
    
    tempState.autoRestoreTimer = C_Timer.NewTimer(delay, function()
        MagiDebugPrint("Auto-restore timer expired, restoring morph")
        ClickMorphMagiButton.CancelTemporaryReset()
        print("|cff9933ffMagiButton:|r Auto-restored morph after timeout")
    end)
end

function ClickMorphMagiButton.CancelAutoRestoreTimer()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    if tempState.autoRestoreTimer then
        tempState.autoRestoreTimer:Cancel()
        tempState.autoRestoreTimer = nil
        MagiDebugPrint("Auto-restore timer canceled")
    end
end

-- Lógica principal do clique do botão
function ClickMorphMagiButton.OnButtonClick(button, mouseButton)
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    MagiDebugPrint("Button clicked, current state:", tempState.isTemporaryReset and "RESET" or "MORPH")
    
    if mouseButton == "LeftButton" then
        if tempState.isTemporaryReset then
            -- Está em reset temporário -> restaurar morph
            ClickMorphMagiButton.CancelTemporaryReset()
            print("|cff9933ffMagiButton:|r Morph restored!")
        else
            -- Não está em reset -> aplicar reset temporário
            if ClickMorphMagiButton.ApplyTemporaryReset() then
                print("|cff9933ffMagiButton:|r Showing real character. Click again to restore morph!")
            else
                print("|cff9933ffMagiButton:|r No morph to temporarily hide.")
            end
        end
        
    elseif mouseButton == "RightButton" then
        -- Right-click: menu de opções ou reset permanente
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
    
    -- Aplicar reset
    SendChatMessage(".reset", "GUILD")
    
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

-- Menu de contexto (right-click)
function ClickMorphMagiButton.ShowContextMenu()
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    local menu = {
        {
            text = "MagiButton Options",
            isTitle = true,
        },
        {
            text = "Toggle Visibility",
            func = function()
                ClickMorphMagiButton.ToggleVisibility()
            end,
        },
        {
            text = "Permanent Reset",
            func = function()
                ClickMorphMagiButton.PermanentReset()
            end,
        }
    }
    
    if tempState.isTemporaryReset then
        table.insert(menu, {
            text = "Cancel Temporary Reset",
            func = function()
                ClickMorphMagiButton.CancelTemporaryReset()
            end,
        })
    end
    
    table.insert(menu, {
        text = "Settings",
        hasArrow = true,
        menuList = {
            {
                text = "Auto-Restore Timeout",
                checked = ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout,
                func = function()
                    ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout = not ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout
                    print("|cff9933ffMagiButton:|r Auto-restore timeout", ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout and "ON" or "OFF")
                end,
            },
            {
                text = "Show Tooltips",
                checked = ClickMorphMagiButton.buttonSystem.settings.showTooltips,
                func = function()
                    ClickMorphMagiButton.buttonSystem.settings.showTooltips = not ClickMorphMagiButton.buttonSystem.settings.showTooltips
                    print("|cff9933ffMagiButton:|r Tooltips", ClickMorphMagiButton.buttonSystem.settings.showTooltips and "ON" or "OFF")
                end,
            },
            {
                text = "Debug Mode",
                checked = ClickMorphMagiButton.buttonSystem.settings.debugMode,
                func = function()
                    ClickMorphMagiButton.buttonSystem.settings.debugMode = not ClickMorphMagiButton.buttonSystem.settings.debugMode
                    print("|cff9933ffMagiButton:|r Debug mode", ClickMorphMagiButton.buttonSystem.settings.debugMode and "ON" or "OFF")
                end,
            }
        }
    })
    
    local contextMenu = CreateFrame("Frame", "MagiButtonContextMenu", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, contextMenu, "cursor", 0, 0, "MENU")
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

-- Criar o botão físico
function ClickMorphMagiButton.CreateButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    if system.button then
        MagiDebugPrint("Button already exists")
        return system.button
    end
    
    MagiDebugPrint("Creating MagiButton")
    
    -- Criar frame do botão
    local button = CreateFrame("Button", "ClickMorphMagiButton", UIParent)
    button:SetSize(system.settings.buttonSize, system.settings.buttonSize)
    button:SetPoint("CENTER", UIParent, "CENTER", system.position.x, system.position.y)
    
    -- Texturas
    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
    
    -- Ícone
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    button.icon = icon
    
    -- Event handlers
    button:SetScript("OnClick", ClickMorphMagiButton.OnButtonClick)
    button:SetScript("OnEnter", ClickMorphMagiButton.OnButtonEnter)
    button:SetScript("OnLeave", ClickMorphMagiButton.OnButtonLeave)
    
    -- Tornar movível
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    
    button:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Salvar posição
        local point, _, _, x, y = self:GetPoint()
        system.position.x = x
        system.position.y = y
        MagiDebugPrint("Button moved to:", x, y)
    end)
    
    -- Salvar referência
    system.button = button
    
    MagiDebugPrint("MagiButton created successfully")
    return button
end

-- Toggle visibilidade do botão
function ClickMorphMagiButton.ToggleVisibility()
    local system = ClickMorphMagiButton.buttonSystem
    
    if not system.button then
        ClickMorphMagiButton.CreateButton()
        return
    end
    
    system.isVisible = not system.isVisible
    
    if system.isVisible then
        system.button:Show()
        print("|cff9933ffMagiButton:|r Button shown")
    else
        system.button:Hide()
        print("|cff9933ffMagiButton:|r Button hidden")
    end
end

-- Mostrar/esconder botão
function ClickMorphMagiButton.ShowButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    if not system.button then
        ClickMorphMagiButton.CreateButton()
    end
    
    system.button:Show()
    system.isVisible = true
end

function ClickMorphMagiButton.HideButton()
    local system = ClickMorphMagiButton.buttonSystem
    
    if system.button then
        system.button:Hide()
        system.isVisible = false
    end
end

-- Status do sistema
function ClickMorphMagiButton.ShowStatus()
    local system = ClickMorphMagiButton.buttonSystem
    local tempState = system.temporaryState
    
    print("|cff9933ff=== MAGI BUTTON STATUS ===|r")
    print("Button Visible:", system.isVisible and "YES" or "NO")
    print("Button Created:", system.button and "YES" or "NO")
    print("Temporary Reset State:", tempState.isTemporaryReset and "ACTIVE" or "INACTIVE")
    print("Auto-Restore Timeout:", system.settings.autoRestoreTimeout and "ON" or "OFF")
    print("Show Tooltips:", system.settings.showTooltips and "ON" or "OFF")
    print("Debug Mode:", system.settings.debugMode and "ON" or "OFF")
    
    if tempState.savedMorph then
        print("Saved Morph:", tempState.savedMorph.name or "Unknown")
    end
    
    if system.button then
        print("Position: " .. system.position.x .. ", " .. system.position.y)
    end
end

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
        print("|cff9933ffMagiButton:|r Debug mode", ClickMorphMagiButton.buttonSystem.settings.debugMode and "ON" or "OFF")
        
    elseif command == "timeout" then
        ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout = not ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout
        print("|cff9933ffMagiButton:|r Auto-restore timeout", ClickMorphMagiButton.buttonSystem.settings.autoRestoreTimeout and "ON" or "OFF")
        
    else
        print("|cff9933ffMagiButton Commands:|r")
        print("/cmbutton show - Show the MagiButton")
        print("/cmbutton hide - Hide the MagiButton") 
        print("/cmbutton toggle - Toggle button visibility")
        print("/cmbutton reset - Permanent reset (clear all morphs)")
        print("/cmbutton status - Show system status")
        print("/cmbutton timeout - Toggle auto-restore timeout")
        print("/cmbutton debug - Toggle debug mode")
        print("")
        print("|cffccccccLeft-Click: Toggle between morph and real character|r")
        print("|cffccccccRight-Click: Options menu|r")
        print("|cffccccccMiddle-Click: Permanent reset|r")
        print("|cffccccccDrag to move the button|r")
    end
end

-- Integration hook para quando outros módulos aplicam morphs
function ClickMorphMagiButton.OnMorphApplied(morphData)
    local tempState = ClickMorphMagiButton.buttonSystem.temporaryState
    
    -- Se estava em reset temporário, cancelar porque um novo morph foi aplicado
    if tempState.isTemporaryReset then
        MagiDebugPrint("New morph applied while in temporary reset, canceling temporary state")
        tempState.isTemporaryReset = false
        tempState.savedMorph = nil
        ClickMorphMagiButton.CancelAutoRestoreTimer()
        ClickMorphMagiButton.UpdateButtonAppearance()
    end
end

-- Public API para outros módulos
ClickMorphMagiButton.API = {
    -- Notificar que um morph foi aplicado
    OnMorphApplied = ClickMorphMagiButton.OnMorphApplied,
    
    -- Obter estado atual
    GetState = function()
        return ClickMorphMagiButton.buttonSystem.temporaryState.isTemporaryReset
    end,
    
    -- Reset permanente
    PermanentReset = ClickMorphMagiButton.PermanentReset
}

-- Inicialização
local function InitializeMagiButton()
    MagiDebugPrint("Initializing MagiButton...")
    
    -- Criar botão após delay para garantir que UI está carregada
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            MagiDebugPrint("ClickMorph loaded")
            
        elseif event == "PLAYER_LOGIN" then
            C_Timer.After(1, function()
                ClickMorphMagiButton.CreateButton()
                MagiDebugPrint("MagiButton ready")
            end)
        end
    end)
end

InitializeMagiButton()

print("|cff9933ffClickMorph MagiButton Enhanced|r loaded!")
print("Use |cffffcc00/cmbutton show|r to display the magic button")
MagiDebugPrint("MagiButton.lua loaded successfully")