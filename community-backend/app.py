"""
Community Backend - Flask Application

A standalone microservice for Reddit-like community features.
"""
from flask import Flask, jsonify
from flask_cors import CORS
from config import get_config
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__)
config = get_config()

# Configure CORS
CORS(app, resources={
    r"/api/*": {
        "origins": config.CORS_ORIGINS,
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# Import and register blueprints
from routes.subthreads import subthreads_bp
from routes.posts import posts_bp
from routes.comments import comments_bp

app.register_blueprint(subthreads_bp, url_prefix="/api/subthreads")
app.register_blueprint(posts_bp, url_prefix="/api/posts")
app.register_blueprint(comments_bp, url_prefix="/api/comments")


@app.route("/")
def index():
    """Root endpoint."""
    return jsonify({
        "service": "Community Backend",
        "version": "1.0.0",
        "status": "running"
    })


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "community-backend"
    }), 200


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    logger.info(f"Starting Community Backend on port {config.PORT}")
    logger.info(f"Environment: {config.FLASK_ENV}")
    logger.info(f"Debug mode: {config.DEBUG}")
    
    app.run(
        host="0.0.0.0",
        port=config.PORT,
        debug=config.DEBUG
    )
