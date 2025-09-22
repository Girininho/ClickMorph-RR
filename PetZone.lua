-- PetZone.lua - Sistema de Pets com APIs experimentais para ClickMorph iMorph Edition
-- Interface estilo Wardrobe com morfagem de player e pets

ClickMorphPetZone = {}

-- Sistema de pets
ClickMorphPetZone.petSystem = {
    isActive = false,
    selectedPet = nil,
    selectedCategory = "All",
    currentMode = "player", -- "player" ou "playerpet"
    debugMode = false,
    searchText = "",
    useAPIData = false -- Toggle para usar dados da API vs hardcode
}

-- Debug print
local function PetDebugPrint(...)
    if ClickMorphPetZone.petSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cff66ff66Pet:|r", table.concat(args, " "))
    end
end

-- ============================================================================
-- SEÇÃO DE TESTES: APIs COMENTADAS PARA DESCOBRIR DADOS DINÂMICOS
-- Descomente essas seções quando estiver no WoW para testar
-- ============================================================================

--[[
-- Teste 1: Descobrir pets do Pet Journal
function ClickMorphPetZone.TestPetJournalAPI()
    PetDebugPrint("=== TESTE: Pet Journal API ===")
    local discoveredPets = {}
    
    if C_PetJournal then
        local numPets = C_PetJournal.GetNumPets()
        PetDebugPrint("Encontrados", numPets, "pets no journal")
        
        for i = 1, min(10, numPets) do -- Testar apenas os primeiros 10
            local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType = C_PetJournal.GetPetInfoByIndex(i)
            
            if speciesID and speciesName and icon then
                table.insert(discoveredPets, {
                    name = speciesName,
                    displayID = speciesID,
                    icon = icon,
                    source = "Pet Journal API",
                    category = "Battle Pet",
                    rarity = favorite and 4 or 2,
                    owned = owned
                })
                
                PetDebugPrint("Pet encontrado:", speciesName, "ID:", speciesID, "Owned:", owned and "SIM" or "NAO")
            end
        end
    else
        PetDebugPrint("Pet Journal API nao disponivel")
    end
    
    return discoveredPets
end

-- Teste 2: Descobrir montarias que podem ser pets
function ClickMorphPetZone.TestMountJournalAPI()
    PetDebugPrint("=== TESTE: Mount Journal API ===")
    local mountPets = {}
    
    if C_MountJournal then
        local numMounts = C_MountJournal.GetNumMounts()
        PetDebugPrint("Encontradas", numMounts, "montarias no journal")
        
        for i = 1, min(10, numMounts) do -- Testar apenas as primeiras 10
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByIndex(i)
            
            if name and icon and isCollected then
                -- Tentar obter Display ID da montaria
                local mountInfo = C_MountJournal.GetMountInfoExtraByID(mountID)
                if mountInfo and mountInfo.creatureDisplayInfoID then
                    table.insert(mountPets, {
                        name = name .. " (Mount)",
                        displayID = mountInfo.creatureDisplayInfoID,
                        icon = icon,
                        source = "Mount Journal API",
                        category = "Mount Pet",
                        rarity = isFavorite and 4 or 3
                    })
                    
                    PetDebugPrint("Montaria encontrada:", name, "DisplayID:", mountInfo.creatureDisplayInfoID)
                end
            end
        end
    else
        PetDebugPrint("Mount Journal API nao disponivel")
    end
    
    return mountPets
end

-- Teste 3: Validar Display IDs por força bruta (CUIDADO: pode ser laggy)
function ClickMorphPetZone.TestDisplayIDRange(startID, endID)
    PetDebugPrint("=== TESTE: Display ID range", startID, "ate", endID, "===")
    
    for displayID = startID, endID do
        -- Testar comando .morph para ver se é válido
        local testCmd = ".morph " .. displayID
        PetDebugPrint("Testando Display ID:", displayID)
        
        -- DESCOMENTE para testar de verdade (vai fazer os morphs)
        -- SendChatMessage(testCmd, "SAY")
        
        -- Delay para não sobrecarregar
        if displayID % 10 == 0 then
            C_Timer.After(1, function() end)
        end
    end
end

-- Teste 4: Criar modelo 3D temporário para validar Display ID
function ClickMorphPetZone.TestModelValidation(displayID)
    PetDebugPrint("=== TESTE: Validacao de modelo para DisplayID", displayID, "===")
    
    local testFrame = CreateFrame("PlayerModel", nil, UIParent)
    testFrame:SetSize(1, 1) -- Invisivel
    testFrame:SetPoint("CENTER")
    
    -- Tentar carregar o modelo
    testFrame:SetDisplayInfo(displayID)
    
    C_Timer.After(0.5, function()
        local modelFile = testFrame:GetModelFileID()
        if modelFile and modelFile > 0 then
            PetDebugPrint("Display ID", displayID, "tem modelo valido:", modelFile)
            testFrame:SetParent(nil)
            return true
        else
            PetDebugPrint("Display ID", displayID, "nao tem modelo valido")
            testFrame:SetParent(nil)
            return false
        end
    end)
end

-- Teste 5: Hook para descobrir ícones de criaturas automaticamente
function ClickMorphPetZone.TestIconDiscovery()
    PetDebugPrint("=== TESTE: Descobrir icones de criaturas ===")
    
    local foundIcons = {}
    
    -- Testar FileData IDs comuns de pets
    local commonPetPaths = {
        "Interface\\Icons\\INV_Pet_",
        "Interface\\Icons\\Ability_Hunter_Pet_",
        "Interface\\Icons\\INV_Box_PetCarrier_"
    }
    
    for _, basePath in ipairs(commonPetPaths) do
        for i = 1, 50 do
            local iconPath = basePath .. string.format("%02d", i)
            -- Aqui você poderia testar se o ícone existe
            table.insert(foundIcons, iconPath)
            PetDebugPrint("Testando icone:", iconPath)
        end
    end
    
    return foundIcons
end
--]]

