# Air Raid Alert Map for Plasma 6

A KDE Plasma 6 widget that shows the current air raid alert map of Ukraine and
notifies you when the status changes for a chosen oblast, city, community, or
district.

The live status comes from [alerts.in.ua](https://alerts.in.ua/).

## Install

Requires `curl`, which the widget uses for network requests: Qt keeps a single
HTTP/2 connection per host that goes stale after suspend, while curl starts a
fresh connection for every request. Area shapes are cached in
`~/.cache/plasmoid-ua-status`.

```bash
kpackagetool6 --type Plasma/Applet --install .
```

If the widget is already installed:

```bash
kpackagetool6 --type Plasma/Applet --upgrade .
```

Then add **Air Raid Alert Map** from Plasma's widget picker and choose a
location in its settings. The included presets cover all oblasts and the main
cities; any location supported by alerts.in.ua can be selected with its numeric UID.

## Behaviour

- Refreshes every 60 seconds by default (15 seconds to 5 minutes in settings),
  retries failed requests with backoff, and refreshes right after the system wakes up.
- Shows air-raid alerts only, using the alerts.in.ua map geometry with 139 district
  boundaries, in Plasma's light or dark color scheme.
- Distinguishes red-level and yellow-level air raid alerts on the map, in the
  status, and in notifications, and notifies when the level is raised or lowered.
- Colors the exact raions and communities for partial alerts.
- Labels the regions in alert and your location; click a region to see where
  alerts are active or to make it your location.
- Sends a critical desktop notification when an alert starts or becomes partial,
  and optionally an all-clear when it ends.
- Remembers the last status so restarting Plasma does not repeat unchanged alerts.
- Includes Ukrainian translations.

The backend returns `{ statuses, alerts, sourceUpdatedAt }`: `statuses` is the
official UID-indexed air-raid status string, and `alerts` lists the areas under
alert with the geometry needed to draw them.

To rebuild the bundled Ukrainian translation after editing `po/uk.po`, run
`msgfmt -o contents/locale/uk/LC_MESSAGES/plasma_applet_plasmoid-ua-status.mo po/uk.po`.

## Safety and sources

API data may be delayed or temporarily unavailable. Do not use this widget as
your only warning source, and always follow official civil-defence guidance.

The oblast status order and location UIDs follow the
[official API documentation](https://devs.alerts.in.ua/). The base map and
region masks are generated from these alerts.in.ua CDN assets:

- [`simplified.svg`](https://cdn.alerts.in.ua/assets/maps/simplified.svg?v=4)
- [`districts.svg`](https://cdn.alerts.in.ua/assets/regions/v2/districts.svg?v=12)
- [`ua-border.svg`](https://cdn.alerts.in.ua/assets/maps/ua-border.svg)
- numbered region fragments such as [`351.svg`](https://cdn.alerts.in.ua/assets/regions/351.svg?v=3)

