--[[ 
CustomWardrobe.lua - ClickMorph Enhanced Wardrobe
Author: Victor Nunes Leites
Description: Wardrobe system with tabs, SaveHub, ShowAll integration, account-wide support and enhanced settings.
Enhanced by Claude with visual improvements and resize functionality.
]]

ClickMorphCustomWardrobe = {}

-- ===================================================================
-- DATABASE
-- ===================================================================
ClickMorphCustomWardrobeDB = ClickMorphCustomWardrobeDB or {}
ClickMorphCustomWardrobeCharDB = ClickMorphCustomWardrobeCharDB or {}

function ClickMorphCustomWardrobe:GetAccountDB()
    if not ClickMorphCustomWardrobeDB.saveSlots then
        ClickMorphCustomWardrobeDB.saveSlots = {}
    end
    if not ClickMorphCustomWardrobeDB.config then
        ClickMorphCustomWardrobeDB.config = self:GetDefaultConfig()
    end
    return ClickMorphCustomWardrobeDB
end

function ClickMorphCustomWardrobe:GetCharDB()
    local key = UnitName("player") .. "-" .. GetRealmName()
    if not ClickMorphCustomWardrobeCharDB[key] then
        ClickMorphCustomWardrobeCharDB[key] = { saveSlots = {}, config = {} }
    end
    local db = ClickMorphCustomWardrobeCharDB[key]
    if not db.saveSlots then db.saveSlots = {} end
    if not db.config then db.config = self:GetDefaultConfig() end
    return db
end

function ClickMorphCustomWardrobe:GetActiveDB()
    if self.wardrobeSystem.config.useAccountWide then
        return self:GetAccountDB()
    else
        return self:GetCharDB()
    end
end

-- ===================================================================
-- DEFAULT CONFIG
-- ===================================================================
function ClickMorphCustomWardrobe:GetDefaultConfig()
    return {
        enableShowAll = false,
        autoEnableShowAll = false,
        magicReset = true,
        debugMode = false,
        smartDiscovery = true,
        enablePauldrons = true,
        showTooltips = true,
        chatOutput = true,
        frameWidth = 650,
        frameHeight = 500,
        frameScale = 1.0,
        useAccountWide = false
    }
end

-- ===================================================================
-- WARDROBE SYSTEM
-- ===================================================================
ClickMorphCustomWardrobe.wardrobeSystem = {
    mainFrame = nil,
    currentTab = 1,
    tabs = {},
    tabPanels = {},
    isVisible = false,
    config = {}
}

local function WardrobeDebugPrint(...)
    if ClickMorphCustomWardrobe.wardrobeSystem.config.debugMode then
        local msg = "|cff00ffffWardrobe Debug:|r " .. table.concat({...}, " ")
        print(msg)
    end
end


function ClickMorphCustomWardrobe:ShowStatus()
    local config = self.wardrobeSystem.config
    print("|cff00ffffWardrobe Status:|r")
    print("ShowAll:", config.enableShowAll and "ENABLED" or "DISABLED")
    print("Account Wide:", config.useAccountWide and "YES" or "NO")
    print("Debug Mode:", config.debugMode and "ON" or "OFF")
    
    if ClickMorphShowAllWardrobe then
        print("ShowAll Active:", ClickMorphShowAllWardrobe.wardrobeSystem.isActive and "YES" or "NO")
    else
        print("ShowAll Module: NOT LOADED")
    end
end

-- ===================================================================
-- TAB SWITCHING - ENHANCED
-- ===================================================================
function ClickMorphCustomWardrobe.SelectTab(tabIndex)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    for i, panel in ipairs(system.tabPanels) do
        if panel then panel:Hide() end
    end
    if system.tabPanels[tabIndex] then 
        system.tabPanels[tabIndex]:Show() 
        
        -- Refresh específico por tab
        if tabIndex == 4 then -- SaveHub
            ClickMorphCustomWardrobe:RefreshSaveHub()
        end
    end
    PanelTemplates_SetTab(system.mainFrame, tabIndex)
    system.currentTab = tabIndex
    WardrobeDebugPrint("Selected tab", tabIndex)
end

