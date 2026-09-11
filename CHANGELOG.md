# Changelog

## v0.1.0 (First release)

This is the first working version of K.I.S.S. It's a little wizard that
walks new GRIP-EMS users through getting their rotation up and running.
You pick or import a sequence, bind a key to it, then go test it on a
dummy.

**What's in it:**

- A full guided setup. It walks you from the Home screen, to picking your
  sequence, to binding a key, to testing it out.
- Step 1 lets you pick from sequences you've already imported. If you
  don't have one yet, it sends you to GRIP-EMS's own import window, with
  links to LazyGrip and HouseOfMacros in case you need a rotation to
  begin with.
- One click to capture a keybind. It gets applied straight through
  GRIP-EMS automatically.
- You can delete old test sequences right from the picker, with a
  confirmation step so you don't delete something by accident.
- It opens automatically the first time you log in with it installed.
  After that, typing `/gems kiss` brings it back anytime.

**Annoying bugs that took longer than they should have:**

- The whole addon was silently failing to load. It was trying to listen
  for an event that doesn't actually exist in the game.
- Some sequence boxes and text were rendering outside the window instead
  of wrapping properly inside it.
- The sequence list used to only show 4 entries at a time. It scrolls
  properly now, so you can see all of them.
- The delete confirmation popup would show up, but it never closed
  itself afterward.

