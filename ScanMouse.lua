-- ScanMouse.lua - Escanear item sob mouse no Wardrobe
-- Cole isso num arquivo ScanMouse.lua e adicione no .toc
-- Depois use: /scanmouse

SLASH_SCANMOUSE1 = "/scanmouse"
SlashCmdList.SCANMOUSE = function()
    print("=== SCANNING BETTERWARDROBE MODELS ===")
    
    -- Tentar BetterWardrobe primeiro
    local itemsFrame = BetterWardrobeCollectionFrame and BetterWardrobeCollectionFrame.ItemsCollectionFrame
    
    -- Fallback para Wardrobe padrão
    if not itemsFrame then
        itemsFrame = WardrobeCollectionFrame and WardrobeCollectionFrame.ItemsCollectionFrame
    end
    
    if not itemsFrame then
        print("Nenhum Wardrobe encontrado")
        return
    end
    
    if not itemsFrame.Models then
        print("Models não encontrado em ItemsCollectionFrame")
        print("Explorando ItemsCollectionFrame:")
        for k in pairs(itemsFrame) do
            print("  ", k)
        end
        return
    end
    
    local count = 0
    for i, m in pairs(itemsFrame.Models) do
        if m.visualInfo then
            local visualID = m.visualInfo.visualID
            local sources = C_TransmogCollection.GetAllAppearanceSources(visualID)
            
            if sources and #sources > 0 then
                local sourceInfo = C_TransmogCollection.GetSourceInfo(sources[1])
                
                if sourceInfo then
                    count = count + 1
                    print(" ")
                    print("MODEL", i)
                    print("  ItemID:", sourceInfo.itemID)
                    print("  ModID:", sourceInfo.itemModID)
                    print("  VisualID:", visualID)
                    
                    local itemName = C_Item.GetItemInfo(sourceInfo.itemID)
                    if itemName then
                        print("  Name:", itemName)
                    end
                end
            end
        end
    end
    
    print(" ")
    print("Total models found:", count)
end

print("ScanMouse loaded - use /scanmouse com mouse sobre item")