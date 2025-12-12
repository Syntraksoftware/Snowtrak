"""Authentication middleware for JWT verification."""
from functools import wraps
from flask import request, jsonify
import jwt
from config import get_config

config = get_config()


def token_required(f):
    """
    Decorator to require valid JWT token for routes.
    
    Extracts user_id from token and passes it to the route function.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from Authorization header
        if "Authorization" in request.headers:
            auth_header = request.headers["Authorization"]
            try:
                # Format: "Bearer <token>"
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({"error": "Invalid authorization header format"}), 401
        
        if not token:
            return jsonify({"error": "Token is missing"}), 401
        
        try:
            # Decode JWT token
            payload = jwt.decode(
                token,
                config.JWT_SECRET,
                algorithms=[config.JWT_ALGORITHM]
            )
            
            # Extract user_id from token
            user_id = payload.get("sub")
            if not user_id:
                return jsonify({"error": "Invalid token payload"}), 401
            
            # Pass user_id to the route function
            return f(user_id=user_id, *args, **kwargs)
            
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token has expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid token"}), 401
        except Exception as e:
            return jsonify({"error": f"Authentication error: {str(e)}"}), 401
    
    return decorated


def optional_token(f):
    """
    Decorator for routes where authentication is optional.
    
    If token is present and valid, user_id is passed; otherwise user_id is None.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        user_id = None
        
        # Get token from Authorization header
        if "Authorization" in request.headers:
            auth_header = request.headers["Authorization"]
            try:
                token = auth_header.split(" ")[1]
                payload = jwt.decode(
                    token,
                    config.JWT_SECRET,
                    algorithms=[config.JWT_ALGORITHM]
                )
                user_id = payload.get("sub")
            except:
                pass  # Silently ignore invalid tokens for optional auth
        
        return f(user_id=user_id, *args, **kwargs)
    
    return decorated
