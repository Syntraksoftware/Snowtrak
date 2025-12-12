"""Comment routes."""
from flask import Blueprint, request, jsonify
from middleware.auth import token_required
from services.supabase_client import get_community_client

comments_bp = Blueprint("comments", __name__)


@comments_bp.route("", methods=["POST"])
@token_required
def create_comment(user_id):
    """Create a new comment (authenticated)."""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data or "post_id" not in data or "content" not in data:
            return jsonify({"error": "post_id and content are required"}), 400
        
        client = get_community_client()
        
        # Verify post exists
        post = client.get_post_by_id(data["post_id"])
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        # If parent_id is provided, verify it exists
        parent_id = data.get("parent_id")
        if parent_id:
            parent = client.get_comment_by_id(parent_id)
            if not parent:
                return jsonify({"error": "Parent comment not found"}), 404
        
        result = client.create_comment(
            user_id=user_id,
            post_id=data["post_id"],
            content=data["content"],
            parent_id=parent_id
        )
        
        if not result:
            return jsonify({"error": "Failed to create comment"}), 500
        
        return jsonify(result), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@comments_bp.route("/<comment_id>", methods=["GET"])
def get_comment(comment_id):
    """Get comment by ID."""
    try:
        client = get_community_client()
        comment = client.get_comment_by_id(comment_id)
        
        if not comment:
            return jsonify({"error": "Comment not found"}), 404
        
        return jsonify(comment), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
