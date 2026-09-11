# K.I.S.S. (Keep It Simple, Stupid)

A setup wizard for [GRIP-EMS](https://www.curseforge.com/wow/addons/grip-enhanced-macro-sequencer) (GRIP - Enhanced Macro Sequencer), a World of Warcraft Retail addon. If you're new to GRIP-EMS, K.I.S.S. walks you through the three things you need to do to get it working: pick or import a sequence, bind a key to it, then test it out.

![K.I.S.S. version](https://img.shields.io/badge/version-0.1.0-blue)

## What it does

- A step by step wizard anyone can follow and not mess up.
- Lets you pick a sequence you already have, or loads GRIP-EMS's import window if you need to load one. Includes links to external sites for finding rotations.
- Lets you set a keybind with one click, applied through GRIP-EMS automatically.
- A final page with tips if something isn't working, plus a link to the [GRIP-EMS Discord](https://discord.gg/XQXH3nt2X8) 
- Lets you delete sequences you don't need anymore, right from the picker, with a confirmation dialog so you don't delete something by mistake.
- Opens by itself the first time you install it. After that, type `/gems kiss` anytime to bring it back.

## What you need

- World of Warcraft: Retail
- [GRIP-EMS](https://www.curseforge.com/wow/addons/grip-enhanced-macro-sequencer) installed and turned on. K.I.S.S. is just a companion plugin and won't load without it

## How to install it

1. Download or clone this repository
2. Copy the `GRIP-EMS-KISS` folder into your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Start WoW and enable **GRIP - K.I.S.S. - Keep It Simple, Stupid** in your AddOns list

## How to use it

- The first time you log in, the wizard opens on its own
- You can reopen it anytime by typing `/gems kiss`
- Follow the addons instructions.

## Project layout

```
GRIP-EMS-KISS/
  GRIP-EMS-KISS.toc
  Core/
    Init.lua         (handles startup, registering the plugin, the slash command, and event listeners)
  UI/
    Widgets.lua       (shared colors and basic building blocks used everywhere)
    URLPopup.lua       (a popup for copying links, since addons can't open a browser directly)
    SequenceGrid.lua   (the sequence picker grid, plus the delete confirmation popup)
    Pages.lua          (the actual Home, Step 1, Step 2, and Step 3 screens)
    Wizard.lua         (the window itself: the frame, side menu, bottom bar, and page switching)
  Media/
    opai.blp           (the mascot image)
```

Every file shares one private table (using the standard `local ADDON_NAME, KISS = ...` pattern), so things defined in one file can be used in the others without creating any global variables.

## Built against

GRIP-EMS Plugin API v2 or newer. It uses `RegisterPlugin`, `RegisterSlashCommand`, and the public event bus. See the [GRIP-EMS Plugin API docs](https://JesperLive.github.io/GRIP-EMS-PluginAPI) if you want the full details.

## Credits

Made by MFDOOM with love.

## License

See [LICENSE](LICENSE).
