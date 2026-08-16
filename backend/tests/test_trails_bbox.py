"""Unit tests for trails_service bbox parsing."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "map-backend"))

from domains.trails_service.bbox import parse_bbox


def test_parse_bbox_valid() -> None:
    assert parse_bbox("8.0,47.0,9.0,48.0") == (8.0, 47.0, 9.0, 48.0)


def test_parse_bbox_rejects_wrong_part_count() -> None:
    with pytest.raises(ValueError, match="four comma-separated"):
        parse_bbox("1,2,3")


def test_parse_bbox_rejects_inverted_envelope() -> None:
    with pytest.raises(ValueError, match="min_lon"):
        parse_bbox("9,47,8,48")