-- ===================================================================
-- SHOW/HIDE - ENHANCED
-- ===================================================================
function ClickMorphCustomWardrobe.Toggle()
    local frame = ClickMorphCustomWardrobe.wardrobeSystem.mainFrame
    if frame and frame:IsShown() then
        ClickMorphCustomWardrobe.Hide()
    else
        ClickMorphCustomWardrobe.Show()
    end
end

function ClickMorphCustomWardrobe.Show()
    ClickMorphCustomWardrobe:LoadConfig()
    if not ClickMorphCustomWardrobe.wardrobeSystem.mainFrame then
        ClickMorphCustomWardrobe.CreateMainInterface()
    end
    ClickMorphCustomWardrobe.wardrobeSystem.mainFrame:Show()
    ClickMorphCustomWardrobe.wardrobeSystem.isVisible = true
    ClickMorphCustomWardrobe:RefreshSaveHub()
    WardrobeDebugPrint("Enhanced wardrobe shown")
end

function ClickMorphCustomWardrobe.Hide()
    if ClickMorphCustomWardrobe.wardrobeSystem.mainFrame then
        ClickMorphCustomWardrobe.wardrobeSystem.mainFrame:Hide()
        ClickMorphCustomWardrobe.wardrobeSystem.isVisible = false
    end
    WardrobeDebugPrint("Wardrobe hidden")
end

-- ===================================================================
-- COMMAND SYSTEM - ENHANCED
-- ===================================================================
function NewClickMorphHandler(msg)
    local command = string.lower(msg or "")
    
    if command == "" then
        ClickMorphCustomWardrobe.Show()
        return
    elseif command == "settings" then
        ClickMorphCustomWardrobe.Show()
        ClickMorphCustomWardrobe.SelectTab(5)
        return
    elseif command == "savehub" then
        ClickMorphCustomWardrobe.Show()
        ClickMorphCustomWardrobe.SelectTab(4)
        return
    elseif command == "showall" then
        local config = ClickMorphCustomWardrobe.wardrobeSystem.config
        config.enableShowAll = not config.enableShowAll
        ClickMorphCustomWardrobe:SaveConfig()
        ClickMorphCustomWardrobe:ApplyShowAllConfig()
        print("|cff00ff00ClickMorph:|r ShowAll", config.enableShowAll and "activated" or "deactivated")
        return
    elseif command == "help" then
        print("|cff00ff00=== ClickMorph Enhanced Wardrobe ===|r")
        print("|cffffcc00/cm|r - Open wardrobe interface")
        print("|cffffcc00/cm settings|r - Open settings panel")
        print("|cffffcc00/cm savehub|r - Open SaveHub panel") 
        print("|cffffcc00/cm showall|r - Toggle ShowAll system")
        return
    else
        print("|cffff0000ClickMorph:|r Unknown command. Use '/cm help' for available commands.")
        return
    end
end

-- Inicialização aprimorada
local function InitializeEnhancedWardrobe()
    ClickMorphCustomWardrobe:LoadConfig()
    
    -- Auto-ativar ShowAll se configurado
    if ClickMorphCustomWardrobe.wardrobeSystem.config.autoEnableShowAll and 
       ClickMorphCustomWardrobe.wardrobeSystem.config.enableShowAll then
        C_Timer.After(3, function()
            ClickMorphCustomWardrobe:ApplyShowAllConfig()
        end)
    end
    
    WardrobeDebugPrint("Enhanced wardrobe system initialized")
end

-- Override do comando /cm
local function OverrideClickMorphCommand()
    C_Timer.After(1, function()
        SlashCmdList["CLICKMORPH"] = NewClickMorphHandler
        
        if ClickMorphCustomWardrobe.wardrobeSystem.config.chatOutput then
            print("|cff00ff00ClickMorph:|r Enhanced wardrobe ready! Type '/cm' to open.")
        end
        
        WardrobeDebugPrint("Command /cm successfully overridden with enhanced version")
    end)
end

-- ===================================================================
-- SLASH COMMANDS
-- ===================================================================
SLASH_CLICKMORPHWARDROBE1 = "/cmw"
SlashCmdList["CLICKMORPHWARDROBE"] = function(msg)
    ClickMorphCustomWardrobe.Toggle()
