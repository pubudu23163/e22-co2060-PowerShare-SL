# ⚡ PowerShare SL — P2P EV Charging Marketplace

<p align="center">
  <img src="assets/images/logo.png" alt="PowerShare SL Logo" width="150"/>
</p>

<p align="center">
  <strong>A Peer-to-Peer Electric Vehicle Charging Platform for Sri Lanka</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Node.js-22-green?logo=node.js" />
  <img src="https://img.shields.io/badge/MongoDB-Atlas-green?logo=mongodb" />
  <img src="https://img.shields.io/badge/Platform-Android-brightgreen?logo=android" />
  <img src="https://img.shields.io/badge/License-MIT-yellow" />
</p>

---

## 📖 Introduction

**PowerShare SL** is a mobile application that enables Sri Lankan homeowners with EV charging facilities to share their chargers with EV drivers — similar to Airbnb, but for EV chargers.

With the rapid growth of electric vehicles in Sri Lanka, public charging infrastructure remains limited. PowerShare SL bridges this gap by creating a **peer-to-peer charging network** where:

- 🚗 **EV Drivers** can find, book, and pay for nearby chargers
- 🏠 **Charger Hosts** can list their home chargers and earn income
- ⚡ **Smart Billing** based on actual kWh consumed

---

## ✨ Features

### For EV Drivers
- 📍 Interactive map with real-time charger availability
- 🔍 Filter chargers by type (Slow / Standard / Fast / Rapid)
- 📅 Book charging slots with clash detection
- ⚡ Accurate kWh-based cost calculation
- 💳 Mock payment system (Card / Dialog / Mobitel)
- 📋 Booking history with status tracking
- 💰 Wallet with top-up and transaction history
- 🔔 In-app notifications

### For Charger Hosts
- ➕ Register chargers with GPS location
- 🔌 Charger type selection (3.3kW / 7.4kW / 22kW / 50kW)
- ✅ Manual or auto booking acceptance
- 📊 Host dashboard with earnings overview
- 💵 Wallet with withdrawal system
- 📋 Received bookings management

### Admin
- 🌐 Web-based admin dashboard
- 👥 User management
- 🔌 Charger management
- 📋 Booking overview
- 💰 Revenue statistics

---

## 🏗️ Architecture

```
PowerShare SL
├── Flutter App (Android)
│   ├── EV Driver Interface
│   ├── Host Interface  
│   └── Admin Dashboard (Web)
├── Node.js Backend (Railway)
│   ├── REST API
│   ├── JWT Authentication
│   └── Auto-cancel Jobs
└── MongoDB Atlas (Database)
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile Frontend | Flutter (Dart) |
| Backend | Node.js + Express.js |
| Database | MongoDB Atlas |
| Authentication | Google Sign-In + JWT |
| Maps | OpenStreetMap (flutter_map) |
| Deployment | Railway.app |
| Admin Dashboard | HTML + CSS + JavaScript |

---

## 📱 Screenshots

> App screenshots and demo video available in `/docs/images/`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Node.js 18+
- MongoDB Atlas account

### Backend Setup
```bash
cd backend
cp .env.example .env
# Fill in your credentials in .env
npm install
npm run dev
```

### Flutter Setup
```bash
flutter pub get
flutter run
```

### Environment Variables
```env
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
PORT=3000
ADMIN_SECRET_KEY=your_admin_key
```

---

## 👥 Team

| Name | E-Number | Email |
|------|----------|-------|
| Pubudu Madusanka Herath | E/22/142 | e22142@eng.pdn.ac.lk |
| Dulanjaya Herath | E/22/141 | e22141@eng.pdn.ac.lk |
| Himasha Sathsarani | E/22/362 | e22362@eng.pdn.ac.lk |
| Akash | E/22/248 | e22248@eng.pdn.ac.lk |

---

## 🔗 Links

- 🌐 [Project Page](https://cepdnaclk.github.io/e22-co2060-PowerShare-SL)
- 🚀 [Live API](https://e22-co2060-powershare-sl-production.up.railway.app)
- 🎓 [Department of Computer Engineering, University of Peradeniya](http://www.ce.pdn.ac.lk/)

---

## 📄 License

This project is licensed under the MIT License.

---

<p align="center">Made with ❤️ in Sri Lanka 🇱🇰</p>