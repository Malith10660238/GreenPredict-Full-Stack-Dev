"""
Cloudinary service for handling image uploads and management
Replaces local storage with cloud-based image management
"""
import cloudinary
import cloudinary.uploader
import cloudinary.api
from typing import Optional
import os
from dotenv import load_dotenv

load_dotenv()

class CloudinaryService:
    def __init__(self):
        """Initialize Cloudinary with credentials from environment"""
        cloudinary.config(
            cloud_name=os.getenv('CLOUDINARY_CLOUD_NAME'),
            api_key=os.getenv('CLOUDINARY_API_KEY'),
            api_secret=os.getenv('CLOUDINARY_API_SECRET'),
            secure=True
        )
    
    async def upload_profile_image(
        self, 
        user_id: str, 
        image_data: bytes, 
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload profile image to Cloudinary
        
        Args:
            user_id: User ID
            image_data: Image file data
            content_type: MIME type of the image
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        try:
            # Upload to Cloudinary with transformations
            result = cloudinary.uploader.upload(
                image_data,
                folder="greenpredict/profile_images",
                public_id=f"profile_{user_id}",
                transformation=[
                    {'width': 500, 'height': 500, 'crop': 'fill', 'gravity': 'face'},
                    {'quality': 'auto', 'fetch_format': 'auto'}
                ],
                resource_type="image"
            )
            
            return result.get('secure_url')
            
        except Exception as e:
            print(f"Error uploading profile image to Cloudinary: {e}")
            return None
    
    async def upload_listing_image(
        self, 
        listing_id: str, 
        image_data: bytes, 
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload listing image to Cloudinary
        
        Args:
            listing_id: Listing ID
            image_data: Image file data
            content_type: MIME type of the image
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        try:
            # Upload to Cloudinary with transformations
            result = cloudinary.uploader.upload(
                image_data,
                folder="greenpredict/listing_images",
                public_id=f"listing_{listing_id}",
                transformation=[
                    {'width': 800, 'height': 600, 'crop': 'fill', 'gravity': 'auto'},
                    {'quality': 'auto', 'fetch_format': 'auto'}
                ],
                resource_type="image"
            )
            
            return result.get('secure_url')
            
        except Exception as e:
            print(f"Error uploading listing image to Cloudinary: {e}")
            return None
    
    async def upload_chat_image(
        self, 
        inquiry_id: str, 
        sender_id: str,
        image_data: bytes, 
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload chat image to Cloudinary
        
        Args:
            inquiry_id: Inquiry ID
            sender_id: Sender ID
            image_data: Image file data
            content_type: MIME type of the image
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        try:
            # Upload to Cloudinary with transformations
            result = cloudinary.uploader.upload(
                image_data,
                folder="greenpredict/chat_images",
                public_id=f"chat_{inquiry_id}_{sender_id}",
                transformation=[
                    {'width': 400, 'height': 400, 'crop': 'fill', 'gravity': 'auto'},
                    {'quality': 'auto', 'fetch_format': 'auto'}
                ],
                resource_type="image"
            )
            
            return result.get('secure_url')
            
        except Exception as e:
            print(f"Error uploading chat image to Cloudinary: {e}")
            return None
    
    async def delete_image(self, image_url: str) -> bool:
        """
        Delete image from Cloudinary
        
        Args:
            image_url: Public URL of the image to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Extract public_id from URL
            # Cloudinary URLs format: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{public_id}.{format}
            parts = image_url.split('/')
            if len(parts) >= 9 and 'cloudinary.com' in image_url:
                public_id_with_version = parts[-1].split('.')[0]  # Remove file extension
                # Remove version prefix if present
                if public_id_with_version.startswith('v'):
                    public_id = '/'.join(parts[-2:]).split('.')[0]
                else:
                    public_id = '/'.join(parts[-2:]).split('.')[0]
                
                # Delete from Cloudinary
                result = cloudinary.uploader.destroy(public_id)
                return result.get('result') == 'ok'
            
            return False
            
        except Exception as e:
            print(f"Error deleting image from Cloudinary: {e}")
            return False
    
    def get_optimized_url(self, image_url: str, width: int = None, height: int = None, quality: str = 'auto') -> str:
        """
        Get optimized image URL with transformations
        
        Args:
            image_url: Original Cloudinary URL
            width: Desired width
            height: Desired height
            quality: Image quality ('auto', 'best', 'good', 'eco', 'low')
            
        Returns:
            Optimized image URL
        """
        try:
            # Parse the URL to get public_id
            if 'cloudinary.com' not in image_url:
                return image_url
            
            # Build transformation parameters
            transformations = []
            if width or height:
                crop_params = []
                if width:
                    crop_params.append(f"w_{width}")
                if height:
                    crop_params.append(f"h_{height}")
                transformations.append(f"c_fill,{','.join(crop_params)}")
            
            if quality:
                transformations.append(f"q_{quality}")
            
            transformations.append("f_auto")  # Auto format
            
            # Insert transformations into URL
            if transformations:
                # Find the upload part and insert transformations
                if '/upload/' in image_url:
                    base_url = image_url.split('/upload/')[0]
                    rest_url = image_url.split('/upload/')[1]
                    return f"{base_url}/upload/{','.join(transformations)}/{rest_url}"
            
            return image_url
            
        except Exception as e:
            print(f"Error optimizing image URL: {e}")
            return image_url

# Global Cloudinary service instance
cloudinary_service = CloudinaryService()
