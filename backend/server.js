const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/chargers', require('./src/routes/chargers'));
app.use('/api/bookings', require('./src/routes/bookings'));
app.use('/api/notifications', require('./src/routes/notifications'));
// Routes-ට add කරන්න:
app.use('/api/admin', require('./src/routes/admin').router);

// Static files (admin dashboard):
app.use(express.static('public'));

app.get('/', (req, res) => {
  res.json({ message: 'PowerShare SL API Running! 🚀' });
});

mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ MongoDB Connected!');

    // Auto-cancel expired bookings every 5 minutes
    const cancelExpiredBookings = require('./src/jobs/autoCancel');
    setInterval(cancelExpiredBookings, 5 * 60 * 1000);
    cancelExpiredBookings(); // run on startup too

    app.listen(process.env.PORT || 3000, () => {
      console.log(`🚀 Server running on port ${process.env.PORT || 3000}`);
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
  });
