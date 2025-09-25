-- ClickMorph MagiButton - ENHANCED VERSION
-- Botão simples: Drag=move, Right-click=menu, Alt+Click=.reset

ClickMorphMagiButton = {}

-- Config
ClickMorphMagiButton.config = {
    visible = false,
    position = { x = 0, y = 0 },
    enableSounds = true  -- Nova opção para sons
}

-- Save/Load
local function SaveConfig()
    ClickMorphMagiButtonSV = ClickMorphMagiButtonSV or {}
    ClickMorphMagiButtonSV = CopyTable(ClickMorphMagiButton.config)
end

local function LoadConfig()
    if ClickMorphMagiButtonSV then
        for k, v in pairs(ClickMorphMagiButtonSV) do
            ClickMorphMagiButton.config[k] = v
        end
    end
end

-- Função para executar .reset no editbox
local function ExecuteResetCommand()
    local editBox = ChatFrame1EditBox or DEFAULT_CHAT_FRAME.editBox
    if editBox then
        editBox:SetText(".reset")
        editBox:SetFocus()
        ChatEdit_SendText(editBox, 0)
        print("|cff00ff00MagiButton:|r .reset executed!")
        if ClickMorphMagiButton.config.enableSounds then
            PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE)
        end
        return true
    else
        -- Fallback para SendChatMessage
        SendChatMessage(".reset", "SAY")
        print("|cff00ff00MagiButton:|r .reset sent via chat!")
        if ClickMorphMagiButton.config.enableSounds then
            PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE)
        end
        return true
    end
end

