const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  googleId:  { type: String, required: true, unique: true },
  name:      { type: String, required: true },
  email:     { type: String, required: true, unique: true },
  photo:     { type: String },

  // ── Wallet ────────────────────────────────────────────────────────
  walletBalance:  { type: Number, default: 0 },   // driver top-up balance
  hostEarnings:   { type: Number, default: 0 },   // host total earned
  hostWithdrawable: { type: Number, default: 0 }, // available to withdraw

  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);