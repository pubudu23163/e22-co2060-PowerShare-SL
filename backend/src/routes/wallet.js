const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Booking = require('../models/Booking');
const auth = require('../middleware/auth');

// ── GET /api/wallet — Get wallet info ────────────────────────────────
router.get('/', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    // Transaction history
    const bookingsAsDriver = await Booking.find({
      userId: req.user.userId,
      paymentStatus: { $in: ['held', 'released', 'refunded'] },
    }).sort({ createdAt: -1 }).limit(20);

    const bookingsAsHost = await Booking.find({
      hostId: req.user.userId,
      paymentStatus: 'released',
    }).sort({ createdAt: -1 }).limit(20);

    res.json({
      success: true,
      wallet: {
        walletBalance:    user.walletBalance,
        hostEarnings:     user.hostEarnings,
        hostWithdrawable: user.hostWithdrawable,
      },
      driverTransactions: bookingsAsDriver,
      hostTransactions:   bookingsAsHost,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── POST /api/wallet/topup — Driver top up wallet (mock) ─────────────
router.post('/topup', auth, async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid amount' });
    }

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $inc: { walletBalance: amount } },
      { new: true }
    );

    res.json({
      success: true,
      message: `Rs. ${amount} added to wallet!`,
      walletBalance: user.walletBalance,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── POST /api/wallet/withdraw — Host withdraw earnings (mock) ─────────
router.post('/withdraw', auth, async (req, res) => {
  try {
    const { amount, bankName, accountNumber, accountName } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid amount' });
    }
    if (amount > user.hostWithdrawable) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Available: Rs. ${user.hostWithdrawable.toFixed(2)}`,
      });
    }

    // Deduct from withdrawable
    await User.findByIdAndUpdate(req.user.userId, {
      $inc: { hostWithdrawable: -amount },
    });

    // Mock bank transfer — 2-3 business days
    res.json({
      success: true,
      message: `Rs. ${amount} withdrawal initiated!`,
      details: {
        amount,
        bankName,
        accountNumber: `****${accountNumber.slice(-4)}`,
        accountName,
        status: 'Processing',
        estimatedDays: '2-3 business days',
      },
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;