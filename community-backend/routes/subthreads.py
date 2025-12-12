"""Subthread routes."""
from flask import Blueprint, request, jsonify
from middleware.auth import token_required, optional_token
from services.supabase_client import get_community_client

subthreads_bp = Blueprint("subthreads", __name__)


@subthreads_bp.route("", methods=["GET"])
def list_subthreads():
    """List all subthreads."""
    try:
        limit = request.args.get("limit", 50, type=int)
        client = get_community_client()
        subthreads = client.list_subthreads(limit=limit)
        
        return jsonify({
            "subthreads": subthreads,
            "total": len(subthreads)
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@subthreads_bp.route("", methods=["POST"])
@token_required
def create_subthread(user_id):
    """Create a new subthread (authenticated)."""
    try:
        data = request.get_json()
        
        if not data or "name" not in data:
            return jsonify({"error": "name is required"}), 400
        
        name = data["name"]
        description = data.get("description")
        
        client = get_community_client()
        result = client.create_subthread(name=name, description=description)
        
        if not result:
            return jsonify({"error": "Failed to create subthread"}), 500
        
        return jsonify(result), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@subthreads_bp.route("/<subthread_id>", methods=["GET"])
def get_subthread(subthread_id):
    """Get subthread by ID."""
    try:
        client = get_community_client()
        subthread = client.get_subthread_by_id(subthread_id)
        
        if not subthread:
            return jsonify({"error": "Subthread not found"}), 404
        
        return jsonify(subthread), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@subthreads_bp.route("/<subthread_id>/posts", methods=["GET"])
def list_subthread_posts(subthread_id):
    """List posts in a subthread."""
    try:
        limit = request.args.get("limit", 20, type=int)
        offset = request.args.get("offset", 0, type=int)
        
        client = get_community_client()
        
        # Verify subthread exists
        subthread = client.get_subthread_by_id(subthread_id)
        if not subthread:
            return jsonify({"error": "Subthread not found"}), 404
        
        posts = client.list_posts_by_subthread(
            subthread_id=subthread_id,
            limit=limit,
            offset=offset
        )
        total = client.count_posts_by_subthread(subthread_id)
        
        return jsonify({
            "posts": posts,
            "total": total,
            "page": offset // limit + 1,
            "page_size": limit
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@subthreads_bp.route("/<subthread_id>", methods=["DELETE"])
@token_required
def delete_subthread(user_id, subthread_id):
    """Delete a subthread and all its posts/comments (authenticated, admin only in production)."""
    try:
        client = get_community_client()
        
        # Note: In production, add admin/moderator check here
        # For now, any authenticated user can delete
        
        success = client.delete_subthread(subthread_id)
        
        if not success:
            return jsonify({"error": "Subthread not found"}), 404
        
        return jsonify({
            "message": "Subthread, posts, and comments deleted successfully",
            "deleted_subthread_id": subthread_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
