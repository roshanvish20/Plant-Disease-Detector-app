import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demos/services/remedy_page.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _plantHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterBy = 'All';
  late AnimationController _animationController;
  final List<String> _filterOptions = ['All', 'Healthy', 'Diseased'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _supabase
          .from('plant_analysis')
          .select('plant_name, disease_name, image_url, created_at')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      setState(() {
        _plantHistory = List<Map<String, dynamic>>.from(response);
        _applyFilters();
        _isLoading = false;
      });

      // Debugging: Print fetched data
      for (var item in _plantHistory) {
        debugPrint("Fetched: $item");
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load history: $e';
        _isLoading = false;
      });
      debugPrint('Error loading history: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredHistory = _plantHistory.where((analysis) {
        // Apply search filter
        final plantName = (analysis['plant_name'] ?? '').toLowerCase();
        final diseaseName = (analysis['disease_name'] ?? '').toLowerCase();
        final matchesSearch = _searchQuery.isEmpty || 
                             plantName.contains(_searchQuery.toLowerCase()) || 
                             diseaseName.contains(_searchQuery.toLowerCase());
        
        // Apply category filter
        bool matchesFilter = true;
        if (_filterBy == 'Healthy') {
          matchesFilter = (diseaseName.toLowerCase() == 'healthy');
        } else if (_filterBy == 'Diseased') {
          matchesFilter = (diseaseName.toLowerCase() != 'healthy');
        }
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  // Function to get signed image URL
  Future<String?> _getSignedImageUrl(String path) async {
    try {
      final response = await _supabase.storage
          .from('plant_images')
          .createSignedUrl(path, 60 * 60);
      return response;
    } catch (e) {
      debugPrint('Error fetching signed URL: $e');
      return null;
    }
  }

  // Navigate to remedy page with hero animation
  void _viewRemedy(String plantName, String diseaseName, String heroTag) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RemedyPage(
          plant: plantName,
          disease: diseaseName,
          heroTag: heroTag,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // Delete analysis entry
  Future<void> _deleteAnalysis(String plantName, String diseaseName, String createdAt) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Analysis'),
          content: Text('Are you sure you want to delete the analysis for $plantName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      // In a real app, you'd delete from the database
      // For now, just remove from the local list
      setState(() {
        _plantHistory.removeWhere((item) => 
          item['plant_name'] == plantName && 
          item['disease_name'] == diseaseName &&
          item['created_at'] == createdAt
        );
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis for $plantName deleted'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          width: 300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Analysis History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadHistory,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _applyFilters();
                                  });
                                },
                              )
                            : null,
                        hintText: 'Search plants or conditions...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filterOptions.map((filter) {
                        final isSelected = _filterBy == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _filterBy = filter;
                                _applyFilters();
                              });
                            },
                            backgroundColor: Colors.white.withOpacity(0.2),
                            selectedColor: Colors.white,
                            checkmarkColor: Colors.green.shade700,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.green.shade700 : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading 
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadHistory,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredHistory.isEmpty
                    ? Center(
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history, size: 84, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _filterBy != 'All'
                                  ? 'No matching results'
                                  : 'No analysis history yet',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _filterBy != 'All'
                                  ? 'Try different search terms or filters'
                                  : 'Your analyzed plants will appear here',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Analyze a Plant'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: Colors.green,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            final analysis = _filteredHistory[index];
                            String plantName = analysis['plant_name'] ?? 'Unknown Plant';
                            String diseaseName = analysis['disease_name'] ?? 'Unknown Condition';
                            String? imagePath = analysis['image_url'];
                            DateTime createdAt = DateTime.parse(analysis['created_at']);
                            String formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(createdAt);
                            String heroTag = 'plant_${index}_${createdAt.millisecondsSinceEpoch}';
                            
                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final delay = index * 0.1;
                                final slideAnimation = Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      delay.clamp(0.0, 0.9), 
                                      (delay + 0.5).clamp(0.0, 1.0),
                                      curve: Curves.easeOutQuart,
                                    ),
                                  ),
                                );
                                
                                return SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                );
                              },
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () => _viewRemedy(plantName, diseaseName, heroTag),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    children: [
                                      // Image section with status indicator
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: imagePath != null && imagePath.isNotEmpty
                                              ? FutureBuilder<String?>(
                                                  future: _getSignedImageUrl(imagePath),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return Container(
                                                        height: 160,
                                                        color: Colors.grey.shade200,
                                                        child: const Center(
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                          ),
                                                        ),
                                                      );
                                                    } else if (snapshot.hasError || snapshot.data == null) {
                                                      return Container(
                                                        height: 160,
                                                        color: Colors.grey.shade200,
                                                        child: const Center(
                                                          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                        ),
                                                      );
                                                    } else {
                                                      return Hero(
                                                        tag: heroTag,
                                                        child: Image.network(
                                                          snapshot.data!,
                                                          height: 160,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              height: 160,
                                                              color: Colors.grey.shade200,
                                                              child: const Center(
                                                                child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                              : Container(
                                                  height: 160,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                                  ),
                                                ),
                                          ),
                                          // Status chip
                                          Positioned(
                                            right: 12,
                                            top: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: diseaseName.toLowerCase() == 'healthy'
                                                  ? Colors.green.withOpacity(0.9)
                                                  : Colors.red.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                diseaseName.toLowerCase() == 'healthy' ? 'Healthy' : 'Diseased',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // Content section
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        plantName,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        diseaseName,
                                                        style: TextStyle(
                                                          color: diseaseName.toLowerCase() == 'healthy'
                                                            ? Colors.green.shade700
                                                            : Colors.red.shade700,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                                  onSelected: (value) {
                                                    if (value == 'delete') {
                                                      _deleteAnalysis(
                                                        plantName,
                                                        diseaseName,
                                                        analysis['created_at'],
                                                      );
                                                    } else if (value == 'remedy') {
                                                      _viewRemedy(plantName, diseaseName, heroTag);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'remedy',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.healing, color: Colors.green),
                                                          SizedBox(width: 8),
                                                          Text('View Remedy'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Delete'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _viewRemedy(plantName, diseaseName, heroTag),
                                                    icon: const Icon(Icons.healing),
                                                    label: const Text('View Remedy'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green.shade100,
                                                      foregroundColor: Colors.green.shade800,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}