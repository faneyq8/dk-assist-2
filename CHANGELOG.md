# DK Assist 2.0.0

## New

- Redesigned the standalone `/dka` interface with a cleaner sidebar and reorganized warning, tracker, and Sudden Doom sections.
- Added a Gargoyle tracker with timeline and icon modes, Runic Power spent, damage increase, best-result tracking, font sizing, and horizontal or vertical orientation.
- Added a Dark Transformation tracker with timeline and icon modes that follow the real aura duration, including Death Coil and Epidemic extensions.
- Added horizontal and vertical orientation to the Blightfall & Soul Reaper timeline.
- Added configurable font size and optional spell names to timeline displays.

## Improved

- Reworked the Blightfall & Soul Reaper page into a compact two-column layout.
- Added customizable icon-only glow styles, colors, animation speed, and opacity to the Blightfall tracker.
- Improved live previews, spacing, descriptions, card sizing, and control alignment throughout the standalone interface.
- Renamed Death and Decay status text to `Cleaving Active` and `Cleaving Missing` so it accurately describes the tracked buff state.
- Added a short grace delay to the missing-cleaving warning to prevent flicker.
- Added clearer Putrefy guidance and dynamically sized warning appearance controls.
- Updated the addon subtitle to include both Unholy and Blood combat tools.

## Fixed

- Fixed tracker settings migration errors for existing SavedVariables.
- Fixed overlapping controls and numeric fields in several standalone pages.
- Fixed timeline glow being applied to the whole bar instead of the active spell icon.
- Fixed Gargoyle artwork to use the in-game Summon Gargoyle icon.
- Fixed timers overlapping movable tracker icons.
- Restricted Blightfall & Soul Reaper tracking to the San'layn hero specialization.
