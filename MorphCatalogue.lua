-- MorphCatalogue.lua
-- Catálogo de morphs integrado ao wardrobe (NPCs + DruidForms + Pets + Descobertas)

ClickMorphMorphCatalogue = {}

-- Sistema do Morph Catalogue
ClickMorphMorphCatalogue.catalogueSystem = {
    contentFrame = nil,
    previewComponent = nil,
    gridComponent = nil,
    filterComponent = nil,
    selectedAsset = nil,
    filteredAssets = {},
    currentFilters = {},
    searchText = "",
    isInitialized = false
}

-- Debug print
local function CatalogueDebugPrint(...)
    if ClickMorphCustomWardrobe and ClickMorphCustomWardrobe.wardrobeSystem.settings.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cff66ccffCatalogue:|r", table.concat(args, " "))
    end
end

-- =============================================================================
-- MORPH CATALOGUE WARDROBE CONTENT
-- =============================================================================

-- Criar conteúdo do Morph Catalogue no wardrobe
function ClickMorphMorphCatalogue.CreateMorphCatalogueContent(parent)
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    CatalogueDebugPrint("Creating Morph Catalogue wardrobe content")
    
    if system.isInitialized then
        CatalogueDebugPrint("Morph Catalogue already initialized, refreshing")
        ClickMorphMorphCatalogue.RefreshCatalogue()
        return system.contentFrame
    end
    
    -- Frame principal do conteúdo
    local contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetAllPoints()
    system.contentFrame = contentFrame
    
    -- Título da seção
    local titleFrame = CreateFrame("Frame", nil, contentFrame)
    titleFrame:SetSize(792, 30)
    titleFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    
    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleFrame, "LEFT", 0, 0)
    title:SetText("Morph Catalogue - Browse All Assets")
    title:SetTextColor(1, 1, 1)
    
    -- Contador de assets
    local assetCounter = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    assetCounter:SetPoint("RIGHT", titleFrame, "RIGHT", 0, 0)
    assetCounter:SetText("Loading...")
    assetCounter:SetTextColor(0.8, 0.8, 0.8)
    system.assetCounter = assetCounter
    
    -- Criar componentes usando o framework
    ClickMorphMorphCatalogue.CreateCatalogueComponents(contentFrame)
    
    -- Popular com dados iniciais
    ClickMorphMorphCatalogue.PopulateCatalogue()
    
    system.isInitialized = true
    CatalogueDebugPrint("Morph Catalogue wardrobe content created")
    
    return contentFrame
end

-- Criar componentes específicos do Morph Catalogue
function ClickMorphMorphCatalogue.CreateCatalogueComponents(parent)
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    -- Componente de filtros (lado esquerdo)
    system.filterComponent = ClickMorphCustomWardrobe.API.CreateFilterSystem(parent, {
        point = "TOPLEFT",
        relativeTo = "TOPLEFT",
        x = 10,
        y = -40
    }, {width = 180, height = 380})
    
    -- Componente de preview 3D (lado direito)
    system.previewComponent = ClickMorphCustomWardrobe.API.CreatePreview3D(parent, {
        point = "TOPRIGHT",
        relativeTo = "TOPRIGHT", 
        x = -10,
        y = -40
    }, {width = 280, height = 380})
    
    -- Componente de grid (centro)
    system.gridComponent = ClickMorphCustomWardrobe.API.CreateAssetGrid(parent, {
        point = "TOPLEFT",
        relativeTo = "TOPLEFT",
        x = 200, 
        y = -40
    }, {width = 380, height = 380})
    
    -- Customizar componentes para o catalogue
    ClickMorphMorphCatalogue.CustomizeComponentsForCatalogue()
    
    CatalogueDebugPrint("Morph Catalogue components created")
end

