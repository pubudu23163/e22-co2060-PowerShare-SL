const mongoose = require('mongoose');
const chargerSchema = new mongoose.Schema({
  name:         { type: String, required: true },
  address:      { type: String, required: true },
  latitude:     { type: Number, required: true },
  longitude:    { type: Number, required: true },
  pricePerKwh:  { type: Number, required: true },
  powerKw:      { type: Number, required: true, default: 7.4 },
  chargerType:  { type: String, default: 'Standard' },
  isAvailable:  { type: Boolean, default: true },
  ownerName:    { type: String, required: true },
  ownerId:      { type: String },
  rating: { type: Number, default: 0 },
  manualAcceptance: { type: Boolean, default: false },
  createdAt:    { type: Date, default: Date.now },
});
module.exports = mongoose.model('Charger', chargerSchema);