-- Base de dados hardcoded (fallback)
ClickMorphPetZone.PET_DATABASE = {
    -- Companions Clássicos
    {
        name = "Classic Companions",
        category = "Companion", 
        icon = "Interface\\Icons\\INV_Box_PetCarrier_01",
        pets = {
            {
                name = "Wolf Companion", 
                displayID = 1821, 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
                description = "Loyal wolf companion", 
                rarity = 2,
                source = "Hunter Pet Collection"
            },
            {
                name = "House Cat", 
                displayID = 892, 
                icon = "Interface\\Icons\\INV_Box_PetCarrier_01",
                description = "Adorable house cat", 
                rarity = 1,
                source = "Basic Pet Collection"
            },
            {
                name = "Bear Cub", 
                displayID = 2281, 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
                description = "Playful bear cub", 
                rarity = 2,
                source = "Wilderness Collection"
            },
            {
                name = "Owl", 
                displayID = 1557, 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
                description = "Wise owl", 
                rarity = 2,
                source = "Avian Collection"
            },
            {
                name = "Rabbit", 
                displayID = 721, 
                icon = "Interface\\Icons\\INV_Pet_Rabbit",
                description = "Quick forest rabbit", 
                rarity = 1,
                source = "Woodland Creatures"
            }
        }
    },
    -- Battle Pets
    {
        name = "Battle Pets",
        category = "Battle",
        icon = "Interface\\Icons\\INV_Pet_BattlePetTraining",
        pets = {
            {
                name = "Mini Ragnaros", 
                displayID = 37671, 
                icon = "Interface\\Icons\\INV_Ragnaros",
                description = "Miniature fire lord", 
                rarity = 4,
                source = "Blizzard Store"
            },
            {
                name = "Zergling", 
                displayID = 6532, 
                icon = "Interface\\Icons\\INV_Pet_Zergling",
                description = "Starcraft zergling", 
                rarity = 4,
                source = "Collector's Edition"
            },
            {
                name = "Murloc Tadpole", 
                displayID = 15371, 
                icon = "Interface\\Icons\\INV_Pet_PinkMurloc",
                description = "Baby murloc companion", 
                rarity = 3,
                source = "Murloc Collection"
            },
            {
                name = "Mechanical Squirrel", 
                displayID = 28085, 
                icon = "Interface\\Icons\\INV_Pet_MechanicalSquirrel",
                description = "Clockwork marvel", 
                rarity = 3,
                source = "Engineering"
            }
        }
    },
    -- Aquatic Creatures
    {
        name = "Aquatic Creatures",
        category = "Aquatic",
        icon = "Interface\\Icons\\Ability_Druid_AquaticForm",
        pets = {
            {
                name = "Sea Turtle", 
                displayID = 9991, 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
                description = "Ancient sea turtle", 
                rarity = 3,
                source = "Deep Ocean"
            },
            {
                name = "Great White Shark", 
                displayID = 20217, 
                icon = "Interface\\Icons\\INV_Pet_Shark",
                description = "Ocean predator", 
                rarity = 4,
                source = "Rare Ocean Spawn"
            },
            {
                name = "Seahorse", 
                displayID = 35637, 
                icon = "Interface\\Icons\\INV_Pet_Seahorse",
                description = "Mystical seahorse", 
                rarity = 3,
                source = "Vashj'ir Discovery"
            }
        }
    }
}

