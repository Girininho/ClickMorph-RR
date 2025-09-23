-- PauldronSystem.lua - Versão Simples e Dinâmica
-- Intercepta Alt+Shift+Click apenas em pauldrons

-- Inicializar ClickMorphPauldron primeiro
ClickMorphPauldron = {}
ClickMorphPauldron.config = {
    enabled = true,
    debugMode = false,
    showMessages = true
}

local function DebugPrint(...)
    if ClickMorphPauldron.config.debugMode then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i] or "nil")
        end
        print("|cff9999ff[Pauldron]|r", table.concat(args, " "))
    end
end

-- Verificar se item é pauldron
function ClickMorphPauldron.IsPauldronItem(itemID)
    if not itemID then return false end
    
    local equipLoc = select(9, GetItemInfo(itemID))
    return equipLoc == "INVTYPE_SHOULDER"
end

-- Sistema de IDs alternados e ID invisível
local INVISIBLE_SHOULDER_ID = 1371 -- ID que torna ombreira invisível

local function GetAlternateID(mainID)
    local alternates = {
        [229251] = 238420,
        [238420] = 229251,
        [229480] = 238420,
        [229479] = 238420,
        -- Adicionar mais conforme necessário
    }
    return alternates[mainID] or (mainID == 238420 and 229251 or 238420) -- Fallback
end

-- Executar comando com estratégia simplificada
function ClickMorphPauldron.ExecuteCommand(itemID, side)
    local message = ""
    
    if side == "both" then
        -- Ambas: estratégia simples que sempre funciona
        message = "Both shoulders"
        
        if iMorphChatHandler then
            iMorphChatHandler(".reset")
            C_Timer.After(0.1, function()
                iMorphChatHandler(string.format(".item 3 %d 0 0", itemID))
            end)
        else
            SendChatMessage(".reset", "SAY")
            C_Timer.After(0.1, function()
                SendChatMessage(string.format(".item 3 %d 0 0", itemID), "SAY")
            end)
        end
        
    elseif side == "right_split" then
        -- Para direita apenas: usar split 1 (SEM forçar invisível)
        message = "Right shoulder only (split method - preserves left)"
        
        if iMorphChatHandler then
            -- NÃO fazer reset - preservar ombreira esquerda atual
            -- Aplicar ID desejado com split 1 (só direita)
            iMorphChatHandler(string.format(".item 3 %d 0 1", itemID))
        else
            SendChatMessage(string.format(".item 3 %d 0 1", itemID), "SAY")
        end
        
    elseif side == "make_invisible" then
        -- Tornar esquerda invisível (para destacar direita atual)
        message = "Left shoulder made invisible"
        
        if iMorphChatHandler then
            -- Aplicar ID invisível em ambos, depois aplicar split 1 vazio para limpar direita
            iMorphChatHandler(string.format(".item 3 %d 0 0", INVISIBLE_SHOULDER_ID))
        else
            SendChatMessage(string.format(".item 3 %d 0 0", INVISIBLE_SHOULDER_ID), "SAY")
        end
        
    elseif side == "right_invisible" then
        -- Para direita com esquerda forçada invisível (estratégia original testada)
        message = "Right shoulder only with invisible left"
        
        if iMorphChatHandler then
            iMorphChatHandler(".reset")
            C_Timer.After(0.1, function()
                -- Aplicar ID invisível em ambos primeiro
                iMorphChatHandler(string.format(".item 3 %d 0 0", INVISIBLE_SHOULDER_ID))
                C_Timer.After(0.2, function()
                    -- Aplicar ID desejado com split 1 (só direita)
                    iMorphChatHandler(string.format(".item 3 %d 0 1", itemID))
                end)
            end)
        else
            SendChatMessage(".reset", "SAY")
            C_Timer.After(0.1, function()
                SendChatMessage(string.format(".item 3 %d 0 0", INVISIBLE_SHOULDER_ID), "SAY")
                C_Timer.After(0.2, function()
                    SendChatMessage(string.format(".item 3 %d 0 1", itemID), "SAY")
                end)
            end)
        end
        
    elseif side == "clear" then
        -- Clear total
        message = "Cleared shoulders"
        if iMorphChatHandler then
            iMorphChatHandler(".reset")
        else
            SendChatMessage(".reset", "SAY")
        end
    end
    
    DebugPrint("Executing simplified strategy:", side, "for item:", itemID or "invisible")
    
    if ClickMorphPauldron.config.showMessages then
        print("|cff00ff00Pauldron:|r " .. message .. " (ID: " .. (itemID or INVISIBLE_SHOULDER_ID) .. ")")
    end
