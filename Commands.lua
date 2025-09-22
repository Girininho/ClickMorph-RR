-- ClickMorph Command System
-- Sistema de comandos básicos integrado com UI nativa do WoW

ClickMorphCommands = {} -- Global

-- Configurações do addon
ClickMorphCommands.config = {
    enableSounds = true,
    showWarnings = true,
    autoClose = true,
    silentMode = false,
    magicReset = false
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

-- Frame principal do menu
local commandFrame = nil

local function CreateCommandFrame()
    if commandFrame then return commandFrame end
    
    commandFrame = CreateFrame("Frame", "ClickMorphCommandFrame", UIParent, "PortraitFrameTemplate")
    commandFrame:SetSize(400, 300)
    commandFrame:SetPoint("CENTER", UIParent, "CENTER")
    commandFrame:SetMovable(true)
    commandFrame:EnableMouse(true)
    commandFrame:RegisterForDrag("LeftButton")
    commandFrame:SetScript("OnDragStart", commandFrame.StartMoving)
    commandFrame:SetScript("OnDragStop", commandFrame.StopMovingOrSizing)
    
    commandFrame:SetTitle("ClickMorph")
    commandFrame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    commandFrame.CloseButton:SetScript("OnClick", function()
        commandFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
    end)
    
    local buttonContainer = CreateFrame("Frame", nil, commandFrame)
    buttonContainer:SetPoint("TOPLEFT", commandFrame, "TOPLEFT", 20, -70)
    buttonContainer:SetPoint("BOTTOMRIGHT", commandFrame, "BOTTOMRIGHT", -20, 40)
    
    -- Botão Show All Items
    local showAllBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    showAllBtn:SetSize(340, 35)
    showAllBtn:SetPoint("TOP", buttonContainer, "TOP", 0, -20)
    showAllBtn:SetText("Show All Wardrobe & Mounts")
    showAllBtn.tooltipText = "Loads ALL transmog appearances and mounts (may cause temporary lag)"
    showAllBtn:SetScript("OnClick", function()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        -- Chamar função do ShowAll.lua
        if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
            ClickMorphShowAll.ShowConfirmation()
        else
            print("|cffff0000Error:|r ShowAll system not loaded!")
        end
    end)
    showAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showAllBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Botão Reset (se Magic Reset não estiver ativo)
    local resetBtn
    if not ClickMorphCommands.config.magicReset then
        resetBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
        resetBtn:SetSize(340, 35)
        resetBtn:SetPoint("TOP", showAllBtn, "BOTTOM", 0, -15)
        resetBtn:SetText("Reset Appearance")
        resetBtn.tooltipText = "Resets your current transmog to original gear"
        resetBtn:SetScript("OnClick", function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            ClickMorphCommands.ExecuteReset()
            if ClickMorphCommands.config.autoClose then
                commandFrame:Hide()
            end
        end)
        resetBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        resetBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Botão Settings
    local settingsBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    settingsBtn:SetSize(340, 35)
    if resetBtn then
        settingsBtn:SetPoint("TOP", resetBtn, "BOTTOM", 0, -15)
    else
        settingsBtn:SetPoint("TOP", showAllBtn, "BOTTOM", 0, -15)
    end
    settingsBtn:SetText("Settings")
    settingsBtn.tooltipText = "Configure ClickMorph addon settings"
    settingsBtn:SetScript("OnClick", function()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        commandFrame:Hide()
        C_Timer.After(0.05, function()
            ClickMorphCommands.ShowSettings()
        end)
    end)
    settingsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    settingsBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Versão
    local versionText = buttonContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOM", buttonContainer, "BOTTOM", 0, 10)
    versionText:SetText("|cff888888ClickMorph RR - Retail Remaster|r")
    
    return commandFrame
end

-- Função de Reset
function ClickMorphCommands.ExecuteReset()
    if ResetIds then
        ResetIds()
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r Reset executed!")
        end
    elseif iMorphChatHandler then
        iMorphChatHandler(".reset")
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r iMorph chat handler called!")
        end
    else
        RunScript('SendChatMessage(".reset", "SAY")')
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r .reset sent via chat!")
        end
    end
end

-- Sistema Magic Reset Button
local magicResetButton = nil

function ClickMorphCommands.CreateMagicResetButton()
    if magicResetButton then return end
    
    magicResetButton = CreateFrame("Button", "ClickMorphMagicResetButton", UIParent)
    magicResetButton:SetSize(32, 32)
    magicResetButton:SetPoint("CENTER", UIParent, "CENTER", -200, -100)
    magicResetButton:SetMovable(true)
    magicResetButton:EnableMouse(true)
    magicResetButton:RegisterForDrag("LeftButton")
    
    local icon = magicResetButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    local highlight = magicResetButton:CreateTexture(nil, "HIGHLIGHT") 
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    
    magicResetButton:SetScript("OnDragStart", magicResetButton.StartMoving)
    magicResetButton:SetScript("OnDragStop", magicResetButton.StopMovingOrSizing)
    
    magicResetButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ClickMorphCommands.ExecuteReset()
        end
    end)
    
    magicResetButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Magic Reset Button\nClick to reset appearance", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    
    magicResetButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    magicResetButton:Show()
