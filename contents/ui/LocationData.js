.pragma library

// Ordered by Ukrainian name, which is also the order of the location presets.
// x/y are normalized label positions on the bundled map.
var regions = [
    { uid: "29", label: "Autonomous Republic of Crimea", asset: "crimea", x: 0.680, y: 0.813 },
    { uid: "4", label: "Vinnytsia Oblast", asset: "vinnytsia", x: 0.390, y: 0.425 },
    { uid: "8", label: "Volyn Oblast", asset: "volyn", x: 0.190, y: 0.205 },
    { uid: "9", label: "Dnipropetrovsk Oblast", asset: "dnipropetrovsk", x: 0.699, y: 0.455 },
    { uid: "28", label: "Donetsk Oblast", asset: "donetsk", x: 0.838, y: 0.536 },
    { uid: "10", label: "Zhytomyr Oblast", asset: "zhytomyr", x: 0.365, y: 0.275 },
    { uid: "11", label: "Zakarpattia Oblast", asset: "zakarpattia", x: 0.085, y: 0.505 },
    { uid: "12", label: "Zaporizhzhia Oblast", asset: "zaporizhzhia", x: 0.706, y: 0.555 },
    { uid: "13", label: "Ivano-Frankivsk Oblast", mapLabel: "Ivano-\nFrankivsk", asset: "ivano_frankivsk", x: 0.165, y: 0.435 },
    { uid: "31", label: "Kyiv", mapLabel: "Kyiv", asset: "kyiv_city", x: 0.480, y: 0.245 },
    { uid: "14", label: "Kyiv Oblast", mapLabel: "Kyiv\noblast", asset: "kyiv", x: 0.440, y: 0.325 },
    { uid: "15", label: "Kirovohrad Oblast", asset: "kirovohrad", x: 0.548, y: 0.527 },
    { uid: "16", label: "Luhansk Oblast", asset: "luhansk", x: 0.899, y: 0.467 },
    { uid: "27", label: "Lviv Oblast", asset: "lviv", x: 0.137, y: 0.323 },
    { uid: "17", label: "Mykolaiv Oblast", asset: "mykolaiv", x: 0.520, y: 0.635 },
    { uid: "18", label: "Odesa Oblast", asset: "odesa", x: 0.455, y: 0.720 },
    { uid: "19", label: "Poltava Oblast", asset: "poltava", x: 0.665, y: 0.352 },
    { uid: "5", label: "Rivne Oblast", asset: "rivne", x: 0.265, y: 0.230 },
    { uid: "30", label: "Sevastopol", asset: "sevastopol", x: 0.565, y: 0.858 },
    { uid: "20", label: "Sumy Oblast", asset: "sumy", x: 0.685, y: 0.202 },
    { uid: "21", label: "Ternopil Oblast", asset: "ternopil", x: 0.205, y: 0.350 },
    { uid: "22", label: "Kharkiv Oblast", asset: "kharkiv", x: 0.760, y: 0.307 },
    { uid: "23", label: "Kherson Oblast", asset: "kherson", x: 0.595, y: 0.700 },
    { uid: "3", label: "Khmelnytskyi Oblast", asset: "khmelnytskyi", x: 0.310, y: 0.390 },
    { uid: "24", label: "Cherkasy Oblast", asset: "cherkasy", x: 0.546, y: 0.370 },
    { uid: "26", label: "Chernivtsi Oblast", asset: "chernivtsi", x: 0.250, y: 0.520 },
    { uid: "25", label: "Chernihiv Oblast", asset: "chernihiv", x: 0.505, y: 0.145 }
];

// Kyiv first, then the other oblasts, then the main cities.
var locations = [regions[regionIndex("31")]].concat(regions.filter(function(region) { return region.uid !== "31"; }), [
    { uid: "155", label: "Vinnytsia", oblastUid: "4" },
    { uid: "711", label: "Bila Tserkva", oblastUid: "14" },
    { uid: "733", label: "Boryspil", oblastUid: "14" },
    { uid: "332", label: "Dnipro", oblastUid: "9" },
    { uid: "632", label: "Ivano-Frankivsk", oblastUid: "13" },
    { uid: "706", label: "Irpin", oblastUid: "14" },
    { uid: "442", label: "Zhytomyr", oblastUid: "10" },
    { uid: "564", label: "Zaporizhzhia", oblastUid: "12" },
    { uid: "761", label: "Kropyvnytskyi", oblastUid: "15" },
    { uid: "375", label: "Kramatorsk", oblastUid: "28" },
    { uid: "279", label: "Kryvyi Rih", oblastUid: "9" },
    { uid: "1901", label: "Luhansk", oblastUid: "16" },
    { uid: "845", label: "Lviv", oblastUid: "27" },
    { uid: "400", label: "Mariupol", oblastUid: "28" },
    { uid: "926", label: "Mykolaiv", oblastUid: "17" },
    { uid: "964", label: "Odesa", oblastUid: "18" },
    { uid: "1060", label: "Poltava", oblastUid: "19" },
    { uid: "1133", label: "Rivne", oblastUid: "5" },
    { uid: "1187", label: "Sumy", oblastUid: "20" },
    { uid: "1241", label: "Ternopil", oblastUid: "21" },
    { uid: "500", label: "Uzhhorod", oblastUid: "11" },
    { uid: "1293", label: "Kharkiv", oblastUid: "22" },
    { uid: "1370", label: "Kherson", oblastUid: "23" },
    { uid: "1400", label: "Khmelnytskyi", oblastUid: "3" },
    { uid: "1473", label: "Cherkasy", oblastUid: "24" },
    { uid: "1542", label: "Chernivtsi", oblastUid: "26" },
    { uid: "1591", label: "Chernihiv", oblastUid: "25" },
    { uid: "custom", label: "Custom location…" }
]);

function regionIndex(uid) {
    var target = String(uid);
    return regions.findIndex(function(region) { return region.uid === target; });
}

function locationIndex(uid) {
    var target = String(uid);
    return Math.max(0, locations.findIndex(function(location) { return location.uid === target; }));
}

function locationByUid(uid) {
    return locations[locationIndex(uid)];
}
