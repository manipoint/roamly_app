import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';
import 'package:roamly_ui/roamly_ui.dart';

import 'app_navigation_items.dart';

final class AuthenticatedAppShell extends ConsumerStatefulWidget {
  const AuthenticatedAppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AuthenticatedAppShell> createState() =>
      _AuthenticatedAppShellState();
}

final class _AuthenticatedAppShellState
    extends ConsumerState<AuthenticatedAppShell> {
  // Keep this aligned with the Assistant entry in appNavigationItems.
  static const int _assistantBranchIndex = 2;
  static const Duration _assistantIdleDisconnectDelay = Duration(seconds: 30);

  Timer? _assistantDisconnectTimer;
  Future<void> _lifecycleOperations = Future<void>.value();
  bool _assistantTabActive = false;
  bool _assistantDisconnected = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _assistantTabActive =
        widget.navigationShell.currentIndex == _assistantBranchIndex;
  }

  @override
  void didUpdateWidget(covariant AuthenticatedAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAssistantActivity(
      widget.navigationShell.currentIndex == _assistantBranchIndex,
    );
  }

  void _selectDestination(int index) {
    _updateAssistantActivity(index == _assistantBranchIndex);

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _updateAssistantActivity(bool isActive) {
    if (_assistantTabActive == isActive) return;
    _assistantTabActive = isActive;

    if (isActive) {
      _assistantDisconnectTimer?.cancel();
      _assistantDisconnectTimer = null;

      // Queue behind any disconnect already in progress. This avoids racing
      // connect() against disconnect() if the user returns at the timeout.
      _enqueueLifecycleOperation(() async {
        if (!_assistantTabActive || !_assistantDisconnected) return;

        ref.read(assistantRepositoryProvider).connect();
        _assistantDisconnected = false;
      });
      return;
    }

    _assistantDisconnectTimer?.cancel();
    _assistantDisconnectTimer = Timer(_assistantIdleDisconnectDelay, () {
      _assistantDisconnectTimer = null;

      _enqueueLifecycleOperation(() async {
        // The user may have returned while this operation waited in the queue.
        if (_assistantTabActive || _assistantDisconnected) return;

        await ref.read(assistantRepositoryProvider).disconnect();
        _assistantDisconnected = true;
      });
    });
  }

  void _enqueueLifecycleOperation(Future<void> Function() operation) {
    _lifecycleOperations = _lifecycleOperations.then((_) async {
      if (_disposed) return;

      try {
        await operation();
      } on Object catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Roamly assistant connection lifecycle',
            context: ErrorDescription(
              'while changing Assistant connection state',
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _assistantDisconnectTimer?.cancel();
    _assistantDisconnectTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoamlyScaffold(
      bodyPadding: EdgeInsets.zero,
      // Each branch owns its top inset so immersive child routes can draw
      // behind the status bar without affecting standard tab pages.
      safeAreaTop: false,
      body: widget.navigationShell,
      bottomNavigationBar: RoamlyBottomNavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _selectDestination,
        items: appNavigationItems,
      ),
    );
  }
}
