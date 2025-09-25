-- ClickMorph Command System - Retail Remaster
-- Sistema de comandos integrado com UI nativa do WoW

ClickMorphCommands = {} -- Global

-- ========================================
-- PATCH PARA COMMANDS.LUA
-- Adicione estas linhas no INÍCIO do Commands.lua para desabilitar o botão antigo
-- ========================================

-- IMPORTANTE: Prevenir criação do botão antigo
local magicResetButton = nil -- Declarar como local para evitar global

-- Sobrescrever a função antiga de criação do botão
local function CreateMagicResetButton()
    -- NÃO fazer nada - o novo MagiButton.lua cuida disso
    if ClickMorphMagiButton and ClickMorphMagiButton.API then
        print("|cffccccccRedirecting to new MagiButton system...|r")
        ClickMorphMagiButton.API.Show()
    else
        print("|cffff6666Old Magic Reset Button disabled - use /cmbutton show|r")
    end
end

-- Sobrescrever a função antiga de esconder o botão  
local function HideMagicResetButton()
    -- NÃO fazer nada - o novo MagiButton.lua cuida disso
    if ClickMorphMagiButton and ClickMorphMagiButton.API then
        ClickMorphMagiButton.API.Hide()
    else
        print("|cffff6666Old Magic Reset Button disabled - use /cmbutton hide|r")
    end
end

-- Prevenir que as funções antigas sejam chamadas
if ClickMorphCommands then
    ClickMorphCommands.CreateMagicResetButton = CreateMagicResetButton
    ClickMorphCommands.HideMagicResetButton = HideMagicResetButton
end

-- ========================================
-- RESTO DO COMMANDS.LUA ORIGINAL CONTINUA AQUI...
-- Apenas REMOVA as funções CreateMagicResetButton() e HideMagicResetButton() 
-- do Commands.lua original e substitua por este patch
-- ========================================


-- Configurações do addon
ClickMorphCommands.config = {
    enableSounds = true,
    showWarnings = true,
    autoClose = false, -- Mudei para false para melhor UX
    silentMode = false,
    magicReset = false,
    compactMode = false, -- Nova opção
    windowWidth = 420,   -- Tamanho da janela
    windowHeight = 380
}

-- Informações do sistema
ClickMorphCommands.systemInfo = {
    build = "Retail Remaster",
    iMorphDetected = false,
    apiStatus = "Unknown"
}

-- Carregar configurações
local function LoadConfig()
    if ClickMorphDB and ClickMorphDB.commands then
        for key, value in pairs(ClickMorphDB.commands) do
            ClickMorphCommands.config[key] = value
        end
    end
end

-- Salvar configurações
local function SaveConfig()
    if not ClickMorphDB then
        ClickMorphDB = {}
    end
    ClickMorphDB.commands = ClickMorphCommands.config
end

-- Verificar status do sistema
local function CheckSystemStatus()
    -- Verificar iMorph
    if GetClickMorph and GetClickMorph() then
        ClickMorphCommands.systemInfo.iMorphDetected = true
        ClickMorphCommands.systemInfo.apiStatus = "Active"
    elseif IMorphInfo then
        ClickMorphCommands.systemInfo.iMorphDetected = true
        ClickMorphCommands.systemInfo.apiStatus = "Ready"
    else
        ClickMorphCommands.systemInfo.iMorphDetected = false
        ClickMorphCommands.systemInfo.apiStatus = "Not Found"
    end
end

-- Frame principal do menu
local commandFrame = nil

