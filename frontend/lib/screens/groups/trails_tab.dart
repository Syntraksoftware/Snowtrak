import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/ski_trail.dart';
import 'package:syntrak/screens/groups/widgets/trail_list_card.dart';
import 'package:syntrak/screens/groups/widgets/trails_filter_sheets.dart';
import 'package:syntrak/screens/groups/widgets/trails_mock_trails.dart';
import 'package:syntrak/screens/groups/widgets/trails_search_bar.dart';

class TrailsTab extends StatefulWidget {
  const TrailsTab({super.key});

  @override
  State<TrailsTab> createState() => _TrailsTabState();
}

class _TrailsTabState extends State<TrailsTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SkiTrail> _trails = [];
  List<SkiTrail> _filteredTrails = [];
  bool _isLoading = false;
  bool _isSearchFocused = false;
  TrailDifficulty? _selectedDifficulty;
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _loadTrails();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrails() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _trails = mockSkiTrails();
        _filteredTrails = _trails;
        _isLoading = false;
      });
    }
  }

  void _filterTrails() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTrails = _trails.where((trail) {
        final matchesSearch = query.isEmpty ||
            trail.name.toLowerCase().contains(query) ||
            trail.resort.toLowerCase().contains(query) ||
            trail.country.toLowerCase().contains(query);

        final matchesDifficulty = _selectedDifficulty == null ||
            trail.difficulty == _selectedDifficulty;

        final matchesCountry =
            _selectedCountry == null || trail.country == _selectedCountry;

        return matchesSearch && matchesDifficulty && matchesCountry;
      }).toList();
    });
  }

  List<String> get _countries {
    return _trails.map((t) => t.country).toSet().toList()..sort();
  }

  Future<void> _pickDifficulty() async {
    await showTrailsDifficultyPicker(
      context,
      selected: _selectedDifficulty,
      onSelected: (d) {
        setState(() => _selectedDifficulty = d);
        _filterTrails();
      },
    );
  }

  Future<void> _pickCountry() async {
    await showTrailsCountryPicker(
      context,
      selected: _selectedCountry,
      countries: _countries,
      onSelected: (c) {
        setState(() => _selectedCountry = c);
        _filterTrails();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrails,
      color: SyntrakColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: TrailsSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isSearchFocused: _isSearchFocused,
              onQueryChanged: _filterTrails,
              onClear: () {
                _searchController.clear();
                _filterTrails();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _FilterChipsRow(
              selectedDifficulty: _selectedDifficulty,
              selectedCountry: _selectedCountry,
              onDifficultyTap: _pickDifficulty,
              onCountryTap: _pickCountry,
              onClearFilters: () {
                setState(() {
                  _selectedDifficulty = null;
                  _selectedCountry = null;
                });
                _filterTrails();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _ResultsHeader(count: _filteredTrails.length),
          ),
          if (_filteredTrails.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No trails match your filters',
                  style: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SyntrakSpacing.md,
                0,
                SyntrakSpacing.md,
                SyntrakSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: SyntrakSpacing.sm),
                      child: TrailListCard(trail: _filteredTrails[index]),
                    );
                  },
                  childCount: _filteredTrails.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedDifficulty,
    required this.selectedCountry,
    required this.onDifficultyTap,
    required this.onCountryTap,
    required this.onClearFilters,
  });

  final TrailDifficulty? selectedDifficulty;
  final String? selectedCountry;
  final VoidCallback onDifficultyTap;
  final VoidCallback onCountryTap;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final isDifficulty = selectedDifficulty != null;
    final isCountry = selectedCountry != null;

    return Container(
      color: SyntrakColors.background,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              children: [
                FilterChip(
                  selected: isDifficulty,
                  showCheckmark: false,
                  avatar: isDifficulty
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Color(selectedDifficulty!.color),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Icon(
                          Icons.terrain,
                          size: 16,
                          color: SyntrakColors.textSecondary,
                        ),
                  label: Text(
                    isDifficulty
                        ? selectedDifficulty!.shortName
                        : 'Difficulty',
                    style: SyntrakTypography.labelMedium.copyWith(
                      color: isDifficulty
                          ? SyntrakColors.primary
                          : SyntrakColors.textSecondary,
                      fontWeight:
                          isDifficulty ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: SyntrakColors.surfaceVariant,
                  selectedColor: SyntrakColors.primary.withAlpha(25),
                  side: BorderSide(
                    color: isDifficulty ? SyntrakColors.primary : Colors.transparent,
                  ),
                  onSelected: (_) => onDifficultyTap(),
                ),
                const SizedBox(width: SyntrakSpacing.sm),
                FilterChip(
                  selected: isCountry,
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.public,
                    size: 16,
                    color: isCountry
                        ? SyntrakColors.primary
                        : SyntrakColors.textSecondary,
                  ),
                  label: Text(
                    isCountry ? selectedCountry! : 'Country',
                    style: SyntrakTypography.labelMedium.copyWith(
                      color: isCountry
                          ? SyntrakColors.primary
                          : SyntrakColors.textSecondary,
                      fontWeight:
                          isCountry ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: SyntrakColors.surfaceVariant,
                  selectedColor: SyntrakColors.primary.withAlpha(25),
                  side: BorderSide(
                    color: isCountry ? SyntrakColors.primary : Colors.transparent,
                  ),
                  onSelected: (_) => onCountryTap(),
                ),
                if (isDifficulty || isCountry) ...[
                  const SizedBox(width: SyntrakSpacing.sm),
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                    onPressed: onClearFilters,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: SyntrakSpacing.sm,
        bottom: SyntrakSpacing.sm,
        left: SyntrakSpacing.md,
        right: SyntrakSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            '$count trails',
            style: SyntrakTypography.labelLarge.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(
              Icons.sort,
              size: 18,
              color: SyntrakColors.textSecondary,
            ),
            label: Text(
              'Sort',
              style: SyntrakTypography.labelMedium.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
