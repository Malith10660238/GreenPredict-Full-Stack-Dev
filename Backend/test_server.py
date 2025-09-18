#!/usr/bin/env python3
"""
Simple test server to verify Python and Firebase setup
"""

import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

class TestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                "status": "healthy",
                "service": "GreenPredict Backend",
                "timestamp": datetime.now().isoformat()
            }
            self.wfile.write(json.dumps(response).encode())
            
        elif parsed_path.path == '/test':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                "message": "Backend is working!",
                "timestamp": datetime.now().isoformat()
            }
            self.wfile.write(json.dumps(response).encode())
            
        elif parsed_path.path == '/test-firebase':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            try:
                # Test Firebase connection
                if db is None:
                    response = {"error": "Firebase not initialized"}
                else:
                    # Test Firestore connection
                    test_doc = db.collection('test').document('connection').get()
                    response = {
                        "message": "Firebase connection successful", 
                        "firestore": "connected",
                        "timestamp": datetime.now().isoformat()
                    }
            except Exception as e:
                response = {"error": f"Firebase connection failed: {str(e)}"}
            
            self.wfile.write(json.dumps(response).encode())
            
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {"error": "Not found"}
            self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        if not firebase_admin._apps:
            # Check if service account key file exists
            service_account_path = "serviceAccountKey.json"
            if os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                print("✅ Firebase initialized with service account key")
            else:
                print("⚠️  serviceAccountKey.json not found. Please place your Firebase service account key in the Backend directory.")
                return None
        
        return firestore.client()
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Starting GreenPredict Test Server...")
    
    # Initialize Firebase
    db = initialize_firebase()
    
    # Start server
    server_address = ('', 8000)
    httpd = HTTPServer(server_address, TestHandler)
    
    print("✅ Server started successfully!")
    print("📍 Server running at: http://localhost:8000")
    print("🔗 Test endpoints:")
    print("   - http://localhost:8000/health")
    print("   - http://localhost:8000/test")
    print("   - http://localhost:8000/test-firebase")
    print("\n⏹️  Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
        httpd.server_close()
