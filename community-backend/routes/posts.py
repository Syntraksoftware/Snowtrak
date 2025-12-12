"""Post routes."""
from flask import Blueprint, request, jsonify
from middleware.auth import token_required, optional_token
from services.supabase_client import get_community_client

posts_bp = Blueprint("posts", __name__)


@posts_bp.route("", methods=["POST"])
@token_required
def create_post(user_id):
    """Create a new post (authenticated)."""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ["subthread_id", "title", "content"]
        for field in required_fields:
            if not data or field not in data:
                return jsonify({"error": f"{field} is required"}), 400
        
        client = get_community_client()
        
        # Verify subthread exists
        subthread = client.get_subthread_by_id(data["subthread_id"])
        if not subthread:
            return jsonify({"error": "Subthread not found"}), 404
        
        result = client.create_post(
            user_id=user_id,
            subthread_id=data["subthread_id"],
            title=data["title"],
            content=data["content"]
        )
        
        if not result:
            return jsonify({"error": "Failed to create post"}), 500
        
        return jsonify(result), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@posts_bp.route("/<post_id>", methods=["GET"])
def get_post(post_id):
    """Get post by ID."""
    try:
        client = get_community_client()
        post = client.get_post_by_id(post_id)
        
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        return jsonify(post), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@posts_bp.route("/<post_id>/comments", methods=["GET"])
def list_post_comments(post_id):
    """List all comments for a post."""
    try:
        client = get_community_client()
        
        # Verify post exists
        post = client.get_post_by_id(post_id)
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        comments = client.list_comments_by_post(post_id)
        total = client.count_comments_by_post(post_id)
        
        return jsonify({
            "comments": comments,
            "total": total,
            "post_id": post_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
