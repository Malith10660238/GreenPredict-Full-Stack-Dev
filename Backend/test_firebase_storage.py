import firebase_admin
from firebase_admin import credentials, storage
import os

def test_firebase_storage():
    """Test Firebase Storage availability"""
    try:
        print("🔍 Testing Firebase Storage availability...")
        
        # Initialize Firebase if not already initialized
        if not firebase_admin._apps:
            print("Initializing Firebase...")
            service_account_path = "serviceAccountKey.json"
            if os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred, {
                    'storageBucket': 'green-predict.appspot.com'
                })
                print("✅ Firebase initialized")
            else:
                print("❌ Service account key not found")
                return
        
        print("✅ Firebase is initialized")
        
        # Try to get the storage bucket
        try:
            bucket = storage.bucket()
            print(f"✅ Storage bucket available: {bucket.name}")
            
            # Try to list files (this will fail if storage is not enabled)
            try:
                blobs = list(bucket.list_blobs(max_results=1))
                print("✅ Storage bucket is accessible")
            except Exception as e:
                print(f"⚠️ Storage bucket exists but may not be properly configured: {e}")
                
        except Exception as e:
            print(f"❌ Storage bucket not available: {e}")
            print("This usually means Firebase Storage is not enabled in your Firebase project")
            
    except Exception as e:
        print(f"❌ Error testing Firebase Storage: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_firebase_storage()
