#!/usr/bin/env python3
"""
Migration script to upload existing local images to Cloudinary
This will upload all your existing local images to Cloudinary automatically
"""

import os
import asyncio
from pathlib import Path
from cloudinary_service import cloudinary_service
from dotenv import load_dotenv

load_dotenv()

async def migrate_profile_images():
    """Migrate all existing profile images to Cloudinary"""
    print("Starting migration of profile images to Cloudinary...")
    
    profile_images_dir = Path("uploads/profile_images")
    if not profile_images_dir.exists():
        print("ERROR: No profile images directory found")
        return []
    
    migrated_urls = []
    image_files = list(profile_images_dir.glob("*.jpg")) + list(profile_images_dir.glob("*.png"))
    
    if not image_files:
        print("ERROR: No profile images found to migrate")
        return []
    
    print(f"Found {len(image_files)} profile images to migrate")
    
    for i, image_path in enumerate(image_files, 1):
        try:
            print(f"Uploading image {i}/{len(image_files)}: {image_path.name}")
            
            # Read the image file
            with open(image_path, 'rb') as f:
                image_data = f.read()
            
            # Extract user ID from filename (format: userid_uuid.jpg)
            filename = image_path.stem
            if '_' in filename:
                user_id = filename.split('_')[0]
            else:
                user_id = filename  # fallback
            
            # Upload to Cloudinary
            cloudinary_url = await cloudinary_service.upload_profile_image(
                user_id=user_id,
                image_data=image_data,
                content_type="image/jpeg"
            )
            
            if cloudinary_url:
                migrated_urls.append({
                    'local_path': str(image_path),
                    'cloudinary_url': cloudinary_url,
                    'user_id': user_id
                })
                print(f"SUCCESS: Uploaded: {cloudinary_url}")
            else:
                print(f"ERROR: Failed to upload: {image_path.name}")
                
        except Exception as e:
            print(f"ERROR: Error uploading {image_path.name}: {e}")
    
    return migrated_urls

async def migrate_listing_images():
    """Migrate all existing listing images to Cloudinary"""
    print("Starting migration of listing images to Cloudinary...")
    
    listing_images_dir = Path("uploads/listing_images")
    if not listing_images_dir.exists():
        print("ERROR: No listing images directory found")
        return []
    
    migrated_urls = []
    image_files = list(listing_images_dir.glob("*.jpg")) + list(listing_images_dir.glob("*.png"))
    
    if not image_files:
        print("ERROR: No listing images found to migrate")
        return []
    
    print(f"Found {len(image_files)} listing images to migrate")
    
    for i, image_path in enumerate(image_files, 1):
        try:
            print(f"Uploading image {i}/{len(image_files)}: {image_path.name}")
            
            # Read the image file
            with open(image_path, 'rb') as f:
                image_data = f.read()
            
            # Generate a temporary listing ID
            import uuid
            listing_id = f"migrated_{uuid.uuid4()}"
            
            # Upload to Cloudinary
            cloudinary_url = await cloudinary_service.upload_listing_image(
                listing_id=listing_id,
                image_data=image_data,
                content_type="image/jpeg"
            )
            
            if cloudinary_url:
                migrated_urls.append({
                    'local_path': str(image_path),
                    'cloudinary_url': cloudinary_url,
                    'listing_id': listing_id
                })
                print(f"SUCCESS: Uploaded: {cloudinary_url}")
            else:
                print(f"ERROR: Failed to upload: {image_path.name}")
                
        except Exception as e:
            print(f"ERROR: Error uploading {image_path.name}: {e}")
    
    return migrated_urls

def create_migration_report(profile_migrations, listing_migrations):
    """Create a report of all migrated images"""
    report_path = "migration_report.txt"
    
    with open(report_path, 'w') as f:
        f.write("Cloudinary Migration Report\n")
        f.write("=" * 50 + "\n\n")
        
        f.write(f"Profile Images Migrated: {len(profile_migrations)}\n")
        for migration in profile_migrations:
            f.write(f"  - User: {migration['user_id']}\n")
            f.write(f"    Local: {migration['local_path']}\n")
            f.write(f"    Cloudinary: {migration['cloudinary_url']}\n\n")
        
        f.write(f"Listing Images Migrated: {len(listing_migrations)}\n")
        for migration in listing_migrations:
            f.write(f"  - Listing: {migration['listing_id']}\n")
            f.write(f"    Local: {migration['local_path']}\n")
            f.write(f"    Cloudinary: {migration['cloudinary_url']}\n\n")
        
        f.write("Migration completed successfully!\n")
        f.write("You can now safely delete the local images.\n")
    
    print(f"Migration report saved to: {report_path}")

async def main():
    """Main migration function"""
    print("Starting Cloudinary Migration")
    print("=" * 50)
    
    # Migrate profile images
    profile_migrations = await migrate_profile_images()
    
    # Migrate listing images
    listing_migrations = await migrate_listing_images()
    
    # Create migration report
    create_migration_report(profile_migrations, listing_migrations)
    
    print("\n" + "=" * 50)
    print("Migration completed!")
    print(f"Profile images migrated: {len(profile_migrations)}")
    print(f"Listing images migrated: {len(listing_migrations)}")
    print("\nCheck 'migration_report.txt' for detailed URLs")
    print("You can now safely delete the local images in 'uploads/' folder")

if __name__ == "__main__":
    asyncio.run(main())