-- Criar botão
function ClickMorphMagiButton.CreateButton()
    -- Limpar botão antigo
    if ClickMorphMagiButton.button then
        ClickMorphMagiButton.button:Hide()
        ClickMorphMagiButton.button = nil
    end
    
    if _G["ClickMorphMagiButtonFrame"] then
        _G["ClickMorphMagiButtonFrame"]:Hide()
        _G["ClickMorphMagiButtonFrame"] = nil
    end
    
    print("|cffff00ffMagiButton:|r Creating button...")
    
    -- Botão base
    local button = CreateFrame("Button", "ClickMorphMagiButtonFrame", UIParent, "UIPanelButtonTemplate")
    button:SetSize(40, 40)
    button:SetPoint("CENTER", UIParent, "CENTER", 
                   ClickMorphMagiButton.config.position.x, 
                   ClickMorphMagiButton.config.position.y)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(100)
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.isDragging = false
    
    -- Limpar texturas padrão do template
    button:SetNormalTexture("")
    button:SetPushedTexture("")
    button:SetDisabledTexture("")
    
    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(36, 36)
    bg:SetPoint("CENTER")
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    
    -- Ícone
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\Spell_Nature_Polymorph")
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(40, 40)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.3)
    
    -- Fallback do ícone
    C_Timer.After(0.2, function()
        if not icon:GetTexture() then
            icon:SetTexture("Interface\\Icons\\Trade_Engineering")
            C_Timer.After(0.1, function()
                if not icon:GetTexture() then
                    icon:SetColorTexture(0.4, 0.2, 0.7, 1.0)
                end
            end)
        end
    end)
    
    -- Salvar referências
    button.bg = bg
    button.icon = icon
    
    -- Drag
    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:StartMoving()
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local screenWidth, screenHeight = UIParent:GetSize()
        ClickMorphMagiButton.config.position.x = x - (screenWidth/2)
        ClickMorphMagiButton.config.position.y = y - (screenHeight/2)
        SaveConfig()
        C_Timer.After(0.2, function()
            self.isDragging = false
        end)
    end)
    
    -- Efeitos visuais
    button:SetScript("OnMouseDown", function(self, buttonPressed)
        if not self.isDragging then
            if buttonPressed == "RightButton" then
                self.icon:SetPoint("CENTER", 1, -1)
            elseif buttonPressed == "LeftButton" and IsAltKeyDown() then
                self.icon:SetPoint("CENTER", 1, -1)
            end
        end
    end)
    
    button:SetScript("OnMouseUp", function(self, buttonPressed)
        if buttonPressed == "RightButton" or (buttonPressed == "LeftButton" and IsAltKeyDown()) then
            self.icon:SetPoint("CENTER", 0, 0)
            if not self.isDragging then
                self:GetScript("OnClick")(self, buttonPressed)
            end
        end
    end)
    
    -- Click handler
    button:SetScript("OnClick", function(self, buttonPressed)
        if self.isDragging then
            return
        end
        
        if buttonPressed == "RightButton" then
            print("|cff00ff00MagiButton:|r Opening menu...")
            local chatFrame = DEFAULT_CHAT_FRAME.editBox or ChatFrame1EditBox
            if chatFrame then
                chatFrame:SetText("/cm")
                ChatEdit_SendText(chatFrame, 0)
            else
                SendChatMessage("/cm", "SAY")
            end
            if ClickMorphMagiButton.config.enableSounds then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
            end
            
        elseif buttonPressed == "LeftButton" and IsAltKeyDown() then
            print("|cff00ff00MagiButton:|r Alt+Click detected, executing .reset...")
            ExecuteResetCommand()
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("ClickMorph MagiButton", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Open ClickMorph menu", 1, 1, 1)
        GameTooltip:AddLine("|cffff9900Alt+Click:|r Execute .reset command", 1, 1, 1)
        GameTooltip:AddLine("|cffccccccDrag:|r Move button", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    ClickMorphMagiButton.button = button
    print("|cff00ff00MagiButton:|r Button created with Alt+Click support!")
    return button
end

-- API
ClickMorphMagiButton.API = {
    Show = function()
        if not ClickMorphMagiButton.button then
            ClickMorphMagiButton.CreateButton()
        end
        if ClickMorphMagiButton.button then
            ClickMorphMagiButton.button:Show()
            ClickMorphMagiButton.config.visible = true
            SaveConfig()
            print("|cff00ff00MagiButton:|r Button shown!")
        end
    end,
    
    Hide = function()
        if ClickMorphMagiButton.button then
            ClickMorphMagiButton.button:Hide()
            ClickMorphMagiButton.config.visible = false
            SaveConfig()
            print("|cff00ff00MagiButton:|r Button hidden")
        end
    end,
    
    Toggle = function()
        if ClickMorphMagiButton.config.visible then
            ClickMorphMagiButton.API.Hide()
        else
            ClickMorphMagiButton.API.Show()
        end
    end,
    
    IsVisible = function()
        return ClickMorphMagiButton.config.visible and 
               ClickMorphMagiButton.button and 
               ClickMorphMagiButton.button:IsShown()
    end,
    
    -- Nova função para testar o .reset
    TestReset = function()
        print("|cffff00ffMagiButton:|r Testing .reset command...")
        return ExecuteResetCommand()
    end,
    
    -- Função para toggle de sons
    ToggleSounds = function()
        ClickMorphMagiButton.config.enableSounds = not ClickMorphMagiButton.config.enableSounds
        SaveConfig()
        local status = ClickMorphMagiButton.config.enableSounds and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
        print("|cff00ff00MagiButton:|r Sounds " .. status)
        return ClickMorphMagiButton.config.enableSounds
    end,
    
    -- Função para definir estado dos sons
    SetSounds = function(enabled)
        ClickMorphMagiButton.config.enableSounds = enabled
        SaveConfig()
        local status = enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
        print("|cff00ff00MagiButton:|r Sounds " .. status)
    end,
    
    -- Função para sincronizar com sistema global de settings
    SyncWithGlobalSettings = function()
        if ClickMorphCommands and ClickMorphCommands.config then
            -- Sincronizar visibilidade
            ClickMorphCommands.config.magiButtonEnabled = ClickMorphMagiButton.config.visible
            
            -- Sincronizar sons
            ClickMorphCommands.config.magiButtonSounds = ClickMorphMagiButton.config.enableSounds
            
            -- Salvar configurações globais se existir função
            if SaveConfig then
                SaveConfig()
            end
        end
    end,
    
    -- Função chamada pelo sistema de settings
    OnGlobalToggle = function(enabled)
        if enabled then
            ClickMorphMagiButton.API.Show()
        else
            ClickMorphMagiButton.API.Hide()
        end
    end,
    
    -- Função chamada pelo sistema de settings para sons
    OnSoundsToggle = function(enabled)
        ClickMorphMagiButton.config.enableSounds = enabled
        SaveConfig()
    end
}

-- Slash commands
SLASH_CLICKMORPH_MAGIBUTTON1 = "/cmbutton"
SLASH_CLICKMORPH_MAGIBUTTON2 = "/magibutton"

SlashCmdList.CLICKMORPH_MAGIBUTTON = function(msg)
    local command = string.lower(msg or "")
    
    if command == "" or command == "show" then
        ClickMorphMagiButton.API.Show()
    elseif command == "hide" then
        ClickMorphMagiButton.API.Hide()
    elseif command == "toggle" then
        ClickMorphMagiButton.API.Toggle()
    elseif command == "status" then
        print("|cff00ff00=== MagiButton Status ===|r")
        print("Button exists:", ClickMorphMagiButton.button and "|cff00ff00YES|r" or "|cffff0000NO|r")
        print("Is visible:", ClickMorphMagiButton.API.IsVisible() and "|cff00ff00YES|r" or "|cffff0000NO|r")
        if ClickMorphMagiButton.button then
            local texture = ClickMorphMagiButton.button.icon
            print("Icon loaded:", texture and texture:GetTexture() and "|cff00ff00YES|r" or "|cffffcc00NO|r")
            if texture and texture:GetTexture() then
                print("Icon path:", texture:GetTexture())
            end
        end
        print("Alt+Click support:", "|cff00ff00ENABLED|r")
    elseif command == "position" then
        if ClickMorphMagiButton.button then
            local x, y = ClickMorphMagiButton.button:GetCenter()
            print("|cff00ff00Button position:|r", string.format("%.1f, %.1f", x or 0, y or 0))
            print("Saved position:", ClickMorphMagiButton.config.position.x, ClickMorphMagiButton.config.position.y)
        else
            print("No button to check position")
        end
    elseif command == "center" then
        if ClickMorphMagiButton.button then
            ClickMorphMagiButton.config.position.x = 0
            ClickMorphMagiButton.config.position.y = 0
            ClickMorphMagiButton.button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            SaveConfig()
            print("|cff00ff00MagiButton:|r Moved to center")
        else
            print("No button to center")
        end
    elseif command == "testreset" then
        ClickMorphMagiButton.API.TestReset()
    elseif command == "sound" or command == "sounds" then
        ClickMorphMagiButton.API.ToggleSounds()
    elseif command == "mute" then
        ClickMorphMagiButton.API.SetSounds(false)
    elseif command == "unmute" then
        ClickMorphMagiButton.API.SetSounds(true)
    elseif command == "testmenu" then
        print("|cffff00ffMagiButton:|r Testing menu...")
        local chatFrame = DEFAULT_CHAT_FRAME.editBox or ChatFrame1EditBox
        if chatFrame then
            chatFrame:SetText("/cm")
            ChatEdit_SendText(chatFrame, 0)
            print("✓ Menu opened")
        else
            print("✗ Chat frame not found")
        end
    else
        print("|cff00ff00MagiButton Commands:|r")
        print("/cmbutton show - Show button")
        print("/cmbutton hide - Hide button")
        print("/cmbutton toggle - Toggle visibility")
        print("/cmbutton status - Show status")
        print("/cmbutton position - Show position")
        print("/cmbutton center - Move to center")
        print("/cmbutton testreset - Test .reset command")
        print("/cmbutton sound - Toggle sounds on/off")
        print("/cmbutton mute - Disable sounds")
        print("/cmbutton unmute - Enable sounds")
        print("/cmbutton testmenu - Test menu")
        print(" ")
        print("|cffccccccDrag to move • Right-click for menu • Alt+Click for .reset|r")
    end
end

-- Inicialização
local function Initialize()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            LoadConfig()
            print("|cffff00ffMagiButton:|r Loaded with Alt+Click support")
            
            -- Integrar com sistema de configurações após pequeno delay
            C_Timer.After(0.5, function()
                ClickMorphMagiButton.IntegrateWithSettings()
            end)
            
        elseif event == "PLAYER_LOGIN" then
            if ClickMorphMagiButton.config.visible then
                C_Timer.After(2, function()
                    ClickMorphMagiButton.API.Show()
                end)
            end
        end
    end)
end

-- Função para integração com sistema de settings
function ClickMorphMagiButton.IntegrateWithSettings()
    -- Garantir que as configurações do MagiButton existem no sistema global
    if ClickMorphCommands and ClickMorphCommands.config then
        -- Inicializar campos no sistema global se não existirem
        if ClickMorphCommands.config.magiButtonEnabled == nil then
            ClickMorphCommands.config.magiButtonEnabled = ClickMorphMagiButton.config.visible
        end
        
        if ClickMorphCommands.config.magiButtonSounds == nil then
            ClickMorphCommands.config.magiButtonSounds = ClickMorphMagiButton.config.enableSounds
        end
        
        print("|cff00ff00MagiButton:|r Integrated with /cm settings menu")
    else
        -- Tentar novamente em 2 segundos
        C_Timer.After(2, function()
            ClickMorphMagiButton.IntegrateWithSettings()
        end)
    end
end

Initialize()

-- Compatibilidade
function CreateMagicResetButton()
    ClickMorphMagiButton.API.Show()
end

function HideMagicResetButton()
    ClickMorphMagiButton.API.Hide()
end

_G.ClickMorphMagiButton = ClickMorphMagiButton

print("|cff00ff00ClickMorph MagiButton|r loaded with enhanced functionality!")
print("Use |cffffcc00/cmbutton show|r to show the button")
print("|cffccccccFeatures: Drag to move • Right-click for menu • Alt+Click for .reset|r")