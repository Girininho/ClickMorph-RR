-- SaveHubWardrobe.lua - Sistema integrado com menu de configurações (/cm)
-- Mantém: FACILIDADE DE USO / DINAMISMO E MODULARIDADE
-- Integra com: ClickMorphCommands.config para ser trigado pelo checkbox do menu

ClickMorphShowAllWardrobe = {}

-- Debug system específico para wardrobe
local function WardrobeDebugPrint(...)
    if ClickMorphShowAllWardrobe.wardrobeSystem and ClickMorphShowAllWardrobe.wardrobeSystem.debugMode then
        print("|cffffff00[Wardrobe Debug]|r", ...)
    end
end

-- Sistema principal do wardrobe
ClickMorphShowAllWardrobe.wardrobeSystem = {
    isActive = false,
    debugMode = false,
    originalAPIs = {},
    hiddenAppearances = {},
    hiddenSets = {},
    appearancesBuilt = false,
    setsBuilt = false,
    sortedAppearancesList = {},
    configKey = "showAllWardrobe", -- Chave na config para integração com menu
    settingsIntegrated = false
}

-- **SISTEMA DE ORDENAÇÃO ALFABÉTICA PARA WARDROBE** (mesmo sistema das montarias)
-- Tabela de normalização de acentos para transmog
ClickMorphShowAllWardrobe.ACCENT_MAP = {
    -- Letras com acentos agudos
    ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
    ["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u",
    
    -- Letras com acentos graves
    ["à"] = "a", ["è"] = "e", ["ì"] = "i", ["ò"] = "o", ["ù"] = "u",
    ["À"] = "a", ["È"] = "e", ["Ì"] = "i", ["Ò"] = "o", ["Ù"] = "u",
    
    -- Letras com til
    ["ã"] = "a", ["õ"] = "o", ["ñ"] = "n",
    ["Ã"] = "a", ["Õ"] = "o", ["Ñ"] = "n",
    
    -- Letras com circunflexo
    ["â"] = "a", ["ê"] = "e", ["î"] = "i", ["ô"] = "o", ["û"] = "u",
    ["Â"] = "a", ["Ê"] = "e", ["Î"] = "i", ["Ô"] = "o", ["Û"] = "u",
    
    -- Letras com trema
    ["ä"] = "a", ["ë"] = "e", ["ï"] = "i", ["ö"] = "o", ["ü"] = "u",
    ["Ä"] = "a", ["Ë"] = "e", ["Ï"] = "i", ["Ö"] = "o", ["Ü"] = "u",
    
    -- Caracteres especiais
    ["ç"] = "c", ["Ç"] = "c",
    ["ß"] = "ss",
    ["š"] = "s", ["Š"] = "s",
    ["ž"] = "z", ["Ž"] = "z",
    ["č"] = "c", ["Č"] = "c",
}

-- Artigos para remover na ordenação de transmog
ClickMorphShowAllWardrobe.ARTICLES_TO_REMOVE = {
    "^of ", "^the ", "^a ", "^an ",
    "^de ", "^da ", "^do ", "^das ", "^dos ",
    "^le ", "^la ", "^les ", "^des ", "^du ",
    "^el ", "^los ", "^las ",
}

-- **FUNÇÃO DE CRIAÇÃO DE CHAVE DE ORDENAÇÃO PARA TRANSMOG**
function ClickMorphShowAllWardrobe.CreateSortKey(name)
    if not name or name == "" then return "" end
    
    local sortKey = string.lower(name)
    
    -- Aplicar normalização de acentos
    for accented, plain in pairs(ClickMorphShowAllWardrobe.ACCENT_MAP) do
        sortKey = sortKey:gsub(accented, plain)
    end
    
    -- Remover artigos
    for _, article in ipairs(ClickMorphShowAllWardrobe.ARTICLES_TO_REMOVE) do
        sortKey = sortKey:gsub(article, "")
    end
    
    -- Limpar caracteres especiais
    sortKey = sortKey:gsub("^%s+", ""):gsub("%s+$", ""):gsub("'", ""):gsub("-", " ")
    
    return sortKey
end

-- **INTEGRAÇÃO COM SISTEMA DE CONFIGURAÇÕES**
-- Esta função é chamada quando o checkbox no menu /cm é alterado
function ClickMorphShowAllWardrobe.OnConfigToggle(enabled)
    WardrobeDebugPrint("Config toggle received:", enabled and "ON" or "OFF")
    
    if enabled then
        ClickMorphShowAllWardrobe.ActivateWardrobe()
    else
        ClickMorphShowAllWardrobe.RevertWardrobe()
    end
end

-- Registrar integração com o sistema de configurações
-- function ClickMorphShowAllWardrobe.RegisterWithConfigSystem()
   -- if ClickMorphCommands and ClickMorphCommands.config then
       -- local system = ClickMorphShowAllWardrobe.wardrobeSystem
        
        -- Inicializar valor na config se não existir
      --  if ClickMorphCommands.config[system.configKey] == nil then
       --     ClickMorphCommands.config[system.configKey] = false
       -- end
        
        -- Hook na função SaveConfig para detectar mudanças
      --  if SaveConfig and not system.settingsIntegrated then
         --   local originalSaveConfig = SaveConfig
          --  SaveConfig = function()
                -- Salvar primeiro
             --   originalSaveConfig()
                
                -- Verificar se nossa configuração mudou
        --        local currentState = ClickMorphCommands.config[system.configKey]
       --         if currentState ~= system.isActive then
        --            ClickMorphShowAllWardrobe.OnConfigToggle(currentState)
       --         end
       --     end
     --       
       --     system.settingsIntegrated = true
    --        WardrobeDebugPrint("Integrated with config system")
     --   end
   --     
        -- Aplicar estado inicial se configurado como ativo
     --   if ClickMorphCommands.config[system.configKey] then
            --C_Timer.After(1, function()
               -- ClickMorphShowAllWardrobe.ActivateWardrobe()
            --end)
        --end
   -- else
        -- Tentar novamente em 2 segundos se o sistema de comandos não carregou ainda
        --C_Timer.After(2, function()
            --ClickMorphShowAllWardrobe.RegisterWithConfigSystem()
        --end)
    --end
--end

-- Lista expandida de appearances e sets ocultos
ClickMorphShowAllWardrobe.HIDDEN_APPEARANCES = {
    -- Adicione IDs de appearances hidden aqui
    -- Pode ser expandido facilmente conforme necessário
}

ClickMorphShowAllWardrobe.HIDDEN_SETS = {
    -- Adicione IDs de sets hidden aqui
    -- Exemplo: sets de desenvolvimento, GMs, etc.
}

-- **SISTEMA DE CACHE DE ORDENAÇÃO ALFABÉTICA**
function ClickMorphShowAllWardrobe.BuildSortedAppearancesList()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if #system.sortedAppearancesList > 0 then
        WardrobeDebugPrint("Using cached sorted appearances list")
        return system.sortedAppearancesList
    end
    
    WardrobeDebugPrint("Building sorted appearances list with accent normalization...")
    
    local allAppearances = {}
    
    -- Coletar todas as appearances originais
    for categoryID = 1, 15 do -- Categorias típicas de transmog
        local categoryAppearances = system.originalAPIs.GetCategoryAppearances(categoryID) or {}
        
        for _, appearanceInfo in ipairs(categoryAppearances) do
            if appearanceInfo and appearanceInfo.visualID then
                local sources = system.originalAPIs.GetAppearanceSources(appearanceInfo.visualID)
                if sources and #sources > 0 then
                    local sourceName = sources[1].name or ("Appearance " .. appearanceInfo.visualID)
                    
                    table.insert(allAppearances, {
                        visualID = appearanceInfo.visualID,
                        name = sourceName,
                        sortKey = ClickMorphShowAllWardrobe.CreateSortKey(sourceName),
                        categoryID = categoryID,
                        isCollected = appearanceInfo.isCollected,
                        isUsable = appearanceInfo.isUsable,
                        uiOrder = appearanceInfo.uiOrder,
                        source = "ORIGINAL"
                    })
                end
            end
        end
    end
    
    -- Adicionar appearances hidden
    for _, visualID in ipairs(system.hiddenAppearances) do
        table.insert(allAppearances, {
            visualID = visualID,
            name = "Hidden Appearance " .. visualID,
            sortKey = ClickMorphShowAllWardrobe.CreateSortKey("Hidden Appearance " .. visualID),
            categoryID = 1,
            isCollected = true,
            isUsable = true,
            uiOrder = 999999,
            source = "HIDDEN"
        })
    end
    
    -- **ORDENAR ALFABETICAMENTE USANDO CHAVE NORMALIZADA**
    table.sort(allAppearances, function(a, b)
        return a.sortKey < b.sortKey
    end)
    
    -- Armazenar lista ordenada
    system.sortedAppearancesList = allAppearances
    
    WardrobeDebugPrint("Sorted appearances cache built:", #allAppearances, "items")
    WardrobeDebugPrint("First 3 items:")
    for i = 1, math.min(3, #allAppearances) do
        WardrobeDebugPrint("  " .. i .. ":", allAppearances[i].name, "(" .. allAppearances[i].sortKey .. ")")
    end
    
    return allAppearances
end

-- Salvar APIs originais
function ClickMorphShowAllWardrobe.SaveOriginalAPIs()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if next(system.originalAPIs) then 
        WardrobeDebugPrint("Original APIs already saved")
        return 
    end
    
    -- APIs principais do Transmog Collection
    system.originalAPIs = {
        GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances,
        GetAppearanceSources = C_TransmogCollection.GetAppearanceSources,
        GetAllAppearances = C_TransmogCollection.GetAllAppearances,
        GetAppearanceCamera = C_TransmogCollection.GetAppearanceCamera,
        GetAppearanceInfoBySource = C_TransmogCollection.GetAppearanceInfoBySource,
        
        -- APIs de Sets
        GetAllSets = C_TransmogSets.GetAllSets,
        GetSetInfo = C_TransmogSets.GetSetInfo,
        GetSetPrimaryAppearances = C_TransmogSets.GetSetPrimaryAppearances,
        GetSetsContainingSourceID = C_TransmogSets.GetSetsContainingSourceID,
    }
    
    WardrobeDebugPrint("Original Transmog APIs saved successfully")
end

-- Construir lista de appearances hidden
function ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.appearancesBuilt then 
        WardrobeDebugPrint("Hidden appearances list already built")
        return 
    end
    
    WardrobeDebugPrint("Building hidden appearances list...")
    
    -- Começar com lista estática conhecida
    system.hiddenAppearances = {}
    
    -- Adicionar appearances conhecidas como hidden
    for _, visualID in ipairs(ClickMorphShowAllWardrobe.HIDDEN_APPEARANCES) do
        table.insert(system.hiddenAppearances, visualID)
    end
    
    -- TODO: Aqui poderia fazer scan da database para encontrar mais appearances
    -- Por enquanto, usar lista estática para manter performance
    
    system.appearancesBuilt = true
    WardrobeDebugPrint("Hidden appearances list built:", #system.hiddenAppearances, "items")
end

-- Construir lista de sets hidden
function ClickMorphShowAllWardrobe.BuildHiddenSetsList()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.setsBuilt then 
        WardrobeDebugPrint("Hidden sets list already built")
        return 
    end
    
    WardrobeDebugPrint("Building hidden sets list...")
    
    system.hiddenSets = {}
    
    for _, setID in ipairs(ClickMorphShowAllWardrobe.HIDDEN_SETS) do
        table.insert(system.hiddenSets, setID)
    end
    
    system.setsBuilt = true
    WardrobeDebugPrint("Hidden sets list built:", #system.hiddenSets, "items")
end

-- **HOOKS DE ORDENAÇÃO ALFABÉTICA PARA WARDROBE**
function ClickMorphShowAllWardrobe.InstallAlphabeticalSorting()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    WardrobeDebugPrint("Installing alphabetical sorting for wardrobe...")
    
    -- Hook GetCategoryAppearances com ordenação alfabética
    C_TransmogCollection.GetCategoryAppearances = function(categoryID)
        WardrobeDebugPrint("GetCategoryAppearances called for category", categoryID)
        
        local sortedList = ClickMorphShowAllWardrobe.BuildSortedAppearancesList()
        local categoryAppearances = {}
        
        -- Filtrar por categoria e retornar ordenado alfabeticamente
        for _, appearance in ipairs(sortedList) do
            if not categoryID or appearance.categoryID == categoryID then
                table.insert(categoryAppearances, {
                    visualID = appearance.visualID,
                    isCollected = true, -- Marcar todas como coletadas
                    isUsable = true,
                    isHideVisual = false,
                    uiOrder = #categoryAppearances + 1,
                    categoryID = appearance.categoryID
                })
            end
        end
        
        WardrobeDebugPrint("Returning", #categoryAppearances, "appearances for category", categoryID, "in alphabetical order")
        return categoryAppearances
    end
    
    -- Hook GetAllAppearances com ordenação
    C_TransmogCollection.GetAllAppearances = function()
        WardrobeDebugPrint("GetAllAppearances called")
        
        local sortedList = ClickMorphShowAllWardrobe.BuildSortedAppearancesList()
        local allAppearances = {}
        
        for _, appearance in ipairs(sortedList) do
            table.insert(allAppearances, {
                visualID = appearance.visualID,
                isCollected = true,
                isUsable = true,
                isHideVisual = false,
                uiOrder = #allAppearances + 1,
                categoryID = appearance.categoryID
            })
        end
        
        WardrobeDebugPrint("Returning", #allAppearances, "total appearances in alphabetical order")
        return allAppearances
    end
    
    -- Hook GetAppearanceSources - sempre marcar como coletado
    C_TransmogCollection.GetAppearanceSources = function(visualID)
        local sources = system.originalAPIs.GetAppearanceSources(visualID)
        
        if sources then
            -- Marcar todas as sources como coletadas
            for _, source in ipairs(sources) do
                source.isCollected = true
                source.isHideVisual = false
            end
            WardrobeDebugPrint("Marked appearance", visualID, "sources as collected")
        elseif system.hiddenAppearances and tContains(system.hiddenAppearances, visualID) then
            -- Criar source fake para appearance hidden
            sources = {{
                sourceID = visualID,
                visualID = visualID,
                isCollected = true,
                isHideVisual = false,
                name = "Hidden Appearance " .. visualID,
                quality = 4, -- Epic
                sourceType = 0
            }}
            WardrobeDebugPrint("Created fake source for hidden appearance", visualID)
        end
        
        return sources
    end
    
    WardrobeDebugPrint("Alphabetical sorting hooks installed for wardrobe")
end

-- Instalar hooks principal do wardrobe
function ClickMorphShowAllWardrobe.InstallWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    WardrobeDebugPrint("Installing wardrobe hooks...")
    
    -- Instalar ordenação alfabética
    ClickMorphShowAllWardrobe.InstallAlphabeticalSorting()
    
    -- Hook GetSetInfo - marcar sets como coletados
    C_TransmogSets.GetSetInfo = function(setID)
        local info = system.originalAPIs.GetSetInfo(setID)
        
        if info then
            info.collected = true
            info.favorite = false
            WardrobeDebugPrint("Marked set", setID, "as collected:", info.name)
            return info
        end
        
        -- Criar info fake para set hidden se necessário
        if system.hiddenSets and tContains(system.hiddenSets, setID) then
            WardrobeDebugPrint("Creating fake info for hidden set", setID)
            return {
                setID = setID,
                name = "Hidden Set " .. setID,
                description = "Unobtainable transmog set",
                collected = true,
                favorite = false,
                limitedTimeSet = false,
                label = 1,
                expansionID = 0,
                patchID = 0,
                uiOrder = 999,
                classMask = 0,
                hiddenUntilCollected = false,
                requiredFaction = nil
            }
        end
        
        return info
    end
    
    -- Hook GetAllSets - expandir com sets hidden
    C_TransmogSets.GetAllSets = function()
        local sets = system.originalAPIs.GetAllSets() or {}
        
        -- Marcar todos os sets como coletados
        for _, set in ipairs(sets) do
            set.collected = true
            set.favorite = false
        end
        
        -- Adicionar sets hidden
        for _, setID in ipairs(system.hiddenSets) do
            local setInfo = system.originalAPIs.GetSetInfo(setID)
            if setInfo then
                setInfo.collected = true
                setInfo.favorite = false
                table.insert(sets, setInfo)
            else
                -- Criar set fake
                table.insert(sets, {
                    setID = setID,
                    name = "Hidden Set " .. setID,
                    description = "Unobtainable set",
                    collected = true,
                    favorite = false,
                    limitedTimeSet = false,
                    label = 1,
                    expansionID = 0,
                    patchID = 0,
                    uiOrder = 999,
                    classMask = 0,
                    hiddenUntilCollected = false,
                    requiredFaction = nil
                })
            end
        end
        
        WardrobeDebugPrint("Expanded sets count:", #sets)
        return sets
    end
    
    system.isActive = true
    WardrobeDebugPrint("Wardrobe hooks installed successfully")
end

-- Ativar sistema de wardrobe
function ClickMorphShowAllWardrobe.ActivateWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if system.isActive then
        WardrobeDebugPrint("Wardrobe system already active")
        print("|cff00ff00ClickMorph Wardrobe:|r System already active!")
        return
    end
    
    WardrobeDebugPrint("Activating wardrobe unlock system...")
    
    -- Salvar APIs originais
    ClickMorphShowAllWardrobe.SaveOriginalAPIs()
    
    -- Instalar hooks
    ClickMorphShowAllWardrobe.InstallWardrobe()
    
    -- Construir listas de items hidden (async para não travar)
    C_Timer.After(0.1, function()
        ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
    end)
    
    C_Timer.After(0.2, function()
        ClickMorphShowAllWardrobe.BuildHiddenSetsList()
    end)
    
    -- Refresh da UI após um delay
    C_Timer.After(1, function()
        ClickMorphShowAllWardrobe.RefreshWardrobe()
        
        local appearanceCount = #system.hiddenAppearances
        local setCount = #system.hiddenSets
        
        print("|cff00ff00ClickMorph Wardrobe:|r Unlocked " .. appearanceCount .. " hidden appearances and " .. setCount .. " hidden sets!")
        print("|cff00ff00ClickMorph Wardrobe:|r All transmog items are now marked as collected and alphabetically sorted!")
        WardrobeDebugPrint("Activation complete")
    end)
end

-- **FIX DO SCROLL PARA WARDROBE** (mesmo conceito das montarias)
function ClickMorphShowAllWardrobe.EnableWardrobeScrollProtection()
    if not WardrobeCollectionFrame then
        WardrobeDebugPrint("WardrobeCollectionFrame not found")
        return
    end
    
    -- Verificar se tem sistema de scroll moderno
    local scrollFrame = WardrobeCollectionFrame.ItemsCollectionFrame and WardrobeCollectionFrame.ItemsCollectionFrame.PagingFrame
    if not scrollFrame then
        WardrobeDebugPrint("Wardrobe scroll frame not found - may be different structure")
        return
    end
    
    if scrollFrame._clickMorphScrollProtected then
        WardrobeDebugPrint("Wardrobe scroll protection already active")
        return
    end
    
    WardrobeDebugPrint("Applying scroll protection to wardrobe...")
    
    -- Salvar funções originais se disponíveis
    scrollFrame._originalWardrobeScrollFunctions = {}
    
    -- Desabilitar scroll automático se as funções existirem
    if scrollFrame.ScrollToElementDataIndex then
        scrollFrame._originalWardrobeScrollFunctions.ScrollToElementDataIndex = scrollFrame.ScrollToElementDataIndex
        scrollFrame.ScrollToElementDataIndex = function() end
    end
    
    if scrollFrame.ScrollToPage then
        scrollFrame._originalWardrobeScrollFunctions.ScrollToPage = scrollFrame.ScrollToPage
        scrollFrame.ScrollToPage = function() end
    end
    
    scrollFrame._clickMorphScrollProtected = true
    
    WardrobeDebugPrint("Wardrobe scroll protection enabled")
end

-- Refresh da interface do wardrobe
function ClickMorphShowAllWardrobe.RefreshWardrobe()
    WardrobeDebugPrint("Refreshing wardrobe interface...")
    
    -- Aplicar proteção de scroll
    ClickMorphShowAllWardrobe.EnableWardrobeScrollProtection()
    
    -- Refresh do Collections frame se estiver aberto
    if CollectionsJournal and CollectionsJournal:IsVisible() then
        local selectedTab = CollectionsJournal.selectedTab
        if selectedTab and selectedTab == 5 then -- Wardrobe tab
            WardrobeCollectionFrame_OnShow(WardrobeCollectionFrame)
            
            -- Refresh da aba ativa
            local activeFrame = WardrobeCollectionFrame.activeFrame
            if activeFrame and activeFrame.RefreshItems then
                activeFrame:RefreshItems()
            end
            
            -- Force refresh das várias abas
            if WardrobeCollectionFrame.ItemsCollectionFrame then
                WardrobeCollectionFrameTab1_OnClick(WardrobeCollectionFrameTab1)
            end
        end
    end
    
    -- Forçar atualização de eventos
    C_Timer.After(0.1, function()
        if CollectionsJournal then
            CollectionsJournal:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
        end
    end)
    
    WardrobeDebugPrint("Wardrobe refresh completed")
end

-- Reverter sistema
function ClickMorphShowAllWardrobe.RevertWardrobe()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    if not system.isActive then
        print("|cff00ff00ClickMorph Wardrobe:|r System not active")
        return
    end
    
    WardrobeDebugPrint("Reverting wardrobe system to original state...")
    
    -- Restaurar APIs originais
    for apiName, originalFunc in pairs(system.originalAPIs) do
        if apiName:find("^Get") then -- APIs do C_TransmogCollection
            C_TransmogCollection[apiName:gsub("^Get", "")] = originalFunc
        else -- APIs do C_TransmogSets
            local setApiName = apiName:gsub("^Get", "")
            C_TransmogSets[setApiName] = originalFunc
        end
    end
    
    -- Limpar sistema
    system.isActive = false
    system.hiddenAppearances = {}
    system.hiddenSets = {}
    system.sortedAppearancesList = {}
    system.appearancesBuilt = false
    system.setsBuilt = false
    
    -- Refresh da interface
    ClickMorphShowAllWardrobe.RefreshWardrobe()
    
    print("|cff00ff00ClickMorph Wardrobe:|r System reverted to original state")
    WardrobeDebugPrint("Wardrobe system reverted successfully")
end

-- Mostrar status do sistema
function ClickMorphShowAllWardrobe.ShowStatus()
    local system = ClickMorphShowAllWardrobe.wardrobeSystem
    
    print("|cff00ff00ClickMorph Wardrobe Status:|r")
    print("Active:", system.isActive and "YES" or "NO")
    print("Debug Mode:", system.debugMode and "ON" or "OFF")
    print("APIs Hooked:", next(system.originalAPIs) and "YES" or "NO")
    print("Config Integration:", system.settingsIntegrated and "YES" or "NO")
    
    if system.isActive then
        print("Hidden Appearances Loaded:", #system.hiddenAppearances)
        print("Hidden Sets Loaded:", #system.hiddenSets)
        print("Appearances Cache Built:", system.appearancesBuilt and "YES" or "NO")
        print("Sets Cache Built:", system.setsBuilt and "YES" or "NO")
        print("Sorted Cache Size:", #system.sortedAppearancesList)
        
        print("\nHooked APIs:")
        for apiName, _ in pairs(system.originalAPIs) do
            print("  ✓", apiName)
        end
    end
    
    -- Verificar integração com config
    if ClickMorphCommands and ClickMorphCommands.config then
        print("\nConfig Integration:")
        print("  Config Key:", system.configKey)
        print("  Config Value:", ClickMorphCommands.config[system.configKey] and "true" or "false")
    end
end

-- Comandos de wardrobe (mantidos para compatibilidade)
SLASH_CLICKMORPH_WARDROBE1 = "/cmwardrobe"
SlashCmdList.CLICKMORPH_WARDROBE = function(arg)
    local command = string.lower(arg or "")
    
    if command == "on" or command == "" then
        ClickMorphShowAllWardrobe.ActivateWardrobe()
    elseif command == "off" then
        ClickMorphShowAllWardrobe.RevertWardrobe()
    elseif command == "status" then
        ClickMorphShowAllWardrobe.ShowStatus()
    elseif command == "refresh" then
        ClickMorphShowAllWardrobe.RefreshWardrobe()
        print("|cff00ff00ClickMorph Wardrobe:|r Wardrobe refreshed")
    elseif command == "rebuild" then
        -- Rebuildar caches
        ClickMorphShowAllWardrobe.wardrobeSystem.appearancesBuilt = false
        ClickMorphShowAllWardrobe.wardrobeSystem.setsBuilt = false
        ClickMorphShowAllWardrobe.wardrobeSystem.sortedAppearancesList = {}
        ClickMorphShowAllWardrobe.BuildHiddenAppearancesList()
        ClickMorphShowAllWardrobe.BuildHiddenSetsList()
        print("|cff00ff00ClickMorph Wardrobe:|r Rebuilt hidden items cache")
    elseif command == "debug" then
        ClickMorphShowAllWardrobe.wardrobeSystem.debugMode = not ClickMorphShowAllWardrobe.wardrobeSystem.debugMode
        print("|cff00ff00ClickMorph Wardrobe:|r Debug mode", ClickMorphShowAllWardrobe.wardrobeSystem.debugMode and "ON" or "OFF")
    else
        print("|cff00ff00ClickMorph Wardrobe Commands:|r")
        print("/cmwardrobe on - Activate wardrobe unlock with alphabetical sorting")
        print("/cmwardrobe off - Revert to original wardrobe")
        print("/cmwardrobe status - Show detailed system status")
        print("/cmwardrobe refresh - Refresh wardrobe UI")
        print("/cmwardrobe rebuild - Rebuild hidden items cache")
        print("/cmwardrobe debug - Toggle debug mode")
        print("")
        print("|cffccccccThis system unlocks hidden/unobtainable transmog items,")
        print("marks all items as collected, and sorts them alphabetically")
        print("with proper accent normalization.|r")
        print("")
        print("|cffccccccIntegrated with /cm settings menu - use checkbox to toggle.|r")
    end
end

-- **INICIALIZAÇÃO E INTEGRAÇÃO**
local function Initialize()
    WardrobeDebugPrint("Initializing SaveHub Wardrobe system...")
    
    -- Event frame para detectar quando Collections está carregado
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "ClickMorph" then
            WardrobeDebugPrint("ClickMorph loaded, attempting config integration...")
            
            -- Tentar registrar com sistema de configurações após pequeno delay
            C_Timer.After(0.5, function()
                ClickMorphShowAllWardrobe.RegisterWithConfigSystem()
            end)
            
        elseif event == "ADDON_LOADED" and addonName == "Blizzard_Collections" then
            WardrobeDebugPrint("Blizzard_Collections loaded, wardrobe APIs ready")
            
            -- Refresh se sistema estiver ativo
            C_Timer.After(1, function()
                if ClickMorphShowAllWardrobe.wardrobeSystem.isActive then
                    ClickMorphShowAllWardrobe.RefreshWardrobe()
                end
            end)
            
        elseif event == "PLAYER_LOGIN" then
            WardrobeDebugPrint("Player login, final initialization...")
            
            -- Final setup após tudo ter carregado
            C_Timer.After(3, function()
                -- Verificar se perdeu integração com config e tentar novamente
                if not ClickMorphShowAllWardrobe.wardrobeSystem.settingsIntegrated then
                    ClickMorphShowAllWardrobe.RegisterWithConfigSystem()
                end
            end)
        end
    end)
end

-- **API PÚBLICA PARA INTEGRAÇÃO COM MENU /cm**
ClickMorphShowAllWardrobe.API = {
    -- Função chamada pelo checkbox do menu settings
    OnToggle = ClickMorphShowAllWardrobe.OnConfigToggle,
    
    -- Verificar se está ativo
    IsActive = function()
        return ClickMorphShowAllWardrobe.wardrobeSystem.isActive
    end,
    
    -- Obter key da configuração
    GetConfigKey = function()
        return ClickMorphShowAllWardrobe.wardrobeSystem.configKey
    end,
    
    -- Status para debug
    GetStatus = function()
        return {
            isActive = ClickMorphShowAllWardrobe.wardrobeSystem.isActive,
            isIntegrated = ClickMorphShowAllWardrobe.wardrobeSystem.settingsIntegrated,
            hiddenAppearances = #ClickMorphShowAllWardrobe.wardrobeSystem.hiddenAppearances,
            hiddenSets = #ClickMorphShowAllWardrobe.wardrobeSystem.hiddenSets
        }
    end
}

Initialize()

print("|cff00ff00ClickMorph SaveHub Wardrobe|r loaded!")
print("Integrates with |cffffcc00/cm|r settings menu - look for 'Show All Wardrobe' checkbox")
print("Manual commands: |cffffcc00/cmwardrobe on/off|r")
print("Features: |cffffff00Alphabetical sorting with accent normalization + Scroll fix|r")
WardrobeDebugPrint("SaveHubWardrobe.lua loaded successfully with config integration")