const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Charger = require('../models/Charger');
const User = require('../models/User');
const auth = require('../middleware/auth');
const { createNotification } = require('../services/notificationService');

// ── Create booking ────────────────────────────────────────────────
router.post('/', auth, async (req, res) => {
  try {
    const charger = await Charger.findById(req.body.chargerId);
    if (!charger) return res.status(404).json({ success: false, message: 'Charger not found' });

    const isManual = charger.manualAcceptance === true;
    const status = isManual ? 'pending' : 'confirmed';

    const booking = new Booking({
      ...req.body,
      userId: req.user.userId,
      userName: req.user.name,
      userEmail: req.user.email,
      hostId: charger.ownerId ? charger.ownerId.toString() : null,
      status,
      expiresAt: isManual ? new Date(Date.now() + 60 * 60 * 1000) : null,
    });
    await booking.save();

    // ✅ Auto-confirmed → update host wallet immediately
    if (!isManual && charger.ownerId) {
      const hostEarning = parseFloat(((req.body.totalPrice || 0) * 0.90).toFixed(2));
      console.log(`Auto-confirm: updating wallet for host ${charger.ownerId}, earning: ${hostEarning}`);
      const updatedUser = await User.findByIdAndUpdate(
        charger.ownerId.toString(),
        { $inc: { walletBalance: hostEarning, totalEarned: hostEarning } },
        { new: true }
      );
      console.log(`Host wallet updated: ${updatedUser ? updatedUser.walletBalance : 'user not found'}`);
    }

    // Notifications
    if (isManual) {
      if (charger.ownerId) {
        await createNotification({
          userId: charger.ownerId.toString(),
          title: '⏳ New Booking Request!',
          message: `${req.user.name} wants to book "${charger.name}" — ${req.body.date} at ${req.body.time}. Accept or reject within 1 hour.`,
          type: 'booking',
          data: { bookingId: booking._id },
        });
      }
      await createNotification({
        userId: req.user.userId,
        title: '⏳ Booking Pending',
        message: `"${charger.name}" booking sent. Waiting for host approval.`,
        type: 'booking',
        data: { bookingId: booking._id },
      });
    } else {
      if (charger.ownerId) {
        await createNotification({
          userId: charger.ownerId.toString(),
          title: '💰 Booking + Rs.' + Math.floor((req.body.totalPrice || 0) * 0.90) + ' Earned!',
          message: `${req.user.name} booked "${charger.name}". Rs.${Math.floor((req.body.totalPrice||0)*0.90)} added to your wallet!`,
          type: 'booking',
          data: { bookingId: booking._id },
        });
      }
      await createNotification({
        userId: req.user.userId,
        title: '✅ Booking Confirmed!',
        message: `"${charger.name}" — ${req.body.date} at ${req.body.time} — Rs.${req.body.totalPrice}`,
        type: 'confirmation',
        data: { bookingId: booking._id },
      });
    }

    res.json({ success: true, booking, isManual });
  } catch (e) {
    console.error('Create booking error:', e);
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── Get my bookings (driver) ──────────────────────────────────────
router.get('/my', auth, async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user.userId }).sort({ createdAt: -1 });
    res.json({ success: true, bookings });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── Get received bookings (host) ──────────────────────────────────
router.get('/received', auth, async (req, res) => {
  try {
    const myChargers = await Charger.find({ ownerId: req.user.userId });
    const ids = myChargers.map(c => c._id.toString());
    const bookings = await Booking.find({ chargerId: { $in: ids } }).sort({ createdAt: -1 });
    res.json({ success: true, bookings });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── Accept booking ────────────────────────────────────────────────
router.patch('/:id/accept', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: 'Not found' });
    if (booking.hostId !== req.user.userId)
      return res.status(403).json({ success: false, message: 'Not your booking' });

    booking.status = 'confirmed';
    booking.expiresAt = null;
    await booking.save();

    // ✅ Update host wallet on accept
    const hostEarning = parseFloat(((booking.totalPrice || 0) * 0.90).toFixed(2));
    console.log(`Accept: updating wallet for ${req.user.userId}, earning: ${hostEarning}`);
    const updatedUser = await User.findByIdAndUpdate(
      req.user.userId,
      { $inc: { walletBalance: hostEarning, totalEarned: hostEarning } },
      { new: true }
    );
    console.log(`Wallet after accept: ${updatedUser ? updatedUser.walletBalance : 'not found'}`);

    await createNotification({
      userId: booking.userId,
      title: '✅ Booking Accepted!',
      message: `Your booking for "${booking.chargerName}" on ${booking.date} at ${booking.time} has been accepted!`,
      type: 'confirmation',
      data: { bookingId: booking._id },
    });

    res.json({ success: true, booking, hostEarning });
  } catch (e) {
    console.error('Accept error:', e);
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── Reject booking ────────────────────────────────────────────────
router.patch('/:id/reject', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: 'Not found' });
    if (booking.hostId !== req.user.userId)
      return res.status(403).json({ success: false, message: 'Not your booking' });

    booking.status = 'cancelled';
    booking.cancelReason = req.body.reason || 'Rejected by host';
    await booking.save();

    await createNotification({
      userId: booking.userId,
      title: '❌ Booking Rejected',
      message: `Sorry, your booking for "${booking.chargerName}" on ${booking.date} was rejected.`,
      type: 'cancelled',
      data: { bookingId: booking._id },
    });

    res.json({ success: true, booking });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── Cancel booking (driver) ───────────────────────────────────────
router.patch('/:id/cancel', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: 'Not found' });
    if (booking.userId !== req.user.userId)
      return res.status(403).json({ success: false, message: 'Not your booking' });

    if (booking.status === 'confirmed' && booking.hostId) {
      const hostEarning = parseFloat(((booking.totalPrice || 0) * 0.90).toFixed(2));
      await User.findByIdAndUpdate(booking.hostId, {
        $inc: { walletBalance: -hostEarning }
      });
    }

    booking.status = 'cancelled';
    await booking.save();

    if (booking.hostId) {
      await createNotification({
        userId: booking.hostId,
        title: '❌ Booking Cancelled',
        message: `${booking.userName} cancelled the booking for ${booking.date}`,
        type: 'cancelled',
        data: { bookingId: booking._id },
      });
    }

    res.json({ success: true, booking });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;