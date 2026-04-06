"""Compatibility shim for elevation_dem_service external dependencies."""

from domains.elevation_dem_service.infra import correct_dem_batch

batch_correct = correct_dem_batch

__all__ = ["batch_correct", "correct_dem_batch"]
