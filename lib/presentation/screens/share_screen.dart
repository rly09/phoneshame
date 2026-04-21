import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/share_card_widget.dart';

class ShareScreen extends StatefulWidget {
  final int score;
  final String topApp;
  final String totalTimeStr;
  final String roastSnippet;

  const ShareScreen({
    super.key,
    required this.score,
    required this.topApp,
    required this.totalTimeStr,
    required this.roastSnippet,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;

  Future<Uint8List?> _capturePng() async {
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    final Uint8List? pngBytes = await _capturePng();
    if (pngBytes != null) {
      final result = await ImageGallerySaver.saveImage(pngBytes, name: "phoneshame_score_${DateTime.now().millisecondsSinceEpoch}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isSuccess'] ? 'Saved to gallery' : 'Failed to save'),
            backgroundColor: result['isSuccess'] ? AppColors.primary : Colors.red,
          )
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _shareImage() async {
    setState(() => _isSaving = true);
    final Uint8List? pngBytes = await _capturePng();
    if (pngBytes != null) {
       await Share.shareXFiles(
        [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'shame_score.png')],
        text: 'My PhoneShame score is ${widget.score}. I need help.',
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PhoneShameAppBar(title: "Your Card"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: ShareCardWidget(
                repaintKey: _repaintKey,
                score: widget.score,
                totalTime: widget.totalTimeStr,
                topApp: widget.topApp,
                roastSnippet: widget.roastSnippet,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                     onPressed: _isSaving ? null : _saveToGallery,
                     icon: const Icon(Icons.download),
                     label: const Text("Save"),
                     style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       foregroundColor: AppColors.primary,
                       side: const BorderSide(color: AppColors.primary),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                     onPressed: _isSaving ? null : _shareImage,
                     icon: const Icon(Icons.share, color: Colors.white),
                     label: const Text("Share", style: TextStyle(color: Colors.white)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
