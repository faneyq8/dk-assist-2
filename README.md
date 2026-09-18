# DK Assist 2

Configurable combat alerts and trackers for **Unholy, Frost, and Blood Death Knights** in **World of Warcraft Retail / Midnight**. Open the settings with **/dka**.

This community-maintained fork of **DK Assist** by ZachoWOW preserves the original MIT license and attribution.

## New in 2.1.0

- **Killing Machine and Rime text alerts:** optional, independent, movable text alerts with custom text, font, outline, size, and colour controls, similar to Sudden Doom.
- **Optional timers below the text:** enable **Show timer below text** separately for each Frost proc alert.
- **Choose your display:** use Frost text alerts alongside the existing icon or Cooldown Manager glow, or use text on its own.
- The new text alerts and their timers are **disabled by default**. Existing saved settings are preserved.

## Improvements and fixes in 2.1.0

- Reorganized Frost settings into **Warnings** and **Trackers**, following the Unholy layout, with each proc's icon and text settings grouped together.
- Fixed the Soul Reaper / Blightfall icon moving outside the horizontal timeline near the end of the countdown and hiding its ready glow.
- Enabling the Soul Reaper / Blightfall timeline or optional icon during an active countdown now shows that display immediately.
- The Soul Reaper / Blightfall **Test** now displays the ready glow for two seconds before advancing to the next step.
- Improved expiry cleanup so timeline and icon displays hide together and do not reappear when expired settings are refreshed.

## Frost features

- **Killing Machine and Rime:** independent icon toggles, movable icons or Cooldown Manager glows, optional text alerts, and optional countdowns below the text. Killing Machine supports consecutive proc stacks.
- **Pillar of Frost:** compact horizontal or vertical timeline and movable icon modes, following the aura duration and extensions from The Long Winter.
- **Breath of Sindragosa:** timeline and movable icon modes with an elapsed-time display.
- **Custom proc glows:** separate style, colour, presets, animation speed, opacity, and particle or thickness controls where supported.

## Unholy features

- **Festering Scythe:** action-bar or Cooldown Manager warnings, expiry timing, combat-start reminder, and an optional Lesser Ghoul reminder.
- **Festering Scythe WA-style text:** a movable alert with custom timing, font, outline, size, colour presets, live preview, coloured countdown, optional EXPIRED state, and optional LESSER GHOUL MISSING message.
- **Sudden Doom:** separate configurable Death Coil and Epidemic glows, with Necrotic Coil and Graveyard support where applicable, plus an independent movable text alert.
- **Putrefy hold warning:** a configurable red cross or glow that hides during Dark Transformation and its duration extensions.
- **Summon Gargoyle:** compact horizontal or vertical timeline and movable icon modes for its 25-second window.
- **Dark Transformation:** compact timeline and icon modes with duration extensions from Death Coil and Epidemic casts.
- **Blightfall & Soul Reaper:** horizontal or vertical timeline, optional movable icon, spell-name and size controls, voice countdown, and configurable ready glow. This reminder is for **Unholy San'layn**: Dark Transformation starts the Soul Reaper countdown; casting Soul Reaper starts the Blightfall countdown.

## Blood features

- **Blood Shield tracker:** a movable absorb display with a separate thin yellow duration bar. The duration follows the aura when available, with a 10-second fallback refreshed by a successful Death Strike. Includes display, icon, colour, size, position-lock, and reset controls.
- **Bone Shield reminder:** separate five-second and missing-buff alerts, selectable sounds with previews, an optional Ossuary low-stack warning, and Cooldown Manager detection.
- **Death and Decay / Cleaving:** active-window tracking and Cleaving status reminders with optional display and glow controls.

## Customization and access

- **Four glow styles:** Pixel Glow, Autocast Shine, Button Glow, and Proc Border, with appearance controls where supported.
- **Runic Power cap warning:** configurable threshold and compatible resource-bar glow targets.
- **Standalone settings:** grouped navigation, live previews, themed controls, and Esc-to-close support, alongside Blizzard's Settings > AddOns page.
- **Seven themes:** Classic, Carbon Cyan, Graphite Red, Obsidian Lime, Frosted Blue, Slate Orange, and Unholy Green.
- **Convenient access:** minimap button, addon compartment entry, HidingBar / DataBroker support, Rescan Bars, Test tools, and **/dka**.

## Installation and setup

1. Download the latest release ZIP.
2. Extract the **DKAssist** folder into `World of Warcraft/_retail_/Interface/AddOns/`.
3. Restart WoW or run **/reload**.
4. Open **/dka**. To use the new Frost text alerts, enable the corresponding **Text Alert** and optionally **Show timer below text**. Use Test and the position-lock controls to arrange your displays.

## Credits and license

Original project: [DK Assist (Death Knight QoL)](https://www.curseforge.com/wow/addons/dk-assist-death-knight-qol) by **ZachoWOW**. Special thanks to **Zachoe** for the original DKQoL / WA-style alert concept, testing, and feedback that helped shape the Festering Scythe and Sudden Doom text alerts.

Maintained by **FaneyQ8**. Distributed under the [MIT License](https://github.com/faneyq8/dk-assist-2/blob/main/LICENSE). Original copyright notices and license terms are preserved.
