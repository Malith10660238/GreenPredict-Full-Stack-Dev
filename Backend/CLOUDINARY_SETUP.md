# 🚀 Cloudinary Setup Guide for GreenPredict

## **Step 1: Get Cloudinary Credentials**

1. **Sign up at [cloudinary.com](https://cloudinary.com)**
2. **Go to your Dashboard**
3. **Copy your credentials:**
   - Cloud Name
   - API Key  
   - API Secret

## **Step 2: Update Environment Variables**

Add these to your `.env` file in the Backend directory:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your-cloudinary-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-api-key
CLOUDINARY_API_SECRET=your-cloudinary-api-secret
```

## **Step 3: Test the Integration**

1. **Start your backend server:**
   ```bash
   cd Backend
   python main_firebase.py
   ```

2. **Test profile image upload:**
   - Use the `/profile/upload-image` endpoint
   - Check if images appear in your Cloudinary dashboard

3. **Test listing image upload:**
   - Use the `/listings/upload-images` endpoint
   - Verify images are stored in `greenpredict/listing_images/` folder

## **Step 4: Benefits You'll Get**

✅ **25GB free storage** (vs local storage limitations)  
✅ **Automatic image optimization** and resizing  
✅ **Global CDN** for fast image delivery  
✅ **Transform images on-the-fly** (thumbnails, crops, filters)  
✅ **Better scalability** than local storage  
✅ **Professional image management** features  

## **Step 5: Image Organization in Cloudinary**

Your images will be organized as:
```
greenpredict/
├── profile_images/
│   └── profile_{user_id}
├── listing_images/
│   └── listing_{listing_id}
└── chat_images/
    └── chat_{inquiry_id}_{sender_id}
```

## **Step 6: URL Examples**

After upload, you'll get URLs like:
```
https://res.cloudinary.com/your-cloud-name/image/upload/v1234567890/greenpredict/profile_images/profile_user123.jpg
```

## **Step 7: Frontend Integration**

The frontend will automatically:
- Upload images to Cloudinary via backend
- Display images from Cloudinary URLs
- Handle image optimization automatically

## **Troubleshooting**

### Issue: "Cloudinary not configured"
**Solution:** Check your `.env` file has the correct Cloudinary credentials

### Issue: "Upload failed"
**Solution:** Verify your Cloudinary account is active and has sufficient quota

### Issue: "Images not displaying"
**Solution:** Check if the URLs are accessible and properly formatted

---

**Ready to test! Your GreenPredict app now uses Cloudinary for professional image management! 🎉**
