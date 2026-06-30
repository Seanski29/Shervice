# 🚐 Shervice: GT LANTIN Shuttle Service Management System
> **Shervice: GT LANTIN Shuttle Service Management System with Driver Performance Analytics and Predictive Maintenance ** 

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)

##  Executive Summary
**Shervice** is a \data-driven transport management system engineered to modernize the shuttle fleet operations of GT LANTIN Shuttle Rental Services. The platform replaces legacy manual tracking methods (whiteboards, paper logs) to seamlessly coordinate over 70 vehicles and 12,000+ weekly passenger trips for multinational manufacturing clients like EPSON, Bandai Namco, and NX Logistics

By transitioning to a proactive operational strategy, Shervice integrates a unified micro-frontend web architecture with a dual-engine backend, utilizing advanced machine learning algorithms to forecast vehicle maintenance, analyze route delays, and classify driver performance .

---

## 🏗️ System Architecture & Tech Stack

Shervice utilizes a robust, multi-tier architecture to separate user interfaces, system logic, and data management .

### 1. Presentation Layer (Micro-Frontend)
*   **Authentication Hub:** React.js (18.3+) / Vite (5.0+) running on `localhost:3000`. Handles initial user sessions and Role-Based Access Control (RBAC) .
*   **Main Application Portal:** Flutter Web running on `localhost:8080`. Reads URL query parameters (e.g., `?role=admin`) passed from React via `dart:html` to dynamically render role-specific layouts.
*   **Styling:** Tailwind CSS (3.4) ensures mobile responsiveness for drivers in the field .

### 2. Application Layer (Dual-Engine Backend)
*   **Primary Runtime:** Node.js (20.x) with Express.js (4.19) handles asynchronous tasks, RESTful API endpoints, and high-velocity data ingestion (attendance, trip logs) .
*   **Real-Time Engine:** Socket.io (4.7) enables bidirectional communication for instant push notifications on the Admin dashboard .
*   **Analytical Engine:** Python Flask (3.0) operates as a dedicated microservice to host the machine learning models and high-level computational tasks .

### 3. Data Layer
*   **Relational Database:** MySQL / PostgreSQL (16) securely stores structured driver records, operational logs, and maintenance histories .
*   **Backend-as-a-Service:** Supabase provides secure authentication protocols and real-time database listeners .

---

## Machine Learning & Predictive Analytics Pipeline
The core intelligence of Shervice transforms raw daily logs into actionable business intelligence using Scikit-learn (1.4) and Pandas (2.2) . 

### 1. Driver Performance Classification (Random Forest)
Evaluates combined driver attendance logs and anonymous passenger evaluations to automatically classify overall driver performance into actionable categories (e.g., Highly Reliable, Needs Improvement) . 
*   **Evaluation Metrics:** Validated using Accuracy, Precision, Recall, and the F1-Score .
    $$F_{1} = 2\frac{precision \cdot recall}{precision + recall}$$

### 2. Predictive Maintenance (Multiple Linear Regression)
Shifts fleet management from a reactive to a proactive state by calculating the mathematical relationship between historical vehicle wear-and-tear and future required maintenance cycles .
    $$y = \beta_0 + \beta_1x_1 + \beta_2x_2 + ... + \beta_nx_n + \epsilon$$
*   **Evaluation Metrics:** Validated using Mean Absolute Error (MAE) and Root Mean Squared Error (RMSE) .

### 3. Route Delay Analysis (K-Means Clustering)
An unsupervised learning model that analyzes route distances, vehicle health, and actual arrival times to automatically group similar logistical bottlenecks, helping dispatchers visually identify recurring delays . 
*   **Optimization:** Minimizes the Within-Cluster Sum of Squares (WCSS) :
    $$J = \sum_{j=1}^{k}\sum_{i=1}^{n}||x_i^{(j)} - c_j||^2$$

---

##  Key Features by User Role

*   ** Administrators & Staff:** Oversee comprehensive driver records, manage daily vehicle dispatching, input maintenance logs, and access the React-based Performance Analytics Dashboard for real-time KPIs .
*   ** Drivers:** Access a mobile-responsive portal to check vehicle assignments and shift schedules . Log daily time-in/time-out via terminal biometric fingerprint scanners for exact punctuality tracking .
*   ** Officer-in-Charge (OIC):** Corporate client representatives use a dedicated portal to digitally submit shift requirements, input passenger counts, and formalize dispatch requests .
*   ** Passengers:** Scan in-vehicle QR codes to access an anonymous evaluation portal, rating drivers on safety, attitude, and punctuality to feed the machine learning models .

---

##  Local Development & Getting Started

### Prerequisites
*   [Node.js v20+](https://nodejs.org/)
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [Python 3.10+](https://www.python.org/)
*   [Supabase](https://supabase.com)

### 1. How to Run
TERMINAL1
cd shuttle-backend
Activate.ps1    
python app.py

TERMINAL 2
cd shervice_flutter
flutter run -d chrome --web-port 8080

