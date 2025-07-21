import 'package:flutter/material.dart';
import 'package:demos/services/supabase_service.dart';

class RemedyPage extends StatefulWidget {
  final String plant;
  final String disease;
  final String heroTag;

  const RemedyPage({
    Key? key,
    required this.plant,
    required this.disease,
    required this.heroTag,
  }) : super(key: key);

  @override
  _RemedyPageState createState() => _RemedyPageState();
}

class _RemedyPageState extends State<RemedyPage> with SingleTickerProviderStateMixin {
  String? remedy;
  bool isLoading = true;
  bool isError = false;
  bool isFavorite = false;
  int currentTab = 0;

  // Initialize _animationController immediately
  late AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  // Initialize _fadeAnimation immediately, using the already initialized _animationController
  late Animation<double> _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    _fetchRemedy();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRemedy() async {
    try {
      String? fetchedRemedy = await fetchRemedy(widget.plant, widget.disease);

      // Ensure newlines are correctly interpreted
      fetchedRemedy = fetchedRemedy?.replaceAll(r'\n', '\n');

      // Debugging output
      debugPrint("Fetched Remedy: $fetchedRemedy");

      setState(() {
        remedy = fetchedRemedy;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      debugPrint("Error fetching remedy: $e");
      setState(() {
        isError = true;
        isLoading = false;
        remedy = 'Error fetching remedy information. Please try again later.';
      });

      _animationController.forward();
    }
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite
            ? '${widget.plant} added to favorites'
            : '${widget.plant} removed from favorites'),
        backgroundColor: isFavorite ? Colors.green.shade700 : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to favorites (would be implemented in a real app)
          },
        ),
      ),
    );
  }

  List<String> _formatRemedyText(String? text) {
    if (text == null || text.isEmpty) return ['No specific remedy found.'];
    return text.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  // Extract tips section from remedy text
  List<String> _getTips() {
    if (remedy == null) return [];
    List<String> lines = _formatRemedyText(remedy);
    if (lines.length <= 2) return [];
    return lines.sublist(lines.length ~/ 2);
  }

  // Extract treatment steps from remedy text
  List<String> _getTreatmentSteps() {
    if (remedy == null) return [];
    List<String> lines = _formatRemedyText(remedy);
    if (lines.length <= 2) return lines;
    return lines.sublist(0, lines.length ~/ 2);
  }

  @override
  Widget build(BuildContext context) {
    bool isHealthy = widget.disease.toLowerCase() == 'healthy';
    Color primaryColor = isHealthy ? Colors.green.shade700 : Colors.orange.shade800;
    Color secondaryColor = isHealthy ? Colors.green.shade100 : Colors.orange.shade100;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with expandable image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.plant,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Hero(
                tag: widget.heroTag,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withOpacity(0.8),
                        primaryColor.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image would go here in real implementation
                      Center(
                        child: Icon(
                          isHealthy ? Icons.eco : Icons.healing,
                          size: 80,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      // Dark gradient for better text visibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // Share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing functionality would be implemented here'))
                  );
                },
              ),
            ],
          ),

          // Main content
          SliverToBoxAdapter(
            child: isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height - 200,
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text(
                            "Loading care instructions...",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status and Condition Card
                          Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Condition",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.disease.replaceAll('_', ' '),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Recommendation",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isHealthy
                                        ? "Continue with regular care to maintain health"
                                        : "Follow treatment plan to restore plant health",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tab Selection
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => currentTab = 0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: currentTab == 0 ? primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Treatment",
                                          style: TextStyle(
                                            color: currentTab == 0 ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => currentTab = 1),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: currentTab == 1 ? primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Care Tips",
                                          style: TextStyle(
                                            color: currentTab == 1 ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tab Content
                          if (isError)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      remedy!,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (currentTab == 0)
                            _buildTreatmentSteps(secondaryColor, primaryColor)
                          else
                            _buildCareTips(secondaryColor, primaryColor),

                          const SizedBox(height: 20),

                          // Additional Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Would trigger calendar integration
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Care reminder added to calendar'))
                                    );
                                  },
                                  icon: const Icon(Icons.calendar_today),
                                  label: const Text("Set Reminder"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: primaryColor),
                                    foregroundColor: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Would open plant shop
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Opening plant shop...'))
                                    );
                                  },
                                  icon: const Icon(Icons.shopping_cart),
                                  label: const Text("Shop Supplies"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSteps(Color bgColor, Color textColor) {
    List<String> steps = _getTreatmentSteps();

    if (steps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No specific treatment steps available for this condition.",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: steps.length,
        separatorBuilder: (context, index) => Divider(color: textColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: textColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCareTips(Color bgColor, Color textColor) {
    List<String> tips = _getTips();

    if (tips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No specific care tips available for this plant.",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: textColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tips[index],
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}