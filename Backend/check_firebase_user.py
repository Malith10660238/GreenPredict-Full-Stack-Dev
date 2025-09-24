#!/usr/bin/env python3
"""
Check what's actually stored in Firebase for the consumer user
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

def check_firebase_user():
    """Check Firebase user data"""
    
    # Initialize Firebase Admin SDK
    if not firebase_admin._apps:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # Check consumer user
    consumer_uid = "ng82isXAqgTelbZgq1aqU1MHGR12"
    
    print("🔵 Checking users collection...")
    user_doc = db.collection('users').document(consumer_uid).get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        print("✅ User document found in users collection:")
        print(json.dumps(user_data, indent=2, default=str))
    else:
        print("❌ User document not found in users collection")
    
    print("\n🔵 Checking consumers collection...")
    consumer_doc = db.collection('consumers').document(consumer_uid).get()
    if consumer_doc.exists:
        consumer_data = consumer_doc.to_dict()
        print("✅ Consumer document found in consumers collection:")
        print(json.dumps(consumer_data, indent=2, default=str))
    else:
        print("❌ Consumer document not found in consumers collection")
    
    # Check farmer user too
    farmer_uid = "2qBsMZEOQ0MY1EFfxTz4dgl3s9i1"
    
    print("\n🔵 Checking farmer user in users collection...")
    farmer_user_doc = db.collection('users').document(farmer_uid).get()
    if farmer_user_doc.exists:
        farmer_user_data = farmer_user_doc.to_dict()
        print("✅ Farmer user document found in users collection:")
        print(json.dumps(farmer_user_data, indent=2, default=str))
    else:
        print("❌ Farmer user document not found in users collection")
    
    print("\n🔵 Checking farmers collection...")
    farmer_doc = db.collection('farmers').document(farmer_uid).get()
    if farmer_doc.exists:
        farmer_data = farmer_doc.to_dict()
        print("✅ Farmer document found in farmers collection:")
        print(json.dumps(farmer_data, indent=2, default=str))
    else:
        print("❌ Farmer document not found in farmers collection")

if __name__ == "__main__":
    print("🧪 Checking Firebase User Data")
    print("=" * 50)
    
    try:
        check_firebase_user()
        print("\n✅ Check completed!")
    except Exception as e:
        print(f"❌ Check failed with error: {e}")