end

SLASH_CLICKMORPHSETTINGS1 = "/cms"
SlashCmdList["CLICKMORPHSETTINGS"] = function(msg)
    ClickMorphCustomWardrobe.Show()
    ClickMorphCustomWardrobe.SelectTab(5)
end

-- ===================================================================
-- EVENTS
-- ===================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "ClickMorph" then
        InitializeEnhancedWardrobe()
        OverrideClickMorphCommand()
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Re-aplicar ShowAll após mudança de área se necessário
        C_Timer.After(2, function()
            local config = ClickMorphCustomWardrobe.wardrobeSystem.config
            if config.autoEnableShowAll and config.enableShowAll then
                if ClickMorphShowAllWardrobe and not ClickMorphShowAllWardrobe.wardrobeSystem.isActive then
                    ClickMorphShowAllWardrobe.ActivateWardrobe()
                    if config.chatOutput then
                        print("|cff00ffffWardrobe:|r ShowAll re-activated after area change")
                    end
                end
            end
        end)
        
        -- Re-aplicar override do comando
        C_Timer.After(1, function()
            SlashCmdList["CLICKMORPH"] = NewClickMorphHandler
        end)
    end
end)

-- ===================================================================
-- DEBUG OUTPUT
-- ===================================================================
WardrobeDebugPrint("ClickMorph Enhanced Wardrobe loaded successfully")
print("|cff00ffffClickMorph Enhanced Wardrobe:|r Loaded with portrait icon, resize system and enhanced features!")


function ClickMorphCustomWardrobe:LoadConfig()
    local db = self:GetCharDB()
    if not db.config or not next(db.config) then
        db.config = self:GetDefaultConfig()
    end
    self.wardrobeSystem.config = db.config
    
    -- Aplicar tamanho salvo
    if self.wardrobeSystem.mainFrame and db.config.frameWidth and db.config.frameHeight then
        self.wardrobeSystem.mainFrame:SetSize(db.config.frameWidth, db.config.frameHeight)
    end
end

function ClickMorphCustomWardrobe:SaveConfig()
    local db = self:GetCharDB()
    db.config = self.wardrobeSystem.config
end

-- ===================================================================
-- SAVEHUB FUNCTIONS
-- ===================================================================
function ClickMorphCustomWardrobe:GetSlotName(slot)
    local db = self:GetActiveDB()
    return db.saveSlots[slot] and db.saveSlots[slot].name or "Empty"
end

function ClickMorphCustomWardrobe:GetCurrentAppearance()
    -- Mockup: coletar transmogs ativos
    return {
        head = 12345,
        shoulder = 67890,
        chest = 11223
    }
end

function ClickMorphCustomWardrobe:ApplyAppearance(appearance)
    if not appearance then return end
    for slot, id in pairs(appearance) do
        print("Applying", slot, id)
        -- aqui você aplicaria via API real
    end
end

function ClickMorphCustomWardrobe:SaveToSlot(slot, name)
    local db = self:GetActiveDB()
    db.saveSlots[slot] = {
        name = name or ("Slot " .. slot),
        time = date("%Y-%m-%d %H:%M"),
        appearance = self:GetCurrentAppearance()
    }
    print("|cff00ffffWardrobe:|r Saved set to slot " .. slot)
    self:RefreshSaveHub()
end

function ClickMorphCustomWardrobe:LoadFromSlot(slot)
    local db = self:GetActiveDB()
    local set = db.saveSlots[slot]
    if not set then
        print("|cff00ffffWardrobe:|r Slot " .. slot .. " is empty")
        return
    end
    self:ApplyAppearance(set.appearance)
    print("|cff00ffffWardrobe:|r Loaded " .. set.name)
end

-- Atualiza botões do SaveHub
function ClickMorphCustomWardrobe:RefreshSaveHub()
    local system = self.wardrobeSystem
    local panel = system.tabPanels[4]
    if not panel or not panel.saveHubContent then return end
    local children = {panel.saveHubContent:GetChildren()}
    local db = self:GetActiveDB()
    local index = 1
    for i, child in ipairs(children) do
        if child.SetText then
            child:SetText("Save Slot " .. index .. ": " .. (db.saveSlots[index] and db.saveSlots[index].name or "Empty"))
            index = index + 1
        end
    end
