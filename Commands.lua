-- ClickMorph Command System - UNIFIED VERSION
-- Sistema de comandos ÚNICO e centralizado para eliminar conflitos

ClickMorphCommands = ClickMorphCommands or {} -- Global

-- ========================================
-- CONFIGURAÇÃO CENTRALIZADA
-- ========================================
ClickMorphCommands.config = {
    enableSounds = true,
    silentMode = false,
    magicReset = true,
    enableShowAll = false,
    enableWardrobe = false,
    debugMode = false
}

-- Salvar configurações
local function SaveConfig()
    ClickMorphDB = ClickMorphDB or {}
    ClickMorphDB.commands = ClickMorphCommands.config
    if ClickMorphCommands.config.debugMode then
        print("|cffccccccClickMorph:|r Config saved")
    end
end

-- Carregar configurações
local function LoadConfig()
-- Garantir que as configurações do MagiButton existem
    if ClickMorphCommands.config.magiButtonEnabled == nil then
        ClickMorphCommands.config.magiButtonEnabled = false
    end
    
    if ClickMorphCommands.config.magiButtonSounds == nil then
        ClickMorphCommands.config.magiButtonSounds = true
    end
    
    -- Sincronizar com MagiButton se disponível
    if ClickMorphMagiButton then
        -- Aplicar configurações carregadas
        if ClickMorphCommands.config.magiButtonEnabled then
            C_Timer.After(1.5, function()
                if ClickMorphMagiButton.API then
                    ClickMorphMagiButton.API.Show()
                end
            end)
        end
        
        -- Sincronizar sons
        if ClickMorphMagiButton.config then
            ClickMorphMagiButton.config.enableSounds = ClickMorphCommands.config.magiButtonSounds
        end
    end

    if ClickMorphDB and ClickMorphDB.commands then
        for k, v in pairs(ClickMorphDB.commands) do
            ClickMorphCommands.config[k] = v
        end
    end
    if ClickMorphCommands.config.debugMode then
        print("|cffccccccClickMorph:|r Config loaded")
    end
end

-- ========================================
-- COMANDO UNIFICADO /CM - VERSÃO ÚNICA
-- ========================================
local function UnifiedClickMorphHandler(msg)
    local args = {strsplit(" ", msg)}
    local command = string.lower(args[1] or "")
    
    -- Comando principal - abrir menu
    if command == "" or command == "menu" then
        ClickMorphCommands.CreateCommandFrame()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
        return
        
    -- Reset morph
    elseif command == "reset" then
        ClickMorphCommands.ExecuteReset()
        return
        
    -- ShowAll - chamar o sistema do ShowAll.lua
    elseif command == "showall" then
        if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
            ClickMorphShowAll.ShowConfirmation()
        else
            print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
        end
        return
        
    -- Debug
    elseif command == "debug" then
        ClickMorphCommands.ShowDebugInfo()
        return
        
    -- Settings
    elseif command == "settings" then
        ClickMorphCommands.ShowSettings()
        return
        
    -- MagiButton control
    elseif command == "button" then
        local subCommand = string.lower(args[2] or "")
        if ClickMorphMagiButton and ClickMorphMagiButton.API then
            if subCommand == "show" then
                ClickMorphMagiButton.API.Show()
            elseif subCommand == "hide" then
                ClickMorphMagiButton.API.Hide()
            elseif subCommand == "toggle" then
                ClickMorphMagiButton.API.Toggle()
            else
                print("|cffffcc00MagiButton:|r /cm button show/hide/toggle")
            end
        else
            print("|cffff0000ClickMorph:|r MagiButton not loaded!")
        end
        return
        
    -- Help
    elseif command == "help" then
        print("|cff00ff00=== ClickMorph Retail Remaster ===|r")
        print("|cffffcc00/cm|r - Open main menu interface")
        print("|cffffcc00/cm reset|r - Reset all morphs")
        print("|cffffcc00/cm showall|r - Unlock all transmog/mounts")
        print("|cffffcc00/cm settings|r - Open settings panel")
        print("|cffffcc00/cm button show/hide|r - Control MagiButton")
        print("|cffffcc00/cm debug|r - Show system information")
        return
        
    else
        print("|cffff0000ClickMorph:|r Unknown command '/" .. tostring(command) .. "'")
        print("Use |cffffcc00/cm help|r for available commands")
        return
    end
end

