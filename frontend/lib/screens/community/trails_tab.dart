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
  List<SkiTrail> _trails = [];
  List<SkiTrail> _filteredTrails = [];
  bool _isLoading = false;
  TrailDifficulty? _selectedDifficulty;
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _loadTrails();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
        ),
      );
    }

    return Column(
      children: [
        // Search and filters
        Container(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          color: SyntrakColors.surface,
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (_) => _filterTrails(),
                decoration: InputDecoration(
                  hintText: 'Search trails, resorts, or countries...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterTrails();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: SyntrakColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SyntrakRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SyntrakSpacing.md,
                    vertical: SyntrakSpacing.sm,
                  ),
                ),
              ),
              const SizedBox(height: SyntrakSpacing.sm),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDifficultyFilter(),
                    const SizedBox(width: SyntrakSpacing.sm),
                    _buildCountryFilter(),
                    if (_selectedDifficulty != null ||
                        _selectedCountry != null) ...[
                      const SizedBox(width: SyntrakSpacing.sm),
                      ActionChip(
                        label: const Text('Clear Filters'),
                        onPressed: () {
                          setState(() {
                            _selectedDifficulty = null;
                            _selectedCountry = null;
                          });
                          _filterTrails();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SyntrakSpacing.md,
            vertical: SyntrakSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '${_filteredTrails.length} trails found',
                style: SyntrakTypography.labelMedium.copyWith(
                  color: SyntrakColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Trail list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTrails,
            color: SyntrakColors.primary,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
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

  Widget _buildDifficultyFilter() {
    return PopupMenuButton<TrailDifficulty?>(
      onSelected: (value) {
        setState(() {
          _selectedDifficulty = value;
        });
        _filterTrails();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All Difficulties'),
        ),
        ...TrailDifficulty.values.map(
          (d) => PopupMenuItem(
            value: d,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(d.color),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      d.icon,
                      style: TextStyle(
                        fontSize: 10,
                        color: d == TrailDifficulty.green
                            ? Colors.white
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(d.shortName),
              ],
            ),
          ),
        ),
      ],
      child: Chip(
        avatar: _selectedDifficulty != null
            ? Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(_selectedDifficulty!.color),
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.filter_list, size: 18),
        label: Text(_selectedDifficulty?.shortName ?? 'Difficulty'),
        backgroundColor: _selectedDifficulty != null
            ? Color(_selectedDifficulty!.color).withAlpha(30)
            : null,
      ),
    );
  }

  Widget _buildCountryFilter() {
    return PopupMenuButton<String?>(
      onSelected: (value) {
        setState(() {
          _selectedCountry = value;
        });
        _filterTrails();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All Countries'),
        ),
        ..._countries.map(
          (c) => PopupMenuItem(
            value: c,
            child: Text(c),
          ),
        ),
      ],
      child: Chip(
        avatar: const Icon(Icons.public, size: 18),
        label: Text(_selectedCountry ?? 'Country'),
        backgroundColor: _selectedCountry != null
            ? SyntrakColors.primaryLight.withAlpha(30)
            : null,
      ),
    );
  }
}

class _TrailCard extends StatelessWidget {
  final SkiTrail trail;

  const _TrailCard({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: SyntrakSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        side: BorderSide(color: SyntrakColors.divider),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to trail detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trail details for ${trail.name} coming soon!'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(trail.difficulty.color),
                      borderRadius: BorderRadius.circular(SyntrakRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        trail.difficulty.icon,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: SyntrakSpacing.md),
                  // Trail name and resort
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trail.name,
                          style: SyntrakTypography.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${trail.resort} • ${trail.country}',
                          style: SyntrakTypography.bodySmall.copyWith(
                            color: SyntrakColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating
                  if (trail.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          trail.rating!.toStringAsFixed(1),
                          style: SyntrakTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: SyntrakSpacing.md),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.straighten,
                    label: '${trail.lengthKm.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  _StatChip(
                    icon: Icons.height,
                    label: '${trail.elevationDropM} m drop',
                  ),
                  if (trail.isGroomed) ...[
                    const SizedBox(width: SyntrakSpacing.sm),
                    _StatChip(
                      icon: Icons.ac_unit,
                      label: 'Groomed',
                    ),
                  ],
                ],
              ),
              // Description
              if (trail.description != null) ...[
                const SizedBox(height: SyntrakSpacing.sm),
                Text(
                  trail.description!,
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Features
              if (trail.features != null && trail.features!.isNotEmpty) ...[
                const SizedBox(height: SyntrakSpacing.sm),
                Wrap(
                  spacing: SyntrakSpacing.xs,
                  runSpacing: SyntrakSpacing.xs,
                  children: trail.features!
                      .take(3)
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SyntrakSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SyntrakColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(SyntrakRadius.sm),
                          ),
                          child: Text(
                            f,
                            style: SyntrakTypography.labelSmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: SyntrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SyntrakRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SyntrakColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
