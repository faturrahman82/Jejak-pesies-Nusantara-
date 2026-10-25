import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../application/occurrence_controller.dart';
import '../../domain/occurrence_page.dart';
import '../../domain/species_occurrence.dart';
import '../widgets/landscape_hero.dart';
import '../widgets/request_state.dart';
import '../widgets/species_card.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final OccurrenceController controller;
  final ValueChanged<SpeciesOccurrence> onOpen;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  static const _groups = [
    'Semua',
    'Burung',
    'Mamalia',
    'Reptil',
    'Amfibi',
    'Serangga',
    'Tumbuhan',
  ];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  List<String> _suggestions = [];

  Future<void> _chooseProvince() async {
    final input = TextEditingController(text: widget.controller.province);
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Filter provinsi'),
      content: TextField(controller: input, decoration: const InputDecoration(hintText: 'Contoh: Jawa Timur')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Semua provinsi')), FilledButton(onPressed: () => Navigator.pop(context, input.text.trim()), child: const Text('Terapkan'))],
    ));
    if (value == null || !mounted) return;
    widget.controller.province = value;
    await _refresh();
  }

  String _selectedGroup = 'Semua';
  late Future<OccurrencePage> _request;

  @override
  void initState() {
    super.initState();
    _request = widget.controller.loadFirstPage();
    _scrollController.addListener(_loadWhenNearEnd);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadWhenNearEnd() {
    if (_scrollController.position.extentAfter < 360) {
      widget.controller.loadNextPage();
    }
  }

  void _search(String query) {
    _debounce?.cancel();
    setState(() {
      _suggestions = query.trim().isEmpty ? [] : widget.controller.occurrences.map((item) => item.scientificName).where((name) => name.toLowerCase().contains(query.toLowerCase())).toSet().take(3).toList();
    });
    _debounce = Timer(const Duration(milliseconds: 420), () async {
      if (!mounted) return;
      setState(() => _request = widget.controller.loadFirstPage(query: query));
      try {
        final names = await widget.controller.suggestNames(query);
        if (mounted && _searchController.text == query) setState(() => _suggestions = names);
      } catch (_) {
        // Saran bersifat opsional; hasil pencarian tetap ditampilkan.
      }
    });
  }

  Future<void> _refresh() async {
    final request = widget.controller.loadFirstPage(
      query: _searchController.text,
    );
    setState(() => _request = request);
    await request;
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Positioned.fill(child: LandscapeBackdrop()),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LandscapeHero(),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari spesies atau lokasi',
                        fillColor: AppColors.card.withValues(alpha: 0.76),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.forest,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  _search('');
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    if (_suggestions.isNotEmpty) Wrap(children: _suggestions.map((name) => ActionChip(label: Text(name), onPressed: () { _searchController.text = name; _search(name); setState(() => _suggestions = []); })).toList()),
                    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _chooseProvince, icon: const Icon(Icons.tune, size: 18), label: Text(widget.controller.province.isEmpty ? 'Filter provinsi' : widget.controller.province))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _groups.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          final selected = group == _selectedGroup;
                          return ChoiceChip(
                            label: Text(group),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedGroup = group),
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.deepForest,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.card.withValues(
                              alpha: 0.76,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.forest
                                  : AppColors.line,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => FutureBuilder<OccurrencePage>(
                future: _request,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const RequestState.loading();
                  }
                  if (snapshot.hasError) {
                    return RequestState.error(
                      message: _friendlyError(snapshot.error),
                      onRetry: _refresh,
                    );
                  }
                  final results = _selectedGroup == 'Semua'
                      ? widget.controller.occurrences
                      : widget.controller.occurrences
                            .where((item) => item.groupLabel == _selectedGroup)
                            .toList(growable: false);
                  if (results.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 180,
                            child: RequestState.empty(
                              message: _selectedGroup == 'Semua'
                                  ? 'Belum ada catatan yang cocok. Coba kata pencarian lain.'
                                  : 'Belum ada catatan untuk kelompok ini di hasil yang dimuat.',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount:
                          results.length +
                          (widget.controller.hasMore ||
                                  widget.controller.loadMoreError != null
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (index == results.length) {
                          return _PaginationFooter(
                            controller: widget.controller,
                          );
                        }
                        final occurrence = results[index];
                        final card = SpeciesCard(
                          occurrence: occurrence,
                          isFavorite: widget.controller.favoriteIds.contains(
                            occurrence.id,
                          ),
                          onTap: () => widget.onOpen(occurrence),
                          onFavorite: () =>
                              widget.controller.toggleFavorite(occurrence),
                        );
                        if (MediaQuery.disableAnimationsOf(context)) {
                          return card;
                        }
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          child: card,
                          builder: (context, progress, child) => Opacity(
                            opacity: progress,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - progress)),
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.controller});

  final OccurrenceController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loadMoreError != null) {
      return TextButton.icon(
        onPressed: controller.loadNextPage,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba muat catatan berikutnya'),
      );
    }
    if (controller.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox(height: 18);
  }
}

String _friendlyError(Object? error) => error is Exception
    ? error.toString()
    : 'Catatan belum berhasil dimuat. Periksa koneksi lalu coba lagi.';
