import QtCore
import QtQuick
import org.kde.notification as Notifications
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "LocationData.js" as LocationData

PlasmoidItem {
    id: root

    readonly property string configuredUid: String(Plasmoid.configuration.locationUid)
    readonly property string effectiveUid: configuredUid === "custom"
        ? String(Plasmoid.configuration.customLocationUid).trim()
        : configuredUid
    readonly property var presetLocation: LocationData.locationByUid(configuredUid)
    readonly property var selectedLocation: configuredUid === "custom"
        ? {
            "uid": effectiveUid,
            "label": String(Plasmoid.configuration.customLocationName).trim() || i18n("Custom location")
        }
        : {
            "uid": presetLocation.uid,
            "label": i18n(presetLocation.label),
            "oblastUid": presetLocation.oblastUid
        }

    property string selectedStatus: "?"
    property var oblastStatuses: LocationData.regions.map(() => "?")
    property string allStatuses: ""
    property var activeAlerts: []
    property date lastUpdated
    property date sourceUpdatedAt
    property string errorMessage: ""
    property bool loading: false
    property int activeRequest: 0
    property int requestSerial: 0
    property int commandSerial: 0
    property int transientFailures: 0
    property var geometryFiles: ({})
    property bool fetchingGeometry: false
    property bool geometryPending: false
    property var commandCallbacks: ({})

    readonly property string backendBaseUrl: "https://plasmoid-ua-status.rossetnocpes.dev"
    readonly property string backendUrl: `${backendBaseUrl}/api/alerts`
    readonly property string geometryBaseUrl: `${backendBaseUrl}/api/geometry/`
    readonly property string geometryDirectory: decodeURIComponent(
        String(StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)).replace(/^file:\/\//, ""))
        + "/plasmoid-ua-status/geometry"
    readonly property string mapLabelBehavior: String(Plasmoid.configuration.mapLabelBehavior || "auto")
    readonly property bool hasData: allStatuses.length > 0
    readonly property bool canRefresh: effectiveUid.length > 0 && !loading
    readonly property string selectedOblastUid: oblastUidForLocation()
    readonly property int activeRegionCount: oblastStatuses.filter(isAlert).length
    readonly property string selectedLevel: isAlert(selectedStatus) ? locationLevel(effectiveUid) : ""
    readonly property color selectedColor: statusColor(selectedStatus, selectedLevel)

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 12
    activationTogglesExpanded: true
    toolTipMainText: selectedLocation.label
    toolTipSubText: statusText(selectedStatus, selectedLevel)
        + (errorMessage ? i18n(" · Data may be stale") : "")

    Plasmoid.status: isAlert(selectedStatus)
        ? PlasmaCore.Types.ActiveStatus
        : PlasmaCore.Types.PassiveStatus

    compactRepresentation: CompactRepresentation {
        controller: root
    }

    fullRepresentation: FullRepresentation {
        controller: root
    }

    function isAlert(status) {
        return status === "A" || status === "P";
    }

    function statusText(status, level) {
        const yellow = level === "yellow";
        switch (status) {
        case "A": return yellow ? i18n("Air raid alert, yellow level") : i18n("Air raid alert, red level");
        case "P": return yellow ? i18n("Partial alert, yellow level") : i18n("Partial alert, red level");
        case "N": return i18n("No active alert");
        default: return loading && !hasData ? i18n("Loading…") : i18n("No data");
        }
    }

    function levelColor(level) {
        return level === "yellow" ? "#ffc928" : "#e66f64";
    }

    function statusColor(status, level) {
        if (isAlert(status)) {
            return levelColor(level);
        }
        return status === "N" ? "#2f9a70" : Kirigami.Theme.disabledTextColor;
    }

    // Highest alert level in an oblast. Red is the default when the feed has no
    // details, so a location is never shown as yellow when red might apply.
    function oblastLevel(uid) {
        const alerts = activeAlerts.filter(alert => alert.oblastUid === String(uid));
        return alerts.length > 0 && alerts.every(alert => alert.alertLevel === "yellow") ? "yellow" : "red";
    }

    // Level of an alert declared for the whole oblast, or "" without one.
    function oblastWideLevel(uid) {
        const alert = activeAlerts.find(alert => alert.locationType === "oblast" && alert.oblastUid === String(uid));
        return alert ? alert.alertLevel : "";
    }

    function locationLevel(uid) {
        if (LocationData.regionIndex(uid) !== -1) {
            return oblastLevel(uid);
        }
        const own = activeAlerts.find(alert => alert.locationUid === String(uid));
        return own ? own.alertLevel : oblastLevel(selectedOblastUid);
    }

    function oblastUidForLocation() {
        if (LocationData.regionIndex(effectiveUid) !== -1) {
            return effectiveUid;
        }
        if (selectedLocation.oblastUid) {
            return String(selectedLocation.oblastUid);
        }
        const own = activeAlerts.find(alert => String(alert.locationUid) === effectiveUid);
        return own ? String(own.oblastUid || own.locationUid) : "";
    }

    function activeMapRegions() {
        const result = [];
        for (let i = 0; i < LocationData.regions.length; ++i) {
            const status = oblastStatuses[i] || "?";
            const uid = LocationData.regions[i].uid;
            if (status === "A" || (status !== "P" && uid === selectedOblastUid)) {
                result.push({
                    "region": LocationData.regions[i],
                    "status": status,
                    "level": oblastWideLevel(uid) || oblastLevel(uid)
                });
            }
        }
        return result;
    }

    // Titles of the districts, communities, and cities with an alert in an oblast.
    function affectedPlacesForOblast(uid) {
        const target = String(uid);
        const places = [];
        const seenGeometry = new Set();
        for (const alert of activeAlerts) {
            if (alert.oblastUid !== target || alert.locationType === "oblast") {
                continue;
            }
            // A city and its community share one shape; list the first only.
            if (alert.geometryUid) {
                if (seenGeometry.has(alert.geometryUid)) {
                    continue;
                }
                seenGeometry.add(alert.geometryUid);
            }
            if (alert.locationTitle && !places.includes(alert.locationTitle)) {
                places.push(alert.locationTitle);
            }
        }
        return places;
    }

    function geometryLayers() {
        const layers = [];
        const seenUrls = new Set();
        for (const alert of activeAlerts) {
            // A red oblast-wide alert already covers every area; a yellow one only hides yellow areas.
            const oblastWide = oblastWideLevel(alert.oblastUid);
            if (oblastWide === "red" || (oblastWide === "yellow" && alert.alertLevel === "yellow")) {
                continue;
            }
            const file = geometryFiles[alert.geometryUid];
            if (file && !seenUrls.has(file)) {
                seenUrls.add(file);
                layers.push({ "url": file, "alertLevel": alert.alertLevel });
            }
        }
        return layers;
    }

    function mapLabel(region) {
        if (region.mapLabel) {
            return i18n(region.mapLabel);
        }
        return i18n(region.label).replace(/ (Oblast|область)$/, "")
            .replace(/^(Autonomous Republic of |Автономна Республіка )/, "");
    }

    function affectedSummary(uid) {
        const places = affectedPlacesForOblast(uid);
        const shown = 3;
        return places.slice(0, shown).join(", ")
            + (places.length > shown ? i18n(" +%1 more", places.length - shown) : "");
    }

    function regionTooltip(uid, label, status) {
        const lines = [label, statusText(status, oblastLevel(uid))];
        const places = affectedSummary(uid);
        if (places) {
            lines.push(places);
        }
        return lines.join("\n");
    }

    function formattedUpdateTime() {
        const shownTime = sourceUpdatedAt || lastUpdated;
        if (!shownTime || isNaN(shownTime.getTime())) {
            return i18n("Not updated yet");
        }
        const today = shownTime.toDateString() === new Date().toDateString();
        return i18n("Updated %1", today
            ? shownTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
            : shownTime.toLocaleString(Qt.locale(), Locale.ShortFormat));
    }

    function selectLocation(uid) {
        Plasmoid.configuration.locationUid = String(uid);
    }

    function openConfiguration() {
        const action = Plasmoid.internalAction("configure");
        if (action) {
            action.trigger();
        }
    }

    function refreshAll() {
        if (canRefresh) {
            errorMessage = "";
            requestStatuses();
        }
    }

    // Retries back off from 5 seconds to a minute. The first failure stays silent
    // while older data is on screen, so a brief network blip is not reported.
    function requestFailed(message, transient) {
        if (transient) {
            ++transientFailures;
            retryTimer.interval = Math.min(60, 5 * Math.pow(2, transientFailures - 1)) * 1000;
            retryTimer.restart();
            if (transientFailures === 1 && hasData) {
                return;
            }
        }
        errorMessage = message;
    }

    function cancelRequest() {
        activeRequest = 0;
        requestTimeoutTimer.stop();
        loading = false;
    }

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    // Runs a shell command; the serial keeps identical commands from sharing one source.
    function runCommand(command, callback) {
        const source = command + " # " + (++commandSerial);
        commandCallbacks[source] = callback;
        executable.connectSource(source);
    }

    // Requests go through curl rather than XMLHttpRequest: Qt reuses one HTTP/2
    // connection per host, and after suspend that connection is dead but kept,
    // which stalls every request until the kernel gives up on it (~15 minutes).
    // curl opens a fresh connection each time.
    function requestStatuses() {
        loading = true;
        const command = "curl --silent --compressed --connect-timeout 8 --max-time 15"
            + " --write-out '\\n%{http_code}' " + shellQuote(backendUrl);
        const request = ++requestSerial;
        activeRequest = request;
        requestTimeoutTimer.restart();
        runCommand(command, (exitCode, output) => {
            if (activeRequest !== request) {
                return;
            }
            cancelRequest();
            if (exitCode === 127) {
                errorMessage = i18n("The curl command is required to fetch alerts");
                return;
            }
            const split = output.lastIndexOf("\n");
            const status = exitCode === 0 ? Number(output.slice(split + 1)) : 0;
            if (status !== 200) {
                requestFailed(requestError(status), [0, 502, 503, 504].includes(status));
                return;
            }
            try {
                applyPayload(JSON.parse(output.slice(0, split)));
            } catch (error) {
                errorMessage = i18n("The backend response could not be read");
            }
        });
    }

    function applyPayload(payload) {
        const statuses = payload.statuses;
        if (typeof statuses !== "string") {
            throw new Error("Invalid status response");
        }
        const nextOblastStatuses = LocationData.regions.map(region => statusForUid(statuses, region.uid));
        if (nextOblastStatuses.includes("?")) {
            throw new Error("Missing oblast status");
        }

        allStatuses = statuses;
        activeAlerts = Array.isArray(payload.alerts) ? payload.alerts : [];
        oblastStatuses = nextOblastStatuses;
        updateLocationFromCache();
        lastUpdated = new Date();
        sourceUpdatedAt = payload.sourceUpdatedAt ? new Date(payload.sourceUpdatedAt) : lastUpdated;
        transientFailures = 0;
        retryTimer.stop();
        errorMessage = "";
        fetchGeometry();
    }

    // Downloads missing area shapes into the cache, one batch at a time. Shapes never
    // change for a given UID, so each one is downloaded once.
    function fetchGeometry() {
        const missing = [...new Set(activeAlerts.map(alert => String(alert.geometryUid || "")))]
            .filter(uid => /^\d+$/.test(uid) && !geometryFiles[uid]);
        if (missing.length === 0) {
            return;
        }
        // Shapes that appear during a download are fetched right after it.
        if (fetchingGeometry) {
            geometryPending = true;
            return;
        }
        fetchingGeometry = true;
        const command = "mkdir -p " + shellQuote(geometryDirectory) + " && cd " + shellQuote(geometryDirectory)
            + " && for uid in " + missing.join(" ") + "; do"
            + " test -s $uid-v2.svg || { curl --silent --fail --connect-timeout 8 --max-time 20"
            + " --output $uid-v2.svg.part " + shellQuote(geometryBaseUrl) + "\"$uid\"'?v=2'"
            + " && mv $uid-v2.svg.part $uid-v2.svg; }; test -s $uid-v2.svg && echo $uid; done";
        runCommand(command, (exitCode, output) => {
            fetchingGeometry = false;
            const files = Object.assign({}, geometryFiles);
            for (const uid of output.split("\n").filter(line => /^\d+$/.test(line))) {
                files[uid] = "file://" + encodeURI(geometryDirectory + "/" + uid + "-v2.svg");
            }
            geometryFiles = files;
            if (geometryPending) {
                geometryPending = false;
                fetchGeometry();
            }
        });
    }

    function statusForUid(statuses, uid) {
        const uidText = String(uid);
        if (!/^\d+$/.test(uidText)) {
            return "?";
        }
        const status = statuses.charAt(Number(uidText));
        return /^[APN]$/.test(status) ? status : "?";
    }

    function updateLocationFromCache() {
        const status = statusForUid(allStatuses, effectiveUid);
        selectedStatus = status;
        if (status !== "?") {
            updateSelectedStatus(status);
        }
    }

    function requestError(status) {
        switch (status) {
        case 0: return i18n("Could not reach the alert backend");
        case 401: return i18n("The backend could not authenticate with alerts.in.ua");
        case 403: return i18n("Access to the alert backend was denied");
        case 429: return i18n("The alerts.in.ua rate limit was reached; wait before refreshing");
        case 500: return i18n("The alert backend is not configured");
        case 502: return i18n("The backend could not retrieve alert data");
        default: return i18n("The alert backend returned HTTP %1", status);
        }
    }

    function updateSelectedStatus(status) {
        const level = isAlert(status) ? locationLevel(effectiveUid) : "";
        const previousStatus = String(Plasmoid.configuration.lastStatus);
        const previousLevel = String(Plasmoid.configuration.lastAlertLevel);
        const changedLocation = String(Plasmoid.configuration.lastLocationUid) !== effectiveUid;
        const wasAlert = isAlert(previousStatus) && !changedLocation;

        if (Plasmoid.configuration.notificationsEnabled) {
            if (isAlert(status) && !wasAlert) {
                sendAlertNotification(status, level, "");
            } else if (isAlert(status) && level !== previousLevel && previousLevel) {
                sendAlertNotification(status, level, level === "red"
                    ? i18n("The alert level was raised to red.")
                    : i18n("The alert level was lowered to yellow."));
            } else if (status === "N" && wasAlert && Plasmoid.configuration.notifyClear) {
                sendClearNotification();
            }
        }

        Plasmoid.configuration.lastLocationUid = effectiveUid;
        Plasmoid.configuration.lastStatus = status;
        Plasmoid.configuration.lastAlertLevel = level;
    }

    function sendAlertNotification(status, level, change) {
        const places = status === "P" ? affectedSummary(selectedOblastUid) : "";
        const guidance = places
            ? i18n("Active in: %1. Go to shelter and follow official guidance.", places)
            : i18n("Go to shelter and follow official guidance.");
        // Lowering the level is not urgent; everything else interrupts with a sound.
        const urgent = level === "red" || !change;
        notification.close();
        notification.title = level === "yellow"
            ? i18n("Yellow-level air raid alert — %1", selectedLocation.label)
            : i18n("Red-level air raid alert — %1", selectedLocation.label);
        notification.text = change ? change + " " + guidance : guidance;
        notification.iconName = "data-warning";
        notification.urgency = urgent
            ? Notifications.Notification.CriticalUrgency
            : Notifications.Notification.NormalUrgency;
        // "catastrophe" is Plasma's notification event that plays a sound.
        notification.eventId = urgent && Plasmoid.configuration.alertSound ? "catastrophe" : "notification";
        notification.flags = Notifications.Notification.Persistent | Notifications.Notification.SkipGrouping;
        notification.sendEvent();
    }

    function sendClearNotification() {
        notification.close();
        notification.title = i18n("All clear — %1", selectedLocation.label);
        notification.text = i18n("The air raid alert has ended.");
        notification.iconName = "security-high";
        notification.urgency = Notifications.Notification.NormalUrgency;
        notification.eventId = "notification";
        notification.flags = Notifications.Notification.CloseOnTimeout;
        notification.sendEvent();
    }

    Notifications.Notification {
        id: notification

        componentName: "plasma_workspace"
        eventId: "notification"
        autoDelete: false
    }

    Timer {
        id: requestTimeoutTimer

        // Backstop in case curl itself never reports back; curl gives up after 15 seconds.
        interval: 20000
        onTriggered: {
            root.cancelRequest();
            root.requestFailed(i18n("The alert backend did not respond in time"), true);
        }
    }

    Timer {
        id: retryTimer

        onTriggered: root.refreshAll()
    }

    // Timers stop counting during suspend, but the wall clock does not: a jump means
    // the system just woke up, so drop any stale request and refresh right away.
    Timer {
        property double lastTick: Date.now()

        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            const now = Date.now();
            if (now - lastTick > 30000) {
                root.cancelRequest();
                root.transientFailures = 0;
                root.refreshAll();
            }
            lastTick = now;
        }
    }

    P5Support.DataSource {
        id: executable

        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            const callback = root.commandCallbacks[source];
            delete root.commandCallbacks[source];
            if (callback) {
                callback(data["exit code"], String(data["stdout"] || ""));
            }
        }
    }

    Timer {
        interval: Math.max(15, Number(Plasmoid.configuration.refreshInterval)) * 1000
        repeat: true
        running: root.effectiveUid.length > 0
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    Connections {
        target: Plasmoid.configuration

        function onLocationUidChanged() {
            root.updateLocationFromCache();
        }

        function onCustomLocationUidChanged() {
            if (root.configuredUid === "custom") {
                root.updateLocationFromCache();
            }
        }
    }
}
