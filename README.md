# 🌱 GreenPredict – Sustainable Agriculture Prediction and Consumption System

## 🚀 Overview
GreenPredict is an AI-powered mobile application that connects farmers and consumers, promoting sustainable agriculture through smart technology. The system provides intelligent crop recommendations, a digital marketplace, and real-time communication features.

## ✨ Features
- 🤖 AI-powered crop prediction (90%+ accuracy)
- 🛒 Marketplace connecting farmers and consumers
- 💬 Real-time messaging between users
- 🌦 Weather-based insights and recommendations
- 🔐 Secure authentication and user profile management
- 🔔 Notification system for updates and communication

## 🛠 Tech Stack
- Backend: Python (FastAPI)
- Frontend: Flutter (Mobile Application)
- Database: Firebase (Firestore & Authentication)
- Machine Learning: Scikit-learn
- Tools: Git, GitHub, Google Colab

## 🤖 How It Works
Users provide inputs such as:
- Location
- Season
- Environmental factors (optional)

The system analyzes:
- Weather data  
- Soil conditions  
- Market demand  
- Historical trends  

The AI model generates:
- Recommended crops  
- Success rate  
- Profitability insights  
- Seasonal projections  

## 📱 Additional Features
- Marketplace for buying and selling agricultural products  
- Direct communication between farmers and consumers  
- Save and manage favorite products  
- Prediction history tracking  

## 📂 Project Structure
- Backend (FastAPI API & AI integration)
- Frontend (Flutter mobile application)
- Database (Firebase services)

## ▶️ How to Run

### Backend Setup
1. Navigate to backend folder:
   cd Backend

2. Install dependencies:
   pip install -r requirements.txt

3. Create environment file:
   copy env.example .env

4. Add Firebase credentials (serviceAccountKey.json) to Backend folder  

5. Run backend server:
   python main_firebase.py

Backend runs at:
http://localhost:8001

### Frontend Setup (Flutter)
1. Navigate to frontend folder:
   cd Frontend

2. Install dependencies:
   flutter pub get

3. Update API base URL in:
   lib/services/api_service.dart

   Replace with your local IP:
   http://YOUR_IP:8001

4. Run the app:
   flutter run

## ✅ Verification
- API Docs: http://localhost:8001/docs  
- Health Check: http://localhost:8001/health  
- App connects to backend successfully  

## ⚠️ Notes
- Backend and frontend must be on the same network  
- Update IP if network changes  
- Ensure Firebase is configured correctly  

## 👨‍💻 Author
Malith Amarasinghe  
Software Engineering Undergraduate  

## 📌 Note
This project was developed as a final year academic project demonstrating full-stack development, AI integration, and real-world problem solving.

![Login](assets/screenshots/login.png)

