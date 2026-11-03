import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Platform-adaptive Map Helper that complies with Apple Guideline 4 (Design)
/// by providing native Apple Maps integration on iOS devices and Google Maps on Android.
class MapHelper {
  /// Opens the location in native Apple Maps on iOS (with an option for Google Maps via ActionSheet),
  /// and directly in Google Maps on Android / other platforms.
  static Future<void> openMap(
    BuildContext? context, {
    required String query,
    String? title,
    String? customUrl,
  }) async {
    final cleanQuery = query.trim();
    final cleanCustomUrl = customUrl?.trim() ?? '';

    if (cleanQuery.isEmpty && cleanCustomUrl.isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location or address available')),
        );
      }
      return;
    }

    // Determine the query to use
    final effectiveQuery = cleanQuery.isNotEmpty ? cleanQuery : cleanCustomUrl;

    if (Platform.isIOS) {
      // On iOS, present a native CupertinoActionSheet so the user can launch
      // native Apple Maps (as requested by Apple App Store review) or Google Maps.
      if (context != null && context.mounted) {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (ctx) => CupertinoActionSheet(
            title: Text(
              title != null && title.isNotEmpty
                  ? 'Open "$title" in Maps'
                  : 'Open Location in Maps',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            message: const Text('Select your preferred navigation application:'),
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  launchAppleMaps(effectiveQuery);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.map_fill, color: CupertinoColors.activeBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Apple Maps (Built-in)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.activeBlue),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchGoogleMaps(effectiveQuery, customUrl: cleanCustomUrl.isNotEmpty ? cleanCustomUrl : null);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.compass, color: CupertinoColors.activeGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Google Maps',
                      style: TextStyle(color: CupertinoColors.label),
                    ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: false,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
        );
      } else {
        // Fallback if context is not available
        await launchAppleMaps(effectiveQuery);
      }
    } else {
      // Android and other platforms: launch Google Maps
      await launchGoogleMaps(effectiveQuery, customUrl: cleanCustomUrl.isNotEmpty ? cleanCustomUrl : null);
    }
  }

  /// Launch native Apple Maps via maps.apple.com URL
  static Future<void> launchAppleMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse('https://maps.apple.com/?q=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launch Google Maps via web/app URL
  static Future<void> launchGoogleMaps(String query, {String? customUrl}) async {
    Uri targetUri;
    if (customUrl != null && customUrl.isNotEmpty && customUrl.contains('google.com')) {
      targetUri = Uri.parse(customUrl);
    } else {
      final encoded = Uri.encodeComponent(query);
      targetUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    }
    if (await canLaunchUrl(targetUri)) {
      await launchUrl(targetUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Platform-neutral button text
  static const String openDirectionsLabel = 'Open Directions in Maps 🗺️';
  static const String viewMapLabel = 'View on Maps 🗺️';
  static const String testMapLabel = 'Test on Maps 🗺️';
}
