const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Charger = require('../models/Charger');
const Booking = require('../models/Booking');

// ── Simple admin auth middleware ──────────────────────────────────────
const adminAuth = (req, res, next) => {
  const key = req.headers['x-admin-key'];
  if (key !== process.env.ADMIN_SECRET_KEY) {
    return res.status(403).json({ success: false, message: 'Admin access denied' });
  }
  next();
};

// ── GET /api/admin/stats ──────────────────────────────────────────────
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const [totalUsers, totalChargers, totalBookings, bookings] = await Promise.all([
      User.countDocuments(),
      Charger.countDocuments(),
      Booking.countDocuments(),
      Booking.find(),
    ]);

    const totalRevenue = bookings
      .filter(b => b.paymentStatus === 'released')
      .reduce((sum, b) => sum + (b.totalPrice || 0), 0);

    const platformFees = totalRevenue * 0.05;

    const statusCounts = {
      pending_confirmation: bookings.filter(b => b.status === 'pending_confirmation').length,
      confirmed:  bookings.filter(b => b.status === 'confirmed').length,
      rejected:   bookings.filter(b => b.status === 'rejected').length,
      cancelled:  bookings.filter(b => b.status === 'cancelled').length,
      completed:  bookings.filter(b => b.status === 'completed').length,
    };

    res.json({
      success: true,
      stats: {
        totalUsers,
        totalChargers,
        totalBookings,
        totalRevenue: totalRevenue.toFixed(2),
        platformFees: platformFees.toFixed(2),
        statusCounts,
      },
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── GET /api/admin/users ──────────────────────────────────────────────
router.get('/users', adminAuth, async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    res.json({ success: true, users });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── GET /api/admin/chargers ───────────────────────────────────────────
router.get('/chargers', adminAuth, async (req, res) => {
  try {
    const chargers = await Charger.find().sort({ createdAt: -1 });
    res.json({ success: true, chargers });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── DELETE /api/admin/chargers/:id ───────────────────────────────────
router.delete('/chargers/:id', adminAuth, async (req, res) => {
  try {
    await Charger.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Charger deleted' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── GET /api/admin/bookings ───────────────────────────────────────────
router.get('/bookings', adminAuth, async (req, res) => {
  try {
    const bookings = await Booking.find().sort({ createdAt: -1 });
    res.json({ success: true, bookings });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── DELETE /api/admin/users/:id ───────────────────────────────────────
router.delete('/users/:id', adminAuth, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'User deleted' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});
// Recalculate host earnings from confirmed bookings
router.post('/recalculate-earnings', adminAuth, async (req, res) => {
  try {
    const bookings = await Booking.find({ 
      status: 'confirmed', 
      paymentStatus: 'released' 
    });
    
    // Group by hostId
    const earnings = {};
    for (const b of bookings) {
      if (!b.hostId) continue;
      if (!earnings[b.hostId]) earnings[b.hostId] = 0;
      earnings[b.hostId] += b.totalPrice * 0.95;
    }
    
    // Update each host
    for (const [hostId, amount] of Object.entries(earnings)) {
      await User.findByIdAndUpdate(hostId, {
        $set: { hostEarnings: amount, hostWithdrawable: amount }
      });
    }
    
    res.json({ success: true, message: 'Earnings recalculated!', earnings });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = { router, adminAuth };