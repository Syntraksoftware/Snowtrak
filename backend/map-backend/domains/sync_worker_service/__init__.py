"""Sync worker service boundary package.

Owns scheduled and manual OpenSkiMap ingest jobs.
"""
from .job import run_openskimap_sync

__all__ = ["run_openskimap_sync"]