end

-- ===================================================================
-- SHOWALL FUNCTIONS
-- ===================================================================
function ClickMorphCustomWardrobe:ApplyShowAllConfig()
    local config = self.wardrobeSystem.config
    if config.enableShowAll then
        if ClickMorphShowAllWardrobe and ClickMorphShowAllWardrobe.ActivateWardrobe then
            ClickMorphShowAllWardrobe.ActivateWardrobe()
            if config.chatOutput then
                print("|cff00ffffWardrobe:|r ShowAll activated!")
            end
        end
    else
        if ClickMorphShowAllWardrobe and ClickMorphShowAllWardrobe.RevertWardrobe then
            ClickMorphShowAllWardrobe.RevertWardrobe()
            if config.chatOutput then
                print("|cff00ffffWardrobe:|r ShowAll deactivated!")
            end
        end
    end
end

-- ===================================================================
-- UI CREATION - ENHANCED
-- ===================================================================
function ClickMorphCustomWardrobe.CreateMainInterface()
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    if system.mainFrame then return end

    -- Mudar para BasicFrameTemplate que não tem portrait
    local frame = CreateFrame("Frame", "ClickMorphWardrobeMainFrame", UIParent, "BasicFrameTemplateWithInset")
    system.mainFrame = frame
    frame:SetSize(system.config.frameWidth or 650, system.config.frameHeight or 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")

    -- RESIZE SYSTEM - Simples e funcional
    ClickMorphCustomWardrobe.CreateResizeSystem(frame)

    -- Title - POSIÇÃO CORRIGIDA (bem centralizadinho)
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -2) -- MUDANÇA: era -15, agora -2 (perfeito!)
    frame.title:SetText("ClickMorph Wardrobe")

    -- Close button
    if frame.CloseButton then
        frame.CloseButton:SetScript("OnClick", function()
            ClickMorphCustomWardrobe.Hide()
        end)
    else
        local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function()
            ClickMorphCustomWardrobe.Hide()
        end)
        frame.CloseButton = closeBtn
    end

    ClickMorphCustomWardrobe.CreateTabSystem(frame)
    ClickMorphCustomWardrobe.SelectTab(1)
    WardrobeDebugPrint("Clean main interface created without portrait")
end

-- Sistema de resize simples
function ClickMorphCustomWardrobe.CreateResizeSystem(frame)
    local isResizing = false
    local startX, startY, startWidth, startHeight
    
    local resizeGrip = CreateFrame("Frame", nil, frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    resizeGrip:EnableMouse(true)
    
    -- Visual do grip
    local gripTexture = resizeGrip:CreateTexture(nil, "OVERLAY")
    gripTexture:SetAllPoints()
    gripTexture:SetColorTexture(0.5, 0.5, 0.5, 0.7)
    
    -- Linhas do grip
    for i = 1, 3 do
        local line = resizeGrip:CreateTexture(nil, "OVERLAY")
        line:SetSize(2, 10 - (i * 2))
        line:SetPoint("BOTTOMRIGHT", resizeGrip, "BOTTOMRIGHT", -1 - (i * 3), 1 + i)
        line:SetColorTexture(0.8, 0.8, 0.8, 0.9)
    end
    
    resizeGrip:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isResizing = true
            startX, startY = GetCursorPosition()
            startWidth, startHeight = frame:GetSize()
            frame:SetScript("OnUpdate", function(self)
                if isResizing then
                    local x, y = GetCursorPosition()
                    local scale = self:GetEffectiveScale()
                    local deltaX = (x - startX) / scale
                    local deltaY = (y - startY) / scale
                    
                    local newWidth = math.max(400, math.min(1200, startWidth + deltaX))
                    local newHeight = math.max(300, math.min(800, startHeight - deltaY))
                    
                    self:SetSize(newWidth, newHeight)
                end
            end)
        end
    end)
    
    resizeGrip:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and isResizing then
            isResizing = false
            frame:SetScript("OnUpdate", nil)
            
            -- Salvar novo tamanho
            local width, height = frame:GetSize()
            ClickMorphCustomWardrobe.wardrobeSystem.config.frameWidth = width
            ClickMorphCustomWardrobe.wardrobeSystem.config.frameHeight = height
            ClickMorphCustomWardrobe:SaveConfig()
            
            WardrobeDebugPrint("Frame resized to", math.floor(width), "x", math.floor(height))
        end
    end)
    
    frame.resizeGrip = resizeGrip
