# 🛡️ Safe Travel

**Offline-First Flutter App for Managing Vehicles & Travel History**

Safe Travel is a modern, offline-first Flutter application that allows users to store and manage **vehicle details** and **travel records** efficiently.
It syncs seamlessly with a **PHP + MySQL backend**, while supporting secure authentication through **Firebase Auth**.

---

## 🚀 Features

### ✔ Offline-First Architecture

Data is stored in **SQLite** locally and synced automatically when the device goes online.

### ✔ Smart Auto-Sync

* Syncs inserts, updates, and deletions
* Syncs vehicle types at app start
* Detects network status with a background watcher
* Triggers sync instantly when network comes back online

### ✔ Firebase Authentication

* Login
* Sign up
* Password reset with custom email template
* Protects user-specific data

### ✔ Vehicle Management

* Add new vehicles (type, number, name, image)
* Edit and delete vehicles
* Each vehicle is linked to the logged-in user
* Vehicle type images are downloaded, cached, and reused

### ✔ Travel Logging

* Add travels with:

  * From
  * To
  * Price
  * Travel time
* Edit or delete travel entries
* Each travel is linked to a vehicle
* Fast loading with pre-downloaded images
* Latest travels shown on home page

### ✔ Real-Time Network Watcher

* Detects internet ON/OFF instantly
* Shows status in UI
* Auto-runs sync when back online

### ✔ Organized Modular Codebase

Includes:

* `db_helper.dart` – SQLite layer
* `api_service.dart` – Server communication
* `network_watcher.dart` – Internet monitoring
* `Special` functions – Sync helpers
* Page-based navigation (Login, Register, Travels, Vehicle Details, etc.)

---

## 🏗️ Tech Stack

| Layer           | Technology              |
| --------------- | ----------------------- |
| Frontend        | Flutter (Dart)          |
| Auth            | Firebase Authentication |
| Local Storage   | SQLite                  |
| Server          | PHP                     |
| Remote Database | MySQL                   |
| Image Handling  | Cached local files      |
| Network Status  | connectivity_plus       |

---

## 📁 Folder Structure (Summary)

```
lib/
 ├── api_service.dart
 ├── db_helper.dart
 ├── function.dart
 ├── login_page.dart
 ├── register_page.dart
 ├── forgot_password_page.dart
 ├── travel_page.dart
 ├── vehicle_details_page.dart
 ├── edit_vehicle_page.dart
 ├── edit_travel_page.dart
 ├── SmallFunctions/
 │     └── network_watcher.dart
 └── main.dart
```

---

## 🗂️ Database Structure

### **MySQL Tables**

* `vehicletype`
* `vehicles`
* `travels`

### **SQLite Mirrors**

Same structure with an added `sync_status` & `deleted` fields for offline sync.

---

## 🔌 Sync Logic

Each record contains:

```
sync_status = pending | synced
deleted = 0 | 1
updated_at = ISO timestamp
```

### Sync Flow:

1. User inserts/updates/deletes → marked `pending`
2. When internet available:

   * Upload pending records
   * Pull latest changes from server
   * Apply soft deletes
   * Mark all synced

### Conflict Handling:

Latest `updated_at` wins.

---

## 📦 Installation & Running

### 1. Clone the repo:

```bash
git clone https://github.com/mrabhin03/Safe-Travel.git
cd Safe-Travel
```

### 2. Install Flutter packages:

```bash
flutter pub get
```

### 3. Configure Firebase:

Add your Firebase config to the project.

### 4. Configure PHP API:

Set your server URL inside:

```
api_service.dart
```

### 5. Run the app:

```bash
flutter run
```

---

## 🧪 Status

This project is under active development and continuously improving with:

* Faster sync
* Optimized images
* More vehicle management features

---

## 🤝 Contributions

Pull requests and suggestions are welcome!
This project is great for learning:

* Offline-first architecture
* Real-world sync logic
* Flutter + Firebase + PHP integration
* Multi-device data consistency

---

## 📜 License

MIT License — free to use, modify, and improve.
