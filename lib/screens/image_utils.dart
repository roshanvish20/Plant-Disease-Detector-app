import 'dart:ui' as ui;  // Ensure this import is at the top of your file

Future<ui.Image> scaleImage(ui.Image image, double inputSize) async {
  // Define the width and height of the scaled image
  double scaleWidth = inputSize;
  double scaleHeight = inputSize;

  // Create a PictureRecorder to record the drawing commands
  final recorder = ui.PictureRecorder();

  // Create a Canvas to draw on
  final canvas = ui.Canvas(recorder, ui.Rect.fromPoints(ui.Offset(0, 0), ui.Offset(scaleWidth, scaleHeight)));

  // Draw the image on the canvas with scaling
  final paint = ui.Paint();
  canvas.drawImageRect(
    image,
    ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    ui.Rect.fromLTWH(0, 0, scaleWidth, scaleHeight),
    paint,
  );

  // Create the scaled image
  final picture = recorder.endRecording();
  final scaledImage = await picture.toImage(scaleWidth.toInt(), scaleHeight.toInt());

  return scaledImage;
}
