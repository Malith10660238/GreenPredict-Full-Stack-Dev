#!/usr/bin/env python3
"""
Script to check what data is stored in Firebase crop_predictions_ai collection
"""
import firebase_admin
from firebase_admin import credentials, firestore
import os

def check_firebase_data():
    # Initialize Firebase
    if not firebase_admin._apps:
        cred = credentials.Certificate('serviceAccountKey.json')
        firebase_admin.initialize_app(cred)

    db = firestore.client()

    # Check what's actually in the crop_predictions_ai collection
    print('🔍 Checking crop_predictions_ai collection...')
    docs = db.collection('crop_predictions_ai').limit(3).stream()

    for i, doc in enumerate(docs):
        print(f'\n📄 Document {i+1} (ID: {doc.id}):')
        data = doc.to_dict()
        print(f'  - prediction_id: {data.get("prediction_id")}')
        print(f'  - cropType: {data.get("cropType")}')
        print(f'  - location: {data.get("location")}')
        print(f'  - ai_analysis keys: {list(data.get("ai_analysis", {}).keys())}')
        
        ai_analysis = data.get('ai_analysis', {})
        if 'input_parameters' in ai_analysis:
            print(f'  - input_parameters: {ai_analysis["input_parameters"]}')
        if 'current_season' in ai_analysis:
            print(f'  - current_season: {ai_analysis["current_season"]}')
        if 'yield_analysis' in ai_analysis:
            print(f'  - yield_analysis: {ai_analysis["yield_analysis"]}')

if __name__ == "__main__":
    check_firebase_data()