-- ========================================
-- INTERFACE DO MENU PRINCIPAL
-- ========================================
function ClickMorphCommands.CreateCommandFrame()
    -- Se já existe, apenas mostrar
    if ClickMorphCommands.commandFrame then
        ClickMorphCommands.commandFrame:Show()
        return ClickMorphCommands.commandFrame
    end
    
    -- Criar frame principal
    local commandFrame = CreateFrame("Frame", "ClickMorphCommandFrame", UIParent, "BasicFrameTemplateWithInset")
    commandFrame:SetSize(400, 500)
    commandFrame:SetPoint("CENTER")
    commandFrame:SetMovable(true)
    commandFrame:EnableMouse(true)
    commandFrame:RegisterForDrag("LeftButton")
    commandFrame:SetScript("OnDragStart", commandFrame.StartMoving)
    commandFrame:SetScript("OnDragStop", commandFrame.StopMovingOrSizing)
    commandFrame:SetClampedToScreen(true)
    commandFrame:SetFrameStrata("HIGH")
    
    commandFrame.title = commandFrame:CreateFontString(nil, "OVERLAY")
    commandFrame.title:SetFontObject("GameFontHighlightLarge")
    commandFrame.title:SetPoint("LEFT", commandFrame.TitleBg, "LEFT", 5, 0)
    commandFrame.title:SetText("ClickMorph Retail Remaster")
    
    -- ScrollFrame para conteúdo
    local scrollFrame = CreateFrame("ScrollFrame", nil, commandFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", commandFrame.Inset, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", commandFrame.Inset, "BOTTOMRIGHT", -3, 4)
    
    local contentFrame = CreateFrame("Frame")
    contentFrame:SetSize(370, 800) -- Altura maior para scroll
    scrollFrame:SetScrollChild(contentFrame)
    
    local yOffset = -20
    
    -- Função helper para criar botões
    local function CreateMenuButton(parent, yPos, text, tooltip, onClick)
        local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yPos)
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yPos)
        button:SetHeight(32)
        button:SetText(text)
        button:SetNormalFontObject("GameFontNormalLarge")
        button:SetScript("OnClick", onClick)
        
        if tooltip then
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltip)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
        
        return button
    end
    
    -- BOTÕES DO MENU
    
    -- Reset Button
    CreateMenuButton(contentFrame, yOffset, "🔄 Reset Appearance", 
        "Reset all morphs and return to your original appearance", 
        function()
            ClickMorphCommands.ExecuteReset()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
        end)
    yOffset = yOffset - 45
    
    -- ShowAll Button
    CreateMenuButton(contentFrame, yOffset, "🎭 ShowAll System",
        "Unlock ALL transmog appearances and mounts in the game\n|cffff6666Warning: May cause temporary lag|r",
        function()
            if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
                ClickMorphShowAll.ShowConfirmation()
                commandFrame:Hide()
            else
                print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
            end
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
        end)
    yOffset = yOffset - 45
    
    -- MagiButton Control
    CreateMenuButton(contentFrame, yOffset, "🔮 MagiButton Control",
        "Show/Hide the magical reset button\nLeft-click: Remove/reapply morph\nRight-click: Open menu\nAlt+click: Full reset",
        function()
            if ClickMorphMagiButton and ClickMorphMagiButton.API then
                ClickMorphMagiButton.API.Toggle()
                print("|cff00ff00ClickMorph:|r MagiButton toggled!")
            else
                print("|cffff0000ClickMorph:|r MagiButton system not loaded!")
            end
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
        end)
    yOffset = yOffset - 45
    
    -- Settings Button
    CreateMenuButton(contentFrame, yOffset, "⚙️ Settings",
        "Configure addon behavior and preferences",
        function()
            ClickMorphCommands.ShowSettings()
            commandFrame:Hide()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
        end)
    yOffset = yOffset - 45
    
    -- Debug Button
    CreateMenuButton(contentFrame, yOffset, "🔍 System Debug",
        "Check system status and troubleshoot issues",
        function()
            ClickMorphCommands.ShowDebugInfo()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
        end)
    yOffset = yOffset - 65
    
    -- Seção de Status
    local statusHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 30, yOffset)
    statusHeader:SetText("System Status")
    statusHeader:SetTextColor(1, 0.8, 0)
    yOffset = yOffset - 25
    
    -- Status do ShowAll
    local showAllStatus = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showAllStatus:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 40, yOffset)
    local showAllActive = ClickMorphShowAll and ClickMorphShowAll.unlockSystem.isActive
    showAllStatus:SetText("ShowAll System: " .. (showAllActive and "|cff00ff00ACTIVE|r" or "|cffccccccINACTIVE|r"))
    yOffset = yOffset - 20
    
    -- Status do MagiButton
    local magiStatus = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    magiStatus:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 40, yOffset)
    local magiLoaded = ClickMorphMagiButton and ClickMorphMagiButton.API
    magiStatus:SetText("MagiButton: " .. (magiLoaded and "|cff00ff00LOADED|r" or "|cffff6666NOT LOADED|r"))
    yOffset = yOffset - 20
    
    commandFrame.CloseButton:SetScript("OnClick", function()
        commandFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
    end)
    
    ClickMorphCommands.commandFrame = commandFrame
    commandFrame:Show()
    return commandFrame
