const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
app.use(bodyParser.json());

app.post('/midtrans-notification', async (req, res) => {
  const notification = req.body;

  // Verifikasi notifikasi dari Midtrans
  if (notification && notification.order_id) {
    // Ambil order_id dan status pembayaran dari notifikasi
    const { order_id, transaction_status } = notification;

    // Perbarui status pembayaran di Firebase
    try {
      await axios.post('YOUR_PAYMENT_DATABASE_ENDPOINT', {
        orderId: order_id,
        status: transaction_status,
      });
      res.status(200).send('Notification processed');
    } catch (error) {
      console.error('Error updating payment status:', error);
      res.status(500).send('Internal server error');
    }
  } else {
    res.status(400).send('Invalid notification');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
