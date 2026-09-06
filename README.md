# DK Assist 2

A configurable quality-of-life addon for Unholy, Frost, and Blood Death Knights in World of Warcraft Retail / Midnight.

This is a community-maintained fork of **DK Assist** by ZachoWOW. It retains the original MIT license and attribution while adding 12.1 compatibility fixes and quality-of-life improvements.

## Features

- **Blood Shield tracker** — a movable secret-safe absorb display for Blood Death Knights. The main bar visualizes current absorb strength, while a thin yellow bar tracks the real aura duration when available and falls back to a 10-second timer refreshed by each successful Death Strike.
- **Redesigned standalone interface** — a cleaner sidebar groups warnings, trackers, and Sudden Doom buttons while keeping Blizzard's Settings → AddOns page unchanged.
- **Compact Gargoyle tracker** — horizontal or vertical timeline and movable icon modes for the 25-second Summon Gargoyle window. The timeline uses a compact icon-and-timer layout.
- **Compact Dark Transformation tracker** — horizontal or vertical timeline and movable icon modes, starting at 15 seconds and adding one second for every Death Coil or Epidemic cast while active.
- **Pillar of Frost tracker** — compact horizontal or vertical icon-and-timer display that follows the real Pillar of Frost aura, including duration extensions from The Long Winter.
- **Killing Machine alert** — uses the official in-game icon, supports multi-stack proc refreshes, includes an Enable Icon option, and can glow either on a movable DK Assist icon or the Cooldown Manager.
- **Rime alert** — movable icon or Cooldown Manager glow with an Enable Icon option that appears while Rime is active.
- **Breath of Sindragosa tracker** — compact timeline and movable icon modes with a live elapsed timer.
- **Bone Shield reminder** — separate five-second and missing-buff alerts, selectable sounds, optional Ossuary low-stack warning, and live Cooldown Manager detection.
- **Custom Frost proc glows** — independently configure Killing Machine and Rime glow style, colour, presets, animation speed, opacity, particles, and thickness.
- **Blightfall & Soul Reaper timeline** — timeline and icon modes, optional spell names, font and icon sizing, voice countdown, configurable glow effects, and horizontal or vertical orientation.
- **Festering Scythe warning** — configurable action-bar or Cooldown Manager glow when Festering Strike changes to Festering Scythe; includes expiry timing, combat-start reminder, and optional Lesser Ghoul reminder.
- **Festering Scythe WA-Style alert** — a separate movable text alert with its own timing, font, outline, size, colour presets, live preview, green/yellow/red countdown, an optional EXPIRED state, and an optional Lesser Ghoul missing message.
- **Sudden Doom glows** — separate, configurable alerts for Death Coil and Epidemic when Sudden Doom procs. Necrotic Coil and Graveyard are also supported where applicable.
- **Sudden Doom WA-Style alert** — a separate movable and fully configurable text alert for Sudden Doom procs.
- **Putrefy hold warning** — configurable red cross or glow that tells you to hold Putrefy while Dark Transformation is unavailable. The warning hides during Dark Transformation and its Death Coil / Epidemic duration extensions.
- **Runic Power cap warning** — glow your Runic Power bar at a configurable threshold to prevent overcapping; supports Blizzard and compatible UI bars.
- **Death and Decay tracker** — tracks the active Death and Decay window with optional movable display controls.
- **Soul Reaper control** — choose Blizzard's normal execute glow or suppress it entirely.
- **Four glow styles** — Pixel Glow, Autocast Shine, Button Glow, and Proc Border, with independent colours, presets, animation settings, thickness/particles, and opacity where relevant.
- **Action Bar or Cooldown Manager** — choose the target for Festering Scythe, Sudden Doom, Putrefy, Killing Machine, and Rime warnings; includes Rescan Bars and Test tools.
- **Selectable standalone themes** — Classic plus Carbon Cyan, Graphite Red, Obsidian Lime, Frosted Blue, Slate Orange, and Unholy Green. Themes restyle the standalone window without changing Blizzard's AddOns settings page.
- **Modern settings controls** — themed dropdowns, sliders, value fields, and buttons in the standalone window, with live previews and Esc-to-close support.
- **Convenient access** — minimap button, addon compartment entry, HidingBar / DataBroker support, and the `/dka` command.

## Installation

1. Download the latest release ZIP.
2. Extract the `DKAssist` folder into `World of Warcraft/_retail_/Interface/AddOns/`.
3. Restart World of Warcraft or run `/reload`.

Open settings with `/dka`, or left-click the minimap icon.

## Credits and license

Original project: [DK Assist (Death Knight QoL)](https://www.curseforge.com/wow/addons/dk-assist-death-knight-qol) by ZachoWOW.

Special thanks to **Zachoe** for the original DKQoL / WA-Style alert concept, testing, and detailed feedback that helped shape the Festering Scythe and Sudden Doom text alerts in version 1.6.3.

Maintained by **FaneyQ8**.

This fork is distributed under the [MIT License](LICENSE). Original copyright notices and license terms are preserved.
