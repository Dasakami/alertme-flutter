import 'package:flutter/material.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MiniMap extends StatefulWidget {
  const MiniMap({super.key});

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  final LocationService _locationService = LocationService();
  String _locationText = 'Определение местоположения...';
  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _locationText = location?.address ?? 'Местоположение не определено';
        _lat = location?.latitude;
        _lon = location?.longitude;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_lat != null && _lon != null) {
      // Google Maps URL схема
      // Android/iOS: geo:latitude,longitude?q=latitude,longitude
      // Web/Универсальная: https://www.google.com/maps/search/?api=1&query=lat,lon
      
      final Uri url;
      
      try {
        // Пробуем открыть через приложение Google Maps
        url = Uri.parse('geo:$_lat,$_lon?q=$_lat,$_lon');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        // Если не получилось, используем веб-версию
      }
      
      // Fallback на веб-версию Google Maps
      final webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$_lat,$_lon'
      );
      
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: _openInGoogleMaps,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 120,
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.softCyan.withValues(alpha: 0.1),
                AppColors.deepBlue.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.softCyan, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ваше местоположение',
                    style: context.textStyles.labelLarge?.withColor(AppColors.deepBlue),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Text(
                  _locationText,
                  style: context.textStyles.bodyLarge?.semiBold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Открыть в Google Maps',
                    style: context.textStyles.bodySmall?.withColor(AppColors.softCyan),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.softCyan),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}