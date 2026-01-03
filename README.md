
# 🏡 Visitify – Smart Visitor & Delivery Management System

Visitify is a smart visitor and delivery management system designed to simplify and secure entry operations in societies, offices, hostels, and residential complexes.  
It provides three interconnected modules — a **PWA for visitors**, a **Flutter mobile app for guards**, and another for **residents or internal users**.  
The system ensures real-time tracking, visitor verification, and smooth entry approval using modern technologies like **Flutter, Firebase, and Cloudinary**.

<p align="center">
  <a href="https://vistify-apk.vercel.app" download>
    <img src="https://img.shields.io/badge/⬇_Download_Visitify_BETA_APK-blue?style=for-the-badge&logo=android" alt="Download Visitify APK">
  </a>
</p>


---

## 🚀 Features

- QR-based visitor registration through a Progressive Web App (PWA)  
- Live photo capture (no gallery upload) for identity verification  
- Real-time visitor notifications and approvals  
- Guard dashboard for visitor and delivery management  
- Resident module for visitor approval and tracking  
- Cloud storage for images and logs  
- Instant alerts via Firebase Cloud Messaging  
- Role-based authentication (Guard, Resident, Admin)  

---

## 🧭 Workflow Overview

1. **Visitor (PWA):**
   - Scans QR code at gate → redirected to Visitify PWA  
   - Enters name, phone, purpose, vehicle number  
   - Captures live photo and submits request  

2. **Guard App:**
   - Receives visitor requests instantly  
   - Approves/rejects or adds new visitor manually  
   - Records entry and exit times  

3. **Inside User App:**
   - Gets instant notifications for visitor approval  
   - Can pre-add expected visitors  
   - Can view visit logs and delivery updates  

4. **Backend (Firebase + Cloudinary):**
   - Handles authentication, real-time database updates, and secure image storage  

---

## 🧰 Tools and Technologies Used

| Tool | Description |
|------|--------------|
| ![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white) | Used for building the PWA interface |
| ![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white) | Styling for the visitor PWA |
| ![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black) | PWA logic and interactivity |
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) | For cross-platform guard and resident apps |
| ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black) | Authentication, Database, Hosting, Cloud Functions |
| ![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white) | Image storage and optimization |
| ![Figma](https://img.shields.io/badge/Figma-F24E1E?style=for-the-badge&logo=figma&logoColor=white) | UI/UX design and prototyping |
| ![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white) | Version control and collaboration |
| ![VS Code](https://img.shields.io/badge/VS%20Code-007ACC?style=for-the-badge&logo=visualstudiocode&logoColor=white) | Development and debugging |

---

## 📂 Project Structure

```
Visitify/
│
├── visitor_pwa/            # HTML, CSS, JS PWA code
├── guard_app/              # Flutter mobile app for guards
├── resident_app/           # Flutter mobile app for residents
├── firebase_functions/     # Cloud functions for automation
└── assets/                 # Icons, images, and UI assets
```

---


## 📋 Short Description

Visitify is a smart visitor and delivery management system that uses a QR-based PWA for visitors and Flutter apps for guards and residents. It enables real-time tracking, live photo verification, and instant approvals powered by Firebase and Cloudinary.

---

## 👨‍💻 Author  

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](http://www.linkedin.com/in/ayush-kumar-849a1324b)  
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/9A-Ayush)  
[![Instagram](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://www.instagram.com/ayush_ix_xi)  
[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://canary.discord.com/channels/@me)  
[![X](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/ayush_bhai4590?t=HEv_7HYwU_uCIO_8POGwZg&s=09)  
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:wemayush@gmail.com)  

---

## ☕ Support My Work  

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/9a.ayush)

---

## 🛠️ Future Scope

- AI-based visitor face recognition  
- Integration with smart gates and IoT devices  
- Voice-enabled visitor approvals  
- Admin analytics dashboard  

---

## 📄 License

This project is licensed under the **MIT License** – feel free to use and modify it for learning and development.

---
