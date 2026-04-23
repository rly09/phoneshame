import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/share_card_widget.dart';

class ShareScreen extends StatefulWidget {
  final int    score;
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

  Future<Uint8List?> _capture() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image    = await boundary.toImage(pixelRatio: 3.0);
      final data     = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    final bytes = await _capture();
    if (bytes != null) {
      final result = await ImageGallerySaver.saveImage(
          bytes,
          name: 'rot_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['isSuccess'] ? 'Saved to gallery ✓' : 'Failed to save'),
          backgroundColor: result['isSuccess'] ? context.colors.green : context.colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _share() async {
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    final bytes = await _capture();
    if (bytes != null) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'rot_score.png')],
        text: 'My ROT score is ${widget.score}. I need help. 💀',
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor:       context.colors.bg,
        elevation:             0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'your rot card',
          style: GoogleFonts.poppins(
            color:      context.colors.textPrimary,
            fontSize:   18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: ShareCardWidget(
                repaintKey:   _repaintKey,
                score:        widget.score,
                totalTime:    widget.totalTimeStr,
                topApp:       widget.topApp,
                roastSnippet: widget.roastSnippet,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label:    'save',
                    icon:     Icons.download_rounded,
                    bg:       context.colors.surface,
                    fg:       context.colors.textPrimary,
                    border:   context.colors.border,
                    loading:  _isSaving,
                    onTap:    _save,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label:   'share',
                    icon:    Icons.share_rounded,
                    bg:      context.colors.purple,
                    fg:      context.colors.bg,
                    loading: _isSaving,
                    onTap:   _share,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String  label;
  final IconData icon;
  final Color   bg;
  final Color   fg;
  final Color?  border;
  final bool    loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    this.border,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(16),
          border:       border != null ? Border.all(color: border!) : null,
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: fg, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color:      fg,
                      fontSize:   16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