-- Verificar se player pode ter pets
function ClickMorphPetZone.CanHavePets()
    local playerClass = select(2, UnitClass("player"))
    local hasPet = UnitExists("pet")
    
    local petClasses = {
        ["HUNTER"] = true,
        ["WARLOCK"] = true,
        ["DEATHKNIGHT"] = true,
        ["MAGE"] = true,
        ["SHAMAN"] = true,
        ["PRIEST"] = true,
    }
    
    return petClasses[playerClass] or false, hasPet
end

-- Aplicar morph no player
function ClickMorphPetZone.MorphPlayerToPet(petData)
    if not petData or not petData.displayID then
        print("|cffff0000Pet Zone:|r Invalid pet data")
        return false
    end
    
    PetDebugPrint("Morphing player to:", petData.name, "DisplayID:", petData.displayID)
    
    local morphCmd = string.format(".morph %d", petData.displayID)
    SendChatMessage(morphCmd, "SAY")
    
    ClickMorphPetZone.petSystem.selectedPet = petData
    print("|cff00ff00Pet Zone:|r Player morphed to " .. petData.name)
    
    -- Integrar com MagiButton se disponível
    if ClickMorphMagiButton and ClickMorphMagiButton.system then
        ClickMorphMagiButton.system.currentMorph.petMorph = {
            displayID = petData.displayID,
            name = petData.name,
            mode = "player"
        }
    end
    
    return true
end

-- Aplicar morph no pet
function ClickMorphPetZone.MorphPlayerPet(petData)
    if not petData or not petData.displayID then
        print("|cffff0000Pet Zone:|r Invalid pet data")
        return false
    end
    
    local canHavePet, hasPet = ClickMorphPetZone.CanHavePets()
    
    if not canHavePet then
        print("|cffff0000Pet Zone:|r Your class cannot have pets")
        return false
    end
    
    if not hasPet then
        print("|cffff0000Pet Zone:|r You need an active pet")
        return false
    end
    
    PetDebugPrint("Morphing pet to:", petData.name, "DisplayID:", petData.displayID)
    
    local morphPetCmd = string.format(".morphpet %d", petData.displayID)
    SendChatMessage(morphPetCmd, "SAY")
    
    print("|cff00ff00Pet Zone:|r Pet morphed to " .. petData.name)
    return true
end

-- Reset morphs
function ClickMorphPetZone.ResetMorphs()
    PetDebugPrint("Resetting morphs")
    
    SendChatMessage(".reset", "SAY")
    
    local canHavePet, hasPet = ClickMorphPetZone.CanHavePets()
    if canHavePet and hasPet then
        C_Timer.After(0.5, function()
            SendChatMessage(".morphpet 0", "SAY")
        end)
    end
    
    print("|cff00ff00Pet Zone:|r All morphs reset")
end

