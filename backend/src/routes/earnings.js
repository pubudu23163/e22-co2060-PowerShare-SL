// backend/src/routes/earnings.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');

// ── Get wallet balance ────────────────────────────────────────────
router.get('/my', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({
      success: true,
      walletBalance: user.walletBalance || 0,
      totalEarned: user.totalEarned || 0,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── Request withdrawal ────────────────────────────────────────────
router.post('/withdraw', auth, async (req, res) => {
  try {
    const { amount, bankName, accountNumber, accountName } = req.body;
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if ((user.walletBalance || 0) < amount) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Available: Rs.${user.walletBalance || 0}`
      });
    }

    user.walletBalance -= parseFloat(amount);
    await user.save();

    res.json({
      success: true,
      message: `Withdrawal of Rs.${amount} requested successfully`,
      remainingBalance: user.walletBalance,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;