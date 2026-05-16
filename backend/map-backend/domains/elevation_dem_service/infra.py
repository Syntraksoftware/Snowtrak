"""Infrastructure implementations for elevation_dem_service ports."""

import numpy as np

from services.dem_service import batch_correct


def correct_dem_batch(coords: np.ndarray, *, ensure_tiles: bool = True) -> np.ndarray:
    """Run DEM batch correction through the default provider."""
    return batch_correct(coords, ensure_tiles=ensure_tiles)
