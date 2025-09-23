-- PetZone.lua
-- Sistema completo para morphs de pets/battle pets

ClickMorphPetZone = {}

-- Sistema de pets
ClickMorphPetZone.petSystem = {
    isActive = false,
    selectedCategory = "All",
    searchText = "",
    favorites = {},
    debugMode = false,
    useAPIData = false, -- Usar dados hardcoded por padrão
    categoryDropdown = nil
}

-- Base de dados de pets expandida
ClickMorphPetZone.PET_DATABASE = {
    -- Pets Clássicos
    {
        name = "Classic Pets",
        category = "Classic",
        pets = {
            {
                category = "Classic",
                name = "Mechanical Squirrel",
                displayID = 328,
                rarity = 2,
                description = "A tiny mechanical companion"
            },
            {
                category = "Classic",
                name = "Pet Bombling",
                displayID = 777,
                rarity = 3,
                description = "Explosive little friend"
            },
            {
                category = "Classic",
                name = "Whiskers the Rat",
                displayID = 1141,
                rarity = 1,
                description = "A simple brown rat"
            },
            {
                category = "Classic",
                name = "Cockroach",
                displayID = 1447,
                rarity = 1,
                description = "Surprisingly resilient"
            },
            {
                category = "Classic",
                name = "Prairie Dog",
                displayID = 1412,
                rarity = 2,
                description = "Curious little critter"
            }
        }
    },
    
    -- Pets Draenei/Alien
    {
        name = "Draenei Pets",
        category = "Draenei",
        pets = {
            {
                category = "Draenei",
                name = "Blue Moth",
                displayID = 15897,
                rarity = 2,
                description = "Beautiful draenei moth"
            },
            {
                category = "Draenei",
                name = "Red Moth",
                displayID = 15898,
                rarity = 2,
                description = "Crimson draenei moth"
            },
            {
                category = "Draenei",
                name = "Yellow Moth",
                displayID = 15899,
                rarity = 2,
                description = "Golden draenei moth"
            },
            {
                category = "Draenei",
                name = "White Moth",
                displayID = 15900,
                rarity = 3,
                description = "Pure white draenei moth"
            }
        }
    },
    
    -- Pets Mecânicos
    {
        name = "Mechanical Pets",
        category = "Mechanical",
        pets = {
            {
                category = "Mechanical",
                name = "Mechanical Chicken",
                displayID = 7383,
                rarity = 3,
                description = "Gnomish engineering marvel"
            },
            {
                category = "Mechanical",
                name = "Mechanical Dragonling",
                displayID = 5524,
                rarity = 4,
                description = "Tiny mechanical dragon"
            },
            {
                category = "Mechanical",
                name = "Pet Robot",
                displayID = 13069,
                rarity = 3,
                description = "Advanced robotic companion"
            },
            {
                category = "Mechanical",
                name = "Mechanical Toad",
                displayID = 1420,
                rarity = 2,
                description = "Wind-up amphibian"
            }
        }
    },
    
    -- Pets Exóticos
    {
        name = "Exotic Pets",
        category = "Exotic",
        pets = {
            {
                category = "Exotic",
                name = "Tiny Emerald Whelpling",
                displayID = 847,
                rarity = 4,
                description = "Baby green dragon"
            },
            {
                category = "Exotic",
                name = "Tiny Crimson Whelpling",
                displayID = 848,
                rarity = 4,
                description = "Baby red dragon"
            },
            {
                category = "Exotic",
                name = "Azure Whelpling",
                displayID = 849,
                rarity = 4,
                description = "Baby blue dragon"
            },
            {
                category = "Exotic",
                name = "Mini Diablo",
                displayID = 850,
                rarity = 4,
                description = "Tiny Lord of Terror"
            },
            {
                category = "Exotic",
                name = "Zergling",
                displayID = 1352,
                rarity = 4,
                description = "Starcraft zerg unit"
            },
            {
                category = "Exotic",
                name = "Panda Cub",
                displayID = 1433,
                rarity = 3,
                description = "Adorable baby panda"
            }
        }
    },
    
    -- Pets Undead
    {
        name = "Undead Pets",
        category = "Undead",
        pets = {
            {
                category = "Undead",
                name = "Ghostly Skull",
                displayID = 15202,
                rarity = 3,
                description = "Floating spectral skull"
            },
            {
                category = "Undead",
                name = "Bone Serpent",
                displayID = 13435,
                rarity = 3,
                description = "Undead snake companion"
            },
            {
                category = "Undead",
                name = "Haunted Memento",
                displayID = 25824,
                rarity = 4,
                description = "Ghostly reminder"
            }
        }
    },
    
    -- Pets Aquáticos
    {
        name = "Aquatic Pets",
        category = "Aquatic",
        pets = {
            {
                category = "Aquatic",
                name = "Tiny Goldfish",
                displayID = 5017,
                rarity = 1,
                description = "Small golden fish"
            },
            {
                category = "Aquatic",
                name = "Baby Shark",
                displayID = 4591,
                rarity = 3,
                description = "Miniature predator"
            },
            {
                category = "Aquatic",
                name = "Sea Turtle",
                displayID = 9657,
                rarity = 3,
                description = "Slow but steady"
            }
        }
    },
    
    -- Pets Voadores
    {
        name = "Flying Pets",
        category = "Flying",
        pets = {
            {
                category = "Flying",
                name = "Parrot",
                displayID = 9320,
                rarity = 2,
                description = "Colorful tropical bird"
            },
            {
                category = "Flying",
                name = "Owl",
                displayID = 1955,
                rarity = 2,
                description = "Wise night bird"
            },
            {
                category = "Flying",
                name = "Bat",
                displayID = 1554,
                rarity = 1,
                description = "Nocturnal flyer"
            },
            {
                category = "Flying",
                name = "Sprite Darter",
                displayID = 6295,
                rarity = 3,
                description = "Magical fairy dragon"
            }
        }
    },
    
    -- Pets Especiais/Raros
    {
        name = "Special Pets",
        category = "Special",
        pets = {
            {
                category = "Special",
                name = "Mr. Wiggles",
                displayID = 1430,
                rarity = 4,
                description = "The famous pig"
            },
            {
                category = "Special",
                name = "Sleepy Willy",
                displayID = 13321,
                rarity = 3,
                description = "Drowsy companion"
            },
            {
                category = "Special",
                name = "Jubling",
                displayID = 13583,
                rarity = 4,
                description = "Rare event pet"
            },
            {
                category = "Special",
                name = "Worg Pup",
                displayID = 1922,
                rarity = 3,
                description = "Young wolf companion"
            }
        }
    }
}