end

-- Hook principal no HandleModifiedItemClick
function ClickMorphPauldron.InstallHook()
    if ClickMorphPauldron.originalHandleModifiedItemClick then
        DebugPrint("Hook já instalado")
        return true
    end
    
    if not HandleModifiedItemClick then
        DebugPrint("HandleModifiedItemClick não encontrado")
        return false
    end
    
    -- Salvar função original
    ClickMorphPauldron.originalHandleModifiedItemClick = HandleModifiedItemClick
    
    -- Nossa versão interceptada
    HandleModifiedItemClick = function(item)
        DebugPrint("=== HandleModifiedItemClick INTERCEPTED ===")
        DebugPrint("Item:", item)
        
        -- Verificar modificadores ANTES de processar
        local isAltShift = IsAltKeyDown() and IsShiftKeyDown()
        local isCtrlShift = IsControlKeyDown() and IsShiftKeyDown() and not IsAltKeyDown()
        local isShiftOnly = IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown()
        
        DebugPrint("Alt+Shift:", isAltShift, "Ctrl+Shift:", isCtrlShift, "Shift only:", isShiftOnly)
        
        if (isAltShift or isCtrlShift or isShiftOnly) and ClickMorphPauldron.config.enabled then
            -- Tentar obter informações do item
            local success, itemID, itemLink, equipLoc = pcall(CM.GetItemInfo, CM, item)
            
            if success and itemID and ClickMorphPauldron.IsPauldronItem(itemID) then
                DebugPrint("PAULDRON DETECTED:", itemID)
                
                if isAltShift then
                    DebugPrint("Alt+Shift pauldron mode - applying to BOTH shoulders")
                    ClickMorphPauldron.ExecuteCommand(itemID, "both")
                    return -- BLOQUEIA completamente o original
                    
                elseif isShiftOnly then
                    DebugPrint("Shift only pauldron mode - applying to RIGHT shoulder only")
                    ClickMorphPauldron.ExecuteCommand(itemID, "right_split")
                    return -- BLOQUEIA completamente o original
                    
                elseif isCtrlShift then
                    DebugPrint("Ctrl+Shift invisible mode - making left shoulder invisible")
                    ClickMorphPauldron.ExecuteCommand(nil, "make_invisible")
                    return -- BLOQUEIA completamente o original
                end
            else
                DebugPrint("Not a pauldron or failed to get info")
            end
        else
            DebugPrint("No valid modifier combination")
        end
        
        -- Se não foi interceptado, chamar função original
        DebugPrint("Calling original HandleModifiedItemClick")
        return ClickMorphPauldron.originalHandleModifiedItemClick(item)
    end
    
    DebugPrint("HandleModifiedItemClick hook instalado com sucesso")
    return true
end

