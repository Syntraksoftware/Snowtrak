# Segmentation Engine

This folder contains the second-stage segmentation pipeline used after GPS ingestion.

Modules:
- `vertical_velocity_computer.dart`: computes smoothed vertical velocity per point.
- `point_classifier.dart`: classifies each point into `PointState`.
- `segment_grouper.dart`: groups consecutive classified points into `RawSegment`s.
- `gap_merger.dart`: merges short flat/pause bridges between descents.
- `trail_matcher.dart`: enriches descent segments with trail name/difficulty from map-backend.
- `segment_detection_engine.dart`: facade that orchestrates vv -> classify -> group -> merge -> match.