end

function ClickMorphCommands.HideMagicResetButton()
    if magicResetButton then
        magicResetButton:Hide()
        magicResetButton = nil
    end
end

-- Painel de configurações
function ClickMorphCommands.ShowSettings()
    local existingFrame = _G["ClickMorphSettingsFrame"]
    if existingFrame then
        existingFrame:Hide()
        existingFrame:SetParent(nil)
        _G["ClickMorphSettingsFrame"] = nil
    end
    
    local settingsFrame = CreateFrame("Frame", "ClickMorphSettingsFrame", UIParent, "PortraitFrameTemplate")
    settingsFrame:SetSize(380, 320)
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
                commandFrame:ClearAllPoints()
                commandFrame:SetPoint("CENTER", UIParent, "CENTER")
                commandFrame:Show()
            end
        end)
    end)
    
    -- Checkboxes de configuração
    local soundCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    soundCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 30, -80)
    soundCheck.Text:SetText("Enable UI Sounds")
    soundCheck:SetChecked(ClickMorphCommands.config.enableSounds)
    soundCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.enableSounds = self:GetChecked()
        SaveConfig()
        if self:GetChecked() then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    local warningCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    warningCheck:SetPoint("TOPLEFT", soundCheck, "BOTTOMLEFT", 0, -10)
    warningCheck.Text:SetText("Show Warning Messages")
    warningCheck:SetChecked(ClickMorphCommands.config.showWarnings)
    warningCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.showWarnings = self:GetChecked()
        SaveConfig()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    local autoCloseCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    autoCloseCheck:SetPoint("TOPLEFT", warningCheck, "BOTTOMLEFT", 0, -10)
    autoCloseCheck.Text:SetText("Auto-close menu after action")
    autoCloseCheck:SetChecked(ClickMorphCommands.config.autoClose)
    autoCloseCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.autoClose = self:GetChecked()
        SaveConfig()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    local silentCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    silentCheck:SetPoint("TOPLEFT", autoCloseCheck, "BOTTOMLEFT", 0, -10)
    silentCheck.Text:SetText("Silent mode (reduce chat messages)")
    silentCheck:SetChecked(ClickMorphCommands.config.silentMode)
    silentCheck:SetScript("OnClick", function(self)
        ClickMorphCommands.config.silentMode = self:GetChecked()
        SaveConfig()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    local magicResetCheck = CreateFrame("CheckButton", nil, settingsFrame, "InterfaceOptionsCheckButtonTemplate")
    magicResetCheck:SetPoint("TOPLEFT", silentCheck, "BOTTOMLEFT", 0, -10)
    magicResetCheck.Text:SetText("Magic Reset Button (persistent screen button)")
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
        commandFrame:ClearAllPoints()
        commandFrame:SetPoint("CENTER", UIParent, "CENTER")
        commandFrame:Show()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
        
    elseif command == "reset" then
        ClickMorphCommands.ExecuteReset()
        
    elseif command == "showall" then
        if ClickMorphShowAll and ClickMorphShowAll.ShowConfirmation then
            ClickMorphShowAll.ShowConfirmation()
        else
            print("|cffff0000Error:|r ShowAll system not loaded!")
        end
        
    elseif command == "revert" then
        if ClickMorphShowAll and ClickMorphShowAll.RevertAPIs then
            ClickMorphShowAll.RevertAPIs()
        else
            print("|cffff0000Error:|r ShowAll system not loaded!")
        end
        
    else
        print("|cff00ff00ClickMorph Commands:|r")
        print("|cffffcc00/cm|r - Show command menu")
        print("|cffffcc00/cm reset|r - Reset appearance")
        print("|cffffcc00/cm showall|r - Load all transmog/mounts")
        print("|cffffcc00/cm revert|r - Restore original APIs")
    end
end

-- Inicialização do addon
local function OnAddonLoaded()
    LoadConfig()
    
    if ClickMorphCommands.config.magicReset then
        ClickMorphCommands.CreateMagicResetButton()
    end
    
    print("|cff00ff00ClickMorph Commands|r loaded! Type |cffffcc00/cm|r for menu.")
end

-- Registrar evento de carregamento
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        OnAddonLoaded()
    end
end)