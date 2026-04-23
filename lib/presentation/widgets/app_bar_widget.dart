// Kept for backward compatibility — home_screen and share_screen no longer
// use this directly, but any other call sites can still import it.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ROTAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const ROTAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:       AppColors.bg,
      elevation:             0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color:      AppColors.textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
