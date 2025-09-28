-- CLICKMORPH ENHANCED - VERSÃO COMPLETA CORRIGIDA
-- Sistema focado APENAS no workflow de itens individuais
-- CORREÇÃO: Agora usa slot real do equipamento, não posição da UI

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
    
    -- Primeiro método: Pegar do set via API do WoW (mais preciso para modID)
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
    
    -- Método fallback: Procurar na UI (caso API falhe)
    local detailsFrame = BetterWardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame
    if not detailsFrame then
        return nil
    end
    
    local items = {}
    
    -- Procurar pelos frames de item no DetailsFrame
    if detailsFrame.itemFrames then
        for i, itemFrame in pairs(detailsFrame.itemFrames) do
            if itemFrame and itemFrame:IsVisible() then
                local itemID = itemFrame.itemID or itemFrame.id
                local itemModID = itemFrame.itemModID or 0
                
                if itemID then
                    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
                    local realSlot = self.EquipSlotToiMorph[equipLoc]
                    
                    if realSlot then
                        items[realSlot] = {
                            uiSlot = i,
                            realSlot = realSlot,
                            itemID = itemID,
                            itemModID = itemModID,
                            equipLoc = equipLoc,
                            frame = itemFrame
                        }
                    end
                end
            end
        end
    end
    
    -- Se não encontrou, procurar recursivamente
    if next(items) == nil then
        local function FindItemFrames(parent, depth)
            if not parent or depth > 5 then return end
            
            for _, child in ipairs({parent:GetChildren()}) do
                if child.itemID then
                    local itemID = child.itemID
                    local itemModID = child.itemModID or 0
                    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
                    local realSlot = S.EquipSlotToiMorph[equipLoc]
                    
                    if realSlot then
                        items[realSlot] = {
                            uiSlot = #items + 1,
                            realSlot = realSlot,
                            itemID = itemID,
                            itemModID = itemModID,
                            equipLoc = equipLoc,
                            frame = child
                        }
                    end
                end
                FindItemFrames(child, depth + 1)
            end
        end
        
        FindItemFrames(detailsFrame, 0)
    end
    
    return next(items) and items or nil
end

-------------------------------------------------
-- WORKFLOW PRINCIPAL - APENAS ITENS INDIVIDUAIS
-------------------------------------------------
function S:ApplyCleanWorkflow()
    -- 1. Reset completo primeiro
    if iMorphChatHandler then
        pcall(iMorphChatHandler, ".reset")
    end
    
    -- 2. Aguardar reset e aplicar itens
    C_Timer.After(0.5, function()
        -- Extrair info do set
        local info = self:ExtractRealInfo()
        if not info then
            print("|cffff0000ClickMorph:|r Failed to extract set info")
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
        
        -- Aplicar cada item com slot e modID corretos
        local successCount = 0
        local totalItems = 0
        
        for realSlot, item in pairs(uiItems) do
            totalItems = totalItems + 1
            if item.itemID then
                -- Usar modID se disponível, senão usar versionID
                local modID = item.itemModID or info.versionID
                local command = ".item " .. item.realSlot .. " " .. item.itemID .. " " .. modID
                
                if iMorphChatHandler then
                    local ok = pcall(iMorphChatHandler, command)
                    if ok then
                        successCount = successCount + 1
                    end
                end
            end
        end
        
        -- Resultado final
        if successCount > 0 then
            print("|cff00ff00ClickMorph:|r Applied " .. info.name .. " [" .. variantName .. "] - " .. successCount .. "/" .. totalItems .. " items")
            
            -- Salvar para referência
            S.lastApplied = {
                setID = info.selectedSetID,
                name = info.name,
                variant = variantName,
                versionID = info.versionID,
                itemsApplied = successCount,
                method = "clean item workflow",
                timestamp = GetTime()
            }
        else
            print("|cffff0000ClickMorph:|r Failed to apply any items from set")
        end
    end)
end

-------------------------------------------------
-- HOOK LIMPO - APENAS WORKFLOW
-------------------------------------------------
local function SetupCleanHook()
    if BetterWardrobeCollectionFrame and 
       BetterWardrobeCollectionFrame.SetsCollectionFrame and
       BetterWardrobeCollectionFrame.SetsCollectionFrame.Model then
        
        local model = BetterWardrobeCollectionFrame.SetsCollectionFrame.Model
        if not model._CleanHook then
            model:HookScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
                    S:ApplyCleanWorkflow()
                end
            end)
            model._CleanHook = true
        end
    end
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
    if iMorphChatHandler then
        pcall(iMorphChatHandler, ".reset")
        print("|cff00ff00ClickMorph:|r Reset applied")
    end
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

SLASH_CLICKMORPH_EXTRACT1 = "/cmextract"
SlashCmdList.CLICKMORPH_EXTRACT = function()
    ClickMorphSimple:ExtractItemsFromUI()
end

SLASH_CLICKMORPH_TESTSLOT1 = "/cmtestslot"
SlashCmdList.CLICKMORPH_TESTSLOT = function(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        print("Usage: /cmtestslot <itemID>")
        return
    end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
    local realSlot = ClickMorphSimple.EquipSlotToiMorph[equipLoc]
    print("ItemID " .. itemID .. " -> EquipLoc: " .. (equipLoc or "nil") .. " -> Slot: " .. (realSlot or "nil"))
    
    -- Teste aplicação direta
    if realSlot then
        print("Test command: .item " .. realSlot .. " " .. itemID)
    end
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
    local selectedSetID = BetterWardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
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

-- Auto-setup do hook limpo
C_Timer.After(3, SetupCleanHook)

print("|cff00ff00ClickMorph Enhanced - Clean Version loaded!|r")
print("Commands: /cmclean, /cmdebug, /cmlast, /cmreset")
print("Use Alt+Shift+Click on BetterWardrobe sets!")