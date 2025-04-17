# 💊 Medicos – AI-Powered Medicine Reminder App

**Medicos** is an AI-powered medicine management app designed to enhance medication adherence and reduce the chances of missed or incorrect doses. With features like OCR-based prescription reading, personalized reminders, real-time drug data via healthcare APIs, and cloud sync, the app helps users manage their medicine schedule with ease and reliability.

---

## 🚀 Features

- 🔐 **Secure Authentication** – Firebase Auth to log in/register users securely.
- 🧾 **OCR-based Prescription Scan** – Extracts medicine names and dosages from images.
- 💡 **Smart Reminders** – Notifies users when it's time to take their medication.
- ☁️ **Cloud Sync** – Automatically syncs medicine data across devices using Firebase Firestore.
- 📥 **Medicine Management** – Add, view, and update medicines and dosage schedules.
- 📲 **Push Notifications** – Uses Firebase Messaging for timely alerts.
- 🩺 **Healthcare API Integration** – Fetches real-time drug info.
- 📊 **Patient Record PDF Export** – Export medicine schedules to share with doctors or pharmacists.
- 🎨 **Modern UI** – Built using Flutter and Google Fonts for a beautiful user experience.

---

## 📱 Screenshots

![Home Screen](assets/screenshots/home.png)
![Add Medicine](assets/screenshots/add_medicine.png)
![Reminder Notification](assets/screenshots/notification.png)

---

## 🛠️ Tech Stack

| Layer          | Technology            |
|----------------|------------------------|
| **Frontend**   | Flutter (Dart)         |
| **Backend**    | Firebase, Node.js (if needed) |
| **Database**   | Cloud Firestore        |
| **OCR**        | Firebase ML / Tesseract |
| **APIs**       | Healthcare APIs        |
| **Notifications** | Firebase Cloud Messaging |

---

## 🧰 Installation

1. **Clone the repo:**
   ```bash
   git clone https://github.com/yourusername/medicos-app.git
   cd medicos-app
