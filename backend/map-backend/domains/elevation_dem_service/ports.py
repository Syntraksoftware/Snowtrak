"""Port contracts for elevation_dem_service."""

from collections.abc import Sequence
from typing import Protocol

import numpy as np


class DemBatchProvider(Protocol):
    """Provider that returns DEM elevations for WGS84 points."""

    def __call__(
        self,
        points: Sequence[tuple[float, float]] | np.ndarray,
        *,
        cache_dir=None,
        ensure_tiles: bool = True,
    ) -> np.ndarray: ...


_batch_correct_provider: DemBatchProvider | None = None


def set_batch_correct_provider(provider: DemBatchProvider) -> None:
    """Register the runtime implementation for DEM batch correction."""
    global _batch_correct_provider
    _batch_correct_provider = provider


def batch_correct(
    points: Sequence[tuple[float, float]] | np.ndarray,
    *,
    cache_dir=None,
    ensure_tiles: bool = True,
) -> np.ndarray:
    """Run DEM batch correction through the configured provider."""
    if _batch_correct_provider is None:
        raise RuntimeError("DEM batch provider is not configured")
    return _batch_correct_provider(points, ensure_tiles=ensure_tiles)