-- Customizar componentes especificamente para o catalogue
function ClickMorphMorphCatalogue.CustomizeComponentsForCatalogue()
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    -- Customizar filtros
    if system.filterComponent then
        ClickMorphMorphCatalogue.SetupCatalogueFilters(system.filterComponent)
    end
    
    -- Customizar grid
    if system.gridComponent then
        -- Ajustar configurações do grid
        system.gridComponent.buttonsPerRow = 6
        system.gridComponent.buttonSize = 56
        system.gridComponent.buttonSpacing = 60
        
        -- Callback de clique customizado
        local originalOnClick = ClickMorphCustomWardrobe.OnAssetButtonClick
        ClickMorphCustomWardrobe.OnAssetButtonClick = function(button, mouseButton, assetData)
            if button:GetParent():GetParent() == system.gridComponent.scrollContent then
                ClickMorphMorphCatalogue.OnCatalogueAssetClick(button, mouseButton, assetData)
            else
                originalOnClick(button, mouseButton, assetData)
            end
        end
    end
    
    CatalogueDebugPrint("Components customized for catalogue")
end

-- Configurar filtros específicos do catalogue
function ClickMorphMorphCatalogue.SetupCatalogueFilters(filterComponent)
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    -- Callback para mudanças de filtro
    filterComponent.onFilterChanged = function(filters, searchText)
        system.currentFilters = filters
        system.searchText = searchText
        ClickMorphMorphCatalogue.ApplyFilters()
    end
    
    -- Criar checkboxes de filtro
    filterComponent:CreateCheckbox("NPCs", "npcs", true)
    filterComponent:CreateCheckbox("Druid Forms", "druidForms", true)
    filterComponent:CreateCheckbox("Pets", "pets", true)
    filterComponent:CreateCheckbox("Discovered Only", "discoveredOnly", false)
    filterComponent:CreateCheckbox("Elite/Rare Only", "eliteOnly", false)
    filterComponent:CreateCheckbox("Favorites", "favoritesOnly", false)
    
    -- Arranjar checkboxes
    filterComponent:ArrangeCheckboxes()
    
    -- Inicializar filtros padrão
    system.currentFilters = {
        npcs = true,
        druidForms = true,
        pets = true,
        discoveredOnly = false,
        eliteOnly = false,
        favoritesOnly = false
    }
    
    CatalogueDebugPrint("Catalogue filters setup complete")
end

-- =============================================================================
-- DATA AGGREGATION - COMBINAR TODAS AS FONTES
-- =============================================================================

