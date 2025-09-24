"""
Local file storage service for handling image uploads
This is a FREE alternative to Firebase Storage
"""
import os
import uuid
import shutil
from typing import Optional
from PIL import Image
from io import BytesIO
from fastapi import HTTPException
import aiofiles

class LocalStorageService:
    def __init__(self, upload_dir: str = "uploads"):
        """Initialize local storage service"""
        self.upload_dir = upload_dir
        self.base_url = "http://localhost:8001"  # Your FastAPI server URL
        
        # Create upload directories if they don't exist
        os.makedirs(f"{upload_dir}/profile_images", exist_ok=True)
        os.makedirs(f"{upload_dir}/listing_images", exist_ok=True)
    
    async def upload_profile_image(
        self, 
        user_id: str, 
        image_data: bytes, 
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload profile image to local storage
        
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
            filename = f"{uuid.uuid4()}.{file_extension}"
            file_path = f"{self.upload_dir}/profile_images/{filename}"
            
            # Resize image to save space
            resized_data = await self._resize_image(image_data, max_size=(500, 500))
            
            # Save image to local storage
            async with aiofiles.open(file_path, 'wb') as f:
                await f.write(resized_data)
            
            # Return the public URL
            return f"{self.base_url}/static/profile_images/{filename}"
            
        except Exception as e:
            print(f"Error uploading profile image: {e}")
            return None
    
    async def upload_listing_image(
        self, 
        listing_id: str, 
        image_data: bytes, 
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload listing image to local storage
        
        Args:
            listing_id: Listing ID
            image_data: Image file data
            content_type: MIME type of the image
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        try:
            # Generate unique filename
            file_extension = "jpg" if "jpeg" in content_type else "png"
            filename = f"{uuid.uuid4()}.{file_extension}"
            file_path = f"{self.upload_dir}/listing_images/{filename}"
            
            # Resize image to save space
            resized_data = await self._resize_image(image_data, max_size=(800, 600))
            
            # Save image to local storage
            async with aiofiles.open(file_path, 'wb') as f:
                await f.write(resized_data)
            
            # Return the public URL
            return f"{self.base_url}/static/listing_images/{filename}"
            
        except Exception as e:
            print(f"Error uploading listing image: {e}")
            return None
    
    async def delete_image(self, image_url: str) -> bool:
        """
        Delete image from local storage
        
        Args:
            image_url: Public URL of the image to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Extract filename from URL
            filename = image_url.split('/')[-1]
            
            # Determine which directory the image is in
            if 'profile_images' in image_url:
                file_path = f"{self.upload_dir}/profile_images/{filename}"
            elif 'listing_images' in image_url:
                file_path = f"{self.upload_dir}/listing_images/{filename}"
            else:
                return False
            
            # Delete the file
            if os.path.exists(file_path):
                os.remove(file_path)
                return True
            
            return False
            
        except Exception as e:
            print(f"Error deleting image: {e}")
            return False
    
    async def _resize_image(self, image_data: bytes, max_size: tuple = (500, 500)) -> bytes:
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
local_storage_service = LocalStorageService()