-- Mostrar capture simplificado para morph
function ClickMorphPauldron.ShowMorphCapture(itemID)
    DebugPrint("Creating simplified morph capture frame for item:", itemID)
    
    -- FORÇA limpeza de qualquer capture anterior
    ClickMorphPauldron.ForceCleanCapture()
    
    -- Criar frame simples e direto
    local captureFrame = CreateFrame("Frame", nil, UIParent)
    captureFrame:SetAllPoints()
    captureFrame:EnableMouse(true)
    captureFrame:SetFrameLevel(1000)
    captureFrame:Show()
    
    -- Timeout
    local timeoutTimer = C_Timer.NewTimer(5, function()
        DebugPrint("Morph capture TIMEOUT - forcing cleanup")
        ClickMorphPauldron.ForceCleanCapture()
    end)
    
    captureFrame:SetScript("OnMouseDown", function(self, button)
        DebugPrint("Morph button captured:", button, "for item:", itemID)
        
        -- Cancel timeout
        if timeoutTimer then
            timeoutTimer:Cancel()
            timeoutTimer = nil
        end
        
        if button == "LeftButton" then
            DebugPrint("Executing BOTH strategy")
            ClickMorphPauldron.ExecuteCommand(itemID, "both")
        elseif button == "RightButton" then
            DebugPrint("Executing RIGHT_SPLIT strategy")
            ClickMorphPauldron.ExecuteCommand(itemID, "right_split")
        end
        
        -- FORÇA limpeza completa
        ClickMorphPauldron.ForceCleanCapture()
    end)
    
    ClickMorphPauldron.captureFrame = captureFrame
    ClickMorphPauldron.currentMode = "morph"
    DebugPrint("Morph capture frame created and stored")
    print("|cffff8800Pauldron Mode:|r Left=Ambas | Right=Só Direita")
end

-- Mostrar capture para tornar esquerda invisível
function ClickMorphPauldron.ShowInvisibleCapture(itemID)
    DebugPrint("Creating invisible capture frame")
    
    -- FORÇA limpeza de qualquer capture anterior
    ClickMorphPauldron.ForceCleanCapture()
    
    local captureFrame = CreateFrame("Frame", nil, UIParent)
    captureFrame:SetAllPoints()
    captureFrame:EnableMouse(true)
    captureFrame:SetFrameLevel(1000)
    captureFrame:Show()
    
    local timeoutTimer = C_Timer.NewTimer(5, function()
        DebugPrint("Invisible capture TIMEOUT - forcing cleanup")
        ClickMorphPauldron.ForceCleanCapture()
    end)
    
    captureFrame:SetScript("OnMouseDown", function(self, button)
        DebugPrint("Invisible button captured:", button)
        
        -- Cancel timeout
        if timeoutTimer then
            timeoutTimer:Cancel()
            timeoutTimer = nil
        end
        
        if button == "LeftButton" or button == "RightButton" then
            DebugPrint("Executing MAKE_INVISIBLE strategy")
            ClickMorphPauldron.ExecuteCommand(nil, "make_invisible")
        end
        
        -- FORÇA limpeza completa
        ClickMorphPauldron.ForceCleanCapture()
    end)
    
    ClickMorphPauldron.captureFrame = captureFrame
    ClickMorphPauldron.currentMode = "invisible"
    DebugPrint("Invisible capture frame created and stored")
    print("|cffff8800Invisible Mode:|r Qualquer clique = Esquerda invisível")
end

-- Função para forçar limpeza completa do estado
function ClickMorphPauldron.ForceCleanCapture()
    DebugPrint("=== FORCING COMPLETE CAPTURE CLEANUP ===")
    
    if ClickMorphPauldron.captureFrame then
        DebugPrint("Destroying existing capture frame")
        ClickMorphPauldron.captureFrame:Hide()
        ClickMorphPauldron.captureFrame:SetScript("OnMouseDown", nil)
        ClickMorphPauldron.captureFrame = nil
    end
    
    -- Limpar estado interno
    ClickMorphPauldron.currentMode = nil
    
    DebugPrint("Capture state cleaned")
end

