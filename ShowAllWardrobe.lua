-- ShowAllWardrobe.lua - UPDATED VERSION
-- Sistema completo para BetterWardrobe com Alt+Shift+Click
-- SUBSTITUA O ARQUIVO ShowAllWardrobe.lua INTEIRO POR ESTE

ClickMorphSimple = {}
local S = ClickMorphSimple

-- Debug mode
S.debug = false

-------------------------------------------------
-- MAPEAMENTO DE EQUIPSLOT PARA SLOT IMORPH
-------------------------------------------------
S.EquipSlotToiMorph = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_BODY"] = 4,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,
    ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9,
    ["INVTYPE_HAND"] = 10,
    ["INVTYPE_CLOAK"] = 15,
    ["INVTYPE_WEAPON"] = 16,
    ["INVTYPE_2HWEAPON"] = 16,
    ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17,
    ["INVTYPE_HOLDABLE"] = 17,
    ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_RANGED"] = 18,
    ["INVTYPE_TABARD"] = 19,
}

-------------------------------------------------
-- EXTRAIR INFORMAÇÕES REAIS DO WOW
-------------------------------------------------
function S:ExtractRealInfo()
    local selectedSetID = BetterWardrobeCollectionFrame and 
                          BetterWardrobeCollectionFrame.SetsCollectionFrame and
                          BetterWardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
    
    if not selectedSetID then
        return nil
    end
    
    local setInfo = C_TransmogSets.GetSetInfo(selectedSetID)
    if not setInfo then
        return nil
    end
    
    local extractedInfo = {
        selectedSetID = selectedSetID,
        baseSetID = setInfo.baseSetID,
        description = setInfo.description,
        name = setInfo.name,
        versionID = nil
    }
    
    -- Detectar version pela description
    local versionID = 0 -- Default: Normal
    
    if setInfo.description then
        local desc = setInfo.description:lower()
        if desc:find("heroic") or desc:find("heroico") then
            versionID = 1
        elseif desc:find("mythic") or desc:find("mítico") then
            versionID = 2
        elseif desc:find("elite") then
            versionID = 3
        elseif desc:find("normal") then
            versionID = 0
        end
    end
    
    extractedInfo.versionID = versionID
    
    return extractedInfo
end

-------------------------------------------------
-- EXTRAIR ITENS DA UI COM SLOT E MODID CORRETOS
-------------------------------------------------
function S:ExtractItemsFromUI()
    local selectedSetID = BetterWardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
    if not selectedSetID then return nil end
    
    -- Método principal: Pegar do set via API do WoW (mais preciso para modID)
    local sourceIDs = C_TransmogSets.GetAllSourceIDs(selectedSetID)
    if sourceIDs then
        local items = {}
        
        for _, sourceID in pairs(sourceIDs) do
            local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
            if sourceInfo and sourceInfo.itemID then
                local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(sourceInfo.itemID)
                local realSlot = self.EquipSlotToiMorph[equipLoc]
                
                if realSlot then
                    items[realSlot] = {
                        sourceID = sourceID,
                        realSlot = realSlot,
                        itemID = sourceInfo.itemID,
                        itemModID = sourceInfo.itemModID or 0,
                        equipLoc = equipLoc,
                        name = sourceInfo.name
                    }
                end
            end
        end
        
        if next(items) then
            return items
        end
    end
    
    return nil
end

-------------------------------------------------
-- WORKFLOW PRINCIPAL - VERSÃO CORRIGIDA
-------------------------------------------------
function S:ApplyCleanWorkflow()
    -- Verificar se iMorph tá disponível
    if not (IMorphInfo or Morph) then
        print("|cffff0000ClickMorph:|r iMorph not loaded or not injected")
        return
    end

    -- Extrair info do set
    local info = self:ExtractRealInfo()
    if not info then
        print("|cffff0000ClickMorph:|r No set selected")
        return
    end
    
    -- Detectar variante para display
    local variantName = "Normal"
    if info.description then
        local desc = info.description:lower()
        if desc:find("heroic") or desc:find("heroico") then
            variantName = "Heroic"
        elseif desc:find("mythic") or desc:find("mítico") then
            variantName = "Mythic"
        elseif desc:find("elite") then
            variantName = "Elite"
        end
    end
    
    -- Extrair itens da UI
    local uiItems = self:ExtractItemsFromUI()
    if not uiItems then
        print("|cffff0000ClickMorph:|r No items found in set")
        return
    end
    
    -- Preparar comandos
    local commands = {}
    
    -- Reset primeiro
    table.insert(commands, ".reset")
    
    -- Undress slots que o set vai usar
    for realSlot, _ in pairs(uiItems) do
        table.insert(commands, string.format(".item %d 0", realSlot))
    end
    
    -- Adicionar comandos de morph
    local totalItems = 0
    for realSlot, item in pairs(uiItems) do
        if item.itemID then
            totalItems = totalItems + 1
            local modID = item.itemModID or info.versionID
            local cmd = string.format(".item %d %d %d", item.realSlot, item.itemID, modID)
            table.insert(commands, cmd)
            
            if S.debug then
                print("|cff00ccffDebug:|r", cmd)
            end
        end
    end
    
    -- Executar comandos sequencialmente
    local commandIndex = 1
    local successCount = 0
    
    local function ExecuteNextCommand()
        if commandIndex > #commands then
            print(string.format("|cff00ff00ClickMorph:|r Applied %s [%s] - %d items", 
                info.name, variantName, totalItems))
            
            -- Salvar para referência
            S.lastApplied = {
                setID = info.selectedSetID,
                name = info.name,
                variant = variantName,
                versionID = info.versionID,
                itemsApplied = totalItems,
                timestamp = GetTime()
            }
            return
        end
        
        local cmd = commands[commandIndex]
        
        -- Usar ChatFrame1EditBox (método correto do iMorph)
        ChatFrame1EditBox:SetText(cmd)
        ChatEdit_SendText(ChatFrame1EditBox, 0)
        
        commandIndex = commandIndex + 1
        C_Timer.After(0.05, ExecuteNextCommand) -- Delay entre comandos
    end
    
    ExecuteNextCommand()
