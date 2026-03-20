"""
Community Backend Server Runner.
Run with: python run.py

Starts the FastAPI+Uvicorn server with configuration from config.py.
All settings (HOST, PORT, DEBUG) can be overridden via .env file.
"""
import uvicorn
from config import Config

if __name__ == "__main__":
    config = Config()
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info" if config.DEBUG else "warning",
    )
