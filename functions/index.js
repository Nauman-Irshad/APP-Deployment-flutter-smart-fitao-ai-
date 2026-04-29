const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function isStrongPassword(pw) {
  if (!pw || typeof pw !== "string") return false;
  if (pw.length < 8) return false;
  if (!/[A-Z]/.test(pw)) return false;
  if (!/[a-z]/.test(pw)) return false;
  if (!/\d/.test(pw)) return false;
  if (/\s/.test(pw)) return false;
  if (!/[^A-Za-z0-9]/.test(pw)) return false;
  return true;
}

async function resetPasswordCore({ email, otp, newPassword }) {
  if (!email || !email.includes("@")) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid email");
  }
  if (!/^\d{6}$/.test(otp)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid OTP");
  }
  if (!isStrongPassword(newPassword)) {
    throw new functions.https.HttpsError("invalid-argument", "Weak password");
  }

  const otpSnap = await admin
    .firestore()
    .collection("login_app_otp_codes")
    .where("email", "==", email)
    .where("code", "==", otp)
    .orderBy("createdAt", "desc")
    .limit(1)
    .get()
    .catch(async () => {
      return admin
        .firestore()
        .collection("login_app_otp_codes")
        .where("email", "==", email)
        .where("code", "==", otp)
        .orderBy("createdAtClient", "desc")
        .limit(1)
        .get();
    });

  if (otpSnap.empty) {
    throw new functions.https.HttpsError("permission-denied", "OTP not verified");
  }

  const doc = otpSnap.docs[0];
  const expiresAt = doc.get("expiresAt");
  if (expiresAt && expiresAt.toDate) {
    if (Date.now() > expiresAt.toDate().getTime()) {
      throw new functions.https.HttpsError("deadline-exceeded", "OTP expired");
    }
  }

  const userRecord = await admin.auth().getUserByEmail(email);
  await admin.auth().updateUser(userRecord.uid, { password: newPassword });

  await doc.ref.set(
    { usedAt: admin.firestore.FieldValue.serverTimestamp(), used: true },
    { merge: true }
  );

  return { ok: true };
}

exports.resetPasswordWithOtp = functions.https.onCall(async (data) => {
  const email = (data?.email || "").toString().trim();
  const otp = (data?.otp || "").toString().trim();
  const newPassword = (data?.newPassword || "").toString();
  return resetPasswordCore({ email, otp, newPassword });
});

// Web-safe HTTP endpoint (avoids dart2js Int64 issues in cloud_functions on web)
exports.resetPasswordWithOtpHttp = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "content-type");
  res.set("Access-Control-Allow-Methods", "POST,OPTIONS");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({ error: "method-not-allowed" });
    return;
  }

  try {
    const body = req.body || {};
    const email = (body.email || "").toString().trim();
    const otp = (body.otp || "").toString().trim();
    const newPassword = (body.newPassword || "").toString();
    const out = await resetPasswordCore({ email, otp, newPassword });
    res.json(out);
  } catch (e) {
    const code = e?.code || "internal";
    const message = e?.message || "Something went wrong";
    res.status(400).json({ error: code, message });
  }
});

  if (!email || !email.includes("@")) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid email");
  }
  if (!/^\d{6}$/.test(otp)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid OTP");
  }
  if (!isStrongPassword(newPassword)) {
    throw new functions.https.HttpsError("invalid-argument", "Weak password");
  }

