const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  googleId:      { type: String, required: true, unique: true },
  name:          { type: String, required: true },
  email:         { type: String, required: true },
  photo:         { type: String },
  walletBalance: { type: Number, default: 0 },  // ← host earnings
  totalEarned:   { type: Number, default: 0 },  // ← lifetime total
  fcmToken:      { type: String, default: null },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);