-- Obter pets filtrados
function ClickMorphPetZone.GetFilteredPets()
    local system = ClickMorphPetZone.petSystem
    local allPets = {}
    
    -- ============================================================================
    -- DESCOMENTE PARA TESTAR DADOS DA API
    -- ============================================================================
    --[[
    if system.useAPIData then
        PetDebugPrint("Tentando usar dados da API...")
        
        -- Teste Pet Journal
        local petJournalPets = ClickMorphPetZone.TestPetJournalAPI()
        for _, pet in ipairs(petJournalPets) do
            table.insert(allPets, pet)
        end
        
        -- Teste Mount Journal
        local mountPets = ClickMorphPetZone.TestMountJournalAPI()
        for _, pet in ipairs(mountPets) do
            table.insert(allPets, pet)
        end
        
        PetDebugPrint("Carregados", #allPets, "pets da API")
        
        -- Se não conseguiu dados da API, volta pro hardcode
        if #allPets == 0 then
            PetDebugPrint("API nao retornou dados, usando hardcode")
            system.useAPIData = false
        end
    end
    --]]
    
    -- Usar dados hardcoded
    if not system.useAPIData then
        for _, category in ipairs(ClickMorphPetZone.PET_DATABASE) do
            for _, pet in ipairs(category.pets) do
                pet.categoryName = category.name
                table.insert(allPets, pet)
            end
        end
    end
    
    -- Aplicar filtros
    local filteredPets = {}
    for _, pet in ipairs(allPets) do
        local categoryMatch = (system.selectedCategory == "All" or 
                              pet.category == system.selectedCategory)
        
        local searchMatch = (system.searchText == "" or
                           string.find(string.lower(pet.name), string.lower(system.searchText)))
        
        if categoryMatch and searchMatch then
            table.insert(filteredPets, pet)
        end
    end
    
    return filteredPets
end

-- Cores por raridade
function ClickMorphPetZone.GetRarityColor(rarity)
    local colors = {
        [1] = {1, 1, 1},        -- White
        [2] = {0.12, 1, 0},     -- Green
        [3] = {0, 0.44, 0.87},  -- Blue
        [4] = {0.64, 0.21, 0.93} -- Purple
    }
    return colors[rarity] or colors[1]
end

-- Criar interface estilo Wardrobe para CusTab
function ClickMorphPetZone.CreatePetZoneContent(parentFrame)
    local system = ClickMorphPetZone.petSystem
    
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Pet Zone Collection")
    
    -- Controles superiores
    local controlFrame = CreateFrame("Frame", nil, content)
    controlFrame:SetSize(390, 50)
    controlFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    -- Mode buttons
    local modeLabel = controlFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    modeLabel:SetPoint("LEFT", 0, 15)
    modeLabel:SetText("Mode:")
    
    local playerModeBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    playerModeBtn:SetSize(80, 20)
    playerModeBtn:SetPoint("LEFT", modeLabel, "RIGHT", 5, 0)
    playerModeBtn:SetText("Player")
    playerModeBtn:SetScript("OnClick", function()
        system.currentMode = "player"
        ClickMorphPetZone.UpdateModeButtons()
    end)
    system.playerModeBtn = playerModeBtn
    
    local petModeBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    petModeBtn:SetSize(80, 20)
    petModeBtn:SetPoint("LEFT", playerModeBtn, "RIGHT", 5, 0)
    petModeBtn:SetText("Pet")
    petModeBtn:SetScript("OnClick", function()
        system.currentMode = "playerpet"
        ClickMorphPetZone.UpdateModeButtons()
    end)
    system.petModeBtn = petModeBtn
    
    -- Category dropdown
    local categoryLabel = controlFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    categoryLabel:SetPoint("LEFT", petModeBtn, "RIGHT", 15, 0)
    categoryLabel:SetText("Category:")
    
    local categoryDropdown = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    categoryDropdown:SetSize(80, 20)
    categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 5, 0)
    categoryDropdown:SetText("All")
    system.categoryDropdown = categoryDropdown
    
    -- Search box
    local searchLabel = controlFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", 0, -15)
    searchLabel:SetText("Search:")
    
    local searchBox = CreateFrame("EditBox", nil, controlFrame, "InputBoxTemplate")
    searchBox:SetSize(100, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        system.searchText = self:GetText()
        ClickMorphPetZone.RefreshPetGrid()
    end)
    system.searchBox = searchBox
    
    -- ============================================================================
    -- TOGGLE PARA TESTES DA API (descomente para testar)
    -- ============================================================================
    --[[
    local apiToggle = CreateFrame("CheckButton", nil, controlFrame, "ChatConfigCheckButtonTemplate")
    apiToggle:SetPoint("LEFT", searchBox, "RIGHT", 20, 0)
    apiToggle.Text:SetText("Test API")
    apiToggle:SetScript("OnClick", function(self)
        system.useAPIData = self:GetChecked()
        ClickMorphPetZone.RefreshPetGrid()
        PetDebugPrint("API Test mode:", system.useAPIData and "ON" or "OFF")
    end)
    --]]
    
    -- Grid area
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(375, 230)
    scrollFrame:SetPoint("TOPLEFT", controlFrame, "BOTTOMLEFT", 0, -10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(350, 1000)
    system.scrollChild = scrollChild
    
    -- Info panel
    local infoFrame = CreateFrame("Frame", nil, content)
    infoFrame:SetSize(390, 90)
    infoFrame:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    
    local infoBg = infoFrame:CreateTexture(nil, "BACKGROUND")
    infoBg:SetAllPoints()
    infoBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Selected pet info
    local selectedIcon = infoFrame:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(48, 48)
    selectedIcon:SetPoint("LEFT", 10, 0)
    selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    system.selectedIcon = selectedIcon
    
    local selectedName = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    selectedName:SetPoint("TOPLEFT", selectedIcon, "TOPRIGHT", 10, 0)
    selectedName:SetText("No pet selected")
    system.selectedName = selectedName
    
    local selectedDesc = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectedDesc:SetPoint("TOPLEFT", selectedName, "BOTTOMLEFT", 0, -5)
    selectedDesc:SetWidth(250)
    selectedDesc:SetJustifyH("LEFT")
    system.selectedDesc = selectedDesc
    
    -- Buttons
    local applyBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(70, 25)
    applyBtn:SetPoint("RIGHT", -10, 10)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        if system.selectedPetData then
            if system.currentMode == "player" then
                ClickMorphPetZone.MorphPlayerToPet(system.selectedPetData)
            else
                ClickMorphPetZone.MorphPlayerPet(system.selectedPetData)
            end
        end
    end)
    
    local resetBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(60, 25)
    resetBtn:SetPoint("RIGHT", applyBtn, "LEFT", -5, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        ClickMorphPetZone.ResetMorphs()
        ClickMorphPetZone.ClearSelection()
    end)
    
    -- Status text
    local statusText = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", 0, 5)
    statusText:SetTextColor(0.8, 0.8, 0.8)
    system.statusText = statusText
    
    system.isActive = true
    system.contentFrame = content
    
    ClickMorphPetZone.UpdateModeButtons()
    ClickMorphPetZone.RefreshPetGrid()
    
    PetDebugPrint("Pet Zone interface created")
    return content
