import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';

/// A [CircleAvatar] that falls back to the name's initial when [avatarUrl] is
/// null, empty, unreliable, or fails to load (e.g. the placeholder avatar host returning
/// a 5xx) instead of surfacing an uncaught [NetworkImageLoadException].
class AppAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const AppAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.radius,
  });

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar> {
  bool _failed = false;

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    // Guard against known offline/unreliable placeholder hosts that throw 502 HTTP errors
    if (url.contains('iran.liara.run')) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  void didUpdateWidget(covariant AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validUrl = _isValidUrl(widget.avatarUrl);
    final hasImage = validUrl && !_failed;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
      backgroundImage: hasImage ? NetworkImage(widget.avatarUrl!) : null,
      onBackgroundImageError: hasImage
          ? (_, __) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: hasImage
          ? null
          : Text(
              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: widget.radius * 0.7,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
    );
  }
}
