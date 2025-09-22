-- MountCastAnimation.lua - Sistema experimental para alterar animações de cast
-- NOTA: Este é um conceito avançado que pode não funcionar em todos os servidores

ClickMorphMountCast = {}

ClickMorphMountCast.castSystem = {
    isActive = false,
    debugMode = false,
    mountCastOverrides = {}, -- Mapeamento DisplayID -> SpellID de cast
    isHookedCasting = false
}

-- Mapeamento conhecido de montarias para spells de cast apropriados
ClickMorphMountCast.MOUNT_CAST_MAP = {
    -- Montarias voadoras -> spell de voo
    [32345] = 32223, -- Exemplo: Netherdrake -> Spell de invocação de dragão
    [32244] = 32242, -- Exemplo: Phoenix -> Spell de fênix
    
    -- Montarias terrestres -> spell terrestre
    [14568] = 23161, -- Exemplo: Cavalo -> Spell de cavalo
    
    -- Montarias aquáticas -> spell aquático  
    [64731] = 75207, -- Exemplo: Tartaruga -> Spell aquático
    
    -- Casos especiais (montarias que transformam)
    [59569] = 0, -- Dragão de Arenito -> Sem cast (transforma diretamente)
}

--[[
TEORIA DO SISTEMA:

1. Hook evento UNIT_SPELLCAST_START quando player invoca montaria
2. Detectar qual montaria está sendo invocada
3. Cancelar cast original
4. Executar cast customizado baseado no tipo de montaria
5. Aplicar morph quando cast terminar

DESAFIOS:
- Diferentes servidores têm diferentes implementações de cast
- Pode quebrar macros/addons de montaria
- Difícil sincronizar com servidor
- Animações podem não estar disponíveis
--]]

-- Hook sistema de cast
function ClickMorphMountCast.HookCastingSystem()
    local system = ClickMorphMountCast.castSystem
    
    if system.isHookedCasting then return end
    
    -- Event frame para monitorar casts
    local castFrame = CreateFrame("Frame")
    castFrame:RegisterEvent("UNIT_SPELLCAST_START")
    castFrame:RegisterEvent("UNIT_SPELLCAST_STOP") 
    castFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    
    castFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
        if unit ~= "player" then return end
        
        ClickMorphMountCast.HandleCastEvent(event, spellID, castGUID)
    end)
    
    system.isHookedCasting = true
    print("|cff00ff00Mount Cast:|r Hooked casting system")
end

-- Handler de eventos de cast
function ClickMorphMountCast.HandleCastEvent(event, spellID, castGUID)
    local system = ClickMorphMountCast.castSystem
    
    if not system.isActive then return end
    
    -- Verificar se é um spell de montaria
    local mountInfo = ClickMorphMountCast.GetMountInfoFromSpell(spellID)
    if not mountInfo then return end
    
    if event == "UNIT_SPELLCAST_START" then
        ClickMorphMountCast.HandleMountCastStart(spellID, mountInfo, castGUID)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then  
        ClickMorphMountCast.HandleMountCastComplete(spellID, mountInfo)
    end
end

-- Detectar informação da montaria pelo spell
function ClickMorphMountCast.GetMountInfoFromSpell(spellID)
    -- Tentar obter info da montaria via spell
    if C_MountJournal and C_MountJournal.GetMountFromSpell then
        local mountID = C_MountJournal.GetMountFromSpell(spellID)
        if mountID then
            local creatureDisplayID, description, source, isSelfMount, mountTypeID, uiModelSceneID = C_MountJournal.GetMountInfoExtraByID(mountID)
            return {
                mountID = mountID,
                displayID = creatureDisplayID,
                mountTypeID = mountTypeID,
                spellID = spellID
            }
        end
    end
    
    return nil
end

-- Handler início de cast de montaria
function ClickMorphMountCast.HandleMountCastStart(spellID, mountInfo, castGUID)
    local system = ClickMorphMountCast.castSystem
    
    local currentMorph = ClickMorphMountCustomizer and ClickMorphMountCustomizer.customizerSystem.currentDisplayID
    
    if currentMorph and currentMorph ~= mountInfo.displayID then
        -- Player está morphado para montaria diferente
        local customCastSpell = system.mountCastOverrides[currentMorph]
        
        if customCastSpell then
            print("|cff00ff00Mount Cast:|r Overriding cast animation for morphed mount")
            
            -- EXPERIMENTAL: Tentar cancelar cast atual e iniciar customizado
            -- NOTA: Isto pode não funcionar em todos os servidores
            SpellStopCasting()
            
            C_Timer.After(0.1, function()
                -- Simular cast customizado
                ClickMorphMountCast.StartCustomMountCast(customCastSpell, currentMorph)
            end)
        end
    end
end

-- Iniciar cast customizado
function ClickMorphMountCast.StartCustomMountCast(spellID, displayID)
    -- EXPERIMENTAL: Tentar forçar animação de cast específica
    
    if spellID and spellID > 0 then
        -- Método 1: Tentar cast do spell customizado
        CastSpellByID(spellID)
    else
        -- Método 2: Cast genérico com timer
        ClickMorphMountCast.SimulateMountCast(displayID)
    end
end

-- Simular cast de montaria
function ClickMorphMountCast.SimulateMountCast(displayID)
    print("|cff00ff00Mount Cast:|r Simulating cast for display ID", displayID)
    
    -- Criar barra de cast fake
    local castBar = ClickMorphMountCast.CreateFakeCastBar()
    castBar:Show()
    
    -- Simular duração de cast (tipicamente 1.5-3 segundos)
    local castTime = 2.5
    local startTime = GetTime()
    
    castBar:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        local progress = elapsed / castTime
        
        if progress >= 1.0 then
            self:Hide()
            self:SetScript("OnUpdate", nil)
            print("|cff00ff00Mount Cast:|r Custom cast completed")
        else
            -- Atualizar barra de progresso (se implementada)
            self:SetValue(progress)
        end
    end)
end

-- Criar barra de cast falsa (placeholder)
function ClickMorphMountCast.CreateFakeCastBar()
    local castBar = CreateFrame("Frame", nil, UIParent)
    castBar:SetSize(300, 20)
    castBar:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    
    local bg = castBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    local text = castBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("Summoning Mount...")
    
    castBar.SetValue = function(self, value)
        -- Implementar barra de progresso visual se necessário
    end
    
    return castBar
end