#!/usr/bin/env python3
"""
Check if user documents have password fields
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

def check_user_passwords():
    """Check if user documents have password fields"""
    
    # Initialize Firebase Admin SDK
    if not firebase_admin._apps:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # Check farmer user
    farmer_uid = "2qBsMZEOQ0MY1EFfxTz4dgl3s9i1"
    print("🔵 Checking farmer user document...")
    farmer_doc = db.collection('users').document(farmer_uid).get()
    if farmer_doc.exists:
        farmer_data = farmer_doc.to_dict()
        print("✅ Farmer user document:")
        print(f"Email: {farmer_data.get('email')}")
        print(f"Has password field: {'password' in farmer_data}")
        if 'password' in farmer_data:
            print(f"Password: {farmer_data.get('password')}")
        else:
            print("❌ No password field found")
    
    # Check consumer user
    consumer_uid = "ng82isXAqgTelbZgq1aqU1MHGR12"
    print("\n🔵 Checking consumer user document...")
    consumer_doc = db.collection('users').document(consumer_uid).get()
    if consumer_doc.exists:
        consumer_data = consumer_doc.to_dict()
        print("✅ Consumer user document:")
        print(f"Email: {consumer_data.get('email')}")
        print(f"Has password field: {'password' in consumer_data}")
        if 'password' in consumer_data:
            print(f"Password: {consumer_data.get('password')}")
        else:
            print("❌ No password field found")

if __name__ == "__main__":
    print("🧪 Checking User Password Fields")
    print("=" * 50)
    
    try:
        check_user_passwords()
        print("\n✅ Check completed!")
    except Exception as e:
        print(f"❌ Check failed with error: {e}")
