
const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://aquaguard-b0b2c-default-rtdb.asia-southeast1.firebasedatabase.app/",
});

const db = admin.firestore();
const rtdb = admin.database();

const TURBIDITY_THRESHOLD = 50;
const TDS_THRESHOLD = 1000;

async function checkSensorData() {
  try {
    const sensorRef = rtdb.ref("/sensor");
    const snapshot = await sensorRef.once("value");

    if (!snapshot.exists()) {
      console.log("No sensor data found.");
      return;
    }

    const data = snapshot.val();
    const turbidity = data.Turbidity;
    const tds = data["Tds value"];

    console.log(`Current values → Turbidity: ${turbidity}, TDS: ${tds}`);

    if (turbidity > TURBIDITY_THRESHOLD || tds > TDS_THRESHOLD) {
      const alert = {
        alert: `Turbidity (${turbidity}) and TDS (${tds}).\n This Village lake has been polluted!!!`,
        date: new Date(),
        from: "hydrobot"
      };

      const usersSnapshot = await db.collection("users")
        .where("role", "==", "asha_worker")
        .get();

      if (usersSnapshot.empty) {
        console.log("No asha_worker users found.");
        return;
      }

      const batch = db.batch();
      usersSnapshot.forEach((doc) => {
        const userRef = db.collection("users").doc(doc.id);
        batch.update(userRef, {
          alerts: admin.firestore.FieldValue.arrayUnion(alert)
        });
      });

      await batch.commit();
      console.log("✅ Alert added to all asha_worker users!");
    } else {
      console.log("Values are within safe range.");
    }
  } catch (error) {
    console.error("❌ Error checking sensor data:", error);
  }
}

rtdb.ref("/sensor").on("value", async () => {
  console.log("📡 Sensor data changed — checking thresholds...");
  await checkSensorData();
});

console.log("🚀 Sensor watcher started. Listening for database changes...");