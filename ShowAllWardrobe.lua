-- ClickMorph ShowAll Wardrobe - versão revisada
ClickMorphShowAllWardrobe = {}
local W = ClickMorphShowAllWardrobe

W.wardrobeSystem = { isActive = false, originalAPIs = {}, hiddenSets = {} }
W.debug = false

local function DPrint(...)
    if W.debug then print("|cffff8800Wardrobe:|r", ...) end
end

-------------------------------------------------
-- Hidden sets conhecidos (exemplos, pode expandir)
-------------------------------------------------
local HIDDEN_SET_IDS = {
    4372, 4373, 4393, 4394, 4395, 4396, -- Sha, Chama Fria etc
    5001, 5002, 5003, 5004, 5005,       -- GM/dev
}

-------------------------------------------------
-- Construir hidden sets dinamicamente
-------------------------------------------------
function W:BuildHiddenSets()
    wipe(self.wardrobeSystem.hiddenSets)
    local found, o = 0, self.wardrobeSystem.originalAPIs

    for _, setID in ipairs(HIDDEN_SET_IDS) do
        local setInfo = o.GetSetInfo and o.GetSetInfo(setID)
        if setInfo and setInfo.name and setInfo.name ~= "" then
            setInfo.collected = true
            setInfo.validForCharacter = true
            setInfo.canCollect = true
            setInfo.hiddenUntilCollected = false
            setInfo.limitedTimeSet = false
            setInfo.classMask = 2047
            table.insert(self.wardrobeSystem.hiddenSets, setInfo)
            found = found + 1
            DPrint("Hidden found:", setID, setInfo.name)
        end
    end
    DPrint("Hidden sets total:", found)
    return found
end

-------------------------------------------------
-- Salvar APIs originais
-------------------------------------------------
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
        DPrint("Original APIs saved")
    end
end

-------------------------------------------------
-- Helper: força flags num set
-------------------------------------------------
local function ForceSetFlags(s)
    if not s then return end
    s.collected = true
    s.validForCharacter = true
    s.canCollect = true
    s.hiddenUntilCollected = false
    s.limitedTimeSet = false
    s.classMask = 2047
end

-------------------------------------------------
-- Hooks dinâmicos de API
-------------------------------------------------
function W:HookAPIs()
    local o = self.wardrobeSystem.originalAPIs

    -- SETS
    C_TransmogSets.GetAllSets = function(...)
        local sets = o.GetAllSets(...) or {}
        for _, s in ipairs(sets) do ForceSetFlags(s) end
        for _, hiddenSet in ipairs(self.wardrobeSystem.hiddenSets) do
            ForceSetFlags(hiddenSet)
            table.insert(sets, hiddenSet)
        end
        DPrint("GetAllSets ->", #sets)
        return sets
    end

    C_TransmogSets.GetSetInfo = function(setID)
        local s = o.GetSetInfo and o.GetSetInfo(setID)
        if s then ForceSetFlags(s) return s end
        for _, hiddenSet in ipairs(self.wardrobeSystem.hiddenSets) do
            if hiddenSet.setID == setID then return hiddenSet end
        end
    end

    if o.GetUsableSets then
        C_TransmogSets.GetUsableSets = function(...)
            local sets = o.GetUsableSets(...) or {}
            for _, s in ipairs(sets) do ForceSetFlags(s) end
            return sets
        end
    end

    if o.GetBaseSets then
        C_TransmogSets.GetBaseSets = function(...)
            local sets = o.GetBaseSets(...) or {}
            for _, s in ipairs(sets) do ForceSetFlags(s) end
            return sets
        end
    end

    if o.GetVariantSets then
        C_TransmogSets.GetVariantSets = function(baseSetID, ...)
            local sets = o.GetVariantSets(baseSetID, ...) or {}
            for _, s in ipairs(sets) do ForceSetFlags(s) end
            return sets
        end
    end

    C_TransmogSets.IsSetUsable = function() return true end
    C_TransmogSets.IsSetVisible = function() return true end

    -- APARÊNCIAS
    C_TransmogCollection.GetCategoryAppearances = function(catID, ...)
        if not catID then return {} end
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
        return apps
    end

    C_TransmogCollection.GetAppearanceSourceInfo = function(srcID)
        local info = o.GetAppearanceSourceInfo and o.GetAppearanceSourceInfo(srcID)
        if type(info)=="table" then
            info.isCollected = true
            info.isUsable = true
            info.isValidAppearanceForPlayer = true
            return info
        else
            return { sourceID = srcID, isCollected = true, isUsable = true, isValidAppearanceForPlayer = true }
        end
    end

    C_TransmogCollection.GetAllAppearanceSources = function(visualID)
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

-------------------------------------------------
-- UI Patch: mescla hidden no BuildData
-------------------------------------------------
local function HookSetsUI()
    local f = WardrobeCollectionFrame and WardrobeCollectionFrame.SetsCollectionFrame
    if not f or f._ClickMorphHooked then return end
    f._ClickMorphHooked = true

    f._ClickMorph_BuildData = f._ClickMorph_BuildData or f.BuildData
    f.BuildData = function(self, ...)
        self:_ClickMorph_BuildData(...)

        local combined = {}
        for _, s in ipairs(self.filteredSets or {}) do
            ForceSetFlags(s)
            table.insert(combined, s)
        end
        for _, hs in ipairs(W.wardrobeSystem.hiddenSets or {}) do
            ForceSetFlags(hs)
            table.insert(combined, hs)
        end

        self.filteredSets = combined
        self.transmogSets = combined
        DPrint("BuildData patched ->", #combined, "sets (", #W.wardrobeSystem.hiddenSets, "hidden)")
    end
end

-------------------------------------------------
-- Ativar / Reverter
-------------------------------------------------
function W:Activate()
    if self.wardrobeSystem.isActive then
        print("|cffffcc00ClickMorph Wardrobe:|r already active") return
    end
    self:SaveOriginalAPIs()
    self:BuildHiddenSets()
    self:HookAPIs()
    HookSetsUI()
    self.wardrobeSystem.isActive = true
    print("|cff00ff00ClickMorph Wardrobe:|r unlocked (incl. hidden sets)")
    self:Refresh()
end

function W:Revert()
    local o = self.wardrobeSystem.originalAPIs
    if not self.wardrobeSystem.isActive then return end
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
    wipe(self.wardrobeSystem.hiddenSets)
    self.wardrobeSystem.isActive = false
    print("|cff00ff00ClickMorph Wardrobe:|r reverted")
    self:Refresh()
end

-------------------------------------------------
-- Refresh
-------------------------------------------------
function W:Refresh()
    if WardrobeCollectionFrame and WardrobeCollectionFrame:IsShown() then
        if WardrobeCollectionFrame.SetsCollectionFrame and WardrobeCollectionFrame.SetsCollectionFrame.Refresh then
            pcall(function() WardrobeCollectionFrame.SetsCollectionFrame:Refresh() end)
        end
    end
end

-------------------------------------------------
-- Slash Commands
-------------------------------------------------
SLASH_CLICKMORPH_WARDROBE1 = "/cmwardrobe"
SlashCmdList.CLICKMORPH_WARDROBE = function(arg)
    arg = (arg or ""):lower():trim()
    if arg == "on" or arg == "" then W:Activate()
    elseif arg == "off" then W:Revert()
    elseif arg == "refresh" then W:Refresh()
    elseif arg == "debug" then W.debug = not W.debug print("Debug:", W.debug and "ON" or "OFF")
    end
end
