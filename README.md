# ClickMorph-WoW - Retail Fix

This version includes fixes and updates for Retail WoW (11.x) for personal use, but may be useful for anyone who finds manually looking up every ID tedious and misses the Alt+Shift+Click morphing convenience.  

ClickMorph lets you Alt+Shift-Click to morph with [iMorph](https://www.ownedcore.com/forums/wow-classic/wow-classic-general/799754-wow-classic-morpher.html) or [jMorph](https://www.ownedcore.com/forums/world-of-warcraft/world-of-warcraft-bots-programs/795619-jmorph-tmorph-morpher-recreated.html).  
**Note:** It is _not_ standalone; you must load a morpher first.

---

## Install

1. Download the latest [release].  
2. Unpack both *ClickMorph* and *ClickMorphData* into your addons folder:  
C:\Program Files (x86)\World of Warcraft_classic_\Interface\AddOns
![](https://i.imgur.com/3clJHLW.png)

---

## Features

Videos: [Classic](https://streamable.com/m601s), [Retail](https://streamable.com/5rlll)  

* Morph from unlocked Mounts and Appearances (Wardrobe) tab  
* Morph from the Inspect window and item links/containers (needs further testing)  
* Supports some addons (needs further testing): [AtlasLoot Classic](https://www.curseforge.com/wow/addons/atlaslootclassic), [MogIt](https://www.curseforge.com/wow/addons/mogit), [Taku's Morph Catalog](https://www.curseforge.com/wow/addons/takus-morph-catalog)  
* Open the GUI with **/clickmorph** or **/cm** (deprecated)  
* Automatically remorph on inject/relog (iMorph)  

---

## Known Issues / ToDo

* **Unlock Button**: May not appear in some setups; API conflicts or other addons (e.g., Mount Journal Enhancer) can interfere will try to fix first
* **Wardrobe / Appearances Morphing**: Some sets may not morph correctly; needs additional testing and possibly updated hooks  
* **Inspect Window / Item Links**: Functionality partially tested; may require fixes for Retail WoW 11.x  
* **iMorph Integration**: Ensure iMorph is loaded first; otherwise Alt+Shift+Click morphing will fail  
* **Load Order Sensitivity**: Addons depending on TMW or Action may trigger conflicts; careful load order management may be necessary  as to load ClickMorph Lastly
* **Future Enhancements**: Remorph on login/reload could be optimized; GUI buttons could be redesigned for clarity and Re-Made for a config menu (Maybe)

---

## Credits

* Original concept and first version by [Icesythe7](https://www.ownedcore.com/forums/world-of-warcraft/world-of-warcraft-general/wow-ui-macros-talent-specs/785473-clickmog-addon-lucidmorph.html)  
* ClickMorph development by [Ketho](https://github.com/ketho-wow/ClickMorph)  
* Forked and updated for Retail WoW by Me
