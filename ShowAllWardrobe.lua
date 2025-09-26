-- ClickMorph ShowAll Wardrobe - versão dinâmica e segura
ClickMorphShowAllWardrobe = {}
local W = ClickMorphShowAllWardrobe

W.wardrobeSystem = { isActive = false, originalAPIs = {} }
W.debug = false

local function DPrint(...)
    if W.debug then print("|cffff8800Wardrobe:|r", ...) end
end

-- =====================
-- Salvar APIs originais
-- =====================
function W:SaveOriginalAPIs()
    local o = self.wardrobeSystem.originalAPIs
    if not o.GetAllSets then
        o.GetAllSets = C_TransmogSets.GetAllSets
        o.GetSetInfo = C_TransmogSets.GetSetInfo
        o.GetUsableSets = C_TransmogSets.GetUsableSets
        o.GetBaseSets = C_TransmogSets.GetBaseSets
        o.GetVariantSets = C_TransmogSets.GetVariantSets
        o.GetCategoryAppearances = C_TransmogCollection.GetCategoryAppearances
        o.GetAppearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo
        o.GetAllAppearanceSources = C_TransmogCollection.GetAllAppearanceSources
    end
end

-- =====================
-- Hooks dinâmicos
-- =====================
function W:HookAPIs()
    local o = self.wardrobeSystem.originalAPIs

    -- -------- SETS --------
    C_TransmogSets.GetAllSets = function(...)
        local sets = o.GetAllSets(...) or {}
        for _, s in ipairs(sets) do
            if type(s)=="table" then
                s.collected = true
                s.validForCharacter = true
                s.canCollect = true
                s.hiddenUntilCollected = false
                s.limitedTimeSet = false
            end
        end
        DPrint("Returning", #sets, "sets")
        return sets
    end

    C_TransmogSets.GetSetInfo = function(setID)
        if not setID then return nil end
        local s = o.GetSetInfo(setID)
        if s then
            s.collected = true
            s.validForCharacter = true
            s.canCollect = true
            s.hiddenUntilCollected = false
            s.limitedTimeSet = false
        end
        return s
    end

    if o.GetUsableSets then
        C_TransmogSets.GetUsableSets = function(...)
            local sets = o.GetUsableSets(...) or {}
            for _, s in ipairs(sets) do
                if type(s)=="table" then
                    s.collected = true
                    s.validForCharacter = true
                    s.canCollect = true
                    s.hiddenUntilCollected = false
                end
            end
            DPrint("UsableSets:", #sets)
            return sets
        end
    end

    if o.GetBaseSets then
        C_TransmogSets.GetBaseSets = function(...)
            local sets = o.GetBaseSets(...) or {}
            for _, s in ipairs(sets) do
                if type(s)=="table" then
                    s.collected = true
                    s.validForCharacter = true
                    s.canCollect = true
                    s.hiddenUntilCollected = false
                end
            end
            DPrint("BaseSets:", #sets)
            return sets
        end
    end

    if o.GetVariantSets then
        C_TransmogSets.GetVariantSets = function(baseSetID, ...)
            local sets = o.GetVariantSets(baseSetID, ...) or {}
            for _, s in ipairs(sets) do
                if type(s)=="table" then
                    s.collected = true
                    s.validForCharacter = true
                    s.canCollect = true
                end
            end
            DPrint("VariantSets for", baseSetID, ":", #sets)
            return sets
        end
    end

    C_TransmogSets.IsSetUsable = function(setID) return true end
    C_TransmogSets.IsSetVisible = function(setID) return true end

    -- -------- APARÊNCIAS --------
    C_TransmogCollection.GetCategoryAppearances = function(catID, ...)
        if not catID or type(catID) ~= "number" then return {} end
        local apps = o.GetCategoryAppearances(catID, ...) or {}
        for _, a in ipairs(apps) do
            if type(a)=="table" then
                a.isCollected = true
                a.isUsable = true
                a.isValidAppearanceForPlayer = true
                a.hasNoSourceInfo = false
                a.isHideVisual = false
            end
        end
        DPrint("Category", catID, "->", #apps, "apps")
        return apps
    end

    C_TransmogCollection.GetAppearanceSourceInfo = function(srcID)
        if not srcID or type(srcID) ~= "number" then return nil end
        local info = o.GetAppearanceSourceInfo and o.GetAppearanceSourceInfo(srcID)
        if type(info) == "table" then
            info.isCollected = true
            info.isUsable = true
            info.isValidAppearanceForPlayer = true
            info.hasNoSourceInfo = false
            info.isHideVisual = false
            return info
        else
            return {
                sourceID = srcID,
                isCollected = true,
                isUsable = true,
                isValidAppearanceForPlayer = true,
                hasNoSourceInfo = false,
                isHideVisual = false,
            }
        end
    end

    C_TransmogCollection.GetAllAppearanceSources = function(visualID)
        if not visualID or type(visualID) ~= "number" then return {} end
        local srcs = o.GetAllAppearanceSources(visualID) or {}
        for _, s in ipairs(srcs) do
            if type(s)=="table" then
                s.isCollected = true
                s.isUsable = true
                s.isValidAppearanceForPlayer = true
            end
        end
        return srcs
    end
end

-- =====================
-- UI Hook para sets
-- =====================
local function HookSetsUI()
    local f = WardrobeCollectionFrame and WardrobeCollectionFrame.SetsCollectionFrame
    if not f or f._ClickMorphHooked then return end
    f._ClickMorphHooked = true

    f._ClickMorph_BuildData = f.BuildData
    f.BuildData = function(self)
        local sets = C_TransmogSets.GetAllSets() or {}
        local valid = {}
        for _, s in ipairs(sets) do
            if type(s) == "table" and s.setID then
                table.insert(valid, s)
            end
        end
        self.filteredSets = valid
        self.transmogSets = valid
        DPrint("UI BuildData overridden, total sets:", #valid)
        -- se der bug visual, descomenta a linha abaixo
        -- self:_ClickMorph_BuildData()
    end
end

-- =====================
-- Ativar / Reverter
-- =====================
function W:Activate()
    if self.wardrobeSystem.isActive then
        print("|cffffcc00ClickMorph Wardrobe:|r already active")
        return
    end
    self:SaveOriginalAPIs()
    self:HookAPIs()
    HookSetsUI()
    self.wardrobeSystem.isActive = true
    print("|cff00ff00ClickMorph Wardrobe:|r All appearances & sets unlocked!")
    self:Refresh()
end

function W:Revert()
    local o = self.wardrobeSystem.originalAPIs
    if not self.wardrobeSystem.isActive then
        print("|cffffcc00ClickMorph Wardrobe:|r not active")
        return
    end
    if o.GetAllSets then
        C_TransmogSets.GetAllSets = o.GetAllSets
        C_TransmogSets.GetSetInfo = o.GetSetInfo
        C_TransmogSets.GetUsableSets = o.GetUsableSets
        C_TransmogSets.GetBaseSets = o.GetBaseSets
        C_TransmogSets.GetVariantSets = o.GetVariantSets
        C_TransmogCollection.GetCategoryAppearances = o.GetCategoryAppearances
        C_TransmogCollection.GetAppearanceSourceInfo = o.GetAppearanceSourceInfo
        C_TransmogCollection.GetAllAppearanceSources = o.GetAllAppearanceSources
    end
    wipe(o)
    self.wardrobeSystem.isActive = false
    print("|cff00ff00ClickMorph Wardrobe:|r reverted to original")
    self:Refresh()
end

-- =====================
-- Refresh UI
-- =====================
function W:Refresh()
    if WardrobeCollectionFrame and WardrobeCollectionFrame:IsShown() then
        if WardrobeCollectionFrame.SetsCollectionFrame.Refresh then
            WardrobeCollectionFrame.SetsCollectionFrame:Refresh()
        end
        if WardrobeCollectionFrame.ItemsCollectionFrame.RefreshVisualsList then
            WardrobeCollectionFrame.ItemsCollectionFrame:RefreshVisualsList()
        end
    end
end

-- =====================
-- Slash Commands
-- =====================
SLASH_CLICKMORPH_WARDROBE1 = "/cmwardrobe"
SlashCmdList.CLICKMORPH_WARDROBE = function(arg)
    arg = (arg or ""):lower()
    if arg == "on" or arg == "" then W:Activate()
    elseif arg == "off" then W:Revert()
    elseif arg == "status" then print("Active:", W.wardrobeSystem.isActive and "YES" or "NO")
    elseif arg == "refresh" then W:Refresh()
    elseif arg == "debug" then W.debug = not W.debug print("Debug:", W.debug and "ON" or "OFF")
    else
        print("/cmwardrobe on|off|status|refresh|debug")
    end
end
