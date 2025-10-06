-- ADICIONE ESTE CÓDIGO NO FINAL DO ShowAll.lua EXISTENTE
-- Sistema de Mount Morph com HookScript (não quebra Mount Enhancer)

-----------------------------------------------------------
-- MOUNT MORPH SYSTEM
-----------------------------------------------------------
local MountMorph = {}
MountMorph.debug = false

local function MMDebugPrint(...)
    if MountMorph.debug then
        print("|cff00ccffMountMorph:|r", ...)
    end
end

-- Função principal de morph
function MountMorph:ApplyMorph()
    -- Verificar se tá montado
    if not IsMounted() then
        print("|cffff0000MountMorph:|r You need to be mounted first!")
        return
    end
    
    if UnitOnTaxi("player") then
        print("|cffff0000MountMorph:|r Cannot morph while on a flight path!")
        return
    end
    
    -- Verificar iMorph
    if not (IMorphInfo or Morph) then
        print("|cffff0000MountMorph:|r iMorph not loaded")
        return
    end
    
    -- Pegar spell da montaria ATUAL (que player tá montado)
    local currentMountSpellID = nil
    for i = 1, C_MountJournal.GetNumDisplayedMounts() do
        local mountName, spellID, _, _, _, _, _, _, _, _, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i)
        if mountName then
            local buff = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
            if buff then
                currentMountSpellID = spellID
                MMDebugPrint("Current mount spell:", spellID, mountName)
                break
            end
        end
    end
    
    -- Pegar mount selecionada
    local targetMountID = MountJournal.selectedMountID
    if not targetMountID then
        print("|cffff0000MountMorph:|r No mount selected")
        return
    end
    
    -- Pegar info da mount alvo
    local mountName, targetSpellID, icon = C_MountJournal.GetMountInfoByID(targetMountID)
    if not mountName then
        print("|cffff0000MountMorph:|r Could not get mount info")
        return
    end
    
    -- Pegar displayID
    local displayID = C_MountJournal.GetMountInfoExtraByID(targetMountID)
    
    if not displayID then
        local multipleIDs = C_MountJournal.GetMountAllCreatureDisplayInfoByID(targetMountID)
        if multipleIDs and #multipleIDs > 0 then
            displayID = multipleIDs[math.random(#multipleIDs)].creatureDisplayID
            MMDebugPrint("Using random displayID:", displayID)
        end
    end
    
    if not displayID then
        print("|cffff0000MountMorph:|r No displayID found")
        return
    end
    
    -- Aplicar apenas .mount (spell animation removido por causar bugs visuais)
    local mountCmd = string.format(".mount %d", displayID)
    MMDebugPrint("Executing:", mountCmd)
    
    ChatFrame1EditBox:SetText(mountCmd)
    ChatEdit_SendText(ChatFrame1EditBox, 0)
    
    print(string.format("|cff00ff00MountMorph:|r %s (DisplayID: %d)", mountName, displayID))
end

-- Sistema de hook com retry
local mountHookAttempts = 0
local maxMountHookAttempts = 10

local function SetupMountMorphHook()
    mountHookAttempts = mountHookAttempts + 1
    
    if not MountJournal then
        if mountHookAttempts < maxMountHookAttempts then
            C_Timer.After(1, SetupMountMorphHook)
            MMDebugPrint("MountJournal not found, retry", mountHookAttempts)
        end
        return false
    end
    
    -- Hook no ModelScene
    if MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene then
        local modelScene = MountJournal.MountDisplay.ModelScene
        
        if not modelScene._MountMorphHooked then
            modelScene:HookScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
                    MMDebugPrint("Alt+Shift+Click detected on mount model")
                    MountMorph:ApplyMorph()
                end
            end)
            modelScene._MountMorphHooked = true
            print("|cff00ff00MountMorph:|r Mount Journal hook OK (Alt+Shift+Click)")
        end
        return true
    end
    
    if mountHookAttempts < maxMountHookAttempts then
        C_Timer.After(1, SetupMountMorphHook)
        MMDebugPrint("ModelScene not found, retry", mountHookAttempts)
    else
        print("|cffffff00MountMorph:|r Could not auto-hook. Use /mmrehook after opening Mount Journal")
    end
    
    return false
end

-- Comandos
SLASH_MOUNTMORPH_DEBUG1 = "/mmdebug"
SlashCmdList.MOUNTMORPH_DEBUG = function()
    MountMorph.debug = not MountMorph.debug
    print("|cff00ff00MountMorph:|r Debug", MountMorph.debug and "ON" or "OFF")
end

SLASH_MOUNTMORPH_REHOOK1 = "/mmrehook"
SlashCmdList.MOUNTMORPH_REHOOK = function()
    print("|cff00ff00MountMorph:|r Manually applying hook...")
    mountHookAttempts = 0
    SetupMountMorphHook()
end

SLASH_MOUNTMORPH_TEST1 = "/mmtest"
SlashCmdList.MOUNTMORPH_TEST = function()
    print("|cff00ff00=== MOUNTMORPH TEST ===|r")
    print("MountJournal:", MountJournal and "OK" or "NIL")
    print("MountDisplay:", MountJournal and MountJournal.MountDisplay and "OK" or "NIL")
    print("ModelScene:", MountJournal and MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene and "OK" or "NIL")
    print("Hooked:", MountJournal and MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene and MountJournal.MountDisplay.ModelScene._MountMorphHooked and "YES" or "NO")
    print("iMorph:", (IMorphInfo or Morph) and "OK" or "NIL")
    print("Mounted:", IsMounted() and "YES" or "NO")
    print("Selected Mount:", MountJournal and MountJournal.selectedMountID or "NONE")
    
    if MountJournal and MountJournal.selectedMountID then
        local name = C_MountJournal.GetMountInfoByID(MountJournal.selectedMountID)
        print("Mount Name:", name or "N/A")
    end
end

SLASH_MOUNTMORPH_APPLY1 = "/mmapply"
SlashCmdList.MOUNTMORPH_APPLY = function()
    print("|cff00ff00MountMorph:|r Manually applying morph...")
    MountMorph:ApplyMorph()
end

-- Sistema de inicialização
local mountInitFrame = CreateFrame("Frame")
mountInitFrame:RegisterEvent("ADDON_LOADED")
mountInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

mountInitFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_Collections" then
            C_Timer.After(0.5, SetupMountMorphHook)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, SetupMountMorphHook)
        C_Timer.After(10, SetupMountMorphHook)
    end
end)

-- Tentativa imediata
C_Timer.After(1, SetupMountMorphHook)

print("|cff00ff00MountMorph System loaded!|r")
print("Commands: /mmdebug, /mmtest, /mmapply, /mmrehook")
print("Usage: Mount up, select a mount, Alt+Shift+Click the 3D model")