const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://aquaguard-b0b2c-default-rtdb.asia-southeast1.firebasedatabase.app/",
});

const db = admin.firestore();
const rtdb = admin.database();

// ─── Thresholds ───────────────────────────────────────────────────────────────

const THRESHOLDS = {
  Turbidity:   { max: 50,   unit: "NTU", label: "Turbidity" },
  "Tds value": { max: 1000, unit: "ppm", label: "TDS" },
  pHValue:     { min: 6.5, max: 8.5, unit: "pH", label: "pH" },
  Temperature: { max: 35,  unit: "°C",  label: "Temperature" },
  gasValue:    { max: 400, unit: "ppm", label: "Gas" },
  ultrasonic:  { min: 10,  unit: "cm",  label: "Water Level" },
};

/**
 * Tracks which sensors are currently in a breaching state.
 * Alerts are only sent when a sensor transitions safe → unsafe,
 * preventing the same alert from being spammed on every DB update.
 */
const alertedSensors = {};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function parseNumber(value) {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const n = parseFloat(value);
    return isNaN(n) ? null : n;
  }
  return null;
}

function isBreaching(value, cfg) {
  if (cfg.max !== undefined && value > cfg.max) return true;
  if (cfg.min !== undefined && value < cfg.min) return true;
  return false;
}

function buildAlertMessage(field, value, cfg) {
  switch (field) {
    case "Turbidity":
      return `⚠️ High turbidity: ${value} ${cfg.unit} (limit: ${cfg.max}). Water may be unsafe.`;
    case "Tds value":
      return `⚠️ High TDS: ${value} ${cfg.unit} (limit: ${cfg.max}). Excess dissolved solids detected.`;
    case "pHValue":
      return `⚠️ pH out of range: ${value} (safe: ${cfg.min}–${cfg.max}). Water acidity is abnormal.`;
    case "Temperature":
      return `⚠️ High water temperature: ${value}${cfg.unit} (limit: ${cfg.max}). Bacterial growth risk.`;
    case "gasValue":
      return `⚠️ Elevated gas levels: ${value} ${cfg.unit} (limit: ${cfg.max}). Possible contamination nearby.`;
    case "ultrasonic":
      return `⚠️ Water level critically low: ${value} ${cfg.unit} (minimum: ${cfg.min}). HydroBot may be unable to operate.`;
    default:
      return `⚠️ ${cfg.label} out of safe range: ${value} ${cfg.unit}.`;
  }
}

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Evaluates all sensor readings against thresholds.
 * Returns only sensors that have NEWLY crossed into unsafe territory
 * since the last check (deduplication).
 */
function evaluateThresholds(data) {
  const newBreaches = [];

  for (const [field, cfg] of Object.entries(THRESHOLDS)) {
    const raw = data[field];
    if (raw === undefined || raw === null) continue;

    const value = parseNumber(raw);
    if (value === null) continue;

    // DS18B20 sensor returns -127 when physically disconnected — skip
    if (field === "Temperature" && value === -127) continue;

    const breaching = isBreaching(value, cfg);

    if (breaching && !alertedSensors[field]) {
      // Transition: safe → unsafe — send alert
      alertedSensors[field] = true;
      newBreaches.push({ field, value, message: buildAlertMessage(field, value, cfg) });
      console.log(`🔴 NEW breach — ${cfg.label}: ${value} ${cfg.unit}`);
    } else if (!breaching && alertedSensors[field]) {
      // Transition: unsafe → safe — clear flag, no alert needed
      alertedSensors[field] = false;
      console.log(`🟢 Cleared — ${cfg.label}: ${value} ${cfg.unit} (back in safe range)`);
    } else if (breaching) {
      console.log(`🟡 Still breaching — ${cfg.label}: ${value} ${cfg.unit} (alert already sent)`);
    }
  }

  return newBreaches;
}

async function checkSensorData(snapshot) {
  try {
    if (!snapshot.exists()) {
      console.log("No sensor data found.");
      return;
    }

    const data = snapshot.val();
    console.log("Current values →", JSON.stringify(data));

    const newBreaches = evaluateThresholds(data);

    if (newBreaches.length === 0) {
      console.log("✅ All sensors within safe range.");
      return;
    }

    // Build one combined alert covering all newly breaching sensors
    const alert = {
      alert: newBreaches.map((b) => b.message).join("\n"),
      date: admin.firestore.Timestamp.fromDate(new Date()),
      from: "hydrobot",
      sensors: newBreaches.map((b) => ({ field: b.field, value: b.value })),
    };

    const usersSnapshot = await db
      .collection("users")
      .where("role", "==", "asha_worker")
      .get();

    if (usersSnapshot.empty) {
      console.log("No asha_worker users found.");
      return;
    }

    const batch = db.batch();
    usersSnapshot.forEach((doc) => {
      batch.update(db.collection("users").doc(doc.id), {
        alerts: admin.firestore.FieldValue.arrayUnion(alert),
      });
    });

    await batch.commit();
    console.log(`✅ Alert sent to ${usersSnapshot.size} ASHA worker(s)!`);

  } catch (error) {
    console.error("❌ Error checking sensor data:", error);
  }
}

// ─── Reconnection ─────────────────────────────────────────────────────────────

let reconnectDelay = 1000; // ms, doubles on each failure up to 30s

function attachListener() {
  // Remove any existing listener before attaching a new one,
  // otherwise reconnects stack up multiple listeners on the same ref.
  rtdb.ref("/sensor").off();

  rtdb.ref("/sensor").on(
    "value",
    async (snapshot) => {
      reconnectDelay = 1000; // reset backoff on successful event
      console.log("📡 Sensor data changed — checking thresholds...");
      await checkSensorData(snapshot);
    },
    (error) => {
      console.error("❌ Listener error:", error.message);
      scheduleReconnect();
    }
  );
}

function scheduleReconnect() {
  // Double the delay BEFORE scheduling so each retry waits longer
  reconnectDelay = Math.min(reconnectDelay * 2, 30000);
  console.log(`🔄 Reconnecting in ${reconnectDelay / 1000}s...`);
  setTimeout(() => {
    attachListener();
  }, reconnectDelay);
}

// Detect Firebase going offline
rtdb.ref(".info/connected").on("value", (snap) => {
  if (snap.val() === false) {
    console.warn("⚠️  Lost connection to Firebase. Waiting for reconnect...");
  } else {
    console.log("✅ Connected to Firebase.");
  }
});

// ─── Graceful shutdown ────────────────────────────────────────────────────────

function shutdown() {
  console.log("\n🛑 Shutting down watcher...");
  rtdb.ref("/sensor").off();
  admin.app().delete().then(() => {
    console.log("✅ Firebase connection closed.");
    process.exit(0);
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

// ─── Start ────────────────────────────────────────────────────────────────────

attachListener();
console.log("🚀 Sensor watcher started. Listening for database changes...");