end

-- Refresh grid
function ClickMorphPetZone.RefreshPetGrid()
    local system = ClickMorphPetZone.petSystem
    
    if not system.scrollChild then return end
    
    -- Limpar grid
    if system.petButtons then
        for _, btn in pairs(system.petButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    system.petButtons = {}
    
    local pets = ClickMorphPetZone.GetFilteredPets()
    
    -- Grid 5 colunas
    local cols = 5
    local buttonSize = 64
    local spacing = 4
    
    for i, pet in ipairs(pets) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        
        local btn = CreateFrame("Button", nil, system.scrollChild)
        btn:SetSize(buttonSize, buttonSize)
        btn:SetPoint("TOPLEFT", col * (buttonSize + spacing) + 5, -(row * (buttonSize + spacing)) - 5)
        
        -- Ícone
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(buttonSize - 4, buttonSize - 4)
        icon:SetPoint("CENTER")
        icon:SetTexture(pet.icon)
        
        -- Border colorida
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(btn)
        border:SetTexture("Interface\\Common\\WhiteIconFrame")
        local r, g, b = unpack(ClickMorphPetZone.GetRarityColor(pet.rarity))
        border:SetVertexColor(r, g, b, 0.8)
        
        -- Highlight
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        
        -- Click handler
        btn:SetScript("OnClick", function()
            ClickMorphPetZone.SelectPet(pet, btn)
        end)
        
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(pet.name, unpack(ClickMorphPetZone.GetRarityColor(pet.rarity)))
            GameTooltip:AddLine(pet.description, 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Display ID: " .. pet.displayID, 0.6, 0.6, 1)
            GameTooltip:AddLine("Source: " .. pet.source, 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(system.petButtons, btn)
    end
    
    PetDebugPrint("Grid refreshed with", #pets, "pets")
end

-- Selecionar pet
function ClickMorphPetZone.SelectPet(petData, button)
    local system = ClickMorphPetZone.petSystem
    
    if system.selectedButton then
        system.selectedButton:SetNormalTexture("")
    end
    
    system.selectedPetData = petData
    system.selectedButton = button
    
    -- Visual da seleção
    local selectedTex = button:CreateTexture(nil, "BACKGROUND")
    selectedTex:SetAllPoints()
    selectedTex:SetColorTexture(1, 1, 0, 0.3)
    button:SetNormalTexture(selectedTex)
    
    -- Atualizar info
    system.selectedIcon:SetTexture(petData.icon)
    system.selectedName:SetText(petData.name)
    local r, g, b = unpack(ClickMorphPetZone.GetRarityColor(petData.rarity))
    system.selectedName:SetTextColor(r, g, b)
    
    system.selectedDesc:SetText(petData.description or "")
    
    PetDebugPrint("Selected pet:", petData.name)
end

-- Limpar seleção
function ClickMorphPetZone.ClearSelection()
    local system = ClickMorphPetZone.petSystem
    
    if system.selectedButton then
        system.selectedButton:SetNormalTexture("")
    end
    
    system.selectedPetData = nil
    system.selectedButton = nil
    
    system.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    system.selectedName:SetText("No pet selected")
    system.selectedName:SetTextColor(1, 1, 1)
    system.selectedDesc:SetText("")
end

-- Update botões de modo
function ClickMorphPetZone.UpdateModeButtons()
    local system = ClickMorphPetZone.petSystem
    
    if system.playerModeBtn and system.petModeBtn then
        if system.currentMode == "player" then
            system.playerModeBtn:SetNormalFontObject("GameFontHighlight")
            system.petModeBtn:SetNormalFontObject("GameFontNormal")
        else
            system.playerModeBtn:SetNormalFontObject("GameFontNormal")
            system.petModeBtn:SetNormalFontObject("GameFontHighlight")
        end
    end
    
    -- Update status
    if system.statusText then
        local canHavePet, hasPet = ClickMorphPetZone.CanHavePets()
        
        if system.currentMode == "player" then
            system.statusText:SetText("Mode: Transform player into pet creature")
            system.statusText:SetTextColor(0.8, 1, 0.8)
        else
            if canHavePet and hasPet then
                system.statusText:SetText("Mode: Transform your pet")
                system.statusText:SetTextColor(0.8, 0.8, 1)
            else
                system.statusText:SetText("Mode: Pet transform (Need active pet)")
                system.statusText:SetTextColor(1, 0.8, 0.8)
            end
        end
    end
end

-- Status do sistema
function ClickMorphPetZone.ShowStatus()
    local system = ClickMorphPetZone.petSystem
    
    print("|cff00ff00=== PET ZONE STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Current Mode:", system.currentMode)
    print("Selected Category:", system.selectedCategory)
    print("Search Text:", system.searchText ~= "" and system.searchText or "None")
    print("Use API Data:", system.useAPIData and "YES" or "NO")
    
    local canHavePet, hasPet = ClickMorphPetZone.CanHavePets()
    local playerClass = select(2, UnitClass("player"))
    print("Player Class:", playerClass)
    print("Can Have Pet:", canHavePet and "YES" or "NO")
    print("Has Active Pet:", hasPet and "YES" or "NO")
    
    local totalPets = 0
    for _, cat in ipairs(ClickMorphPetZone.PET_DATABASE) do
        totalPets = totalPets + #cat.pets
    end
    print("Total Hardcoded Pets:", totalPets)
    
    if system.selectedPetData then
        print("Selected Pet:", system.selectedPetData.name)
    end
end

-- Comandos para testes
SLASH_CLICKMORPH_PET1 = "/cmpet"
SlashCmdList.CLICKMORPH_PET = function(arg)
    local args = {}
    for word in arg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = string.lower(args[1] or "")
    
    if command == "reset" then
        ClickMorphPetZone.ResetMorphs()
    elseif command == "mode" then
        local mode = args[2]
        if mode == "player" then
            ClickMorphPetZone.petSystem.currentMode = "player"
            ClickMorphPetZone.UpdateModeButtons()
            print("|cff00ff00Pet Zone:|r Mode set to player")
        elseif mode == "pet" then
            ClickMorphPetZone.petSystem.currentMode = "playerpet"
            ClickMorphPetZone.UpdateModeButtons()
            print("|cff00ff00Pet Zone:|r Mode set to pet")
        else
            print("|cffff0000Pet Zone:|r Usage: /cmpet mode <player|pet>")
        end
    elseif command == "status" then
        ClickMorphPetZone.ShowStatus()
    elseif command == "debug" then
        ClickMorphPetZone.petSystem.debugMode = not ClickMorphPetZone.petSystem.debugMode
        print("|cff00ff00Pet Zone:|r Debug mode", ClickMorphPetZone.petSystem.debugMode and "ON" or "OFF")
    
    -- ============================================================================
    -- COMANDOS DE TESTE (descomente para usar)
    -- ============================================================================
    --[[
    elseif command == "testapi" then
        ClickMorphPetZone.petSystem.useAPIData = not ClickMorphPetZone.petSystem.useAPIData
        print("|cff00ff00Pet Zone:|r API Test mode", ClickMorphPetZone.petSystem.useAPIData and "ON" or "OFF")
        if ClickMorphPetZone.petSystem.contentFrame then
            ClickMorphPetZone.RefreshPetGrid()
        end
    elseif command == "testjournal" then
        local pets = ClickMorphPetZone.TestPetJournalAPI()
        print("|cff00ff00Pet Zone:|r Found", #pets, "pets in journal")
    elseif command == "testmounts" then
        local mounts = ClickMorphPetZone.TestMountJournalAPI()
        print("|cff00ff00Pet Zone:|r Found", #mounts, "mount pets")
    elseif command == "testids" then
        local startID = tonumber(args[2]) or 1000
        local endID = tonumber(args[3]) or 1050
        print("|cff00ff00Pet Zone:|r Testing Display IDs", startID, "to", endID)
        ClickMorphPetZone.TestDisplayIDRange(startID, endID)
    elseif command == "testmodel" then
        local displayID = tonumber(args[2]) or 892
        ClickMorphPetZone.TestModelValidation(displayID)
    --]]
    
    else
        print("|cff00ff00Pet Zone Commands:|r")
        print("/cmpet reset - Reset all morphs")
        print("/cmpet mode <player|pet> - Set morph mode")
        print("/cmpet status - Show system status")
        print("/cmpet debug - Toggle debug mode")
        
        -- COMANDOS DE TESTE (descomente as linhas abaixo para mostrar)
        --print("/cmpet testapi - Toggle API test mode")
        --print("/cmpet testjournal - Test Pet Journal API")
        --print("/cmpet testmounts - Test Mount Journal API")
        --print("/cmpet testids <start> <end> - Test Display ID range")
        --print("/cmpet testmodel <displayID> - Test model validation")
        
        print("")
        print("Open Collections Journal -> iMorph tab -> Pet Zone for the full interface!")
    end
end

print("|cff00ff00ClickMorph Pet Zone|r loaded!")
print("|cff00ff00Pet Zone:|r Uncomment API test sections in PetZone.lua to enable experimental features")
print("|cff00ff00Pet Zone:|r Use /cmpet for commands or open the iMorph tab")