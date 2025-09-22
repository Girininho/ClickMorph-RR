-- DruidForms.lua - Sistema aprimorado com APIs de descoberta para ClickMorph iMorph Edition
-- Interface Wardrobe com descoberta dinâmica de shapeshift forms

ClickMorphDruidForms = {}

-- Sistema de formas de druida
ClickMorphDruidForms.formSystem = {
    isActive = false,
    selectedForm = nil,
    selectedCategory = "All",
    debugMode = false,
    searchText = "",
    useAPIData = false -- Toggle para usar dados descobertos vs hardcode
}

-- Debug print específico das formas
local function DruidDebugPrint(...)
    if ClickMorphDruidForms.formSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cff00cc66Druid:|r", table.concat(args, " "))
    end
end

-- ============================================================================
-- SEÇÃO DE TESTES: APIs PARA DESCOBRIR SHAPESHIFT FORMS DINÂMICAMENTE
-- Descomente essas seções quando estiver no WoW para testar
-- ============================================================================

--[[
-- Teste 1: Descobrir formas através da Spell API
function ClickMorphDruidForms.TestShapeshiftSpellAPI()
    DruidDebugPrint("=== TESTE: Shapeshift Spell API ===")
    local discoveredForms = {}
    
    -- IDs conhecidos de spells de shapeshift de druida
    local knownShapeshiftSpells = {
        768,   -- Cat Form
        783,   -- Travel Form  
        1066,  -- Aquatic Form
        5487,  -- Bear Form
        9634,  -- Dire Bear Form
        24858, -- Moonkin Form
        33943, -- Flight Form
        40120, -- Swift Flight Form
        -- Adicione mais IDs conhecidos aqui
    }
    
    for _, spellID in ipairs(knownShapeshiftSpells) do
        local name, _, icon = GetSpellInfo(spellID)
        if name and icon then
            -- Tentar descobrir FormID associado
            local formID = ClickMorphDruidForms.GuessFormIDFromSpell(spellID)
            
            table.insert(discoveredForms, {
                name = name,
                formID = formID or 0,
                displayID = 0, -- Será descoberto por teste
                icon = icon,
                source = "Spell API - ID " .. spellID,
                category = "Discovered",
                rarity = 2,
                spellID = spellID
            })
            
            DruidDebugPrint("Forma encontrada via spell:", name, "SpellID:", spellID, "FormID:", formID or "desconhecido")
        end
    end
    
    return discoveredForms
end

-- Teste 2: Descobrir Display IDs para formas conhecidas
function ClickMorphDruidForms.TestShapeshiftDisplayIDs(formID, startDisplayID, endDisplayID)
    DruidDebugPrint("=== TESTE: Display IDs para FormID", formID, "range", startDisplayID, "ate", endDisplayID, "===")
    local validDisplayIDs = {}
    
    for displayID = startDisplayID, endDisplayID do
        -- Tentar comando shapeshift para ver se funciona
        local testCmd = string.format(".shapeshift %d %d", formID, displayID)
        DruidDebugPrint("Testando:", testCmd)
        
        -- DESCOMENTE para testar de verdade (vai fazer os shapeshifts)
        -- SendChatMessage(testCmd, "SAY")
        -- C_Timer.After(0.2, function()
        --     -- Aqui você poderia verificar se o shapeshift funcionou
        --     -- comparando o modelo do player antes/depois
        --     table.insert(validDisplayIDs, displayID)
        -- end)
        
        -- Delay para não sobrecarregar
        if displayID % 5 == 0 then
            C_Timer.After(0.1, function() end)
        end
    end
    
    return validDisplayIDs
end

-- Teste 3: Validar FormID por força bruta
function ClickMorphDruidForms.TestFormIDRange(startFormID, endFormID)
    DruidDebugPrint("=== TESTE: FormID range", startFormID, "ate", endFormID, "===")
    
    for formID = startFormID, endFormID do
        -- Testar com Display ID padrão (0 ou conhecido)
        local testCmd = string.format(".shapeshift %d", formID)
        DruidDebugPrint("Testando FormID:", formID)
        
        -- DESCOMENTE para testar
        -- SendChatMessage(testCmd, "SAY")
        -- C_Timer.After(1, function()
        --     -- Verificar se funcionou
        --     DruidDebugPrint("FormID", formID, "testado")
        -- end)
        
        C_Timer.After(formID - startFormID + 1, function() end)
    end
end

-- Teste 4: Descobrir formas através do Talent/Spec system
function ClickMorphDruidForms.TestDruidSpecForms()
    DruidDebugPrint("=== TESTE: Formas por especialização ===")
    
    local playerClass = select(2, UnitClass("player"))
    if playerClass ~= "DRUID" then
        DruidDebugPrint("Player nao e druida - teste limitado")
        return {}
    end
    
    local discoveredForms = {}
    
    -- Verificar spec atual
    if GetSpecialization then
        local currentSpec = GetSpecialization()
        local specName = currentSpec and select(2, GetSpecializationInfo(currentSpec))
        
        DruidDebugPrint("Spec atual:", specName or "desconhecida")
        
        -- Mapear specs para formas conhecidas
        local specForms = {
            [1] = "Balance", -- Moonkin
            [2] = "Feral",   -- Cat/Bear
            [3] = "Guardian", -- Bear
            [4] = "Restoration" -- Travel/Aquatic
        }
        
        local specCategory = specForms[currentSpec or 0]
        if specCategory then
            DruidDebugPrint("Categoria de formas:", specCategory)
        end
    end
    
    -- Testar spells de shapeshift conhecidos
    local druidShapeshifts = {
        {spell = 768, name = "Cat Form", category = "Feral"},
        {spell = 783, name = "Travel Form", category = "Travel"},
        {spell = 5487, name = "Bear Form", category = "Guardian"},
        {spell = 24858, name = "Moonkin Form", category = "Balance"}
    }
    
    for _, form in ipairs(druidShapeshifts) do
        if IsSpellKnown(form.spell) then
            DruidDebugPrint("Forma conhecida:", form.name)
            table.insert(discoveredForms, {
                name = form.name,
                spellID = form.spell,
                category = form.category,
                source = "Known Spell",
                rarity = 3
            })
        end
    end
    
    return discoveredForms
end

-- Teste 5: Descobrir ícones de shapeshift automaticamente
function ClickMorphDruidForms.TestShapeshiftIcons()
    DruidDebugPrint("=== TESTE: Descobrir icones de shapeshift ===")
    
    local foundIcons = {}
    
    -- Paths conhecidos de ícones de druida
    local druidIconPaths = {
        "Interface\\Icons\\Ability_Druid_",
        "Interface\\Icons\\Spell_Nature_",
        "Interface\\Icons\\INV_Misc_MonsterClaw_"
    }
    
    local commonDruidSuffixes = {
        "CatForm", "BearForm", "AquaticForm", "FlightForm", "TravelForm",
        "Moonkin", "TreeForm", "StagForm", "OwlForm"
    }
    
    for _, basePath in ipairs(druidIconPaths) do
        for _, suffix in ipairs(commonDruidSuffixes) do
            local iconPath = basePath .. suffix
            table.insert(foundIcons, iconPath)
            DruidDebugPrint("Testando icone:", iconPath)
        end
    end
    
    return foundIcons
end

-- Teste 6: Hook para detectar mudanças de shapeshift
function ClickMorphDruidForms.TestShapeshiftDetection()
    DruidDebugPrint("=== TESTE: Deteccao de mudancas de shapeshift ===")
    
    -- Hook para detectar quando player muda de forma
    local function OnShapeshiftChanged()
        local formID = GetShapeshiftFormID and GetShapeshiftFormID() or 0
        DruidDebugPrint("Shapeshift detectado - FormID:", formID)
        
        -- Tentar obter informações da forma atual
        if GetShapeshiftForm then
            local currentForm = GetShapeshiftForm()
            DruidDebugPrint("Forma atual:", currentForm)
        end
        
        return formID
    end
    
    -- Registrar event para detectar mudanças
    local shapeshiftFrame = CreateFrame("Frame")
    shapeshiftFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    shapeshiftFrame:SetScript("OnEvent", function(self, event)
        if event == "UPDATE_SHAPESHIFT_FORM" then
            OnShapeshiftChanged()
        end
    end)
    
    DruidDebugPrint("Hook de deteccao registrado")
end

-- Função auxiliar para tentar descobrir FormID baseado em SpellID
function ClickMorphDruidForms.GuessFormIDFromSpell(spellID)
    -- Mapeamento conhecido de SpellID para FormID
    local spellToFormMap = {
        [768] = 1,    -- Cat Form
        [783] = 3,    -- Travel Form
        [1066] = 4,   -- Aquatic Form
        [5487] = 5,   -- Bear Form
        [9634] = 5,   -- Dire Bear Form (mesmo que Bear)
        [24858] = 31, -- Moonkin Form
        [33943] = 29, -- Flight Form
        [40120] = 27  -- Swift Flight Form
    }
    
    return spellToFormMap[spellID]
end

-- Teste combinado - descobrir tudo
function ClickMorphDruidForms.RunFullDiscovery()
    DruidDebugPrint("=== DESCOBERTA COMPLETA DE FORMAS ===")
    
    local allDiscovered = {}
    
    -- Teste 1: Spells
    local spellForms = ClickMorphDruidForms.TestShapeshiftSpellAPI()
    for _, form in ipairs(spellForms) do
        table.insert(allDiscovered, form)
    end
    
    -- Teste 2: Spec forms
    local specForms = ClickMorphDruidForms.TestDruidSpecForms()
    for _, form in ipairs(specForms) do
        table.insert(allDiscovered, form)
    end
    
    -- Teste 3: Icons
    local icons = ClickMorphDruidForms.TestShapeshiftIcons()
    DruidDebugPrint("Encontrados", #icons, "icones potenciais")
    
    DruidDebugPrint("=== DESCOBERTA COMPLETA:", #allDiscovered, "formas encontradas ===")
    return allDiscovered
end
--]]

-- Base de dados expandida (hardcode + slots para descoberta)
ClickMorphDruidForms.DRUID_FORMS = {
    {
        name = "Cat Forms",
        category = "Feral",
        icon = "Interface\\Icons\\Ability_Druid_CatForm",
        forms = {
            {
                name = "Cat Form", 
                formID = 1, 
                displayID = 892, 
                description = "Classic cat form", 
                icon = "Interface\\Icons\\Ability_Druid_CatForm",
                rarity = 1,
                source = "Basic Druid Form"
            },
            {
                name = "White Cat", 
                formID = 1, 
                displayID = 9991, 
                description = "Pristine white cat variant", 
                icon = "Interface\\Icons\\Ability_Mount_WhiteTiger",
                rarity = 2,
                source = "Night Elf Heritage"
            },
            {
                name = "Black Panther", 
                formID = 1, 
                displayID = 9992, 
                description = "Sleek black panther form", 
                icon = "Interface\\Icons\\Ability_Mount_BlackPanther",
                rarity = 3,
                source = "Shadowmeld Mastery"
            },
            {
                name = "Saberon Cat", 
                formID = 1, 
                displayID = 52104, 
                description = "Exotic Draenor saberon style", 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
                rarity = 4,
                source = "Draenor Expedition"
            }
        }
    },
    {
        name = "Bear Forms",
        category = "Guardian", 
        icon = "Interface\\Icons\\Ability_Racial_BearForm",
        forms = {
            {
                name = "Bear Form", 
                formID = 5, 
                displayID = 2281, 
                description = "Classic brown bear form", 
                icon = "Interface\\Icons\\Ability_Racial_BearForm",
                rarity = 1,
                source = "Basic Druid Form"
            },
            {
                name = "Polar Bear", 
                formID = 5, 
                displayID = 29422, 
                description = "Arctic polar bear", 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
                rarity = 2,
                source = "Winterspring Training"
            },
            {
                name = "Black Bear", 
                formID = 5, 
                displayID = 29423, 
                description = "Intimidating black bear", 
                icon = "Interface\\Icons\\INV_Misc_Pelt_Bear_03",
                rarity = 3,
                source = "Felwood Corruption"
            },
            {
                name = "Dire Bear", 
                formID = 5, 
                displayID = 29424, 
                description = "Massive dire bear form", 
                icon = "Interface\\Icons\\Ability_Druid_ChallengingRoar",
                rarity = 4,
                source = "Ancient Guardian"
            }
        }
    },
    {
        name = "Flight Forms",
        category = "Travel",
        icon = "Interface\\Icons\\Ability_Druid_FlightForm",
        forms = {
            {
                name = "Storm Crow", 
                formID = 29, 
                displayID = 20857, 
                description = "Classic storm crow flight", 
                icon = "Interface\\Icons\\Ability_Druid_FlightForm",
                rarity = 1,
                source = "Basic Flight Form"
            },
            {
                name = "Swift Flight", 
                formID = 27, 
                displayID = 21243, 
                description = "Enhanced flight speed", 
                icon = "Interface\\Icons\\Spell_Nature_WispSplode",
                rarity = 2,
                source = "Swift Flight Training"
            },
            {
                name = "Raven Form", 
                formID = 29, 
                displayID = 21244, 
                description = "Dark raven flight form", 
                icon = "Interface\\Icons\\Spell_Magic_FeatherFall",
                rarity = 3,
                source = "Shadow Grove"
            }
        }
    },
    {
        name = "Moonkin Forms",
        category = "Balance",
        icon = "Interface\\Icons\\Spell_Nature_ForceOfNature",
        forms = {
            {
                name = "Moonkin", 
                formID = 31, 
                displayID = 15374, 
                description = "Classic moonkin form", 
                icon = "Interface\\Icons\\Spell_Nature_ForceOfNature",
                rarity = 1,
                source = "Balance Specialization"
            },
            {
                name = "Screecher", 
                formID = 31, 
                displayID = 15375, 
                description = "Fierce screecher variant", 
                icon = "Interface\\Icons\\Ability_Druid_Eclipse",
                rarity = 3,
                source = "Lunar Eclipse Mastery"
            }
        }
    },
    {
        name = "Aquatic Forms",
        category = "Travel",
        icon = "Interface\\Icons\\Ability_Druid_AquaticForm",
        forms = {
            {
                name = "Seal Form", 
                formID = 4, 
                displayID = 2428, 
                description = "Swift aquatic seal", 
                icon = "Interface\\Icons\\Ability_Druid_AquaticForm",
                rarity = 1,
                source = "Basic Aquatic Form"
            },
            {
                name = "Orca", 
                formID = 4, 
                displayID = 30221, 
                description = "Majestic orca whale", 
                icon = "Interface\\Icons\\Ability_Hunter_Pet_Whale",
                rarity = 4,
                source = "Deep Ocean Mastery"
            }
        }
    }
}

-- Aplicar forma usando .shapeshift
function ClickMorphDruidForms.ApplyDruidForm(formData)
    if not formData or not formData.formID then
        print("|cffff0000Druid Forms:|r Invalid form data")
        return false
    end
    
    DruidDebugPrint("Applying form:", formData.name, "FormID:", formData.formID, "DisplayID:", formData.displayID)
    
    local shapeshiftCmd = string.format(".shapeshift %d %d", formData.formID, formData.displayID)
    SendChatMessage(shapeshiftCmd, "SAY")
    
    ClickMorphDruidForms.formSystem.selectedForm = formData
    print("|cff00ff00Druid Forms:|r Applied " .. formData.name)
    
    -- Integrar com MagiButton
    if ClickMorphMagiButton and ClickMorphMagiButton.system then
        ClickMorphMagiButton.system.currentMorph.shapeshift = {
            formID = formData.formID,
            displayID = formData.displayID,
            name = formData.name
        }
    end
    
    return true
end

-- Reset para forma original
function ClickMorphDruidForms.ResetToPlayerForm()
    DruidDebugPrint("Resetting shapeshift")
    
    SendChatMessage(".shapeshift reset", "SAY")
    ClickMorphDruidForms.formSystem.selectedForm = nil
    print("|cff00ff00Druid Forms:|r Reset to normal form")
end

-- Filtrar formas baseado na categoria e busca (híbrido API + hardcode)
function ClickMorphDruidForms.GetFilteredForms()
    local system = ClickMorphDruidForms.formSystem
    local allForms = {}
    
    -- ============================================================================
    -- DESCOMENTE PARA TESTAR DADOS DESCOBERTOS DINAMICAMENTE
    -- ============================================================================
    --[[
    if system.useAPIData then
        DruidDebugPrint("Tentando usar dados descobertos...")
        
        -- Descobrir formas dinamicamente
        local discoveredForms = ClickMorphDruidForms.RunFullDiscovery()
        for _, form in ipairs(discoveredForms) do
            table.insert(allForms, form)
        end
        
        DruidDebugPrint("Carregadas", #allForms, "formas descobertas")
        
        -- Se descoberta falhou, volta para hardcode
        if #allForms == 0 then
            DruidDebugPrint("Descoberta falhou, usando dados hardcode")
            system.useAPIData = false
        end
    end
    --]]
    
    -- Usar dados hardcoded
    if not system.useAPIData then
        for _, category in ipairs(ClickMorphDruidForms.DRUID_FORMS) do
            if system.selectedCategory == "All" or category.category == system.selectedCategory then
                for _, form in ipairs(category.forms) do
                    -- Filtro de busca
                    if system.searchText == "" or 
                       string.find(string.lower(form.name), string.lower(system.searchText)) or
                       string.find(string.lower(form.description), string.lower(system.searchText)) then
                        table.insert(allForms, form)
                    end
                end
            end
        end
    end
    
    return allForms
end

-- Resto do código permanece igual...
-- (funções de interface, cores, etc. do arquivo original)

-- Cores por raridade (estilo WoW)
function ClickMorphDruidForms.GetRarityColor(rarity)
    local colors = {
        [1] = {1, 1, 1},        -- White (Common)
        [2] = {0.12, 1, 0},     -- Green (Uncommon)  
        [3] = {0, 0.44, 0.87},  -- Blue (Rare)
        [4] = {0.64, 0.21, 0.93} -- Purple (Epic)
    }
    return colors[rarity] or colors[1]
end

-- Interface creation (mantém código original mas adiciona toggle API)
function ClickMorphDruidForms.CreateDruidFormsContent(parentFrame)
    local system = ClickMorphDruidForms.formSystem
    
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Druid Forms Collection")
    
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
        ClickMorphDruidForms.ShowCategoryMenu(categoryDropdown)
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
        ClickMorphDruidForms.RefreshFormGrid()
    end)
    system.searchBox = searchBox
    
    -- ============================================================================
    -- TOGGLE PARA TESTES DA API (descomente para testar)
    -- ============================================================================
    --[[
    local apiToggle = CreateFrame("CheckButton", nil, filterFrame, "ChatConfigCheckButtonTemplate")
    apiToggle:SetPoint("LEFT", searchBox, "RIGHT", 15, 0)
    apiToggle.Text:SetText("Test Discovery")
    apiToggle:SetScript("OnClick", function(self)
        system.useAPIData = self:GetChecked()
        ClickMorphDruidForms.RefreshFormGrid()
        DruidDebugPrint("API Discovery mode:", system.useAPIData and "ON" or "OFF")
    end)
    --]]
    
    -- Área do grid (estilo Collections)
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(375, 280)
    scrollFrame:SetPoint("TOPLEFT", filterFrame, "BOTTOMLEFT", 0, -10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(350, 1000)
    system.scrollChild = scrollChild
    
    -- Info panel (estilo Wardrobe)
    local infoFrame = CreateFrame("Frame", nil, content)
    infoFrame:SetSize(390, 80)
    infoFrame:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    
    local infoBg = infoFrame:CreateTexture(nil, "BACKGROUND")
    infoBg:SetAllPoints()
    infoBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Ícone da forma selecionada
    local selectedIcon = infoFrame:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(48, 48)
    selectedIcon:SetPoint("LEFT", infoFrame, "LEFT", 10, 0)
    selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    system.selectedIcon = selectedIcon
    
    -- Info texto
    local selectedName = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    selectedName:SetPoint("TOPLEFT", selectedIcon, "TOPRIGHT", 10, 0)
    selectedName:SetText("No form selected")
    system.selectedName = selectedName
    
    local selectedDesc = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectedDesc:SetPoint("TOPLEFT", selectedName, "BOTTOMLEFT", 0, -5)
    selectedDesc:SetWidth(280)
    selectedDesc:SetJustifyH("LEFT")
    selectedDesc:SetText("")
    system.selectedDesc = selectedDesc
    
    local selectedSource = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectedSource:SetPoint("TOPLEFT", selectedDesc, "BOTTOMLEFT", 0, -5)
    selectedSource:SetTextColor(0.8, 0.8, 0.8)
    selectedSource:SetText("")
    system.selectedSource = selectedSource
    
    -- Botão Apply
    local applyBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(80, 25)
    applyBtn:SetPoint("RIGHT", infoFrame, "RIGHT", -10, 0)
    applyBtn:SetText("Apply Form")
    applyBtn:SetScript("OnClick", function()
        if system.selectedFormData then
            ClickMorphDruidForms.ApplyDruidForm(system.selectedFormData)
        end
    end)
    system.applyBtn = applyBtn
    
    -- Botão Reset
    local resetBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(60, 25)
    resetBtn:SetPoint("RIGHT", applyBtn, "LEFT", -5, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        ClickMorphDruidForms.ResetToPlayerForm()
        ClickMorphDruidForms.ClearSelection()
    end)
    
    system.isActive = true
    system.contentFrame = content
    
    -- Inicializar grid
    ClickMorphDruidForms.RefreshFormGrid()
    
    DruidDebugPrint("Druid Forms interface created with discovery APIs")
    return content
end

-- Refresh do grid (mantém código original)
function ClickMorphDruidForms.RefreshFormGrid()
    local system = ClickMorphDruidForms.formSystem
    
    if not system.scrollChild then return end
    
    -- Limpar botões existentes
    if system.formButtons then
        for _, btn in pairs(system.formButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    system.formButtons = {}
    
    -- Obter formas filtradas
    local forms = ClickMorphDruidForms.GetFilteredForms()
    
    -- Criar grid (5 colunas, estilo Collections)
    local cols = 5
    local buttonSize = 64
    local spacing = 4
    
    for i, form in ipairs(forms) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        
        local btn = CreateFrame("Button", nil, system.scrollChild)
        btn:SetSize(buttonSize, buttonSize)
        btn:SetPoint("TOPLEFT", col * (buttonSize + spacing) + 5, -(row * (buttonSize + spacing)) - 5)
        
        -- Ícone da forma
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(buttonSize - 4, buttonSize - 4)
        icon:SetPoint("CENTER")
        icon:SetTexture(form.icon)
        btn.icon = icon
        
        -- Border por raridade
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(btn)
        border:SetTexture("Interface\\Common\\WhiteIconFrame")
        local r, g, b = unpack(ClickMorphDruidForms.GetRarityColor(form.rarity))
        border:SetVertexColor(r, g, b, 0.8)
        btn.border = border
        
        -- Selected highlight
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        
        -- Clique para selecionar
        btn:SetScript("OnClick", function()
            ClickMorphDruidForms.SelectForm(form, btn)
        end)
        
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(form.name, unpack(ClickMorphDruidForms.GetRarityColor(form.rarity)))
            GameTooltip:AddLine(form.description, 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("FormID: " .. form.formID .. " DisplayID: " .. form.displayID, 0.6, 0.6, 1)
            GameTooltip:AddLine("Source: " .. form.source, 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Click to select", 0, 1, 0)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(system.formButtons, btn)
    end
    
    DruidDebugPrint("Grid refreshed with", #forms, "forms")
end

-- Selecionar forma
function ClickMorphDruidForms.SelectForm(formData, button)
    local system = ClickMorphDruidForms.formSystem
    
    -- Remover seleção anterior
    if system.selectedButton then
        system.selectedButton:SetNormalTexture("")
    end
    
    -- Aplicar nova seleção
    system.selectedFormData = formData
    system.selectedButton = button
    
    -- Visual da seleção
    local selectedTex = button:CreateTexture(nil, "BACKGROUND")
    selectedTex:SetAllPoints()
    selectedTex:SetColorTexture(1, 1, 0, 0.3)
    button:SetNormalTexture(selectedTex)
    
    -- Atualizar info panel
    system.selectedIcon:SetTexture(formData.icon)
    system.selectedName:SetText(formData.name)
    local r, g, b = unpack(ClickMorphDruidForms.GetRarityColor(formData.rarity))
    system.selectedName:SetTextColor(r, g, b)
    
    system.selectedDesc:SetText(formData.description)
    system.selectedSource:SetText("Source: " .. formData.source)
    
    DruidDebugPrint("Selected form:", formData.name)
end

-- Limpar seleção
function ClickMorphDruidForms.ClearSelection()
    local system = ClickMorphDruidForms.formSystem
    
    if system.selectedButton then
        system.selectedButton:SetNormalTexture("")
    end
    
    system.selectedFormData = nil
    system.selectedButton = nil
    
    system.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    system.selectedName:SetText("No form selected")
    system.selectedName:SetTextColor(1, 1, 1)
    system.selectedDesc:SetText("")
    system.selectedSource:SetText("")
end

-- Menu dropdown de categoria
function ClickMorphDruidForms.ShowCategoryMenu(parent)
    local system = ClickMorphDruidForms.formSystem
    
    local menu = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    
    local categories = {"All"}
    for _, cat in ipairs(ClickMorphDruidForms.DRUID_FORMS) do
        if not tContains(categories, cat.category) then
            table.insert(categories, cat.category)
        end
    end
    
    local function OnClick(self)
        system.selectedCategory = self.value
        system.categoryDropdown:SetText(self.value)
        ClickMorphDruidForms.RefreshFormGrid()
        CloseDropDownMenus()
    end
    
    local info = {}
    for _, category in ipairs(categories) do
        info = UIDropDownMenu_CreateInfo()
        info.text = category
        info.value = category
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
    
    ToggleDropDownMenu(1, nil, menu, parent, 0, 0)
end

-- Status do sistema
function ClickMorphDruidForms.ShowStatus()
    local system = ClickMorphDruidForms.formSystem
    
    print("|cff00ff00=== DRUID FORMS STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Selected Category:", system.selectedCategory)
    print("Search Text:", system.searchText ~= "" and system.searchText or "None")
    print("Use API Data:", system.useAPIData and "YES" or "NO")
    
    local playerClass = select(2, UnitClass("player"))
    print("Player Class:", playerClass)
    print("Is Druid:", playerClass == "DRUID" and "YES" or "NO")
    
    local totalForms = 0
    for _, cat in ipairs(ClickMorphDruidForms.DRUID_FORMS) do
        totalForms = totalForms + #cat.forms
    end
    print("Total Hardcoded Forms:", totalForms)
    
    if system.selectedFormData then
        print("Selected Form:", system.selectedFormData.name)
    end
    
    -- Status de shapeshift atual
    if GetShapeshiftFormID then
        local currentFormID = GetShapeshiftFormID()
        print("Current Shapeshift FormID:", currentFormID or "None")
    end
end

-- Comandos expandidos para testes
SLASH_CLICKMORPH_DRUID1 = "/cmdruid"
SlashCmdList.CLICKMORPH_DRUID = function(arg)
    local args = {}
    for word in arg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = string.lower(args[1] or "")
    
    if command == "reset" then
        ClickMorphDruidForms.ResetToPlayerForm()
    elseif command == "status" then
        ClickMorphDruidForms.ShowStatus()
    elseif command == "debug" then
        ClickMorphDruidForms.formSystem.debugMode = not ClickMorphDruidForms.formSystem.debugMode
        print("|cff00ff00Druid Forms:|r Debug mode", ClickMorphDruidForms.formSystem.debugMode and "ON" or "OFF")
    
    -- ============================================================================
    -- COMANDOS DE TESTE (descomente para usar)
    -- ============================================================================
    --[[
    elseif command == "testapi" then
        ClickMorphDruidForms.formSystem.useAPIData = not ClickMorphDruidForms.formSystem.useAPIData
        print("|cff00ff00Druid Forms:|r API Discovery mode", ClickMorphDruidForms.formSystem.useAPIData and "ON" or "OFF")
        if ClickMorphDruidForms.formSystem.contentFrame then
            ClickMorphDruidForms.RefreshFormGrid()
        end
    elseif command == "testspells" then
        local forms = ClickMorphDruidForms.TestShapeshiftSpellAPI()
        print("|cff00ff00Druid Forms:|r Found", #forms, "forms via Spell API")
    elseif command == "testspec" then
        local forms = ClickMorphDruidForms.TestDruidSpecForms()
        print("|cff00ff00Druid Forms:|r Found", #forms, "spec-related forms")
    elseif command == "testformids" then
        local startID = tonumber(args[2]) or 1
        local endID = tonumber(args[3]) or 50
        print("|cff00ff00Druid Forms:|r Testing FormIDs", startID, "to", endID)
        ClickMorphDruidForms.TestFormIDRange(startID, endID)
    elseif command == "testdisplays" then
        local formID = tonumber(args[2]) or 1
        local startDisplayID = tonumber(args[3]) or 1000
        local endDisplayID = tonumber(args[4]) or 1100
        print("|cff00ff00Druid Forms:|r Testing DisplayIDs for FormID", formID)
        ClickMorphDruidForms.TestShapeshiftDisplayIDs(formID, startDisplayID, endDisplayID)
    elseif command == "testdetect" then
        ClickMorphDruidForms.TestShapeshiftDetection()
        print("|cff00ff00Druid Forms:|r Shapeshift detection hook activated")
    elseif command == "discovery" then
        local forms = ClickMorphDruidForms.RunFullDiscovery()
        print("|cff00ff00Druid Forms:|r Full discovery completed -", #forms, "forms found")
    --]]
    
    else
        print("|cff00ff00Druid Forms Commands:|r")
        print("/cmdruid reset - Reset to normal form")
        print("/cmdruid status - Show system status") 
        print("/cmdruid debug - Toggle debug mode")
        
        -- COMANDOS DE TESTE (descomente as linhas abaixo para mostrar)
        --print("/cmdruid testapi - Toggle API discovery mode")
        --print("/cmdruid testspells - Test Spell API for forms")
        --print("/cmdruid testspec - Test spec-based form discovery")
        --print("/cmdruid testformids <start> <end> - Test FormID range")
        --print("/cmdruid testdisplays <formID> <startDisplay> <endDisplay> - Test DisplayID range")
        --print("/cmdruid testdetect - Enable shapeshift change detection")
        --print("/cmdruid discovery - Run full form discovery")
        
        print("")
        print("Use the iMorph tab for the full Wardrobe-style interface!")
    end
end

print("|cff00ff00ClickMorph Druid Forms - Enhanced with Discovery APIs|r loaded!")
print("|cff00ff00Druid Forms:|r Uncomment API test sections in DruidForms.lua to enable experimental features")