-- Obter todos os assets do catalogue
function ClickMorphMorphCatalogue.GetAllAssets()
    local allAssets = {}
    
    CatalogueDebugPrint("Gathering assets from all sources...")
    
    -- Adicionar NPCs descobertos
    local npcAssets = ClickMorphMorphCatalogue.GetNPCAssets()
    for _, asset in ipairs(npcAssets) do
        table.insert(allAssets, asset)
    end
    
    -- Adicionar Druid Forms
    local druidAssets = ClickMorphMorphCatalogue.GetDruidFormAssets()
    for _, asset in ipairs(druidAssets) do
        table.insert(allAssets, asset)
    end
    
    -- Adicionar Pets
    local petAssets = ClickMorphMorphCatalogue.GetPetAssets()
    for _, asset in ipairs(petAssets) do
        table.insert(allAssets, asset)
    end
    
    -- Adicionar discoveries do SmartDiscovery
    local discoveryAssets = ClickMorphMorphCatalogue.GetDiscoveryAssets()
    for _, asset in ipairs(discoveryAssets) do
        table.insert(allAssets, asset)
    end
    
    CatalogueDebugPrint("Total assets gathered:", #allAssets)
    return allAssets
end

-- Obter assets de NPCs
function ClickMorphMorphCatalogue.GetNPCAssets()
    local assets = {}
    
    -- Tentar obter NPCs do SmartDiscovery
    if ClickMorphSmartDiscovery and ClickMorphSmartDiscovery.API then
        local npcs = ClickMorphSmartDiscovery.API.GetMorphableNPCs()
        for _, npc in ipairs(npcs) do
            table.insert(assets, {
                name = npc.name,
                type = "npc",
                displayID = npc.displayID,
                source = "Smart Discovery",
                zone = npc.zone,
                coords = npc.coords,
                rarity = npc.rarity or 2,
                category = "NPCs",
                icon = "Interface\\Icons\\INV_Misc_Head_Human_01",
                description = "NPC discovered in " .. (npc.zone or "Unknown Zone")
            })
        end
    end
    
    CatalogueDebugPrint("Gathered", #assets, "NPC assets")
    return assets
end

-- Obter assets de Druid Forms
function ClickMorphMorphCatalogue.GetDruidFormAssets()
    local assets = {}
    
    -- Tentar obter forms do DruidForms module
    if ClickMorphDruidForms and ClickMorphDruidForms.DRUID_FORMS then
        for _, form in ipairs(ClickMorphDruidForms.DRUID_FORMS) do
            table.insert(assets, {
                name = form.name,
                type = "creature",
                displayID = form.displayID,
                source = "Druid Forms",
                category = "Druid Forms",
                subcategory = form.category,
                rarity = form.rarity or 3,
                icon = "Interface\\Icons\\Ability_Druid_CatForm",
                description = form.description
            })
        end
    end
    
    CatalogueDebugPrint("Gathered", #assets, "Druid Form assets")
    return assets
end

-- Obter assets de Pets
function ClickMorphMorphCatalogue.GetPetAssets()
    local assets = {}
    
    -- Tentar obter pets do PetZone module
    if ClickMorphPetZone and ClickMorphPetZone.PET_DATABASE then
        for _, categoryData in ipairs(ClickMorphPetZone.PET_DATABASE) do
            for _, pet in ipairs(categoryData.pets) do
                table.insert(assets, {
                    name = pet.name,
                    type = "creature",
                    displayID = pet.displayID,
                    source = "Pet Zone",
                    category = "Pets",
                    subcategory = pet.category,
                    rarity = pet.rarity or 2,
                    icon = "Interface\\Icons\\INV_Box_PetCarrier_01",
                    description = pet.description
                })
            end
        end
    end
    
    CatalogueDebugPrint("Gathered", #assets, "Pet assets")
    return assets
end

-- Obter assets do SmartDiscovery
function ClickMorphMorphCatalogue.GetDiscoveryAssets()
    local assets = {}
    
    if ClickMorphSmartDiscovery and ClickMorphSmartDiscovery.API then
        -- Creatures descobertos
        local creatures = ClickMorphSmartDiscovery.API.GetCreatures()
        for displayID, creatureData in pairs(creatures) do
            if creatureData.displayID then
                table.insert(assets, {
                    name = creatureData.name,
                    type = "creature", 
                    displayID = creatureData.displayID,
                    source = "Smart Discovery",
                    category = "Discovered",
                    subcategory = "Creatures",
                    rarity = 3,
                    icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
                    description = "Discovered creature morph"
                })
            end
        end
        
        -- Items descobertos
        local items = ClickMorphSmartDiscovery.API.GetItems()
        for itemID, itemData in pairs(items) do
            table.insert(assets, {
                name = itemData.name,
                type = "item",
                itemID = itemID,
                displayID = itemID, -- Usar itemID como displayID para items
                source = "Smart Discovery",
                category = "Discovered",
                subcategory = "Items",
                rarity = itemData.quality or 2,
                icon = itemData.texture or "Interface\\Icons\\INV_Chest_Plate06",
                description = "Discovered item morph"
            })
        end
    end
    
    CatalogueDebugPrint("Gathered", #assets, "Discovery assets")
    return assets
end

-- =============================================================================
-- FILTERING & SEARCH
-- =============================================================================

-- Aplicar filtros aos assets
function ClickMorphMorphCatalogue.ApplyFilters()
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    CatalogueDebugPrint("Applying filters...")
    
    local allAssets = ClickMorphMorphCatalogue.GetAllAssets()
    local filteredAssets = {}
    
    for _, asset in ipairs(allAssets) do
        if ClickMorphMorphCatalogue.AssetMatchesFilters(asset) then
            table.insert(filteredAssets, asset)
        end
    end
    
    system.filteredAssets = filteredAssets
    
    -- Atualizar grid
    if system.gridComponent then
        system.gridComponent:PopulateGrid(filteredAssets)
    end
    
    -- Atualizar contador
    if system.assetCounter then
        system.assetCounter:SetText(#filteredAssets .. " assets")
    end
    
    CatalogueDebugPrint("Filtered to", #filteredAssets, "assets")
end

-- Verificar se asset passa pelos filtros
function ClickMorphMorphCatalogue.AssetMatchesFilters(asset)
    local system = ClickMorphMorphCatalogue.catalogueSystem
    local filters = system.currentFilters
    local searchText = system.searchText
    
    -- Filtro de categoria
    local categoryMatch = false
    if filters.npcs and asset.category == "NPCs" then categoryMatch = true end
    if filters.druidForms and asset.category == "Druid Forms" then categoryMatch = true end
    if filters.pets and asset.category == "Pets" then categoryMatch = true end
    if filters.npcs and asset.category == "Discovered" then categoryMatch = true end
    
    if not categoryMatch then return false end
    
    -- Filtro de texto
    if searchText and searchText ~= "" then
        local searchLower = string.lower(searchText)
        local nameMatch = string.find(string.lower(asset.name or ""), searchLower)
        local descMatch = string.find(string.lower(asset.description or ""), searchLower)
        
        if not (nameMatch or descMatch) then
            return false
        end
    end
    
    -- Filtro discovered only
    if filters.discoveredOnly and asset.source ~= "Smart Discovery" then
        return false
    end
    
    -- Filtro elite/rare only
    if filters.eliteOnly and (asset.rarity or 0) < 3 then
        return false
    end
    
    -- Filtro favorites only (TODO: implementar sistema de favoritos)
    if filters.favoritesOnly then
        -- TODO: Verificar se asset está nos favoritos
    end
    
    return true
end

-- =============================================================================
-- UI INTERACTIONS
-- =============================================================================

-- Clique em asset do catalogue
function ClickMorphMorphCatalogue.OnCatalogueAssetClick(button, mouseButton, assetData)
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    if mouseButton == "LeftButton" then
        -- Preview do asset
        system.selectedAsset = assetData
        ClickMorphMorphCatalogue.PreviewAsset(assetData)
        ClickMorphMorphCatalogue.UpdateAssetSelection()
        
    elseif mouseButton == "RightButton" then
        -- Apply direto
        ClickMorphCustomWardrobe.API.ApplyPreviewData(assetData)
        
        -- Auto-save se aplicar
        if ClickMorphSaveHub and ClickMorphSaveHub.API then
            ClickMorphSaveHub.API.AutoSave(assetData)
        end
        
    elseif mouseButton == "MiddleButton" then
        -- Menu de contexto ou adicionar aos favoritos
        ClickMorphMorphCatalogue.ShowAssetContextMenu(assetData)
    end
end

-- Preview de asset
function ClickMorphMorphCatalogue.PreviewAsset(assetData)
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    if not system.previewComponent or not assetData then
        return
    end
    
    CatalogueDebugPrint("Previewing asset:", assetData.name)
    
    -- Atualizar preview 3D
    system.previewComponent:UpdatePreview(assetData)
end

-- Atualizar seleção visual de asset
function ClickMorphMorphCatalogue.UpdateAssetSelection()
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    if not system.gridComponent then return end
    
    -- Atualizar visual dos botões
    for _, button in pairs(system.gridComponent.buttons) do
        if button.assetData == system.selectedAsset then
            -- Destacar selecionado
            if not button.selectedOverlay then
                button.selectedOverlay = button:CreateTexture(nil, "OVERLAY")
                button.selectedOverlay:SetAllPoints()
                button.selectedOverlay:SetColorTexture(0.3, 0.5, 0.8, 0.4)
            end
            button.selectedOverlay:Show()
        elseif button.selectedOverlay then
            button.selectedOverlay:Hide()
        end
    end
end

-- Menu de contexto para asset
function ClickMorphMorphCatalogue.ShowAssetContextMenu(assetData)
    local menu = {
        {
            text = assetData.name,
            isTitle = true,
        },
        {
            text = "Apply Morph",
            func = function()
                ClickMorphCustomWardrobe.API.ApplyPreviewData(assetData)
            end,
        },
        {
            text = "Save to Hub",
            func = function()
                if ClickMorphSaveHub and ClickMorphSaveHub.API then
                    local saveName = assetData.name .. " - " .. date("%H:%M")
                    ClickMorphSaveHub.API.Save(saveName, assetData, {
                        description = "Saved from Morph Catalogue"
                    })
                    print("|cff66ccffCatalogue:|r Saved to hub: " .. saveName)
                end
            end,
        },
        {
            text = "Copy Display ID",
            func = function()
                if assetData.displayID then
                    -- Simular copy to clipboard (não há API real no WoW)
                    print("|cff66ccffCatalogue:|r Display ID: " .. assetData.displayID)
                end
            end,
        },
        {
            text = "Add to Favorites",
            func = function()
                -- TODO: Implementar sistema de favoritos
                print("|cff66ccffCatalogue:|r Favorites system coming soon!")
            end,
        }
    }
    
    local contextMenu = CreateFrame("Frame", "MorphCatalogueContextMenu", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, contextMenu, "cursor", 0, 0, "MENU")
end

-- =============================================================================
-- MAIN FUNCTIONS
-- =============================================================================

-- Popular catalogue com dados
function ClickMorphMorphCatalogue.PopulateCatalogue()
    local system = ClickMorphMorphCatalogue.catalogueSystem
    
    CatalogueDebugPrint("Populating Morph Catalogue with data")
    
    -- Aplicar filtros (isso vai popular o grid automaticamente)
    ClickMorphMorphCatalogue.ApplyFilters()
    
    CatalogueDebugPrint("Morph Catalogue populated")
end

-- Refresh do catalogue
function ClickMorphMorphCatalogue.RefreshCatalogue()
    CatalogueDebugPrint("Refreshing Morph Catalogue")
    
    ClickMorphMorphCatalogue.PopulateCatalogue()
    
    -- Limpar seleção
    local system = ClickMorphMorphCatalogue.catalogueSystem
    system.selectedAsset = nil
end

-- =============================================================================
-- INTEGRATION & REGISTRATION
-- =============================================================================

-- Registrar Morph Catalogue no framework de wardrobe
local function RegisterMorphCatalogueContent()
    if ClickMorphCustomWardrobe and ClickMorphCustomWardrobe.API then
        ClickMorphCustomWardrobe.API.RegisterTabContent("morphCatalogue", ClickMorphMorphCatalogue.CreateMorphCatalogueContent)
        CatalogueDebugPrint("Morph Catalogue content registered with Custom Wardrobe")
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Inicialização
local function InitializeMorphCatalogue()
    CatalogueDebugPrint("Initializing Morph Catalogue integration...")
    
    -- Registrar content no framework
    RegisterMorphCatalogueContent()
    
    CatalogueDebugPrint("Morph Catalogue integration ready")
end

-- Event frame para inicialização
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        C_Timer.After(1, InitializeMorphCatalogue)
    end
end)

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- API pública para Morph Catalogue
ClickMorphMorphCatalogue.API = {
    -- Content creation
    CreateContent = ClickMorphMorphCatalogue.CreateMorphCatalogueContent,
    
    -- Data management
    GetAllAssets = ClickMorphMorphCatalogue.GetAllAssets,
    RefreshCatalogue = ClickMorphMorphCatalogue.RefreshCatalogue,
    PopulateCatalogue = ClickMorphMorphCatalogue.PopulateCatalogue,
    
    -- Filtering
    ApplyFilters = ClickMorphMorphCatalogue.ApplyFilters,
    AssetMatchesFilters = ClickMorphMorphCatalogue.AssetMatchesFilters,
    
    -- Asset management
    PreviewAsset = ClickMorphMorphCatalogue.PreviewAsset,
    
    -- Data source functions
    GetNPCAssets = ClickMorphMorphCatalogue.GetNPCAssets,
    GetDruidFormAssets = ClickMorphMorphCatalogue.GetDruidFormAssets,
    GetPetAssets = ClickMorphMorphCatalogue.GetPetAssets,
    GetDiscoveryAssets = ClickMorphMorphCatalogue.GetDiscoveryAssets
}

print("|cff66ccffClickMorph Morph Catalogue|r loaded!")
CatalogueDebugPrint("MorphCatalogue.lua loaded successfully")