end

-- Ícone redondo do portrait - versão que limpa a borda dourada
function ClickMorphCustomWardrobe.CreatePortraitIcon(frame)
    if not frame.PortraitContainer then
        WardrobeDebugPrint("No PortraitContainer found, skipping icon")
        return
    end
    
    -- LIMPAR COMPLETAMENTE o PortraitContainer
    local children = {frame.PortraitContainer:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Limpar todas as texturas do container
    local regions = {frame.PortraitContainer:GetRegions()}
    for _, region in ipairs(regions) do
        if region.SetTexture then
            region:Hide()
        end
    end
    
    frame.PortraitContainer:SetSize(56, 56)
    
    -- Background circular simples
    local bg = frame.PortraitContainer:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetSize(46, 46)
    bg:SetPoint("CENTER")
    bg:SetColorTexture(0.05, 0.05, 0.1, 0.8)
    
    -- Ícone principal
    local icon = frame.PortraitContainer:CreateTexture(nil, "ARTWORK", nil, -7)
    icon:SetSize(36, 36)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    
    -- Máscara circular
    local mask = frame.PortraitContainer:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    mask:SetSize(46, 46)
    mask:SetPoint("CENTER")
    bg:AddMaskTexture(mask)
    icon:AddMaskTexture(mask)
    
    frame.portraitIcon = {
        bg = bg,
        icon = icon
    }
    
    WardrobeDebugPrint("Portrait cleaned and simple icon created")
end

function ClickMorphCustomWardrobe.CreateTabSystem(parent)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    local tabData = {
        { name = "Transmogs", icon = "Interface\\Icons\\INV_Chest_Cloth_17" },
        { name = "Mounts", icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
        { name = "Morphs", icon = "Interface\\Icons\\Spell_Nature_Polymorph" },
        { name = "SaveHub", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { name = "Settings", icon = "Interface\\Icons\\Trade_Engineering" }
    }

    for i, data in ipairs(tabData) do
        local tab = CreateFrame("Button", parent:GetName().."Tab"..i, parent, "PanelTabButtonTemplate")
        tab:SetID(i)
        tab:SetText(data.name)
        if data.icon then
            tab:SetNormalTexture(data.icon)
            local texture = tab:GetNormalTexture()
            if texture then
                texture:SetSize(16, 16)
                texture:SetPoint("LEFT", tab, "LEFT", 5, 0)
            end
        end
        if i == 1 then
            tab:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 12, -32)
        else
            tab:SetPoint("LEFT", system.tabs[i-1], "RIGHT", -15, 0)
        end
        tab:SetScript("OnClick", function(self)
            ClickMorphCustomWardrobe.SelectTab(self:GetID())
        end)
        if system.config.showTooltips then
            tab:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(data.name, 1,1,1)
                GameTooltip:AddLine("Click to switch to " .. data.name .. " panel", 0.7,0.7,0.7)
                GameTooltip:Show()
            end)
            tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        system.tabs[i] = tab
    end

    PanelTemplates_SetNumTabs(parent, #tabData)
    ClickMorphCustomWardrobe.CreateTabPanels(parent)
    WardrobeDebugPrint("Enhanced tab system created")
end

function ClickMorphCustomWardrobe.CreateTabPanels(parent)
    local system = ClickMorphCustomWardrobe.wardrobeSystem

    -- Painel base para todos
    local function CreateBasePanel()
        local panel = CreateFrame("Frame", nil, parent)
        panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -30)
        panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
        return panel
    end

    -- Transmogs
    local transmogsPanel = CreateBasePanel()
    ClickMorphCustomWardrobe.CreateTransmogsPanel(transmogsPanel)
    system.tabPanels[1] = transmogsPanel

    -- Mounts
    local mountsPanel = CreateBasePanel()
    ClickMorphCustomWardrobe.CreateMountsPanel(mountsPanel)
    system.tabPanels[2] = mountsPanel

    -- Morphs
    local morphsPanel = CreateBasePanel()
    ClickMorphCustomWardrobe.CreateMorphsPanel(morphsPanel)
    system.tabPanels[3] = morphsPanel

    -- SaveHub
    local saveHubPanel = CreateBasePanel()
    ClickMorphCustomWardrobe.CreateSaveHubPanel(saveHubPanel)
    system.tabPanels[4] = saveHubPanel

    -- Settings
    local settingsPanel = CreateBasePanel()
    ClickMorphCustomWardrobe.CreateSettingsPanel(settingsPanel)
    system.tabPanels[5] = settingsPanel
    
    WardrobeDebugPrint("Enhanced tab panels created")
end

-- ===================================================================
-- PANELS PLACEHOLDER
-- ===================================================================
function ClickMorphCustomWardrobe.CreateTransmogsPanel(parent)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject("GameFontHighlightLarge")
    label:SetPoint("CENTER", parent, "CENTER", 0, 50)
    label:SetText("Transmogs Panel")
    
    local desc = parent:CreateFontString(nil, "OVERLAY")
    desc:SetFontObject("GameFontNormal")
    desc:SetPoint("CENTER", parent, "CENTER", 0, 20)
    desc:SetText("Browse and apply transmog appearances")
    desc:SetTextColor(0.7, 0.7, 0.7)
end

function ClickMorphCustomWardrobe.CreateMountsPanel(parent)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject("GameFontHighlightLarge")
    label:SetPoint("CENTER", parent, "CENTER", 0, 50)
    label:SetText("Mounts Panel")
    
    local desc = parent:CreateFontString(nil, "OVERLAY")
    desc:SetFontObject("GameFontNormal")
    desc:SetPoint("CENTER", parent, "CENTER", 0, 20)
    desc:SetText("Customize and preview mounts")
    desc:SetTextColor(0.7, 0.7, 0.7)
end

function ClickMorphCustomWardrobe.CreateMorphsPanel(parent)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject("GameFontHighlightLarge")
    label:SetPoint("CENTER", parent, "CENTER", 0, 50)
    label:SetText("Morphs Panel")
    
    local desc = parent:CreateFontString(nil, "OVERLAY")
    desc:SetFontObject("GameFontNormal")
    desc:SetPoint("CENTER", parent, "CENTER", 0, 20)
    desc:SetText("Browse creature morphs and NPCs")
    desc:SetTextColor(0.7, 0.7, 0.7)
end

-- ===================================================================
-- SAVEHUB PANEL - ENHANCED
-- ===================================================================
function ClickMorphCustomWardrobe.CreateSaveHubPanel(parent)
    -- Título
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFontObject("GameFontHighlightLarge")
    title:SetPoint("TOP", parent, "TOP", 0, -10)
    title:SetText("|cff00ff00SaveHub - Morph Collections|r")
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -25, 0)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(580, 600)
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = -20
    for i = 1, 15 do -- Mais slots
        local btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        btn:SetSize(280, 28)
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
        btn:SetText("Save Slot " .. i .. ": " .. ClickMorphCustomWardrobe:GetSlotName(i))
        btn:SetScript("OnClick", function()
            StaticPopupDialogs["CLICKMORPH_SAVE_NAME"] = {
                text = "Enter name for slot " .. i,
                button1 = "Save",
                button2 = "Cancel",
                hasEditBox = true,
                OnAccept = function(selfPopup)
                    local text = selfPopup.editBox:GetText()
                    if text and text ~= "" then
                        ClickMorphCustomWardrobe:SaveToSlot(i, text)
                    end
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                EditBoxOnEnterPressed = function(self)
                    local text = self:GetText()
                    if text and text ~= "" then
                        ClickMorphCustomWardrobe:SaveToSlot(i, text)
                    end
                    self:GetParent():Hide()
                end
            }
            StaticPopup_Show("CLICKMORPH_SAVE_NAME")
        end)

        local loadBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        loadBtn:SetSize(80, 28)
        loadBtn:SetPoint("LEFT", btn, "RIGHT", 10, 0)
        loadBtn:SetText("Load")
        loadBtn:SetScript("OnClick", function()
            ClickMorphCustomWardrobe:LoadFromSlot(i)
        end)
        
        local deleteBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 28)
        deleteBtn:SetPoint("LEFT", loadBtn, "RIGHT", 5, 0)
        deleteBtn:SetText("Del")
        deleteBtn:SetScript("OnClick", function()
            local db = ClickMorphCustomWardrobe:GetActiveDB()
            db.saveSlots[i] = nil
            ClickMorphCustomWardrobe:RefreshSaveHub()
            print("|cff00ffffWardrobe:|r Slot " .. i .. " cleared")
        end)
        
        yOffset = yOffset - 35
    end

    parent.saveHubContent = scrollChild
    WardrobeDebugPrint("Enhanced SaveHub panel created")
