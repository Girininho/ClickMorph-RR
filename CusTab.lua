-- CusTab.lua (Retail-only, WoW 11.x safe)
ClickMorphCusTab = {}

ClickMorphCusTab.tabSystem = {
    isCreated = false,
    tabButton = nil,
    contentFrame = nil,
    tabID = 5,
    debugMode = true, -- Ative para ver prints no chat
    categoryButtons = {},
    categoryContents = {},
    activeCategory = "ShowAll"
}

-- Debug print
local function CusTabDebugPrint(...)
    if ClickMorphCusTab.tabSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cffcc6600CusTab:|r", table.concat(args, " "))
    end
end

-- Checar se CollectionsJournal está pronto
function ClickMorphCusTab.IsCollectionsJournalReady()
    return CollectionsJournal and _G["CollectionsJournalTab1"]
end

-- Criar conteúdo da aba
function ClickMorphCusTab.CreateTabContent()
    local system = ClickMorphCusTab.tabSystem
    if system.contentFrame then return system.contentFrame end

    local contentFrame = CreateFrame("Frame", "ClickMorphIMorphTab", CollectionsJournal)
    contentFrame:SetAllPoints(CollectionsJournal)
    contentFrame:Hide()

    -- Título
    local title = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("iMorph Control Center")

    -- Frame de categorias
    local categoryFrame = CreateFrame("Frame", nil, contentFrame)
    categoryFrame:SetSize(150, 400)
    categoryFrame:SetPoint("TOPLEFT", 20, -60)

    -- Categorias
    local categories = {
        {name="ShowAll", displayName="Show All Systems"},
        {name="MorphTools", displayName="Morph Tools"},
        {name="SaveHub", displayName="Save Hub"},
        {name="PauldronSystem", displayName="Pauldron Tools"},
        {name="NPCExplorer", displayName="NPC Explorer"},
        {name="CustomMounts", displayName="Custom Mounts"},
        {name="Settings", displayName="Settings"}
    }

    system.categoryButtons = {}
    system.categoryContents = {}

    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, categoryFrame)
        btn:SetSize(140, 30)
        btn:SetPoint("TOPLEFT", 0, -(i-1)*35)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetAllPoints()
        btn.text:SetText(cat.displayName)
        btn:SetScript("OnClick", function()
            ClickMorphCusTab.ShowCategory(cat.name)
        end)
        system.categoryButtons[cat.name] = btn
    end

    -- Área de conteúdo
    local contentArea = CreateFrame("Frame", nil, contentFrame)
    contentArea:SetSize(400, 400)
    contentArea:SetPoint("LEFT", categoryFrame, "RIGHT", 20, 0)
    local bg = contentArea:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1,0.1,0.1,0.3)

    system.contentFrame = contentFrame
    system.contentArea = contentArea

    -- Criar conteúdos de categorias (vazio/placeholder)
    for _, cat in ipairs(categories) do
        local f = CreateFrame("Frame", nil, contentArea)
        f:SetAllPoints()
        f:Hide()
        system.categoryContents[cat.name] = f
    end

    ClickMorphCusTab.ShowCategory("ShowAll")
    return contentFrame
end

-- Mostrar categoria
function ClickMorphCusTab.ShowCategory(name)
    local system = ClickMorphCusTab.tabSystem
    for _, btn in pairs(system.categoryButtons) do
        btn.text:SetTextColor(1,1,1)
    end
    for _, frame in pairs(system.categoryContents) do
        frame:Hide()
    end
    if system.categoryButtons[name] then
        system.categoryButtons[name].text:SetTextColor(0,1,1)
    end
    if system.categoryContents[name] then
        system.categoryContents[name]:Show()
    end
    system.activeCategory = name
    CusTabDebugPrint("Showing category:", name)
end

-- Criar botão da aba (WoW 11.x safe)
function ClickMorphCusTab.CreateTabButton()
    local system = ClickMorphCusTab.tabSystem
    if system.tabButton then return system.tabButton end

    local lastTab = _G["CollectionsJournalTab4"]
    if not lastTab then
        CusTabDebugPrint("Última aba não encontrada, botão não criado.")
        return
    end

    local tabButton = CreateFrame("Button", "ClickMorphIMorphTabButton", CollectionsJournal)
    tabButton:SetSize(80, 22)
    tabButton:SetPoint("LEFT", lastTab, "RIGHT", 5, 0)

    local bg = tabButton:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    tabButton.text = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tabButton.text:SetAllPoints()
    tabButton.text:SetText("iMorph")
    tabButton.text:SetTextColor(1, 1, 0)

    tabButton:SetScript("OnClick", ClickMorphCusTab.ShowTab)

    system.tabButton = tabButton
    CusTabDebugPrint("iMorph tab button criado com sucesso!")
    return tabButton
end

-- Mostrar aba
function ClickMorphCusTab.ShowTab()
    local system = ClickMorphCusTab.tabSystem
    if system.contentFrame then system.contentFrame:Show() end
    if system.tabButton then
        system.tabButton.text:SetTextColor(0,1,1) -- destaque
    end
    -- esconder outras abas manualmente
    if MountJournal then MountJournal:Hide() end
    if PetJournal then PetJournal:Hide() end
    if ToyBox then ToyBox:Hide() end
    if HeirloomsJournal then HeirloomsJournal:Hide() end
    CusTabDebugPrint("iMorph tab ativa!")
end

-- Inicializar aba customizada
function ClickMorphCusTab.CreateCustomTab()
    local system = ClickMorphCusTab.tabSystem
    if system.isCreated then return end

    if not ClickMorphCusTab.IsCollectionsJournalReady() then
        CusTabDebugPrint("CollectionsJournal ou abas não prontas, tentando novamente em 0.5s")
        C_Timer.After(0.5, ClickMorphCusTab.CreateCustomTab)
        return
    end

    ClickMorphCusTab.CreateTabContent()
    ClickMorphCusTab.CreateTabButton()

    system.isCreated = true
    CusTabDebugPrint("Custom tab criada com sucesso!")
end

-- Evento de criação
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    C_Timer.After(1, ClickMorphCusTab.CreateCustomTab)
end)

CusTabDebugPrint("CusTab system carregado!")
