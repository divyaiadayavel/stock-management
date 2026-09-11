import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_info.dart';

class NetworkAwareWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkAwareWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NetworkAwareWrapper> createState() =>
      _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState
    extends ConsumerState<NetworkAwareWrapper> {
  bool _isOffline = false;
  bool _isVisible = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();

    if (!mounted) return;

    final offline = result.contains(ConnectivityResult.none);

    setState(() {
      _isOffline = offline;
      _isVisible = offline;
    });
  }

void _onConnectivityChanged(List<ConnectivityResult> results) {
  final offline = results.contains(ConnectivityResult.none);

  if (offline == _isOffline) return;

  _timer?.cancel();

  setState(() {
    _isOffline = offline;
    _isVisible = true;
  });

  _timer = Timer(const Duration(seconds: 2), () {
    if (!mounted) return;

    setState(() {
      _isVisible = false;
    });
  });
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (_, next) {
        next.whenData(_onConnectivityChanged);
      },
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,

        SafeArea(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            offset: _isVisible ? Offset.zero : const Offset(0, -1.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isVisible ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: IgnorePointer(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
Icon(
  _isOffline
      ? Icons.wifi_off_outlined
      : Icons.wifi_outlined,
  size: 18,
  color: Colors.black87,
),
                        const SizedBox(width: 8),
                        Text(
                          _isOffline
                              ? 'No Internet'
                              : 'Back Online',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}