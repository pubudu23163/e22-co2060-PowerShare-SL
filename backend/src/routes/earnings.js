// backend/src/routes/earnings.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');

// Get host wallet balance
router.get('/my', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false });
    res.json({
      success: true,
      walletBalance: user.walletBalance || 0,
      totalEarned: user.totalEarned || 0,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// Request withdrawal (mock)
router.post('/withdraw', auth, async (req, res) => {
  try {
    const { amount, bankName, accountNumber, accountName } = req.body;
    const user = await User.findById(req.user.userId);

    if (!user) return res.status(404).json({ success: false });
    if ((user.walletBalance || 0) < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }

    // Deduct from wallet
    user.walletBalance -= amount;
    await user.save();

    res.json({
      success: true,
      message: `Withdrawal of Rs. ${amount} requested successfully`,
      remainingBalance: user.walletBalance,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;