-- Debug print para pets
local function PetDebugPrint(...)
    if ClickMorphPetZone.petSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            if args[i] == nil then
                args[i] = "nil"
            elseif type(args[i]) ~= "string" then
                args[i] = tostring(args[i])
            end
        end
        local message = table.concat(args, " ")
        print("|cff00ccffPetZone:|r", message)
    end
end

-- Função para testar Pet Journal API
function ClickMorphPetZone.TestPetJournalAPI()
    local pets = {}
    
    PetDebugPrint("Testing Pet Journal API...")
    
    if not C_PetJournal then
        PetDebugPrint("C_PetJournal not available")
        return pets
    end
    
    -- Tentar obter pets do journal
    local numPets = C_PetJournal.GetNumPets()
    PetDebugPrint("Found", numPets, "pets in journal")
    
    for i = 1, math.min(numPets, 50) do -- Limite para teste
        local petID, speciesID, isOwned, customName, level, favorite, isRevoked, name, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique = C_PetJournal.GetPetInfoByIndex(i)
        
        if petID and name then
            table.insert(pets, {
                category = "API",
                name = customName or name,
                displayID = speciesID or 1, -- Usar speciesID como displayID
                rarity = isOwned and 3 or 1,
                description = description or "Battle pet from API"
            })
        end
    end
    
    PetDebugPrint("Loaded", #pets, "pets from Pet Journal API")
    return pets
end

-- Função para testar Mount Journal API (alguns mounts podem ser considerados pets)
function ClickMorphPetZone.TestMountJournalAPI()
    local pets = {}
    
    PetDebugPrint("Testing Mount Journal API for pet-like mounts...")
    
    if not C_MountJournal then
        PetDebugPrint("C_MountJournal not available")
        return pets
    end
    
    local numMounts = C_MountJournal.GetNumMounts()
    PetDebugPrint("Found", numMounts, "mounts in journal")
    
    -- Alguns mounts pequenos podem ser usados como "pets"
    local petLikeMounts = {
        -- IDs de exemplo de mounts pequenos que poderiam ser pets
        {mountID = 382, name = "Swift Brown Wolf", category = "Mount-Pet"},
        {mountID = 6648, name = "Swift Yellow Mechanostrider", category = "Mount-Pet"},
    }
    
    for _, mountData in ipairs(petLikeMounts) do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountData.mountID)
        
        if name then
            table.insert(pets, {
                category = mountData.category,
                name = name .. " (Pet Mode)",
                displayID = mountData.mountID,
                rarity = isCollected and 3 or 2,
                description = "Mount used as pet companion"
            })
        end
    end
    
    PetDebugPrint("Loaded", #pets, "pet-like mounts from Mount Journal API")
    return pets
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
    
    PetDebugPrint("Filtered pets:", #filteredPets)
    return filteredPets
end

-- Cores por raridade
function ClickMorphPetZone.GetRarityColor(rarity)
    local colors = {
        [1] = {1, 1, 1},        -- White (Common)
        [2] = {0.12, 1, 0},     -- Green (Uncommon)
        [3] = {0, 0.44, 0.87},  -- Blue (Rare)
        [4] = {0.64, 0.21, 0.93} -- Purple (Epic)
    }
    return colors[rarity] or colors[1]
end

-- Menu de categoria dropdown
function ClickMorphPetZone.ShowCategoryMenu(anchor)
    local system = ClickMorphPetZone.petSystem
    local categories = {"All", "Classic", "Draenei", "Mechanical", "Exotic", "Undead", "Aquatic", "Flying", "Special"}
    
    local menu = CreateFrame("Frame", nil, anchor, "UIDropDownMenuTemplate")
    
    local function OnCategorySelect(self, category)
        system.selectedCategory = category
        system.categoryDropdown:SetText(category)
        ClickMorphPetZone.RefreshPetGrid()
        CloseDropDownMenus()
    end
    
    local menuList = {}
    for _, category in ipairs(categories) do
        table.insert(menuList, {
            text = category,
            func = function() OnCategorySelect(nil, category) end,
            checked = (category == system.selectedCategory)
        })
    end
    
    EasyMenu(menuList, menu, "cursor", 0, 0, "MENU")
end

-- Refresh do grid de pets
function ClickMorphPetZone.RefreshPetGrid()
    if not ClickMorphPetZone.petGrid then return end
    
    local pets = ClickMorphPetZone.GetFilteredPets()
    local grid = ClickMorphPetZone.petGrid
    
    -- Limpar botões existentes
    for i = 1, #grid.buttons do
        grid.buttons[i]:Hide()
    end
    
    -- Mostrar pets filtrados
    for i = 1, math.min(#pets, #grid.buttons) do
        local button = grid.buttons[i]
        local pet = pets[i]
        
        button.pet = pet
        button.icon:SetTexture(GetItemIcon(8498) or "Interface\\Icons\\INV_Box_PetCarrier_01")
        
        -- Cor da borda por raridade
        local r, g, b = unpack(ClickMorphPetZone.GetRarityColor(pet.rarity))
        if button.IconBorder then
            button.IconBorder:SetVertexColor(r, g, b)
            button.IconBorder:Show()
        end
        
        button:Show()
    end
    
    PetDebugPrint("Grid refreshed with", #pets, "pets")
end

-- Criar botão de pet
function ClickMorphPetZone.CreatePetButton(parent, index)
    local button = CreateFrame("Button", nil, parent, "ItemButtonTemplate")
    button:SetSize(40, 40)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        if self.pet then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.pet.name, 1, 1, 1)
            GameTooltip:AddLine(self.pet.description, 1, 1, 1, true)
            
            local rarity = self.pet.rarity
            local rarityText = {"Common", "Uncommon", "Rare", "Epic"}
            local r, g, b = unpack(ClickMorphPetZone.GetRarityColor(rarity))
            GameTooltip:AddLine(rarityText[rarity] or "Unknown", r, g, b)
            
            GameTooltip:Show()
        end
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Clique para aplicar morph
    button:SetScript("OnClick", function(self, btn)
        if self.pet and btn == "LeftButton" then
            PetDebugPrint("Applying pet morph:", self.pet.name, "DisplayID:", self.pet.displayID)
            
            -- Comando SetDisplayId via chat
            SendChatMessage(".morph " .. self.pet.displayID, "GUILD")
            
            -- Feedback visual
            self:SetAlpha(0.5)
            C_Timer.After(0.2, function()
                if self then
                    self:SetAlpha(1.0)
                end
            end)
        end
    end)
    
    return button
end

-- Criar interface estilo Wardrobe para CusTab
function ClickMorphPetZone.CreatePetZoneContent(parentFrame)
    local system = ClickMorphPetZone.petSystem
    
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Pet Zone - Battle Pet Collection")
    
    -- Filtros superiores (estilo Wardrobe)
    local filterFrame = CreateFrame("Frame", nil, content)
    filterFrame:SetSize(390, 35)
    filterFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    -- Dropdown de categoria
    local categoryLabel = filterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    categoryLabel:SetPoint("LEFT", filterFrame, "LEFT", 0, 10)
    categoryLabel:SetText("Category:")
    
    local categoryDropdown = CreateFrame("Button", nil, filterFrame, "UIPanelButtonTemplate")
    categoryDropdown:SetSize(100, 20)
    categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 5, 0)
    categoryDropdown:SetText(system.selectedCategory)
    categoryDropdown:SetScript("OnClick", function()
        ClickMorphPetZone.ShowCategoryMenu(categoryDropdown)
    end)
    system.categoryDropdown = categoryDropdown
    
    -- Caixa de busca
    local searchLabel = filterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", categoryDropdown, "RIGHT", 20, 0)
    searchLabel:SetText("Search:")
    
    local searchBox = CreateFrame("EditBox", nil, filterFrame, "InputBoxTemplate")
    searchBox:SetSize(120, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        system.searchText = self:GetText()
        ClickMorphPetZone.RefreshPetGrid()
    end)
    
    -- Toggle API/Hardcode
    local apiToggle = CreateFrame("CheckButton", nil, filterFrame, "ChatConfigCheckButtonTemplate")
    apiToggle:SetPoint("RIGHT", filterFrame, "RIGHT", 0, 0)
    apiToggle:SetSize(20, 20)
    apiToggle.Text:SetText("Use API")
    apiToggle.Text:SetPoint("LEFT", apiToggle, "RIGHT", 2, 0)
    apiToggle:SetChecked(system.useAPIData)
    apiToggle:SetScript("OnClick", function(self)
        system.useAPIData = self:GetChecked()
        ClickMorphPetZone.RefreshPetGrid()
        PetDebugPrint("API mode:", system.useAPIData and "ON" or "OFF")
    end)
    
    -- Grid de pets (4x6)
    local gridFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    gridFrame:SetSize(340, 300)
    gridFrame:SetPoint("TOPLEFT", filterFrame, "BOTTOMLEFT", 0, -10)
    
    local gridContent = CreateFrame("Frame", nil, gridFrame)
    gridContent:SetSize(320, 800)
    gridFrame:SetScrollChild(gridContent)
    
    -- Criar grid de botões 4x8 = 32 pets
    local buttons = {}
    for i = 1, 32 do
        local button = ClickMorphPetZone.CreatePetButton(gridContent, i)
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        button:SetPoint("TOPLEFT", gridContent, "TOPLEFT", col * 45, -row * 45)
        buttons[i] = button
    end
    
    ClickMorphPetZone.petGrid = {
        frame = gridFrame,
        content = gridContent,
        buttons = buttons
    }
    
    -- Botões de ação na parte inferior
    local actionFrame = CreateFrame("Frame", nil, content)
    actionFrame:SetSize(340, 40)
    actionFrame:SetPoint("TOPLEFT", gridFrame, "BOTTOMLEFT", 0, -10)
    
    -- Botão Random
    local randomButton = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")
    randomButton:SetSize(80, 25)
    randomButton:SetPoint("LEFT", actionFrame, "LEFT", 0, 0)
    randomButton:SetText("Random")
    randomButton:SetScript("OnClick", function()
        local pets = ClickMorphPetZone.GetFilteredPets()
        if #pets > 0 then
            local randomPet = pets[math.random(#pets)]
            PetDebugPrint("Random pet morph:", randomPet.name)
            SendChatMessage(".morph " .. randomPet.displayID, "GUILD")
        end
    end)
    
    -- Botão Reset
    local resetButton = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(80, 25)
    resetButton:SetPoint("LEFT", randomButton, "RIGHT", 10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        PetDebugPrint("Resetting morph")
        SendChatMessage(".demorph", "GUILD")
    end)
    
    -- Botão Debug Toggle
    local debugButton = CreateFrame("Button", nil, actionFrame, "UIPanelButtonTemplate")  
    debugButton:SetSize(80, 25)
    debugButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    debugButton:SetText("Debug")
    debugButton:SetScript("OnClick", function()
        system.debugMode = not system.debugMode
        local status = system.debugMode and "ON" or "OFF"
        PetDebugPrint("Debug mode:", status)
        print("|cff00ccffPetZone Debug:|r", status)
    end)
    
    -- Info panel na parte inferior
    local infoFrame = CreateFrame("Frame", nil, content)
    infoFrame:SetSize(340, 60)
    infoFrame:SetPoint("TOPLEFT", actionFrame, "BOTTOMLEFT", 0, -10)
    
    local infoBg = infoFrame:CreateTexture(nil, "BACKGROUND")
    infoBg:SetAllPoints()
    infoBg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    
    local infoTitle = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    infoTitle:SetPoint("TOPLEFT", 5, -5)
    infoTitle:SetText("Pet Zone Info:")
    
    local infoText = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", infoTitle, "BOTTOMLEFT", 0, -2)
    infoText:SetWidth(330)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Left-click pets to morph. Use Random for surprise morphs.\nIncludes classic pets, battle pets, and exotic companions.")
    
    -- Inicializar grid
    ClickMorphPetZone.RefreshPetGrid()
    
    PetDebugPrint("PetZone interface created successfully")
    
    return content
end

-- Sistema de ativação/desativação
function ClickMorphPetZone.ToggleSystem()
    local system = ClickMorphPetZone.petSystem
    
    if system.isActive then
        ClickMorphPetZone.DisableSystem()
    else
        ClickMorphPetZone.EnableSystem()
    end
end

function ClickMorphPetZone.EnableSystem()
    local system = ClickMorphPetZone.petSystem
    
    if not system.isActive then
        system.isActive = true
        PetDebugPrint("PetZone system enabled")
        return true
    end
    return false
end

function ClickMorphPetZone.DisableSystem()
    local system = ClickMorphPetZone.petSystem
    
    if system.isActive then
        system.isActive = false
        PetDebugPrint("PetZone system disabled")
        return true
    end
    return false
end

-- Comandos do PetZone
SLASH_CLICKMORPH_PETZONE1 = "/cmpets"
SlashCmdList.CLICKMORPH_PETZONE = function(arg)
    local command = string.lower(arg or "")
    
    if command == "toggle" or command == "" then
        ClickMorphPetZone.ToggleSystem()
        local status = ClickMorphPetZone.petSystem.isActive and "enabled" or "disabled"
        print("|cff00ccffPetZone:|r System " .. status)
    elseif command == "debug" then
        ClickMorphPetZone.petSystem.debugMode = not ClickMorphPetZone.petSystem.debugMode
        local status = ClickMorphPetZone.petSystem.debugMode and "ON" or "OFF"
        print("|cff00ccffPetZone:|r Debug mode " .. status)
    elseif command == "api" then
        ClickMorphPetZone.petSystem.useAPIData = not ClickMorphPetZone.petSystem.useAPIData
        local status = ClickMorphPetZone.petSystem.useAPIData and "ON" or "OFF"
        print("|cff00ccffPetZone:|r API mode " .. status)
        ClickMorphPetZone.RefreshPetGrid()
    elseif command == "status" then
        local system = ClickMorphPetZone.petSystem
        print("|cff00ccff=== PETZONE STATUS ===|r")
        print("Active:", system.isActive and "YES" or "NO")
        print("Debug Mode:", system.debugMode and "ON" or "OFF")
        print("API Mode:", system.useAPIData and "ON" or "OFF")
        print("Selected Category:", system.selectedCategory)
        print("Search Text:", system.searchText ~= "" and system.searchText or "None")
        
        local pets = ClickMorphPetZone.GetFilteredPets()
        print("Filtered Pets:", #pets)
    elseif command == "random" then
        local pets = ClickMorphPetZone.GetFilteredPets()
        if #pets > 0 then
            local randomPet = pets[math.random(#pets)]
            print("|cff00ccffPetZone:|r Random morph: " .. randomPet.name)
            SendChatMessage(".morph " .. randomPet.displayID, "GUILD")
        else
            print("|cff00ccffPetZone:|r No pets available for random morph")
        end
    else
        print("|cff00ccffPetZone Commands:|r")
        print("/cmpets toggle - Toggle PetZone system")
        print("/cmpets debug - Toggle debug mode")
        print("/cmpets api - Toggle API data usage")
        print("/cmpets status - Show system status")
        print("/cmpets random - Apply random pet morph")
    end
end

-- Inicialização
local function Initialize()
    PetDebugPrint("Initializing PetZone system...")
    
    -- Registrar eventos se necessário
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            PetDebugPrint("ClickMorph loaded, PetZone ready")
        end
    end)
end

Initialize()

PetDebugPrint("PetZone.lua loaded successfully")
print("|cff00ccffClickMorph PetZone|r loaded!")
print("Use |cffffcc00/cmpets|r to access pet morph commands")