end

-------------------------------------------------
-- HOOK LIMPO - BETTERWARDROBE + FALLBACK
-------------------------------------------------
local hookAttempts = 0
local maxHookAttempts = 10

-- SUBSTITUA a função SetupCleanHook() no ShowAllWardrobe.lua

local function SetupCleanHook()
    hookAttempts = hookAttempts + 1
    
    -- Tentar BetterWardrobe primeiro
    if BetterWardrobeCollectionFrame and 
       BetterWardrobeCollectionFrame.SetsCollectionFrame and
       BetterWardrobeCollectionFrame.SetsCollectionFrame.Model then
        
        local model = BetterWardrobeCollectionFrame.SetsCollectionFrame.Model
        if not model._CleanHook then
            model:HookScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
                    -- VERIFICAÇÃO CRÍTICA: Só processar se estiver na aba de SETS
                    local setsFrame = BetterWardrobeCollectionFrame.SetsCollectionFrame
                    
                    -- Verificar se a aba de Sets está visível E tem set selecionado
                    if setsFrame:IsVisible() and setsFrame.selectedSetID then
                        if S.debug then
                            print("|cff00ccffDebug:|r Alt+Shift+Click on BetterWardrobe - Transmog Set!")
                        end
                        S:ApplyCleanWorkflow()
                    else
                        -- Está na aba de Items, não fazer nada (deixar ClickMorph processar)
                        if S.debug then
                            print("|cff00ccffDebug:|r Alt+Shift+Click ignored - not on Sets tab or no set selected")
                        end
                    end
                end
            end)
            model._CleanHook = true
            print("|cff00ff00ClickMorph:|r BetterWardrobe Sets hook OK (Alt+Shift+Click)")
        end
        return true
    end
    
    -- Fallback: Wardrobe padrão
    if WardrobeCollectionFrame and 
       WardrobeCollectionFrame.SetsCollectionFrame and
       WardrobeCollectionFrame.SetsCollectionFrame.Model then
        
        local model = WardrobeCollectionFrame.SetsCollectionFrame.Model
        if not model._CleanHook then
            model:HookScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
                    -- VERIFICAÇÃO: Só processar se tem set selecionado
                    local setsFrame = WardrobeCollectionFrame.SetsCollectionFrame
                    local selectedSetID = setsFrame.selectedSetID
                    
                    if selectedSetID and setsFrame:IsVisible() then
                        -- Temporariamente setar no BetterWardrobe pra função funcionar
                        if not BetterWardrobeCollectionFrame then
                            BetterWardrobeCollectionFrame = {
                                SetsCollectionFrame = {
                                    selectedSetID = selectedSetID
                                }
                            }
                        end
                        S:ApplyCleanWorkflow()
                    end
                end
            end)
            model._CleanHook = true
            print("|cff00ff00ClickMorph:|r Default Wardrobe Sets hook OK (Alt+Shift+Click)")
        end
        return true
    end
    
    -- Se não conseguiu e ainda tem tentativas, tentar novamente
    if hookAttempts < maxHookAttempts then
        C_Timer.After(1, SetupCleanHook)
        if S.debug then
            print("|cff00ccffDebug:|r Hook attempt", hookAttempts, "- will retry in 1s")
        end
    else
        print("|cffffff00ClickMorph:|r Could not auto-hook. Use /cmrehook after opening wardrobe")
    end
    
    return false
end

