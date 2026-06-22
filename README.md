# 🚐 Shervice - Shuttle Management System

> **Integrative Programming Technologies Capstone**
> A micro-frontend architecture combining a React web portal for secure authentication and a Flutter-based web app for dynamic Admin and Driver dashboards.

## 📋 Table of Contents

* [Overview](https://www.google.com/search?q=%23overview)
* [Tech Stack](https://www.google.com/search?q=%23tech-stack)
* [Key Features](https://www.google.com/search?q=%23key-features)
* [System Architecture](https://www.google.com/search?q=%23system-architecture)
* [Getting Started](https://www.google.com/search?q=%23getting-started)

---

## 📖 Overview

**Shervice** is a comprehensive transport management solution designed to streamline dispatching, track route progression, and provide real-time analytics. It utilizes a unified micro-frontend login system that intelligently routes users to their respective administrative or driver dashboards based on their role credentials.

---

## 🛠 Tech Stack

* **Authentication Hub:** React (Vite)
* **Main Application Portal:** Flutter (Web)
* **Cross-App Communication:** `window.location.assign` (React) and `dart:html` (Flutter)
* **Routing Strategy:** URL Query Parameters (`?role=admin` / `?role=driver`)
* **Version Control:** Git & GitHub

---

## ✨ Key Features

### 👨‍💻 Admin Portal

* **Dispatch Assignment:** Assign vehicles and specific routes to available drivers in real-time.
* **Analytics & Filtering:** Monitor daily passenger volume and route efficiency via interactive charts. Includes a custom slide-out panel for applying date and location filters.
* **Driver Management:** View active/idle statuses of all fleet operators.

### 🚐 Driver Portal

* **Route Progression:** Log passenger drop-offs and track upcoming stops dynamically.
* **Incident & Delay Reporting:** Instantly notify the central admin system of traffic delays or vehicle breakdowns using quick-select alert modals.
* **Profile Management:** Update notification preferences and manage account settings.

---

## 🏗 System Architecture

The Shervice application splits responsibilities across two independent frameworks, bound together by strict port routing:

1. **React Auth Hub (`localhost:3000`):** Handles the initial user session. Upon a successful login, React redirects the browser to the Flutter portal, passing the user's role via the URL.
2. **Flutter Portal (`localhost:8080`):** Acts as the main router. It reads the query parameters and dynamically renders either the Admin or Driver layout. Pressing "Logout" utilizes the integrated layout buttons to forcefully redirect the user back to the React hub.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed on your machine:

* [Node.js](https://www.google.com/search?q=https://nodejs.org/) (for the React Auth Hub)
* [Flutter SDK](https://www.google.com/search?q=https://flutter.dev/docs/get-started/install) (for the Main Portal)

### Running the Application Locally

Because this is a multi-framework project, you must run both servers simultaneously in separate terminal windows to test the full flow.

**Terminal 1: Start the React Login Hub**

```bash
# Navigate to the React folder
cd path/to/shervice/react-login

# Install dependencies
npm install

# Start the Vite development server (locked to Port 3000)
npm run dev

```

**Terminal 2: Start the Flutter Portal**

```bash
# Navigate to the Flutter folder
cd path/to/shervice/flutter-portal

# Fetch dependencies
flutter pub get

# Start the Flutter web server (locked to Port 8080)
flutter run -d chrome --web-port 8080

```
