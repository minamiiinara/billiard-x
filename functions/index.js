const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

// Fungsi untuk memverifikasi autentikasi notifikasi
function verifyNotification(notificationBody) {
  const serverKey = "YOUR_SERVER_KEY";
  const orderId = notificationBody.order_id;
  const statusCode = notificationBody.status_code;
  const grossAmount = notificationBody.gross_amount;

  const payload = `${orderId}${statusCode}${grossAmount}${serverKey}`;
  const hash = crypto.createHash("sha512").update(payload).digest("hex");

  return hash === notificationBody.signature_key;
}

// Fungsi untuk menangani notifikasi dari Midtrans
exports.handleMidtransNotification = functions.https.onRequest((req, res) => {
  const notification = req.body;

  if (!verifyNotification(notification)) {
    return res.status(400).send("Invalid notification");
  }

  const transactionStatus = notification.transaction_status;
  const orderId = notification.order_id;

  // Update status transaksi di Firestore
  const transactionRef = admin.firestore().collection("transactions").doc(orderId);
  transactionRef.set({
    status: transactionStatus,
  }, { merge: true }).then(() => {
    return res.status(200).send("Notification received");
  }).catch((error) => {
    console.error("Error updating transaction status:", error);
    return res.status(500).send("Internal Server Error");
  });
});