-------------------------------------------------
-- DEBUG FUNCTIONS
-------------------------------------------------
function S:DebugInfo()
    local info = self:ExtractRealInfo()
    if info then
        print("|cff00ff00=== DEBUG INFO ===|r")
        print("Selected SetID:", info.selectedSetID)
        print("Base SetID:", info.baseSetID)
        print("Description:", info.description or "none")
        print("Detected VersionID:", info.versionID)
        print("Name:", info.name)
    else
        print("❌ No set selected or info unavailable")
    end
end

function S:ShowLastApplied()
    if self.lastApplied then
        print("|cff00ff00=== LAST APPLIED ===|r")
        for k, v in pairs(self.lastApplied) do
            print(k .. ":", v)
        end
    else
        print("No morph applied yet")
    end
end

function S:QuickReset()
    ChatFrame1EditBox:SetText(".reset")
    ChatEdit_SendText(ChatFrame1EditBox, 0)
    print("|cff00ff00ClickMorph:|r Reset applied")
end

-------------------------------------------------
-- COMANDOS SIMPLIFICADOS
-------------------------------------------------
SLASH_CLICKMORPH_CLEAN1 = "/cmclean"
SlashCmdList.CLICKMORPH_CLEAN = function()
    ClickMorphSimple:ApplyCleanWorkflow()
end

SLASH_CLICKMORPH_DEBUG1 = "/cmdebug"
SlashCmdList.CLICKMORPH_DEBUG = function()
    ClickMorphSimple:DebugInfo()
end

SLASH_CLICKMORPH_LAST1 = "/cmlast"
SlashCmdList.CLICKMORPH_LAST = function()
    ClickMorphSimple:ShowLastApplied()
end

SLASH_CLICKMORPH_RESET1 = "/cmreset"
SlashCmdList.CLICKMORPH_RESET = function()
    ClickMorphSimple:QuickReset()
end

SLASH_CLICKMORPH_DEBUGSET1 = "/cmdebugset"
SlashCmdList.CLICKMORPH_DEBUGSET = function()
    print("|cff00ff00=== DEBUG SET ITEMS ===|r")
    local items = ClickMorphSimple:ExtractItemsFromUI()
    if items then
        for slot, item in pairs(items) do
            local modID = item.itemModID or 0
            print("Slot " .. item.realSlot .. " (" .. item.equipLoc .. "): ItemID " .. item.itemID .. " ModID " .. modID)
            print("  Command: .item " .. item.realSlot .. " " .. item.itemID .. " " .. modID)
        end
    else
        print("No items found")
    end
end

SLASH_CLICKMORPH_TESTSOURCE1 = "/cmtestsource"
SlashCmdList.CLICKMORPH_TESTSOURCE = function()
    local selectedSetID = BetterWardrobeCollectionFrame and 
                          BetterWardrobeCollectionFrame.SetsCollectionFrame and
                          BetterWardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
    if not selectedSetID then
        print("No set selected")
        return
    end
    
    print("|cff00ff00=== TEST SOURCE IDS ===|r")
    local sourceIDs = C_TransmogSets.GetAllSourceIDs(selectedSetID)
    if sourceIDs then
        for _, sourceID in pairs(sourceIDs) do
            local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
            if sourceInfo then
                print("Source " .. sourceID .. ": ItemID " .. sourceInfo.itemID .. " ModID " .. (sourceInfo.itemModID or 0) .. " - " .. sourceInfo.name)
            end
        end
    end
end

SLASH_CLICKMORPH_TOGGLEDEBUG1 = "/cmtoggledebug"
SlashCmdList.CLICKMORPH_TOGGLEDEBUG = function()
    S.debug = not S.debug
    print("|cff00ff00ClickMorph:|r Debug mode", S.debug and "ON" or "OFF")
end

SLASH_CLICKMORPH_REHOOK1 = "/cmrehook"
SlashCmdList.CLICKMORPH_REHOOK = function()
    print("|cff00ff00ClickMorph:|r Manually applying hook...")
    hookAttempts = 0 -- Reset counter
    SetupCleanHook()
end

-- Sistema de inicialização inteligente
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_Collections" then
            -- Collections addon carregou, tentar hook
            C_Timer.After(0.5, SetupCleanHook)
        elseif addonName == "BetterWardrobe" then
            -- BetterWardrobe carregou, tentar hook
            C_Timer.After(1, SetupCleanHook)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Player entrou no mundo, tentar hook após delay
        C_Timer.After(3, SetupCleanHook)
        -- Tentar novamente após 10s (pra garantir)
        C_Timer.After(10, SetupCleanHook)
    end
end)

-- Tentativa imediata (caso já esteja carregado)
C_Timer.After(1, SetupCleanHook)

print("|cff00ff00ClickMorph Enhanced - ShowAllWardrobe.lua loaded!|r")
print("Commands: /cmclean, /cmdebug, /cmlast, /cmreset, /cmdebugset")
print("Use Alt+Shift+Click on BetterWardrobe sets!")