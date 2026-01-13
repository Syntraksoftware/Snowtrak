import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/ski_trail.dart';

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

    // TODO: Fetch from backend API
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _trails = _generateMockTrails();
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

  List<SkiTrail> _generateMockTrails() {
    return [
      SkiTrail(
        id: '1',
        name: 'Peak to Creek',
        resort: 'Whistler Blackcomb',
        country: 'Canada',
        difficulty: TrailDifficulty.blue,
        lengthKm: 11.0,
        elevationDropM: 1609,
        isGroomed: true,
        hasSnowmaking: true,
        description: 'One of the longest runs in North America',
        rating: 4.8,
        reviewCount: 1243,
        features: ['Scenic', 'Long Run', 'Family Friendly'],
      ),
      SkiTrail(
        id: '2',
        name: 'Corbet\'s Couloir',
        resort: 'Jackson Hole',
        country: 'USA',
        difficulty: TrailDifficulty.doubleBlack,
        lengthKm: 0.5,
        elevationDropM: 150,
        isGroomed: false,
        description: 'Legendary expert-only chute with a mandatory air entry',
        rating: 4.9,
        reviewCount: 892,
        features: ['Expert Only', 'Cliff Drop', 'Iconic'],
      ),
      SkiTrail(
        id: '3',
        name: 'La Sarenne',
        resort: 'Alpe d\'Huez',
        country: 'France',
        difficulty: TrailDifficulty.black,
        lengthKm: 16.0,
        elevationDropM: 1800,
        isGroomed: true,
        description: 'One of the longest black runs in the world',
        rating: 4.7,
        reviewCount: 567,
        features: ['Long Run', 'Alpine Views', 'Challenging'],
      ),
      SkiTrail(
        id: '4',
        name: 'Harakiri',
        resort: 'Mayrhofen',
        country: 'Austria',
        difficulty: TrailDifficulty.black,
        lengthKm: 1.5,
        elevationDropM: 380,
        isGroomed: true,
        description: 'Austria\'s steepest groomed slope at 78% gradient',
        rating: 4.6,
        reviewCount: 445,
        features: ['Steep', 'Groomed', 'Challenge'],
      ),
      SkiTrail(
        id: '5',
        name: 'Big Easy',
        resort: 'Vail',
        country: 'USA',
        difficulty: TrailDifficulty.green,
        lengthKm: 2.5,
        elevationDropM: 200,
        isGroomed: true,
        hasSnowmaking: true,
        description: 'Perfect beginner run with gentle slopes',
        rating: 4.5,
        reviewCount: 678,
        features: ['Beginner Friendly', 'Wide', 'Well Groomed'],
      ),
      SkiTrail(
        id: '6',
        name: 'Vallée Blanche',
        resort: 'Chamonix',
        country: 'France',
        difficulty: TrailDifficulty.red,
        lengthKm: 20.0,
        elevationDropM: 2800,
        isGroomed: false,
        description: 'Famous off-piste glacier route with stunning views',
        rating: 4.9,
        reviewCount: 1567,
        features: ['Off-Piste', 'Glacier', 'Guide Required', 'Epic Views'],
      ),
      SkiTrail(
        id: '7',
        name: 'Niseko Super Course',
        resort: 'Niseko United',
        country: 'Japan',
        difficulty: TrailDifficulty.blue,
        lengthKm: 5.6,
        elevationDropM: 889,
        isGroomed: true,
        description: 'Famous for legendary powder snow',
        rating: 4.8,
        reviewCount: 923,
        features: ['Powder', 'Tree Runs', 'Night Skiing'],
      ),
      SkiTrail(
        id: '8',
        name: 'Streif',
        resort: 'Kitzbühel',
        country: 'Austria',
        difficulty: TrailDifficulty.doubleBlack,
        lengthKm: 3.3,
        elevationDropM: 860,
        isGroomed: true,
        description: 'Most dangerous downhill ski race course in the world',
        rating: 4.7,
        reviewCount: 334,
        features: ['World Cup', 'Iconic', 'Expert Only'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Strava-style search bar
        _buildSearchSection(),
        // Results count and sort
        _buildResultsHeader(),
        // Trail list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTrails,
            color: SyntrakColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              itemCount: _filteredTrails.length,
              itemBuilder: (context, index) {
                return _TrailCard(trail: _filteredTrails[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: SyntrakColors.surface,
      child: Column(
        children: [
          // Strava-style search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.sm,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isSearchFocused
                    ? SyntrakColors.surface
                    : SyntrakColors.surfaceVariant,
                borderRadius: BorderRadius.circular(SyntrakRadius.round),
                border: Border.all(
                  color: _isSearchFocused
                      ? SyntrakColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: _isSearchFocused
                    ? [
                        BoxShadow(
                          color: SyntrakColors.primary.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (_) => _filterTrails(),
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search trails, resorts...',
                  hintStyle: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isSearchFocused
                        ? SyntrakColors.primary
                        : SyntrakColors.textTertiary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: SyntrakColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterTrails();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SyntrakSpacing.md,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          // Filter chips - horizontal scroll
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
              children: [
                _buildDifficultyChip(),
                const SizedBox(width: SyntrakSpacing.sm),
                _buildCountryChip(),
                if (_selectedDifficulty != null || _selectedCountry != null) ...[
                  const SizedBox(width: SyntrakSpacing.sm),
                  _buildClearFiltersChip(),
                ],
              ],
            ),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip() {
    final isSelected = _selectedDifficulty != null;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: isSelected
          ? Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Color(_selectedDifficulty!.color),
                shape: BoxShape.circle,
              ),
            )
          : Icon(
              Icons.terrain,
              size: 16,
              color: SyntrakColors.textSecondary,
            ),
      label: Text(
        isSelected ? _selectedDifficulty!.shortName : 'Difficulty',
        style: SyntrakTypography.labelMedium.copyWith(
          color: isSelected ? SyntrakColors.primary : SyntrakColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor: SyntrakColors.surfaceVariant,
      selectedColor: SyntrakColors.primary.withAlpha(25),
      side: BorderSide(
        color: isSelected ? SyntrakColors.primary : Colors.transparent,
      ),
      onSelected: (_) => _showDifficultyPicker(),
    );
  }

  Widget _buildCountryChip() {
    final isSelected = _selectedCountry != null;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        Icons.public,
        size: 16,
        color: isSelected ? SyntrakColors.primary : SyntrakColors.textSecondary,
      ),
      label: Text(
        isSelected ? _selectedCountry! : 'Country',
        style: SyntrakTypography.labelMedium.copyWith(
          color: isSelected ? SyntrakColors.primary : SyntrakColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor: SyntrakColors.surfaceVariant,
      selectedColor: SyntrakColors.primary.withAlpha(25),
      side: BorderSide(
        color: isSelected ? SyntrakColors.primary : Colors.transparent,
      ),
      onSelected: (_) => _showCountryPicker(),
    );
  }

  Widget _buildClearFiltersChip() {
    return ActionChip(
      avatar: const Icon(Icons.close, size: 16),
      label: const Text('Clear'),
      onPressed: () {
        setState(() {
          _selectedDifficulty = null;
          _selectedCountry = null;
        });
        _filterTrails();
      },
    );
  }

  void _showDifficultyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SyntrakColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SyntrakRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SyntrakSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SyntrakColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            Text(
              'Select Difficulty',
              style: SyntrakTypography.headlineSmall,
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('All Difficulties'),
              selected: _selectedDifficulty == null,
              onTap: () {
                setState(() => _selectedDifficulty = null);
                _filterTrails();
                Navigator.pop(context);
              },
            ),
            ...TrailDifficulty.values.map((d) => ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(d.color),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        d.icon,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  title: Text(d.displayName),
                  selected: _selectedDifficulty == d,
                  onTap: () {
                    setState(() => _selectedDifficulty = d);
                    _filterTrails();
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: SyntrakSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SyntrakColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SyntrakRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SyntrakSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SyntrakColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: SyntrakSpacing.md),
            Text(
              'Select Country',
              style: SyntrakTypography.headlineSmall,
            ),
            const SizedBox(height: SyntrakSpacing.md),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('All Countries'),
              selected: _selectedCountry == null,
              onTap: () {
                setState(() => _selectedCountry = null);
                _filterTrails();
                Navigator.pop(context);
              },
            ),
            ..._countries.map((c) => ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(c),
                  selected: _selectedCountry == c,
                  onTap: () {
                    setState(() => _selectedCountry = c);
                    _filterTrails();
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: SyntrakSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${_filteredTrails.length} trails',
            style: SyntrakTypography.labelLarge.copyWith(
              color: SyntrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Sort button
          TextButton.icon(
            onPressed: () {
              // TODO: Implement sort
            },
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

// Enhanced Trail Card with Strava-like design
class _TrailCard extends StatelessWidget {
  final SkiTrail trail;

  const _TrailCard({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trail details for ${trail.name} coming soon!'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient background
              Container(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(trail.difficulty.color).withAlpha(40),
                      Color(trail.difficulty.color).withAlpha(10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(SyntrakRadius.lg),
                    topRight: Radius.circular(SyntrakRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    // Difficulty badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(trail.difficulty.color),
                        borderRadius: BorderRadius.circular(SyntrakRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Color(trail.difficulty.color).withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          trail.difficulty.icon,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.md),
                    // Trail info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trail.name,
                            style: SyntrakTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 14,
                                color: SyntrakColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${trail.resort}, ${trail.country}',
                                  style: SyntrakTypography.bodySmall.copyWith(
                                    color: SyntrakColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Rating
                    if (trail.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SyntrakSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              trail.rating!.toStringAsFixed(1),
                              style: SyntrakTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Stats section
              Padding(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row with icons
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.straighten,
                          value: '${trail.lengthKm.toStringAsFixed(1)} km',
                          label: 'Length',
                        ),
                        const SizedBox(width: SyntrakSpacing.lg),
                        _StatItem(
                          icon: Icons.trending_down,
                          value: '${trail.elevationDropM} m',
                          label: 'Drop',
                        ),
                        const Spacer(),
                        // Badges
                        if (trail.isGroomed)
                          _Badge(
                            icon: Icons.ac_unit,
                            label: 'Groomed',
                            color: SyntrakColors.info,
                          ),
                      ],
                    ),
                    // Description
                    if (trail.description != null) ...[
                      const SizedBox(height: SyntrakSpacing.md),
                      Text(
                        trail.description!,
                        style: SyntrakTypography.bodySmall.copyWith(
                          color: SyntrakColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Features tags
                    if (trail.features != null && trail.features!.isNotEmpty) ...[
                      const SizedBox(height: SyntrakSpacing.md),
                      Wrap(
                        spacing: SyntrakSpacing.xs,
                        runSpacing: SyntrakSpacing.xs,
                        children: trail.features!
                            .take(4)
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SyntrakColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(SyntrakRadius.round),
                                  ),
                                  child: Text(
                                    f,
                                    style: SyntrakTypography.labelSmall.copyWith(
                                      color: SyntrakColors.textSecondary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SyntrakColors.textTertiary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: SyntrakTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: SyntrakColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(SyntrakRadius.sm),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
