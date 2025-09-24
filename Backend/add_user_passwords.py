#!/usr/bin/env python3
"""
Add password fields to existing users
"""

import firebase_admin
from firebase_admin import credentials, firestore
import hashlib

def add_user_passwords():
    """Add password fields to existing users"""
    
    # Initialize Firebase Admin SDK
    if not firebase_admin._apps:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # Hash passwords (simple hash for demo purposes)
    def hash_password(password):
        return hashlib.sha256(password.encode()).hexdigest()
    
    # Update farmer user
    farmer_uid = "2qBsMZEOQ0MY1EFfxTz4dgl3s9i1"
    farmer_password = "password123"
    farmer_password_hash = hash_password(farmer_password)
    
    print("🔵 Adding password to farmer user...")
    farmer_ref = db.collection('users').document(farmer_uid)
    farmer_ref.update({
        'password': farmer_password_hash
    })
    print(f"✅ Added password for farmer@test.com")
    
    # Update consumer user
    consumer_uid = "ng82isXAqgTelbZgq1aqU1MHGR12"
    consumer_password = "password123"
    consumer_password_hash = hash_password(consumer_password)
    
    print("🔵 Adding password to consumer user...")
    consumer_ref = db.collection('users').document(consumer_uid)
    consumer_ref.update({
        'password': consumer_password_hash
    })
    print(f"✅ Added password for consumer@test.com")
    
    print("\n✅ All passwords added successfully!")
    print("Farmer: farmer@test.com / password123")
    print("Consumer: consumer@test.com / password123")

if __name__ == "__main__":
    print("🧪 Adding User Passwords")
    print("=" * 50)
    
    try:
        add_user_passwords()
        print("\n✅ Password setup completed!")
    except Exception as e:
        print(f"❌ Password setup failed with error: {e}")