-- Comandos para testes e configuração
SLASH_PAULDRON1 = "/pauldron"
SlashCmdList["PAULDRON"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = string.lower(args[1] or "")
    
    if command == "toggle" then
        ClickMorphPauldron.config.enabled = not ClickMorphPauldron.config.enabled
        print("|cff00ff00Pauldron:|r", ClickMorphPauldron.config.enabled and "Enabled" or "Disabled")
        
    elseif command == "clean" then
        ClickMorphPauldron.ForceCleanCapture()
        print("|cff00ff00Pauldron:|r Forced cleanup completed")
        
    elseif command == "debug" then
        ClickMorphPauldron.config.debugMode = not ClickMorphPauldron.config.debugMode
        print("|cff00ff00Pauldron:|r Debug mode", ClickMorphPauldron.config.debugMode and "ON" or "OFF")
        
    elseif command == "test" then
        local side = args[2] or "both"
        local itemID = tonumber(args[3]) or 229251
        
        print("|cff00ff00Pauldron:|r Testing", side, "with ID", itemID)
        ClickMorphPauldron.ExecuteCommand(itemID, side)
        
    elseif command == "hook" then
        if ClickMorphPauldron.InstallHook() then
            print("|cff00ff00Pauldron:|r Hook installed successfully")
        else
            print("|cffff0000Pauldron:|r Failed to install hook")
        end
        
    elseif command == "status" then
        print("|cff00ff00=== Pauldron Status ===|r")
        print("Enabled:", ClickMorphPauldron.config.enabled)
        print("Debug:", ClickMorphPauldron.config.debugMode)
        print("HandleModifiedItemClick hook:", ClickMorphPauldron.originalHandleModifiedItemClick ~= nil)
        print("ClickMorph available:", CM and CM.MorphItem ~= nil)
        print("Current capture frame:", ClickMorphPauldron.captureFrame ~= nil)
        print("Current mode:", ClickMorphPauldron.currentMode or "none")
        
        if ClickMorphPauldron.originalHandleModifiedItemClick then
            print("|cff00ff00Ready to intercept pauldron clicks!|r")
        else
            print("|cffff0000Hook not installed - run /pauldron hook|r")
        end
        
    else
        print("|cff00ff00Pauldron Commands:|r")
        print("/pauldron toggle - Enable/disable")
        print("/pauldron debug - Toggle debug")
        print("/pauldron clean - Force cleanup capture state")
        print("/pauldron test <both|right_split|right_invisible|make_invisible|clear> [itemID] - Test command")
        print("/pauldron hook - Reinstall hook")
        print("/pauldron status - Show status")
        print("")
        print("|cffffcc00Usage:|r")
        print("|cffaaff00Alt+Shift+Click ombreira:|r Aplicar em ambas")
        print("|cffaaff00Shift+Click ombreira:|r Aplicar só na direita (preserva esquerda)")
        print("|cffaaff00Ctrl+Shift+Click ombreira:|r Esquerda invisível")
        print("")
        print("|cffffaa00Para mix de ombreiras:|r")
        print("1. Alt+Shift+Click na primeira ombreira (ambas)")
        print("2. Shift+Click na segunda ombreira (só direita)")
        print("3. Resultado: Esquerda=primeira, Direita=segunda")
    end
end

-- Inicialização
local function Initialize()
    DebugPrint("Initializing Pauldron System...")
    
    -- Instalar hook no HandleModifiedItemClick
    if ClickMorphPauldron.InstallHook() then
        DebugPrint("Pauldron system initialized successfully")
    else
        -- Tentar novamente em 1 segundo
        C_Timer.After(1, Initialize)
        DebugPrint("Retrying initialization...")
    end
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ClickMorph" then
        C_Timer.After(0.5, Initialize)
    end
end)

print("|cff00ff00ClickMorph Pauldron System|r loaded!")
print("|cff9999ffUsage:|r Alt+Shift=Ambas | Shift=Só Direita | Ctrl+Shift=Invisível")
print("|cff9999ffTip:|r Usa apenas Shift para evitar conflitos com WoW")