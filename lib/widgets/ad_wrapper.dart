import 'package:flutter/material.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';
import 'package:yurttaye_mobile/services/ad_manager.dart';

class AdWrapper extends StatefulWidget {
  final Widget child;
  final String routeName;
  final bool showAdOnEnter;
  final bool showAdOnExit;

  const AdWrapper({
    Key? key,
    required this.child,
    required this.routeName,
    this.showAdOnEnter = false,
    this.showAdOnExit = false,
  }) : super(key: key);

  @override
  State<AdWrapper> createState() => _AdWrapperState();
}

class _AdWrapperState extends State<AdWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.showAdOnEnter) {
      // Sayfa açıldığında reklam göster
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAdWithDelay();
      });
    }
  }

  void _showAdWithDelay() async {
    print('=== AD WRAPPER DEBUG ===');
    print('Route: ${widget.routeName}');
    print('Show ad on enter: ${widget.showAdOnEnter}');
    print('Mounted: $mounted');
    
    // Kısa bir gecikme ile reklam göster (sayfa yüklendikten sonra)
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        print('Showing ad for route: ${widget.routeName}');
        
        // Menü detay sayfası için özel kontrol (her 2 tıklamada bir)
        if (widget.routeName == 'menu_detail') {
          final shouldShow = await AdManager.shouldShowAdOnMenuDetail();
          if (shouldShow) {
            await AdManager.showAdIfAllowed();
          }
        } else {
          await AdManager.showAdIfAllowed();
        }
      } else {
        print('Widget not mounted, skipping ad');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.showAdOnExit) {
          // Sayfa kapatılırken reklam göster
          await AdManager.showAdIfAllowed();
        }
        return true;
      },
      child: widget.child,
    );
  }
} 