end

-- ========================================
-- FUNÇÕES DE SUPORTE
-- ========================================

-- Reset function
function ClickMorphCommands.ExecuteReset()
    local success = false
    
    if ResetIds then
        ResetIds()
        success = true
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r Reset executed via ResetIds()")
        end
    elseif iMorphChatHandler then
        iMorphChatHandler(".reset")
        success = true
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r Reset via iMorph handler")
        end
    else
        -- Fallback para comando de chat
        SendChatMessage(".reset", "SAY")
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r Reset command sent via chat")
        end
    end
    
    if ClickMorphCommands.config.enableSounds then
        PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE)
    end
end

-- Debug function
function ClickMorphCommands.ShowDebugInfo()
    print("|cff00ff00=== ClickMorph Debug Information ===|r")
    print("Version: Retail Remaster - Unified Command System")
    print("WoW Version: " .. GetBuildInfo())
    
    -- Sistema ShowAll
    if ClickMorphShowAll then
        local status = ClickMorphShowAll.unlockSystem.isActive and "ACTIVE" or "INACTIVE"
        print("ShowAll System: |cffffcc00" .. status .. "|r")
        if ClickMorphShowAll.unlockSystem.isActive then
            local mounts = #(ClickMorphShowAll.unlockSystem.unobtainableMounts or {})
            print("  Unobtainable mounts: " .. mounts)
        end
    else
        print("ShowAll System: |cffff0000NOT LOADED|r")
    end
    
    -- MagiButton
    if ClickMorphMagiButton then
        print("MagiButton System: |cff00ff00LOADED|r")
    else
        print("MagiButton System: |cffff0000NOT LOADED|r")
    end
    
    -- iMorph integration
    if ResetIds then
        print("iMorph Integration: |cff00ff00ACTIVE (ResetIds)|r")
    elseif iMorphChatHandler then
        print("iMorph Integration: |cffffcc00ACTIVE (Chat Handler)|r")
    else
        print("iMorph Integration: |cffff0000INACTIVE|r")
    end
    
    -- Config
    print("Silent Mode: " .. (ClickMorphCommands.config.silentMode and "ON" or "OFF"))
    print("Enable Sounds: " .. (ClickMorphCommands.config.enableSounds and "ON" or "OFF"))
end

