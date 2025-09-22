-- NPCExplorer.lua - Explorador de assets exclusivos de NPCs
-- Descobrir e usar items/armas/armaduras que só NPCs podem usar

ClickMorphNPCExplorer = {}

-- Sistema de explorer de NPCs
ClickMorphNPCExplorer.explorerSystem = {
    isActive = false,
    selectedCategory = "All",
    debugMode = false,
    searchText = "",
    useAPIDiscovery = false -- Toggle para descoberta dinâmica
}

-- Debug print
local function NPCDebugPrint(...)
    if ClickMorphNPCExplorer.explorerSystem.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cffffff00NPC:|r", table.concat(args, " "))
    end
end

-- ============================================================================
-- BASE DE DADOS DE ASSETS EXCLUSIVOS DE NPCS
-- ============================================================================

ClickMorphNPCExplorer.NPC_EXCLUSIVE_ASSETS = {
    -- Armas Lendárias de NPCs
    {
        name = "Legendary NPC Weapons",
        category = "Weapons", 
        icon = "Interface\\Icons\\INV_Sword_97",
        assets = {
            {
                name = "Frostmourne", 
                displayID = 49623, 
                icon = "Interface\\Icons\\INV_Sword_Frostmourne",
                description = "Lâmina maldita do Lich King", 
                rarity = 4,
                source = "Arthas/Lich King NPC",
                npcName = "The Lich King",
                slot = "MainHand",
                command = ".morphitem 16 49623"
            },
            {
                name = "Ashbringer (Corrupted)", 
                displayID = 21460, 
                icon = "Interface\\Icons\\INV_Sword_61",
                description = "Versão corrompida da Ashbringer", 
                rarity = 4,
                source = "Alexandros Mograine NPC",
                npcName = "Highlord Mograine",
                slot = "MainHand", 
                command = ".morphitem 16 21460"
            },
            {
                name = "Gorehowl (Grom's Version)", 
                displayID = 33479, 
                icon = "Interface\\Icons\\INV_Axe_68",
                description = "Versão única do Gorehowl", 
                rarity = 4,
                source = "Grommash Hellscream NPC",
                npcName = "Grommash Hellscream",
                slot = "MainHand",
                command = ".morphitem 16 33479"
            },
            {
                name = "Doomhammer (Thrall's)", 
                displayID = 45406, 
                icon = "Interface\\Icons\\INV_Hammer_25",
                description = "Martelo ancestral de Thrall", 
                rarity = 4,
                source = "Thrall NPC",
                npcName = "Thrall",
                slot = "MainHand",
                command = ".morphitem 16 45406"
            }
        }
    },
    -- Armaduras Únicas de NPCs
    {
        name = "Unique NPC Armor Sets",
        category = "Armor",
        icon = "Interface\\Icons\\INV_Chest_Plate15",
        assets = {
            {
                name = "Lich King Crown", 
                displayID = 50625, 
                icon = "Interface\\Icons\\INV_Crown_13",
                description = "Coroa do Lich King", 
                rarity = 4,
                source = "Arthas NPC",
                npcName = "The Lich King", 
                slot = "Head",
                command = ".morphitem 1 50625"
            },
            {
                name = "Illidan's Blindfold", 
                displayID = 28608, 
                icon = "Interface\\Icons\\INV_Misc_Bandana_03",
                description = "Venda característica do Illidan", 
                rarity = 4,
                source = "Illidan Stormrage NPC",
                npcName = "Illidan Stormrage",
                slot = "Head",
                command = ".morphitem 1 28608"
            },
            {
                name = "Malfurion's Antlers", 
                displayID = 51824, 
                icon = "Interface\\Icons\\INV_Helmet_126",
                description = "Chifres druídicos de Malfurion", 
                rarity = 4,
                source = "Malfurion Stormrage NPC",
                npcName = "Malfurion Stormrage",
                slot = "Head",
                command = ".morphitem 1 51824"
            },
            {
                name = "Sylvanas' Dark Ranger Armor", 
                displayID = 29506, 
                icon = "Interface\\Icons\\INV_Chest_Leather_14",
                description = "Armadura única da Banshee Queen", 
                rarity = 4,
                source = "Sylvanas Windrunner NPC",
                npcName = "Sylvanas Windrunner",
                slot = "Chest",
                command = ".morphitem 5 29506"
            }
        }
    },
    -- Acessórios e Items Únicos
    {
        name = "Unique NPC Accessories",
        category = "Accessories",
        icon = "Interface\\Icons\\INV_Jewelry_Necklace_07",
        assets = {
            {
                name = "Kael'thas Phoenix Orbs", 
                displayID = 34196, 
                icon = "Interface\\Icons\\INV_Offhand_Naxxramas_02",
                description = "Orbs de fênix flutuantes", 
                rarity = 4,
                source = "Kael'thas Sunstrider NPC",
                npcName = "Kael'thas Sunstrider",
                slot = "OffHand",
                command = ".morphitem 17 34196"
            },
            {
                name = "Ner'zhul's Skull", 
                displayID = 40401, 
                icon = "Interface\\Icons\\INV_Misc_Bone_ElfSkull_01",
                description = "Crânio espectral de Ner'zhul", 
                rarity = 4,
                source = "Ner'zhul NPC",
                npcName = "Ner'zhul",
                slot = "OffHand",
                command = ".morphitem 17 40401"
            }
        }
    },
    -- Montarias/Pets de NPCs
    {
        name = "NPC Exclusive Mounts",
        category = "Mounts",
        icon = "Interface\\Icons\\Ability_Mount_Drake_Proto",
        assets = {
            {
                name = "Deathwing Mount Form", 
                displayID = 35268, 
                icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
                description = "Forma de montaria do Deathwing", 
                rarity = 4,
                source = "Deathwing NPC",
                npcName = "Deathwing",
                slot = "Mount",
                command = ".morph 35268"
            },
            {
                name = "Lich King's Frostbrood", 
                displayID = 26752, 
                icon = "Interface\\Icons\\Ability_Mount_Drake_Bone",
                description = "Dragão gélido do Lich King", 
                rarity = 4,
                source = "Lich King Mount",
                npcName = "The Lich King",
                slot = "Mount", 
                command = ".morph 26752"
            }
        ]
    }
}

