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
