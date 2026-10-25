import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../application/occurrence_controller.dart';
import '../../domain/species_occurrence.dart';
import 'discovery_page.dart';
import 'favorites_page.dart';
import 'map_page.dart';
import 'occurrence_detail_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final OccurrenceController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _openDetail(SpeciesOccurrence occurrence) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OccurrenceDetailPage(
          occurrence: occurrence,
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          DiscoveryPage(controller: widget.controller, onOpen: _openDetail),
          MapPage(controller: widget.controller, onOpen: _openDetail),
          FavoritesPage(controller: widget.controller, onOpen: _openDetail),
        ],
      ),
    ),
    bottomNavigationBar: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: NavigationBar(
          backgroundColor: AppColors.card.withValues(alpha: 0.76),
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.travel_explore_outlined),
              selectedIcon: Icon(Icons.travel_explore),
              label: 'Jelajah',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Peta',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Favorit',
            ),
          ],
        ),
      ),
    ),
  );
}
