-- ClickMorph Command System
-- Sistema de comandos integrado com UI nativa do WoW

ClickMorphCommands = {} -- Remover 'local' para tornar global

-- Configurações do addon (serão salvas automaticamente)
ClickMorphCommands.config = {
    enableSounds = true,
    showWarnings = true,
    autoClose = true,
    silentMode = false,
    magicReset = false
}

-- Carregar configurações salvas
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

-- Função para criar o frame principal estilo Blizzard
local function CreateCommandFrame()
    if commandFrame then return commandFrame end
    
    -- Frame principal usando template nativo
    commandFrame = CreateFrame("Frame", "ClickMorphCommandFrame", UIParent, "PortraitFrameTemplate")
    commandFrame:SetSize(400, 300)
    commandFrame:SetPoint("CENTER", UIParent, "CENTER")
    commandFrame:SetMovable(true)
    commandFrame:EnableMouse(true)
    commandFrame:RegisterForDrag("LeftButton")
    commandFrame:SetScript("OnDragStart", commandFrame.StartMoving)
    commandFrame:SetScript("OnDragStop", commandFrame.StopMovingOrSizing)
    
    -- Título no estilo Blizzard
    commandFrame:SetTitle("ClickMorph")
    
    -- Ícone do portrait (temática goblin/engenhoca)
    commandFrame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    -- Botão de fechar
    commandFrame.CloseButton:SetScript("OnClick", function()
        commandFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
    end)
    
    -- Container para os botões
    local buttonContainer = CreateFrame("Frame", nil, commandFrame)
    buttonContainer:SetPoint("TOPLEFT", commandFrame, "TOPLEFT", 20, -70)
    buttonContainer:SetPoint("BOTTOMRIGHT", commandFrame, "BOTTOMRIGHT", -20, 40)
    
    -- Botão 1: Show All Items
    local showAllBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    showAllBtn:SetSize(340, 35)
    showAllBtn:SetPoint("TOP", buttonContainer, "TOP", 0, -20)
    showAllBtn:SetText("Show All Wardrobe & Mounts")
    showAllBtn.tooltipText = "Loads ALL transmog appearances and mounts (may cause temporary lag)"
    showAllBtn:SetScript("OnClick", function()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        ClickMorphCommands.ShowAllConfirmation()
    end)
    showAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showAllBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Botão 2: Reset Appearance (oculto se Magic Reset estiver ativo)
    local resetBtn
    if not ClickMorphCommands.config.magicReset then
        resetBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
        resetBtn:SetSize(340, 35)
        resetBtn:SetPoint("TOP", showAllBtn, "BOTTOM", 0, -15)
        resetBtn:SetText("Reset Appearance")
        resetBtn.tooltipText = "Resets your current transmog to original gear (iMorph reset)"
        resetBtn:SetScript("OnClick", function()
            if ClickMorphCommands.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            -- Usar exatamente a mesma lógica do comando /cm reset que funciona
            if ResetIds then
                ResetIds()
                if not ClickMorphCommands.config.silentMode then
                    print("|cff00ff00ClickMorph:|r iMorph reset executed directly!")
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
    
    -- Botão 3: Settings (ajustar posição baseado se Reset está visível)
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
        -- Fechar o menu principal IMEDIATAMENTE
        commandFrame:Hide()
        -- Aguardar um frame antes de abrir settings
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
    
    -- Versão do addon (rodapé)
    local versionText = buttonContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOM", buttonContainer, "BOTTOM", 0, 10)
    versionText:SetText("|cff888888ClickMorph RR - Retail Remaster|r")
    
    return commandFrame
end

-- Popup de confirmação para Show All (estilo Blizzard)
function ClickMorphCommands.ShowAllConfirmation()
    StaticPopup_Show("CLICKMORPH_SHOWALL_CONFIRM")
end

StaticPopupDialogs["CLICKMORPH_SHOWALL_CONFIRM"] = {
    text = "This will load ALL transmog appearances and mounts available in the game.\n\n|cffff6b6bWarning:|r This may cause temporary lag while loading.\n\nContinue?",
    button1 = "Load All Items",
    button2 = "Cancel",
    OnAccept = function()
        print("|cff00ff00ClickMorph:|r Loading all items... Please wait.")
        ClickMorphCommands.LoadAllItems()
        if commandFrame then commandFrame:Hide() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3, -- Prioridade alta
}

-- Função principal para carregar todos os itens - versão que modifica as APIs
function ClickMorphCommands.LoadAllItems()
    -- Criar barra de progresso
    local progressFrame = CreateFrame("Frame", "ClickMorphProgressFrame", UIParent, "BasicFrameTemplateWithInset")
    progressFrame:SetSize(400, 100)
    progressFrame:SetPoint("CENTER", UIParent, "CENTER")
    
    local titleText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("TOP", progressFrame, "TOP", 0, -20)
    titleText:SetText("Loading All Items...")
    
    local statusBar = CreateFrame("StatusBar", nil, progressFrame)
    statusBar:SetSize(360, 20)
    statusBar:SetPoint("CENTER", progressFrame, "CENTER", 0, -10)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetStatusBarColor(0.2, 0.8, 0.2)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(0)
    
    local progressText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER", statusBar, "CENTER")
    progressText:SetText("0%")
    
    progressFrame:Show()
    
    -- Implementação que realmente modifica as APIs do jogo
    local progress = 0
    local progressTimer
    progressTimer = C_Timer.NewTicker(0.1, function()
        progress = progress + 2
        statusBar:SetValue(progress)
        progressText:SetText(progress .. "%")
        
        -- Processar em etapas
        if progress == 30 then
            titleText:SetText("Hooking Transmog APIs...")
            ClickMorphCommands.HookTransmogAPIs()
        elseif progress == 60 then
            titleText:SetText("Hooking Mount APIs...")
            ClickMorphCommands.HookMountAPIs()
        elseif progress == 90 then
            titleText:SetText("Updating Collection UI...")
            ClickMorphCommands.ForceUIRefresh()
        elseif progress >= 100 then
            if progressTimer then
                progressTimer:Cancel()
                progressTimer = nil
            end
            progressFrame:Hide()
            if not ClickMorphCommands.config.silentMode then
                print("|cff00ff00ClickMorph:|r All items unlocked! Check your collections.")
            end
        end
    end)
end

-- Hook das APIs de Transmog para forçar tudo como coletado
function ClickMorphCommands.HookTransmogAPIs()
    -- Salvar APIs originais
    if not ClickMorphCommands.originalAPIs then
        ClickMorphCommands.originalAPIs = {
            GetAllAppearanceSources = C_TransmogCollection.GetAllAppearanceSources,
            GetAppearanceSources = C_TransmogCollection.GetAppearanceSources,
        }
    end
    
    -- Substituir API para retornar tudo como coletado
    C_TransmogCollection.GetAllAppearanceSources = function(visualID)
        local sources = ClickMorphCommands.originalAPIs.GetAllAppearanceSources(visualID)
        if sources then
            for _, source in pairs(sources) do
                source.isCollected = true
                source.isUsable = true
            end
        end
        return sources
    end
    
    C_TransmogCollection.GetAppearanceSources = function(visualID)
        local sources = ClickMorphCommands.originalAPIs.GetAppearanceSources(visualID)
        if sources then
            for _, source in pairs(sources) do
                source.isCollected = true
                source.isUsable = true
            end
        end
        return sources
    end
    
    if not ClickMorphCommands.config.silentMode then
        print("|cff00ff00ClickMorph:|r Transmog APIs hooked")
    end
end

-- Hook das APIs de Mount para forçar tudo como coletado
function ClickMorphCommands.HookMountAPIs()
    -- Salvar API original
    if not ClickMorphCommands.originalAPIs then
        ClickMorphCommands.originalAPIs = {}
    end
    
    if not ClickMorphCommands.originalAPIs.GetMountInfoByID then
        ClickMorphCommands.originalAPIs.GetMountInfoByID = C_MountJournal.GetMountInfoByID
    end
    
    -- Substituir API para retornar tudo como coletado - MAIS SELETIVO
    C_MountJournal.GetMountInfoByID = function(mountID)
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, isFiltered, isCollected = ClickMorphCommands.originalAPIs.GetMountInfoByID(mountID)
        
        if name then
            -- Se já estava coletado, manter como estava
            if isCollected then
                return name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, isFiltered, isCollected
            else
                -- Se não estava coletado, forçar como coletado e usável
                return name, spellID, icon, isActive, true, sourceType, isFavorite, isFactionSpecific, false, true
            end
        end
        
        return name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, isFiltered, isCollected
    end
    
    if not ClickMorphCommands.config.silentMode then
        print("|cff00ff00ClickMorph:|r Mount APIs hooked")
    end
end

-- Forçar refresh das UIs de coleção
function ClickMorphCommands.ForceUIRefresh()
    -- Forçar reload das coleções
    if WardrobeCollectionFrame then
        local itemsFrame = WardrobeCollectionFrame.ItemsCollectionFrame
        if itemsFrame then
            pcall(function()
                itemsFrame:RefreshVisualsList()
                itemsFrame:UpdateItems()
            end)
        end
    end
    
    if MountJournal then
        pcall(function()
            if MountJournal_UpdateMountList then
                MountJournal_UpdateMountList()
            end
        end)
    end
    
    if not ClickMorphCommands.config.silentMode then
        print("|cff00ff00ClickMorph:|r UI refreshed")
    end
end

-- Reverter APIs para o estado original
function ClickMorphCommands.RevertAPIs()
    if ClickMorphCommands.originalAPIs then
        -- Restaurar APIs de transmog
        if ClickMorphCommands.originalAPIs.GetAllAppearanceSources then
            C_TransmogCollection.GetAllAppearanceSources = ClickMorphCommands.originalAPIs.GetAllAppearanceSources
        end
        if ClickMorphCommands.originalAPIs.GetAppearanceSources then
            C_TransmogCollection.GetAppearanceSources = ClickMorphCommands.originalAPIs.GetAppearanceSources
        end
        
        -- Restaurar APIs de mount
        if ClickMorphCommands.originalAPIs.GetMountInfoByID then
            C_MountJournal.GetMountInfoByID = ClickMorphCommands.originalAPIs.GetMountInfoByID
        end
        
        -- Limpar referências
        ClickMorphCommands.originalAPIs = nil
        
        -- Forçar refresh das UIs
        ClickMorphCommands.ForceUIRefresh()
        
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r All APIs restored to original state")
        end
    else
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r No modified APIs to revert")
        end
    end
end

-- Carregar todas as aparências de transmog
function ClickMorphCommands.LoadAllTransmogAppearances()
    -- Usar APIs modernas do WoW 11.x
    local maxSourceID = 120000 -- Atualizado para WoW 11.x
    local loadedSources = {}
    
    for i = 1, maxSourceID do
        if i % 1000 == 0 then
            -- Yield a cada 1000 iterações para evitar freeze
            coroutine.yield()
        end
        
        local sourceInfo = C_TransmogCollection.GetSourceInfo(i)
        if sourceInfo and sourceInfo.visualID then
            loadedSources[sourceInfo.visualID] = sourceInfo
        end
    end
    
    -- Processar ilusões de arma (enchants) usando API atual
    local illusions = C_TransmogCollection.GetIllusions()
    for _, illusion in pairs(illusions) do
        if illusion.visualID then
            loadedSources[illusion.visualID] = illusion
        end
    end
    
    return loadedSources
end

-- Carregar todas as montarias
function ClickMorphCommands.LoadAllMounts()
    local allMountIDs = C_MountJournal.GetMountIDs()
    local loadedMounts = {}
    
    for _, mountID in pairs(allMountIDs) do
        local mountInfo = {C_MountJournal.GetMountInfoByID(mountID)}
        if mountInfo[1] then -- Nome existe
            loadedMounts[mountID] = {
                name = mountInfo[1],
                spellID = mountInfo[2],
                icon = mountInfo[3],
                isActive = mountInfo[4],
                isUsable = true, -- Forçar como usável
                sourceType = mountInfo[6],
                isFavorite = mountInfo[7],
                isFactionSpecific = mountInfo[8],
                isFiltered = mountInfo[9],
                isCollected = true, -- Forçar como coletado
                mountID = mountID
            }
        end
    end
    
    return loadedMounts
end

-- Sistema Magic Reset Button
local magicResetButton = nil
local lastMorphState = {}
local lastClickTime = 0 -- Proteção contra spam

-- Criar o botão Magic Reset na tela
function ClickMorphCommands.CreateMagicResetButton()
    if magicResetButton then return end
    
    magicResetButton = CreateFrame("Button", "ClickMorphMagicResetButton", UIParent)
    magicResetButton:SetSize(32, 32)
    magicResetButton:SetPoint("CENTER", UIParent, "CENTER", -200, -100) -- Posição inicial
    magicResetButton:SetMovable(true)
    magicResetButton:EnableMouse(true)
    magicResetButton:RegisterForDrag("LeftButton")
    
    -- Ícone do botão (usando mesmo ícone do menu)
    local icon = magicResetButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    -- Border highlight
    local highlight = magicResetButton:CreateTexture(nil, "HIGHLIGHT") 
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    
    -- Estado visual (normal vs com morph salvo)
    local function UpdateButtonState()
        if next(lastMorphState) then
            -- Tem morph salvo - ícone brilhante
            icon:SetVertexColor(1, 1, 0.5) -- Dourado
            magicResetButton.tooltipText = "Click: Reset morph | Shift+Click: Re-apply saved morph"
        else
            -- Sem morph - ícone normal
            icon:SetVertexColor(1, 1, 1) -- Normal
            magicResetButton.tooltipText = "Click: Reset morph"
        end
    end
    
    -- Scripts do botão
    magicResetButton:SetScript("OnDragStart", magicResetButton.StartMoving)
    magicResetButton:SetScript("OnDragStop", magicResetButton.StopMovingOrSizing)
    
    magicResetButton:SetScript("OnClick", function(self, button)
        -- Proteção contra spam (máximo 1 click por segundo)
        local currentTime = GetTime()
        if currentTime - lastClickTime < 1 then
            return
        end
        lastClickTime = currentTime
        
        if button == "LeftButton" then
            if IsShiftKeyDown() and next(lastMorphState) then
                -- Shift+Click: Re-aplicar último morph
                ClickMorphCommands.ReapplyLastMorph()
            else
                -- Click normal: Reset e salvar estado atual
                ClickMorphCommands.SaveCurrentMorphState()
                ClickMorphCommands.DoReset()
            end
            UpdateButtonState()
        end
    end)
    
    magicResetButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText or "Magic Reset Button", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    
    magicResetButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    UpdateButtonState()
    magicResetButton:Show()
end

-- Esconder o botão Magic Reset
function ClickMorphCommands.HideMagicResetButton()
    if magicResetButton then
        magicResetButton:Hide()
        magicResetButton = nil
    end
end

-- Salvar estado atual do morph (implementação real)
function ClickMorphCommands.SaveCurrentMorphState()
    -- Limpar estado anterior
    wipe(lastMorphState)
    
    -- Salvar informações básicas
    lastMorphState.timestamp = time()
    
    -- TODO: Aqui vamos implementar detecção real do estado
    -- Por enquanto, só marca que tem dados para testar o visual
    lastMorphState.hasBasicMorph = true
    
    if not ClickMorphCommands.config.silentMode then
        print("|cff00ff00ClickMorph:|r Current state saved")
    end
end

-- Re-aplicar último morph (implementação real)
function ClickMorphCommands.ReapplyLastMorph()
    if not next(lastMorphState) then
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r No saved morph to restore")
        end
        return
    end
    
    if not ClickMorphCommands.config.silentMode then
        print("|cff00ff00ClickMorph:|r Morph restoration not yet implemented")
    end
    
    -- TODO: Implementar restore real do morph
    -- Por enquanto só mostra que funcionou
end

-- Executar reset
function ClickMorphCommands.DoReset()
    if ResetIds then
        ResetIds()
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r Reset executed!")
        end
    end
end

-- Painel de configurações
function ClickMorphCommands.ShowSettings()
    -- Destruir qualquer janela existente primeiro
    local existingFrame = _G["ClickMorphSettingsFrame"]
    if existingFrame then
        existingFrame:Hide()
        existingFrame:SetParent(nil)
        _G["ClickMorphSettingsFrame"] = nil
    end
    
    local settingsFrame = CreateFrame("Frame", "ClickMorphSettingsFrame", UIParent, "PortraitFrameTemplate")
    settingsFrame:SetSize(380, 320) -- Aumentado de 350x250 para 380x320
    settingsFrame:SetPoint("CENTER", UIParent, "CENTER")
    settingsFrame:SetTitle("ClickMorph Settings")
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Enggizmos_SwissArmy")
    
    -- Quando fechar settings, reabrir o menu principal
    settingsFrame:SetScript("OnHide", function(self)
        C_Timer.After(0.1, function()
            -- Reabrir o menu principal
            if commandFrame then
                commandFrame:ClearAllPoints()
                commandFrame:SetPoint("CENTER", UIParent, "CENTER")
                commandFrame:Show()
            end
        end)
    end)
    
    -- Checkbox: Enable Sounds
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
    
    -- Checkbox: Show Warnings
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
    
    -- Checkbox: Auto Close Menu
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
    
    -- Checkbox: Silent Mode
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
    
    -- Checkbox: Magic Reset Button
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
    
    -- Botão Close
    settingsFrame.CloseButton:SetScript("OnClick", function()
        settingsFrame:Hide()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        end
        -- Reabrir menu imediatamente quando clicar no X
        C_Timer.After(0.1, function()
            if commandFrame then
                commandFrame:ClearAllPoints()
                commandFrame:SetPoint("CENTER", UIParent, "CENTER")
                commandFrame:Show()
            end
        end)
    end)
    
    settingsFrame:Show()
end

-- Registrar comandos slash
SLASH_CLICKMORPH1 = "/cm"
SLASH_CLICKMORPH2 = "/clickmorph"

SlashCmdList["CLICKMORPH"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = string.lower(args[1] or "")
    
    if command == "" or command == "menu" then
        CreateCommandFrame()
        -- Sempre centralizar na tela quando chamar
        commandFrame:ClearAllPoints()
        commandFrame:SetPoint("CENTER", UIParent, "CENTER")
        commandFrame:Show()
        if ClickMorphCommands.config.enableSounds then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
        
    elseif command == "reset" then
        if ResetIds then
            ResetIds()
            if not ClickMorphCommands.config.silentMode then
                print("|cff00ff00ClickMorph:|r iMorph reset executed directly!")
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
        
    elseif command == "showall" then
        ClickMorphCommands.ShowAllConfirmation()
        
    elseif command == "revert" then
        ClickMorphCommands.RevertAPIs()
        if not ClickMorphCommands.config.silentMode then
            print("|cff00ff00ClickMorph:|r APIs reverted to original state")
        end
        
    else
        print("|cff00ff00ClickMorph Commands:|r")
        print("|cffffcc00/cm|r - Show command menu")
        print("|cffffcc00/cm reset|r - Reset appearance")
        print("|cffffcc00/cm showall|r - Load all transmog/mounts")
        print("|cffffcc00/cm settings|r - Open settings")
    end
end

-- Mensagem de carregamento
local function OnAddonLoaded()
    LoadConfig() -- Carregar configurações salvas
    
    -- Inicializar Magic Reset Button se estiver habilitado
    if ClickMorphCommands.config.magicReset then
        ClickMorphCommands.CreateMagicResetButton()
    end
    
    print("|cff00ff00ClickMorph|r loaded! Type |cffffcc00/cm|r for commands.")
end

-- Registrar evento de carregamento
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        OnAddonLoaded()
    end
end)