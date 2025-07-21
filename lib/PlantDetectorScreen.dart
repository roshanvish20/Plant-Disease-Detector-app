import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demos/services/remedy_page.dart';

class PlantDetectorScreen extends StatefulWidget {
  const PlantDetectorScreen({super.key});

  @override
  _PlantDetectorScreenState createState() => _PlantDetectorScreenState();
}

class _PlantDetectorScreenState extends State<PlantDetectorScreen> with SingleTickerProviderStateMixin {
  File? _image;
  String _prediction = "No Prediction Yet";
  bool _showRemedyButton = false;
  String _plantName = "";
  String _diseaseName = "";
  late Interpreter _interpreter;
  late Map<int, String> _labels;
  bool _isLoading = false;
  bool _showLabels = false;
  double _confidence = 0.0;
  bool _isPlant = true; // Flag to indicate if the detected object is a plant
  
  // Animation controller for the scanning effect
  late AnimationController _scanAnimationController;
  bool _isModelLoaded = false;
  bool _areLabelsLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller first
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Then load model and labels
    _loadModel();
    _loadLabels();
  }

  /// ✅ Load the TensorFlow Lite Model
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/plant_disease_models.tflite');
      setState(() {
        _isModelLoaded = true;
      });
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ ERROR: Failed to load model: $e");
    }
  }

  /// ✅ Load Labels from JSON file
  Future<void> _loadLabels() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context).loadString('assets/class_labels.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      setState(() {
        _labels = jsonMap.map((key, value) => MapEntry(value, key));
        _areLabelsLoaded = true;
      });
      print("✅ Labels loaded successfully!");
    } catch (e) {
      print("❌ ERROR: Failed to load labels: $e");
    }
  }

  /// ✅ Pick image from gallery or camera with permission handling
  Future<void> _pickImage(ImageSource source) async {
    // Check if model and labels are loaded
    if (!_isModelLoaded || !_areLabelsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait, model is still loading...")),
      );
      return;
    }
    
    if (source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission denied")),
        );
        return;
      }
    } else {
      // ✅ Handle storage permissions for Android 13+ and lower versions
      if (Platform.isAndroid) {
        var storageStatus = await Permission.photos.request();
        if (storageStatus.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gallery access denied")),
          );
          return;
        }
      }
    }

    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _showRemedyButton = false;
        _showLabels = false;
        _isLoading = true;
        _isPlant = true; // Reset plant flag
      });

      // Start the scanning animation safely
      if (!_scanAnimationController.isAnimating) {
        _scanAnimationController.repeat();
      }

      // Give the UI some time to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Run prediction
      await _predictImage(_image!);
      
      // Stop the scanning animation safely
      if (_scanAnimationController.isAnimating) {
        _scanAnimationController.stop();
      }
      
      setState(() {
        _isLoading = false;
        _showLabels = true;
      });
    } catch (e) {
      // Stop animation in case of error
      if (_scanAnimationController.isAnimating) {
        _scanAnimationController.stop();
      }
      
      setState(() {
        _isLoading = false;
      });
      print("❌ ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  /// ✅ Process image and run inference
  Future<void> _predictImage(File image) async {
    try {
      var input = await _preprocessImage(image);

      // Prepare output buffer
      var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      // Run inference
      _interpreter.run(input, output);

      // ✅ Get max confidence score
      double maxConfidence = output[0].reduce((double a, double b) => a > b ? a : b);
      int maxIndex = output[0].indexOf(maxConfidence);

      // ✅ Confidence threshold to detect unknown objects
      double confidenceThreshold = 0.7;

      String prediction;
      if (maxConfidence < confidenceThreshold) {
        prediction = "Not a Plant – Try a different image";
        
        // For non-plants, artificially reduce the confidence to a very low value
        // This makes it clearer to the user that the confidence is low
        double displayedConfidence = maxConfidence * 0.3; // Reduce confidence by 70%
        
        setState(() {
          _prediction = prediction;
          _showRemedyButton = false;
          _plantName = "Unknown Object";
          _diseaseName = "Not a plant";
          _confidence = displayedConfidence; // Use the reduced confidence value
          _isPlant = false;
        });
      } else {
        prediction = _labels[maxIndex] ?? "Unknown Plant";
        
        // Parse the prediction to extract plant name and disease
        _parsePrediction(prediction);
        
        // Save to database only if it's a plant
        await _saveAnalysisToSupabase(image, prediction);
        
        setState(() {
          _prediction = prediction;
          _showRemedyButton = true;
          _confidence = maxConfidence;
          _isPlant = true;
        });
      }

      print("✅ Prediction: $_prediction (Confidence: ${maxConfidence.toStringAsFixed(2)})");
      print("✅ Plant: $_plantName, Disease: $_diseaseName");
      
    } catch (e) {
      print("❌ ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to process image: $e")),
      );
    }
  }

  /// Parse the prediction to extract plant name and disease
  void _parsePrediction(String prediction) {
    try {
      // Handle predictions in format "PlantName___DiseaseName" or "PlantName__condition"
      if (prediction.contains("___")) {
        // Format with three underscores (standard format)
        List<String> parts = prediction.split('___');
        _plantName = parts[0].replaceAll('_', ' ');
        _diseaseName = parts.length > 1 ? parts[1].replaceAll('_', ' ') : "Healthy";
      } else if (prediction.contains("__")) {
        // Format with two underscores (Chili format)
        List<String> parts = prediction.split('__');
        _plantName = parts[0];
        _diseaseName = parts.length > 1 ? parts[1] : "Healthy";
      } else {
        // No recognizable format, use whole string as plant name
        _plantName = prediction;
        _diseaseName = "Unknown";
      }
      
      // If "healthy" is in the prediction, set disease as Healthy
      if (prediction.toLowerCase().contains("healthy")) {
        _diseaseName = "Healthy";
      }
      
      // Clean up plant name if it has parentheses
      if (_plantName.contains("(")) {
        int parenthesisIndex = _plantName.indexOf("(");
        _plantName = _plantName.substring(0, parenthesisIndex).trim();
      }
    } catch (e) {
      print("Error parsing prediction: $e");
      // Default values if parsing fails
      _plantName = prediction;
      _diseaseName = "Unknown";
    }
  }

  /// Save analysis to Supabase
  Future<void> _saveAnalysisToSupabase(File image, String prediction) async {
    try {
      final supabase = Supabase.instance.client;
      print('Is User Authenticated: ${supabase.auth.currentUser != null}');
      
      // Proceed only if the user is authenticated
      if (supabase.auth.currentUser == null) {
        throw Exception("User is not authenticated.");
      }

      // 1. Upload the image to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${supabase.auth.currentUser!.id}/$timestamp.jpg';

      final imageBytes = await image.readAsBytes();
      await supabase.storage.from('plant_images').uploadBinary(
        imagePath,
        imageBytes,
      );

      // 2. Get the public URL for the uploaded image
      final imageUrl = supabase.storage.from('plant_images').getPublicUrl(imagePath);

      // 3. Save the analysis record to the plant_analysis table
      await supabase.from('plant_analysis').insert({
        'user_id': supabase.auth.currentUser!.id,
        'image_url': imageUrl,
        'prediction': prediction,
        'plant_name': _plantName,
        'disease_name': _diseaseName,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ Analysis saved to Supabase successfully!");
    } catch (e) {
      print("❌ ERROR: Failed to save analysis: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save analysis: $e")),
      );
    }
  }

  /// ✅ Preprocess image manually (resize + normalize)
  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception("Failed to decode image.");
    }

    // ✅ Reduce image size (avoid memory crash)
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    List<List<List<double>>> imageMatrix = List.generate(
      224,
      (y) => List.generate(
        224,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0, // ✅ Extract Red
            pixel.g.toDouble() / 255.0, // ✅ Extract Green
            pixel.b.toDouble() / 255.0  // ✅ Extract Blue
          ];
        },
      ),
    );

    return [imageMatrix];
  }

  void _navigateToRemedy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RemedyPage(
          plant: _plantName,
          disease: _diseaseName,
          heroTag: 'plant_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Safe dispose of resources
    if (_isModelLoaded) {
      _interpreter.close();
    }
    _scanAnimationController.dispose();
    super.dispose();
  }

  // Get status icon based on disease condition
  Widget _getStatusIcon() {
    if (!_isPlant) {
      return const Icon(Icons.error_outline, color: Colors.grey, size: 28);
    } else if (_diseaseName.toLowerCase() == "healthy") {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    } else if (_diseaseName.toLowerCase() == "unknown") {
      return const Icon(Icons.help, color: Colors.orange, size: 28);
    } else {
      return const Icon(Icons.warning, color: Colors.red, size: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Fallback color in case image fails to load
          color: Colors.green.shade100, 
          image: DecorationImage(
            image: const AssetImage("assets/plant1.jpeg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
            // Error handling for missing image
            onError: (exception, stackTrace) {
              print("Image not found: $exception");
            },
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Plant Disease Detector',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content - USING EXPANDED HERE TO FIX OVERFLOW
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Important to prevent overflow
                      children: [
                        // Image Display Card
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 250, // Reduced height
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _image == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_enhance,
                                          size: 80,
                                          color: Colors.green.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Upload a plant image to scan",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "We'll identify diseases and suggest remedies",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          _image!,
                                          fit: BoxFit.cover,
                                        ),
                                        if (_isLoading)
                                          Container(
                                            color: Colors.black.withOpacity(0.3),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  LinearProgressIndicator(
                                                    backgroundColor: Colors.white.withOpacity(0.3),
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade300),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  const Text(
                                                    "Analyzing image...",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Results Card
                        if (_showLabels)
                          Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: !_isPlant 
                                      ? [Colors.grey.shade400, Colors.grey.shade700]
                                      : _diseaseName.toLowerCase() == "healthy" 
                                          ? [Colors.green.shade300, Colors.green.shade700]
                                          : [Colors.orange.shade300, Colors.red.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Important to prevent overflow
                                children: [
                                  Row(
                                    children: [
                                      _getStatusIcon(),
                                      const SizedBox(width: 8),
                                      Text(
                                        !_isPlant
                                            ? "Not a Plant"
                                            : _diseaseName.toLowerCase() == "healthy" 
                                                ? "Healthy Plant" 
                                                : "Disease Detected",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white30),
                                  _buildInfoRow("Detected", _isPlant ? _plantName : "Unknown Object"),
                                  _buildInfoRow("Condition", _isPlant ? _diseaseName : "Not a Plant"),
                                  _buildInfoRow("Confidence", "${(_confidence * 100).toStringAsFixed(1)}%"),
                                  
                                  // Non-plant message
                                  if (!_isPlant)
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Please upload a clearer image of a plant for analysis",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  if (_showRemedyButton && _isPlant)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _navigateToRemedy,
                                        icon: const Icon(Icons.healing),
                                        label: const Text("View Remedies"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.green.shade800,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt,
                        label: "Camera",
                        color: Colors.blue,
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library,
                        label: "Gallery",
                        color: Colors.purple,
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build info rows with enhanced confidence display
  Widget _buildInfoRow(String label, String value) {
    // Special case for confidence display
    if (label == "Confidence") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                "$label:",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      // Make confidence value have strikethrough for non-plants
                      decoration: !_isPlant ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  if (!_isPlant)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        "(Low confidence)",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Default display for other rows
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}