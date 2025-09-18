"""
Firebase Storage service for handling file uploads
"""
import firebase_admin
from firebase_admin import storage
import os
import uuid
from typing import Optional
import base64
from io import BytesIO
from PIL import Image

class StorageService:
    def __init__(self):
        """Initialize Firebase Storage"""
        self._bucket = None
    
    @property
    def bucket(self):
        """Get Firebase Storage bucket (lazy initialization)"""
        if self._bucket is None:
            if not firebase_admin._apps:
                raise Exception("Firebase Admin SDK not initialized")
            self._bucket = storage.bucket()
        return self._bucket
    
    async def upload_profile_image(
        self, 
        user_id: str, 
        image_data: bytes, 
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload profile image to Firebase Storage
        
        Args:
            user_id: User ID
            image_data: Image file data
            content_type: MIME type of the image
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        try:
            # Generate unique filename
            file_extension = "jpg" if "jpeg" in content_type else "png"
            filename = f"profile_images/{user_id}/{uuid.uuid4()}.{file_extension}"
            
            # Create blob
            blob = self.bucket.blob(filename)
            
            # Set content type
            blob.content_type = content_type
            
            # Upload the image
            blob.upload_from_string(image_data, content_type=content_type)
            
            # Make the blob publicly accessible
            blob.make_public()
            
            # Return the public URL
            return blob.public_url
            
        except Exception as e:
            print(f"Error uploading profile image: {e}")
            return None
    
    async def delete_profile_image(self, image_url: str) -> bool:
        """
        Delete profile image from Firebase Storage
        
        Args:
            image_url: Public URL of the image to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Extract blob name from URL
            blob_name = image_url.split('/')[-1]
            blob_path = f"profile_images/{blob_name}"
            
            # Get blob and delete
            blob = self.bucket.blob(blob_path)
            blob.delete()
            
            return True
            
        except Exception as e:
            print(f"Error deleting profile image: {e}")
            return False
    
    async def resize_image(self, image_data: bytes, max_size: tuple = (500, 500)) -> bytes:
        """
        Resize image to specified dimensions
        
        Args:
            image_data: Original image data
            max_size: Maximum dimensions (width, height)
            
        Returns:
            Resized image data
        """
        try:
            # Open image
            image = Image.open(BytesIO(image_data))
            
            # Convert to RGB if necessary
            if image.mode in ('RGBA', 'LA', 'P'):
                image = image.convert('RGB')
            
            # Resize image maintaining aspect ratio
            image.thumbnail(max_size, Image.Resampling.LANCZOS)
            
            # Save to bytes
            output = BytesIO()
            image.save(output, format='JPEG', quality=85, optimize=True)
            
            return output.getvalue()
            
        except Exception as e:
            print(f"Error resizing image: {e}")
            return image_data

# Global storage service instance
storage_service = StorageService()