local function CreateCommandFrame()
    if commandFrame then 
        commandFrame:Show()
        return commandFrame 
    end
    
    CheckSystemStatus() -- Atualizar status
    
    commandFrame = CreateFrame("Frame", "ClickMorphCommandFrame", UIParent, "PortraitFrameTemplate")
    commandFrame:SetSize(ClickMorphCommands.config.windowWidth, ClickMorphCommands.config.windowHeight)
    commandFrame:SetPoint("CENTER", UIParent, "CENTER")
    commandFrame:SetMovable(true)
    commandFrame:SetResizable(true)
    commandFrame:EnableMouse(true)
    commandFrame:RegisterForDrag("LeftButton")
    commandFrame:SetScript("OnDragStart", commandFrame.StartMoving)
    commandFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Salvar tamanho quando parar de redimensionar
        ClickMorphCommands.config.windowWidth = self:GetWidth()
        ClickMorphCommands.config.windowHeight = self:GetHeight()
        SaveConfig()
    end)
    
    -- Adicionar resize grip
    local resizeGrip = CreateFrame("Button", nil, commandFrame)
    resizeGrip:SetSize(20, 20)
    resizeGrip:SetPoint("BOTTOMRIGHT", commandFrame, "BOTTOMRIGHT", -5, 5)
    resizeGrip:EnableMouse(true)
    resizeGrip:RegisterForDrag("LeftButton")
    resizeGrip:SetScript("OnDragStart", function()
        commandFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnDragStop", function()
        commandFrame:StopMovingOrSizing()
        -- Salvar novo tamanho
        ClickMorphCommands.config.windowWidth = commandFrame:GetWidth()
        ClickMorphCommands.config.windowHeight = commandFrame:GetHeight()
        SaveConfig()
    end)
    
    -- Textura visual do resize grip
    local resizeTexture = resizeGrip:CreateTexture(nil, "ARTWORK")
    resizeTexture:SetAllPoints()
    resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    
    commandFrame:SetTitle("ClickMorph Retail Remaster")
    commandFrame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    commandFrame.CloseButton:SetScript("OnClick", function()
        commandFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
    end)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, commandFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", commandFrame, "TOPLEFT", 20, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", commandFrame, "BOTTOMRIGHT", -40, 40)
    
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(contentFrame)
    
    -- Função para atualizar tamanho do conteúdo baseado na janela
    local function UpdateContentSize()
        local width = scrollFrame:GetWidth() - 20
        contentFrame:SetSize(width, 600)
    end
    
    -- Atualizar quando a janela for redimensionada
    commandFrame:SetScript("OnSizeChanged", UpdateContentSize)
    UpdateContentSize() -- Chamar uma vez para configurar inicial
    
    local yOffset = -10
    
    -- Status do Sistema
    local statusHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    statusHeader:SetText("System Status")
    statusHeader:SetTextColor(1, 0.8, 0)
    yOffset = yOffset - 25
    
    local statusText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
    local statusColor = ClickMorphCommands.systemInfo.iMorphDetected and "|cff00ff00" or "|cffff0000"
    statusText:SetText(statusColor .. "iMorph: " .. ClickMorphCommands.systemInfo.apiStatus .. "|r")
    yOffset = yOffset - 20
    
    local buildText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
    buildText:SetText("|cff888888FlyHigh old ClickMorph|r")
    yOffset = yOffset - 30
    
    -- Seção Principal
    local mainHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    mainHeader:SetText("Main Functions")
    mainHeader:SetTextColor(1, 0.8, 0)
    yOffset = yOffset - 30
    
    -- Função auxiliar para criar botões responsivos
    local function CreateResponsiveButton(parent, yPos, text, tooltip, onClick)
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yPos)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yPos)
        btn:SetHeight(35)
        btn:SetText(text)
        btn.tooltipText = tooltip
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1)
            GameTooltip:AddLine(self.tooltipText, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end
    
    -- Botão Show All
    CreateResponsiveButton(contentFrame, yOffset, "Unlock All Wardrobe & Mounts", 
        "Loads ALL transmog appearances and mounts\n|cffff8800Warning:|r May cause temporary lag",
        function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
                ClickMorphShowAll.ShowConfirmation()
                if ClickMorphCommands.config.autoClose then
                    commandFrame:Hide()
                end
            else
                print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
            end
        end)
    yOffset = yOffset - 45
    
    -- Botão Reset
    CreateResponsiveButton(contentFrame, yOffset, "Reset All Appearance",
        "Resets your current transmog to original gear\nWorks with iMorph integration",
        function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            ClickMorphCommands.ExecuteReset()
            if ClickMorphCommands.config.autoClose then
                commandFrame:Hide()
            end
        end)
    yOffset = yOffset - 45
    
    -- Botão Revert APIs
    CreateResponsiveButton(contentFrame, yOffset, "Restore Original APIs",
        "Reverts ShowAll changes back to Blizzard defaults\nUse if experiencing issues",
        function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            if ClickMorphShowAll and ClickMorphShowAll.RevertAPIs then
                ClickMorphShowAll.RevertAPIs()
                print("|cff00ff00ClickMorph:|r APIs restored to original state")
            else
                print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
            end
            if ClickMorphCommands.config.autoClose then
                commandFrame:Hide()
            end
        end)
    yOffset = yOffset - 55
    
    -- Seção de Ferramentas
    local toolsHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toolsHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    toolsHeader:SetText("Tools & Features")
    toolsHeader:SetTextColor(1, 0.8, 0)
    yOffset = yOffset - 30
    
    -- Botão SaveHub
    CreateResponsiveButton(contentFrame, yOffset, "SaveHub - Morph Presets",
        "Save and load your favorite transmog combinations\nQuick access to morph presets",
        function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            if ClickMorphSaveHub and ClickMorphSaveHub.ShowMenu then
                ClickMorphSaveHub.ShowMenu()
            else
                print("|cffff0000ClickMorph:|r SaveHub system not loaded!")
            end
        end)
    yOffset = yOffset - 45
    
    -- Botão Debug
    CreateResponsiveButton(contentFrame, yOffset, "System Debug & Info",
        "Check system status and debug information\nUseful for troubleshooting",
        function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            ClickMorphCommands.ShowDebugInfo()
        end)
    yOffset = yOffset - 55
    
    -- Botão Settings
    CreateResponsiveButton(contentFrame, yOffset, "Settings & Configuration",
        "Configure addon behavior and preferences",
        function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            commandFrame:Hide()
            C_Timer.After(0.1, function()
                ClickMorphCommands.ShowSettings()
            end)
        end)
    
    return commandFrame
end

-- Função de Reset melhorada
function ClickMorphCommands.ExecuteReset()
    local success = false
    
    if ResetIds then
        ResetIds()
        success = true
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r Reset executed via ResetIds()")
        end
    elseif GetClickMorph and GetClickMorph() then
        -- Tentar usar API do iMorph moderno
        if iMorphChatHandler then
            iMorphChatHandler(".reset")
            success = true
            if not ClickMorphCommands.config.silentMode then
                print("|cff00ff00ClickMorph:|r Reset via iMorph chat handler")
            end
        end
    end
    
    if not success then
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

-- Função de debug melhorada
function ClickMorphCommands.ShowDebugInfo()
    CheckSystemStatus()
    
    print("|cff00ff00=== ClickMorph Debug Info ===|r")
    print("|cffffcc00Build:|r " .. ClickMorphCommands.systemInfo.build)
    print("|cffffcc00WoW Build:|r " .. (GetBuildInfo() or "Unknown"))
    print("|cffffcc00iMorph Status:|r " .. (ClickMorphCommands.systemInfo.iMorphDetected and "|cff00ff00Detected|r" or "|cffff0000Not Found|r"))
    print("|cffffcc00API Status:|r " .. ClickMorphCommands.systemInfo.apiStatus)
    
    -- Verificar componentes
    local components = {
        {"ClickMorphShowAll", ClickMorphShowAll ~= nil},
        {"ClickMorphSaveHub", ClickMorphSaveHub ~= nil},
        {"ClickMorphMagiButton", ClickMorphMagiButton ~= nil},
        {"GetClickMorph", GetClickMorph ~= nil},
        {"IMorphInfo", IMorphInfo ~= nil},
        {"ResetIds", ResetIds ~= nil}
    }
    
    print("|cffffcc00Components:|r")
    for _, comp in ipairs(components) do
        local status = comp[2] and "|cff00ff00✓|r" or "|cffff0000✗|r"
        print("  " .. status .. " " .. comp[1])
    end
    
    print("|cffffcc00Settings:|r")
    for key, value in pairs(ClickMorphCommands.config) do
        print("  " .. key .. ": " .. tostring(value))
    end
end


-- Painel de configurações melhorado
function ClickMorphCommands.ShowSettings()
    local existingFrame = _G["ClickMorphSettingsFrame"]
    if existingFrame then
        existingFrame:Show()
        return
    end
    
    local settingsFrame = CreateFrame("Frame", "ClickMorphSettingsFrame", UIParent, "PortraitFrameTemplate")
    settingsFrame:SetSize(400, 380)
    settingsFrame:SetPoint("CENTER", UIParent, "CENTER")
    settingsFrame:SetTitle("ClickMorph Settings")
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    settingsFrame:SetScript("OnHide", function(self)
        C_Timer.After(0.1, function()
            if commandFrame then
                commandFrame:Show()
            end
        end)
    end)
    
    local yPos = -80
    
    -- Título da seção
    local uiHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    uiHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    uiHeader:SetText("User Interface")
    uiHeader:SetTextColor(1, 0.8, 0)
    yPos = yPos - 30
    
    -- Checkboxes de configuração
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
    yPos = yPos - 30
    
    local autoCloseCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    autoCloseCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    autoCloseCheck.Text:SetText("Auto-close menu after actions")
    autoCloseCheck:SetChecked(ClickMorphCommands.config.autoClose)
    autoCloseCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.autoClose = self:GetChecked()
        SaveConfig()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    yPos = yPos - 30
    
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
    yPos = yPos - 40
    
    -- Seção de ferramentas
    local toolsHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toolsHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    toolsHeader:SetText("Tools")
    toolsHeader:SetTextColor(1, 0.8, 0)
    yPos = yPos - 30
    
    local magicResetCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    magicResetCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, yPos)
    magicResetCheck.Text:SetText("Magic Reset Button (draggable screen button)")
    magicResetCheck:SetChecked(ClickMorphCommands.config.magicReset)
    magicResetCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.magicReset = self:GetChecked()
        SaveConfig()
        if self:GetChecked() then
            ClickMorphCommands.CreateMagicResetButton()
        else
            ClickMorphCommands.HideMagicResetButton()
        end
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    settingsFrame.CloseButton:SetScript("OnClick", function()
        settingsFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
    end)
    
    settingsFrame:Show()
