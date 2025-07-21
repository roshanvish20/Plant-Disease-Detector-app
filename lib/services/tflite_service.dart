import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  static late Interpreter _interpreter;
  static List<String> _labels = [];

  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/load_tflite.tflite');
      _labels = await _loadLabels('assets/plant_labels.txt');
      print("Model loaded successfully!");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  static Future<List<String>> _loadLabels(String path) async {
    String labelsData = await File(path).readAsString();
    return labelsData.split("\n").map((e) => e.trim()).toList();
  }

  static Future<String> predictDisease(File imageFile) async {
    if (_interpreter == null) return "Model not loaded";

    // Preprocess image
    Uint8List input = _preprocessImage(imageFile);

    // Run inference
    List<List<double>> output = List.generate(1, (_) => List.filled(_labels.length, 0));
    _interpreter.run(input, output);

    // Get prediction
    int predictedIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
    return _labels[predictedIndex];
  }

  static Uint8List _preprocessImage(File imageFile) {
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resized = img.copyResize(image, width: 224, height: 224);
    return resized.getBytes();
  }
}
