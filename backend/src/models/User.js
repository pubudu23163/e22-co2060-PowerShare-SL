const mongoose = require('mongoose');
const userSchema = new mongoose.Schema({
  googleId:  { type: String, required: true, unique: true },
  name:      { type: String, required: true },
  email:     { type: String, required: true, unique: true },
  photo:     { type: String },
  walletBalance:    { type: Number, default: 0 },
  hostEarnings:     { type: Number, default: 0 },
  hostWithdrawable: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
});
module.exports = mongoose.model('User', userSchema);