-- Settings placeholder
function ClickMorphCommands.ShowSettings()
    -- Se já existe settings frame, apenas mostrar
    if ClickMorphCommands.settingsFrame then
        ClickMorphCommands.settingsFrame:Show()
        return
    end
    
    -- Criar frame de settings
    local settingsFrame = CreateFrame("Frame", "ClickMorphSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    settingsFrame:SetSize(450, 600)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:SetClampedToScreen(true)
    settingsFrame:SetFrameStrata("HIGH")
    
    settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
    settingsFrame.title:SetFontObject("GameFontHighlightLarge")
    settingsFrame.title:SetPoint("LEFT", settingsFrame.TitleBg, "LEFT", 5, 0)
    settingsFrame.title:SetText("ClickMorph Settings")
    
    local yPos = -50
    
    -- ========================================
    -- SEÇÃO: USER INTERFACE
    -- ========================================
    local uiHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    uiHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    uiHeader:SetText("User Interface")
    uiHeader:SetTextColor(1, 0.8, 0)
    yPos = yPos - 35
    
    -- Enable UI Sounds
    local soundCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    soundCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    soundCheck.Text:SetText("Enable UI Sounds")
    soundCheck:SetChecked(ClickMorphCommands.config.enableSounds)
    soundCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.enableSounds = self:GetChecked()
        SaveConfig()
        if self:GetChecked() then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    yPos = yPos - 35
    
    -- Silent Mode
    local silentCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    silentCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    silentCheck.Text:SetText("Silent mode (reduce chat output)")
    silentCheck:SetChecked(ClickMorphCommands.config.silentMode)
    silentCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.silentMode = self:GetChecked()
        SaveConfig()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    yPos = yPos - 35
    
    -- Debug Mode
    local debugCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    debugCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    debugCheck.Text:SetText("Debug mode (detailed logging)")
    debugCheck:SetChecked(ClickMorphCommands.config.debugMode)
    debugCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.debugMode = self:GetChecked()
        SaveConfig()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    yPos = yPos - 50
    
    -- ========================================
    -- SEÇÃO: TOOLS & FEATURES
    -- ========================================
    local toolsHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toolsHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    toolsHeader:SetText("Tools & Features")
    toolsHeader:SetTextColor(1, 0.8, 0)
    yPos = yPos - 35
    
    -- ShowAll System
    local showAllCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    showAllCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    showAllCheck.Text:SetText("ShowAll System (unlock all transmog/mounts)")
    
    -- Verificar se ShowAll está ativo
    local showAllActive = ClickMorphShowAll and ClickMorphShowAll.unlockSystem and ClickMorphShowAll.unlockSystem.isActive
    showAllCheck:SetChecked(showAllActive or false)
    
    showAllCheck:SetScript("OnClick", function(self)
        if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
            if self:GetChecked() then
                ClickMorphShowAll.ShowConfirmation()
            else
                if ClickMorphShowAll.RevertAPIs then
                    ClickMorphShowAll.RevertAPIs()
                    print("|cff00ff00ClickMorph:|r ShowAll deactivated")
                end
            end
        else
            print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
            self:SetChecked(false)
        end
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    yPos = yPos - 35
    
    -- ========================================
    -- MAGIBUTTON INTEGRATION - SEÇÃO PRINCIPAL
    -- ========================================
    
    -- MagiButton - Checkbox principal
    local magiButtonCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    magiButtonCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    magiButtonCheck.Text:SetText("MagiButton - Draggable screen button")
    
    -- Verificar estado atual do MagiButton
    local magiButtonVisible = false
    if ClickMorphMagiButton and ClickMorphMagiButton.API then
        magiButtonVisible = ClickMorphMagiButton.API.IsVisible()
    end
    
    -- Inicializar configuração se não existir
    if ClickMorphCommands.config.magiButtonEnabled == nil then
        ClickMorphCommands.config.magiButtonEnabled = magiButtonVisible
    end
    
    magiButtonCheck:SetChecked(ClickMorphCommands.config.magiButtonEnabled)
    magiButtonCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.magiButtonEnabled = self:GetChecked()
        SaveConfig()
        
        -- Controlar MagiButton
        if ClickMorphMagiButton and ClickMorphMagiButton.API then
            if self:GetChecked() then
                ClickMorphMagiButton.API.Show()
            else
                ClickMorphMagiButton.API.Hide()
            end
        else
            print("|cffff0000ClickMorph:|r MagiButton system not loaded!")
            self:SetChecked(false)
        end
        
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    -- Tooltip para MagiButton
    magiButtonCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("MagiButton", 1, 1, 1)
        GameTooltip:AddLine("Draggable button with multiple functions:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("• Right-Click: Open /cm menu", 0, 1, 0)
        GameTooltip:AddLine("• Alt+Click: Execute .reset command", 1, 1, 0)
        GameTooltip:AddLine("• Drag: Move button position", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    magiButtonCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    yPos = yPos - 35
    
    -- MagiButton Sounds - Checkbox secundário (indentado)
    local magiButtonSoundsCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    magiButtonSoundsCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 50, yPos) -- Indentado 20px
    magiButtonSoundsCheck.Text:SetText("Enable MagiButton sounds")
    magiButtonSoundsCheck.Text:SetTextColor(0.9, 0.9, 0.9) -- Cor mais suave
    
    -- Inicializar configuração de sons
    if ClickMorphCommands.config.magiButtonSounds == nil then
        ClickMorphCommands.config.magiButtonSounds = true
        if ClickMorphMagiButton and ClickMorphMagiButton.config then
            ClickMorphCommands.config.magiButtonSounds = ClickMorphMagiButton.config.enableSounds
        end
    end
    
    magiButtonSoundsCheck:SetChecked(ClickMorphCommands.config.magiButtonSounds)
    magiButtonSoundsCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.magiButtonSounds = self:GetChecked()
        SaveConfig()
        
        -- Sincronizar com MagiButton
        if ClickMorphMagiButton and ClickMorphMagiButton.API then
            ClickMorphMagiButton.API.OnSoundsToggle(self:GetChecked())
        end
        
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    -- Tooltip para sons do MagiButton
    magiButtonSoundsCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("MagiButton Sounds", 1, 1, 1)
        GameTooltip:AddLine("Controls audio feedback for MagiButton:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("• Click sounds when using functions", 0, 1, 0)
        GameTooltip:AddLine("• Independent from main UI sounds", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    magiButtonSoundsCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    yPos = yPos - 50
    
    -- ========================================
    -- SEÇÃO: SYSTEM STATUS
    -- ========================================
    local statusHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    statusHeader:SetText("System Status")
    statusHeader:SetTextColor(0.7, 0.7, 1)
    yPos = yPos - 35
    
    -- Status do MagiButton
    local magiStatus = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    magiStatus:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 40, yPos)
    local magiLoaded = ClickMorphMagiButton and ClickMorphMagiButton.API
    magiStatus:SetText("MagiButton System: " .. (magiLoaded and "|cff00ff00LOADED|r" or "|cffff6666NOT LOADED|r"))
    yPos = yPos - 25
    
    -- Status do ShowAll
    local showAllStatus = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showAllStatus:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 40, yPos)
    showAllStatus:SetText("ShowAll System: " .. (showAllActive and "|cff00ff00ACTIVE|r" or "|cffccccccINACTIVE|r"))
    yPos = yPos - 25
    
    -- Status do iMorph
    local iMorphStatus = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    iMorphStatus:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 40, yPos)
    local iMorphLoaded = ResetIds or iMorphChatHandler
    iMorphStatus:SetText("iMorph Integration: " .. (iMorphLoaded and "|cff00ff00ACTIVE|r" or "|cffff6666INACTIVE|r"))
    yPos = yPos - 40
    
    -- Botão de Reset Settings
    local resetButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
    resetButton:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    resetButton:SetSize(120, 25)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function()
        -- Reset configurações para padrão
        ClickMorphCommands.config.enableSounds = true
        ClickMorphCommands.config.silentMode = false
        ClickMorphCommands.config.debugMode = false
        ClickMorphCommands.config.magiButtonEnabled = false
        ClickMorphCommands.config.magiButtonSounds = true
        SaveConfig()
        
        -- Atualizar checkboxes
        soundCheck:SetChecked(true)
        silentCheck:SetChecked(false)
        debugCheck:SetChecked(false)
        magiButtonCheck:SetChecked(false)
        magiButtonSoundsCheck:SetChecked(true)
        
        -- Esconder MagiButton
        if ClickMorphMagiButton and ClickMorphMagiButton.API then
            ClickMorphMagiButton.API.Hide()
        end
        
        print("|cff00ff00ClickMorph:|r Settings reset to defaults")
        
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    -- Close button
    settingsFrame.CloseButton:SetScript("OnClick", function()
        settingsFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
    end)
    
    ClickMorphCommands.settingsFrame = settingsFrame
    settingsFrame:Show()
end

-- ========================================
-- INICIALIZAÇÃO E REGISTRO
-- ========================================

-- REGISTRAR APENAS UM COMANDO /CM - LIMPAR CONFLITOS
local function RegisterUnifiedCommand()
    -- Limpar registros antigos que possam causar conflito
    SLASH_CLICKMORPH1 = "/cm"
    SLASH_CLICKMORPH2 = "/clickmorph"
    
    -- Registrar APENAS nossa versão unificada
    SlashCmdList["CLICKMORPH"] = UnifiedClickMorphHandler
    
    print("|cff00ff00ClickMorph:|r Unified command system loaded! Type |cffffcc00/cm|r for menu.")
end

-- Inicialização quando addon carrega
local function OnAddonLoaded()
    LoadConfig()
    RegisterUnifiedCommand()
    
    if ClickMorphCommands.config.debugMode then
        print("|cffccccccClickMorph:|r Debug mode enabled")
    end
end

-- Event frame para inicialização
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        OnAddonLoaded()
        initFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Limpar outros handlers conflitantes após delay
C_Timer.After(2, function()
    -- Garantir que apenas nossa versão esteja ativa
    SlashCmdList["CLICKMORPH"] = UnifiedClickMorphHandler
    
    if ClickMorphCommands.config.debugMode then
        print("|cffccccccClickMorph:|r Command handler secured")
    end
end)