#!/usr/bin/env python3
"""
Run script for GreenPredict Backend
"""

import uvicorn
import os
from pathlib import Path

if __name__ == "__main__":
    # Get the directory where this script is located
    current_dir = Path(__file__).parent
    
    # Change to the backend directory
    os.chdir(current_dir)
    
    # Run the FastAPI application
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        reload_dirs=[str(current_dir)],
        log_level="info"
    )