end

-- ===================================================================
-- SETTINGS PANEL - ENHANCED
-- ===================================================================
function ClickMorphCustomWardrobe.CreateSettingsPanel(parent)
    local system = ClickMorphCustomWardrobe.wardrobeSystem
    
    -- Título
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFontObject("GameFontHighlightLarge")
    title:SetPoint("TOP", parent, "TOP", 0, -10)
    title:SetText("|cff00ff00ClickMorph Settings|r")
    
    local y = -50
    local function CreateCheckBox(name, tooltip, key)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        cb.Text:SetText(name)
        cb.tooltipText = tooltip
        cb:SetChecked(system.config[key])
        cb:SetScript("OnClick", function(self)
            system.config[key] = self:GetChecked()
            ClickMorphCustomWardrobe:SaveConfig()
            if key == "enableShowAll" or key == "autoEnableShowAll" then
                ClickMorphCustomWardrobe:ApplyShowAllConfig()
            end
        end)
        
        -- Tooltip melhorado
        if system.config.showTooltips and tooltip then
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:AddLine(tooltip, 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        
        y = y - 35
        return cb
    end

    -- Core settings
    local coreLabel = parent:CreateFontString(nil, "OVERLAY")
    coreLabel:SetFontObject("GameFontHighlight")
    coreLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    coreLabel:SetText("|cffffcc00Core Systems:|r")
    y = y - 25

    CreateCheckBox("Enable ShowAll", "Unlock all transmog appearances in wardrobe", "enableShowAll")
    CreateCheckBox("Auto-enable ShowAll", "Automatically activate ShowAll on login", "autoEnableShowAll")
    
    y = y - 20
    local featuresLabel = parent:CreateFontString(nil, "OVERLAY")
    featuresLabel:SetFontObject("GameFontHighlight")
    featuresLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    featuresLabel:SetText("|cffffcc00Features:|r")
    y = y - 25
    
    CreateCheckBox("Account Wide Saves", "Use same saves for all characters", "useAccountWide")
    CreateCheckBox("Magic Reset Button", "Enable the magic reset button", "magicReset")
    CreateCheckBox("Show Tooltips", "Show helpful tooltips in interface", "showTooltips")
    CreateCheckBox("Chat Output", "Show messages in chat", "chatOutput")
    CreateCheckBox("Debug Mode", "Show debug prints in chat", "debugMode")
    
    -- Botões de ação
    y = y - 30
    local actionsLabel = parent:CreateFontString(nil, "OVERLAY")
    actionsLabel:SetFontObject("GameFontHighlight")
    actionsLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    actionsLabel:SetText("|cffffcc00Actions:|r")
    y = y - 35
    
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    resetBtn:SetText("Reset Settings")
    resetBtn:SetScript("OnClick", function()
        system.config = ClickMorphCustomWardrobe:GetDefaultConfig()
        ClickMorphCustomWardrobe:SaveConfig()
        ClickMorphCustomWardrobe:ApplyShowAllConfig()
		end)
	end
	