end

-- Comandos slash principais
SLASH_CLICKMORPH1 = "/cm"
SLASH_CLICKMORPH2 = "/clickmorph"

SlashCmdList["CLICKMORPH"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = string.lower(args[1] or "")
    
    if command == "" or command == "menu" then
        CreateCommandFrame()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
        
    elseif command == "reset" then
        ClickMorphCommands.ExecuteReset()
        
    elseif command == "showall" then
        if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
            ClickMorphShowAll.ShowConfirmation()
        else
            print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
        end
        
    elseif command == "revert" then
        if ClickMorphShowAll and ClickMorphShowAll.RevertAPIs then
            ClickMorphShowAll.RevertAPIs()
            print("|cff00ff00ClickMorph:|r APIs restored to original state")
        else
            print("|cffff0000ClickMorph:|r ShowAll system not loaded!")
        end
        
    elseif command == "debug" then
        ClickMorphCommands.ShowDebugInfo()
        
    elseif command == "settings" then
        ClickMorphCommands.ShowSettings()
        
    else
        print("|cff00ff00ClickMorph Retail Remaster|r - Available commands:")
        print("|cffffcc00/cm|r - Show main menu")
        print("|cffffcc00/cm reset|r - Reset appearance")
        print("|cffffcc00/cm showall|r - Unlock all transmog/mounts")
        print("|cffffcc00/cm revert|r - Restore original APIs")
        print("|cffffcc00/cm debug|r - Show debug information")
        print("|cffffcc00/cm settings|r - Open settings panel")
    end
end

-- Inicialização do addon
local function OnAddonLoaded()
    LoadConfig()
    CheckSystemStatus()
    
    if ClickMorphCommands.config.magicReset then
        ClickMorphCommands.CreateMagicResetButton()
    end
    
    print("|cff00ff00ClickMorph Retail Remaster|r loaded! Type |cffffcc00/cm|r for menu.")
end

-- Registrar evento de carregamento
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        OnAddonLoaded()
    end
end)