-- ============================================================================
-- SISTEMA DE DESCOBERTA DINÂMICA DE ASSETS DE NPCS
-- ============================================================================

--[[
-- Descobrir assets de NPCs automaticamente
function ClickMorphNPCExplorer.DiscoverNPCAssets()
    NPCDebugPrint("=== DESCOBERTA: Assets de NPCs ===")
    local discoveredAssets = {}
    
    -- Método 1: Escanear NPCs próximos
    local nearbyNPCs = ClickMorphNPCExplorer.GetNearbyNPCs()
    for _, npc in ipairs(nearbyNPCs) do
        local assets = ClickMorphNPCExplorer.ExtractNPCEquipment(npc)
        for _, asset in ipairs(assets) do
            table.insert(discoveredAssets, asset)
        end
    end
    
    -- Método 2: Usar creature database do cliente
    local creatureAssets = ClickMorphNPCExplorer.ScanCreatureDatabase()
    for _, asset in ipairs(creatureAssets) do
        table.insert(discoveredAssets, asset)
    end
    
    NPCDebugPrint("Descobertos", #discoveredAssets, "assets de NPCs")
    return discoveredAssets
end

-- Obter NPCs próximos para análise
function ClickMorphNPCExplorer.GetNearbyNPCs()
    local nearbyNPCs = {}
    
    -- Escanear nameplate de NPCs visíveis
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        if UnitExists(unitID) and not UnitIsPlayer(unitID) then
            local npcInfo = {
                name = UnitName(unitID),
                guid = UnitGUID(unitID),
                creatureID = ClickMorphNPCExplorer.GetCreatureID(UnitGUID(unitID))
            }
            table.insert(nearbyNPCs, npcInfo)
            NPCDebugPrint("NPC encontrado:", npcInfo.name, "ID:", npcInfo.creatureID)
        end
    end
    
    return nearbyNPCs
end

-- Extrair ID da criatura do GUID
function ClickMorphNPCExplorer.GetCreatureID(guid)
    if not guid then return nil end
    
    local creatureID = tonumber(string.match(guid, "Creature%-0%-%d+%-%d+%-%d+%-(%d+)"))
    return creatureID
end

-- Extrair equipamento de NPC específico
function ClickMorphNPCExplorer.ExtractNPCEquipment(npcInfo)
    local equipment = {}
    
    if not npcInfo.creatureID then return equipment end
    
    NPCDebugPrint("Extraindo equipamento do NPC:", npcInfo.name)
    
    -- EXPERIMENTAL: Tentar descobrir display IDs do equipamento
    -- Isto requer APIs avançadas que podem não estar disponíveis
    
    for slot = 1, 19 do -- Slots de equipamento padrão
        local displayID = ClickMorphNPCExplorer.GetNPCSlotDisplayID(npcInfo.creatureID, slot)
        if displayID and displayID > 0 then
            table.insert(equipment, {
                name = npcInfo.name .. " " .. ClickMorphNPCExplorer.GetSlotName(slot),
                displayID = displayID,
                slot = slot,
                source = "Discovered from " .. npcInfo.name,
                npcName = npcInfo.name,
                creatureID = npcInfo.creatureID
            })
            NPCDebugPrint("Equipment found - Slot:", slot, "DisplayID:", displayID)
        end
    end
    
    return equipment
end

-- Obter Display ID de slot específico de NPC (EXPERIMENTAL)
function ClickMorphNPCExplorer.GetNPCSlotDisplayID(creatureID, slot)
    -- Esta função precisaria acessar dados internos do cliente
    -- Pode não funcionar em todos os servidores/clientes
    
    -- Método experimental usando APIs do cliente
    if C_CreatureInfo and C_CreatureInfo.GetCreatureDisplayInfoByID then
        -- Tentar obter info de display da criatura
        local displayInfo = C_CreatureInfo.GetCreatureDisplayInfoByID(creatureID)
        if displayInfo then
            -- Extrair display ID do slot específico
            NPCDebugPrint("Tentando extrair slot", slot, "do creature", creatureID)
            return displayInfo.equipment and displayInfo.equipment[slot]
        end
    end
    
    return nil
end

-- Escanear database de criaturas do cliente
function ClickMorphNPCExplorer.ScanCreatureDatabase()
    NPCDebugPrint("=== ESCANEANDO: Database de criaturas ===")
    local foundAssets = {}
    
    -- Range de IDs de criaturas conhecidas para escanear
    local knownBossIDs = {
        36597, -- The Lich King
        22917, -- Illidan  
        24850, -- Kalecgos
        15348, -- Kurinnaxx
        -- Adicionar mais IDs de bosses conhecidos
    }
    
    for _, creatureID in ipairs(knownBossIDs) do
        local equipment = ClickMorphNPCExplorer.ExtractCreatureEquipment(creatureID)
        for _, item in ipairs(equipment) do
            table.insert(foundAssets, item)
        end
    end
    
    return foundAssets
end

-- Extrair equipamento de creature ID específico
function ClickMorphNPCExplorer.ExtractCreatureEquipment(creatureID)
    -- Implementação similar ao ExtractNPCEquipment
    -- mas usando creatureID diretamente
    
    local equipment = {}
    NPCDebugPrint("Extraindo equipment do creature ID:", creatureID)
    
    -- Tentar métodos diferentes de descobrir equipamento
    for slot = 1, 19 do
        local displayID = ClickMorphNPCExplorer.GetNPCSlotDisplayID(creatureID, slot)
        if displayID then
            table.insert(equipment, {
                displayID = displayID,
                slot = slot,
                creatureID = creatureID,
                source = "Creature Database"
            })
        end
    end
    
    return equipment
end
--]]

-- Obter nome do slot por ID
function ClickMorphNPCExplorer.GetSlotName(slotID)
    local slotNames = {
        [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest",
        [6] = "Belt", [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Gloves",
        [11] = "Finger1", [12] = "Finger2", [13] = "Trinket1", [14] = "Trinket2",
        [15] = "Back", [16] = "MainHand", [17] = "OffHand", [18] = "Ranged", [19] = "Tabard"
    }
    return slotNames[slotID] or "Unknown"
end

-- Aplicar asset de NPC
function ClickMorphNPCExplorer.ApplyNPCAsset(assetData)
    if not assetData or not assetData.command then
        print("|cffff0000NPC Explorer:|r Invalid asset data")
        return false
    end
    
    NPCDebugPrint("Applying NPC asset:", assetData.name)
    NPCDebugPrint("Command:", assetData.command)
    
    SendChatMessage(assetData.command, "SAY")
    
    print("|cff00ff00NPC Explorer:|r Applied " .. assetData.name .. " from " .. assetData.npcName)
    
    -- Integrar com MagiButton
    if ClickMorphMagiButton and ClickMorphMagiButton.system then
        ClickMorphMagiButton.system.currentMorph.npcAsset = {
            displayID = assetData.displayID,
            name = assetData.name,
            npcSource = assetData.npcName,
            slot = assetData.slot
        }
    end
    
    return true
end

-- Reset assets
function ClickMorphNPCExplorer.ResetAssets()
    NPCDebugPrint("Resetting NPC assets")
    
    SendChatMessage(".reset", "SAY")
    print("|cff00ff00NPC Explorer:|r Reset all NPC assets")
end

-- Obter assets filtrados
function ClickMorphNPCExplorer.GetFilteredAssets()
    local system = ClickMorphNPCExplorer.explorerSystem
    local allAssets = {}
    
    -- ============================================================================
    -- DESCOMENTE PARA USAR DESCOBERTA DINÂMICA
    -- ============================================================================
    --[[
    if system.useAPIDiscovery then
        NPCDebugPrint("Usando descoberta dinâmica de assets...")
        
        local discoveredAssets = ClickMorphNPCExplorer.DiscoverNPCAssets()
        for _, asset in ipairs(discoveredAssets) do
            table.insert(allAssets, asset)
        end
        
        NPCDebugPrint("Carregados", #allAssets, "assets descobertos")
        
        if #allAssets == 0 then
            NPCDebugPrint("Descoberta falhou, usando dados hardcode")
            system.useAPIDiscovery = false
        end
    end
    --]]
    
    -- Usar dados hardcoded
    if not system.useAPIDiscovery then
        for _, category in ipairs(ClickMorphNPCExplorer.NPC_EXCLUSIVE_ASSETS) do
            if system.selectedCategory == "All" or category.category == system.selectedCategory then
                for _, asset in ipairs(category.assets) do
                    -- Filtro de busca
                    if system.searchText == "" or 
                       string.find(string.lower(asset.name), string.lower(system.searchText)) or
                       string.find(string.lower(asset.npcName or ""), string.lower(system.searchText)) then
                        asset.categoryName = category.name
                        table.insert(allAssets, asset)
                    end
                end
            end
        end
    end
    
    return allAssets
end

-- Cores por raridade
function ClickMorphNPCExplorer.GetRarityColor(rarity)
    local colors = {
        [1] = {1, 1, 1},        -- White
        [2] = {0.12, 1, 0},     -- Green
        [3] = {0, 0.44, 0.87},  -- Blue
        [4] = {0.64, 0.21, 0.93}, -- Purple
        [5] = {1, 0.5, 0}       -- Orange (Legendary)
    }
    return colors[rarity] or colors[4]
end

-- Interface principal do NPC Explorer
function ClickMorphNPCExplorer.CreateNPCExplorerContent(parentFrame)
    local system = ClickMorphNPCExplorer.explorerSystem
    
    local content = CreateFrame("Frame", nil, parentFrame)
    content:SetAllPoints()
    
    -- Header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("NPC Assets Explorer")
    
    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(380)
    desc:SetText("Discover and use exclusive items, weapons, and armor that only NPCs possess")
    desc:SetJustifyH("LEFT")
    
    -- Filtros
    local filterFrame = CreateFrame("Frame", nil, content)
    filterFrame:SetSize(390, 35)
    filterFrame:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    
    local categoryLabel = filterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    categoryLabel:SetPoint("LEFT", 0, 10)
    categoryLabel:SetText("Category:")
    
    local categoryDropdown = CreateFrame("Button", nil, filterFrame, "UIPanelButtonTemplate")
    categoryDropdown:SetSize(100, 20)
    categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 5, 0)
    categoryDropdown:SetText("All")
    system.categoryDropdown = categoryDropdown
    
    local searchLabel = filterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", categoryDropdown, "RIGHT", 15, 0)
    searchLabel:SetText("Search:")
    
    local searchBox = CreateFrame("EditBox", nil, filterFrame, "InputBoxTemplate")
    searchBox:SetSize(120, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        system.searchText = self:GetText()
        ClickMorphNPCExplorer.RefreshAssetGrid()
    end)
    
    -- Grid de assets
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(375, 230)
    scrollFrame:SetPoint("TOPLEFT", filterFrame, "BOTTOMLEFT", 0, -10)
    
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
    
    -- Asset info
    local selectedIcon = infoFrame:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(48, 48)
    selectedIcon:SetPoint("LEFT", 10, 0)
    selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    system.selectedIcon = selectedIcon
    
    local selectedName = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    selectedName:SetPoint("TOPLEFT", selectedIcon, "TOPRIGHT", 10, 0)
    selectedName:SetText("No asset selected")
    system.selectedName = selectedName
    
    local selectedDesc = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectedDesc:SetPoint("TOPLEFT", selectedName, "BOTTOMLEFT", 0, -5)
    selectedDesc:SetWidth(250)
    selectedDesc:SetJustifyH("LEFT")
    system.selectedDesc = selectedDesc
    
    local selectedSource = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectedSource:SetPoint("TOPLEFT", selectedDesc, "BOTTOMLEFT", 0, -5)
    selectedSource:SetTextColor(0.8, 0.8, 0.8)
    system.selectedSource = selectedSource
    
    -- Botões de ação
    local applyBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(70, 25)
    applyBtn:SetPoint("RIGHT", -10, 10)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        if system.selectedAssetData then
            ClickMorphNPCExplorer.ApplyNPCAsset(system.selectedAssetData)
        end
    end)
    
    local resetBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(60, 25)
    resetBtn:SetPoint("RIGHT", applyBtn, "LEFT", -5, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        ClickMorphNPCExplorer.ResetAssets()
        ClickMorphNPCExplorer.ClearSelection()
    end)
    
    -- ============================================================================
    -- BOTÃO EXPERIMENTAL PARA DESCOBERTA (descomente para testar)
    -- ============================================================================
    --[[
    local discoverBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
    discoverBtn:SetSize(80, 25)
    discoverBtn:SetPoint("RIGHT", resetBtn, "LEFT", -5, 0)
    discoverBtn:SetText("Discover")
    discoverBtn:SetScript("OnClick", function()
        local discoveries = ClickMorphNPCExplorer.DiscoverNPCAssets()
        print("|cff00ff00NPC Explorer:|r Started NPC asset discovery")
        print("|cff00ff00NPC Explorer:|r Found", #discoveries, "potential assets")
    end)
    --]]
    
    system.isActive = true
    system.contentFrame = content
    
    -- Povoar grid inicial
    ClickMorphNPCExplorer.RefreshAssetGrid()
    
    NPCDebugPrint("NPC Explorer interface created")
    return content
end

-- Refresh grid de assets
function ClickMorphNPCExplorer.RefreshAssetGrid()
    local system = ClickMorphNPCExplorer.explorerSystem
    
    if not system.scrollChild then return end
    
    -- Limpar grid existente
    if system.assetButtons then
        for _, btn in pairs(system.assetButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    system.assetButtons = {}
    
    local assets = ClickMorphNPCExplorer.GetFilteredAssets()
    
    -- Grid 5 colunas
    local cols = 5
    local buttonSize = 64
    local spacing = 4
    
    for i, asset in ipairs(assets) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        
        local btn = CreateFrame("Button", nil, system.scrollChild)
        btn:SetSize(buttonSize, buttonSize)
        btn:SetPoint("TOPLEFT", col * (buttonSize + spacing) + 5, -(row * (buttonSize + spacing)) - 5)
        
        -- Ícone
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(buttonSize - 4, buttonSize - 4)
        icon:SetPoint("CENTER")
        icon:SetTexture(asset.icon)
        
        -- Border por raridade
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(btn)
        border:SetTexture("Interface\\Common\\WhiteIconFrame")
        local r, g, b = unpack(ClickMorphNPCExplorer.GetRarityColor(asset.rarity))
        border:SetVertexColor(r, g, b, 0.8)
        
        -- Highlight
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        
        -- Scripts
        btn:SetScript("OnClick", function()
            ClickMorphNPCExplorer.SelectAsset(asset, btn)
        end)
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(asset.name, unpack(ClickMorphNPCExplorer.GetRarityColor(asset.rarity)))
            GameTooltip:AddLine(asset.description, 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("NPC Source: " .. asset.npcName, 1, 0.8, 0)
            GameTooltip:AddLine("Slot: " .. asset.slot, 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Display ID: " .. asset.displayID, 0.6, 0.6, 1)
            GameTooltip:AddLine("Click to select", 0, 1, 0)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(system.assetButtons, btn)
    end
    
    NPCDebugPrint("Grid refreshed with", #assets, "NPC assets")
end

-- Selecionar asset
function ClickMorphNPCExplorer.SelectAsset(assetData, button)
    local system = ClickMorphNPCExplorer.explorerSystem
    
    if system.selectedButton then
        system.selectedButton:SetNormalTexture("")
    end
    
    system.selectedAssetData = assetData
    system.selectedButton = button
    
    -- Visual da seleção
    local selectedTex = button:CreateTexture(nil, "BACKGROUND")
    selectedTex:SetAllPoints()
    selectedTex:SetColorTexture(1, 1, 0, 0.3)
    button:SetNormalTexture(selectedTex)
    
    -- Atualizar info
    system.selectedIcon:SetTexture(assetData.icon)
    system.selectedName:SetText(assetData.name)
    local r, g, b = unpack(ClickMorphNPCExplorer.GetRarityColor(assetData.rarity))
    system.selectedName:SetTextColor(r, g, b)
    
    system.selectedDesc:SetText(assetData.description)
    system.selectedSource:SetText("From: " .. assetData.npcName .. " (" .. assetData.slot .. ")")
    
    NPCDebugPrint("Selected asset:", assetData.name)
end

-- Limpar seleção
function ClickMorphNPCExplorer.ClearSelection()
    local system = ClickMorphNPCExplorer.explorerSystem
    
    if system.selectedButton then
        system.selectedButton:SetNormalTexture("")
    end
    
    system.selectedAssetData = nil
    system.selectedButton = nil
    
    system.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    system.selectedName:SetText("No asset selected")
    system.selectedName:SetTextColor(1, 1, 1)
    system.selectedDesc:SetText("")
    system.selectedSource:SetText("")
end

-- Status do sistema
function ClickMorphNPCExplorer.ShowStatus()
    local system = ClickMorphNPCExplorer.explorerSystem
    
    print("|cff00ff00=== NPC EXPLORER STATUS ===|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Selected Category:", system.selectedCategory)
    print("Search Text:", system.searchText ~= "" and system.searchText or "None")
    print("Use API Discovery:", system.useAPIDiscovery and "YES" or "NO")
    
    local totalAssets = 0
    for _, category in ipairs(ClickMorphNPCExplorer.NPC_EXCLUSIVE_ASSETS) do
        totalAssets = totalAssets + #category.assets
    end
    print("Total Hardcoded Assets:", totalAssets)
    
    if system.selectedAssetData then
        print("Selected Asset:", system.selectedAssetData.name)
        print("From NPC:", system.selectedAssetData.npcName)
    end
end

-- Comandos para NPC Explorer
SLASH_CLICKMORPH_NPC1 = "/cmnpc"
SlashCmdList.CLICKMORPH_NPC = function(arg)
    local args = {}
    for word in arg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = string.lower(args[1] or "")
    
    if command == "reset" then
        ClickMorphNPCExplorer.ResetAssets()
    elseif command == "status" then
        ClickMorphNPCExplorer.ShowStatus()
    elseif command == "debug" then
        ClickMorphNPCExplorer.explorerSystem.debugMode = not ClickMorphNPCExplorer.explorerSystem.debugMode
        print("|cff00ff00NPC Explorer:|r Debug mode", ClickMorphNPCExplorer.explorerSystem.debugMode and "ON" or "OFF")
    
    -- COMANDOS EXPERIMENTAIS (descomente para usar)
    --[[
    elseif command == "discover" then
        local assets = ClickMorphNPCExplorer.DiscoverNPCAssets()
        print("|cff00ff00NPC Explorer:|r Discovered", #assets, "NPC assets")
    elseif command == "scan" then
        local nearbyNPCs = ClickMorphNPCExplorer.GetNearbyNPCs()
        print("|cff00ff00NPC Explorer:|r Found", #nearbyNPCs, "nearby NPCs")
        for _, npc in ipairs(nearbyNPCs) do
            print("|cff00ff00NPC Explorer:|r -", npc.name, "ID:", npc.creatureID or "Unknown")
        end
    elseif command == "testapi" then
        ClickMorphNPCExplorer.explorerSystem.useAPIDiscovery = not ClickMorphNPCExplorer.explorerSystem.useAPIDiscovery
        print("|cff00ff00NPC Explorer:|r API Discovery mode", ClickMorphNPCExplorer.explorerSystem.useAPIDiscovery and "ON" or "OFF")
    --]]
    
    else
        print("|cff00ff00NPC Explorer Commands:|r")
        print("/cmnpc reset - Reset all NPC assets")
        print("/cmnpc status - Show system status")
        print("/cmnpc debug - Toggle debug mode")
        
        -- COMANDOS EXPERIMENTAIS (descomente para mostrar)
        --print("/cmnpc discover - Discover nearby NPC assets")
        --print("/cmnpc scan - Scan nearby NPCs")
        --print("/cmnpc testapi - Toggle API discovery mode")
        
        print("")
        print("Use the iMorph tab -> NPC Explorer for the full interface!")
    end
end

print("|cff00ff00ClickMorph NPC Assets Explorer|r loaded!")
print("|cfffff00NPC Explorer:|r Exclusive legendary items from famous NPCs ready to use")