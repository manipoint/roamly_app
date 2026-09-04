import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  final user = AuthUser(
    id: 'user-1',
    email: 'traveler@roamly.test',
    status: AuthUserStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  testWidgets('renders the current user and sign-out action', (tester) async {
    final repository = _FakeAuthRepository(user: user);

    await _pumpPage(tester, repository);

    expect(find.byKey(const ValueKey<String>('profile-page')), findsOneWidget);
    expect(find.text(user.email), findsOneWidget);
    expect(find.text(AppStrings.signOut), findsOneWidget);
  });

  testWidgets('cancelling confirmation keeps the session active', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(user: user);

    await _pumpPage(tester, repository);
    await tester.tap(
      find.byKey(const ValueKey<String>('profile-logout-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signOutConfirmation), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('cancel-logout-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 0);
    expect(find.text(user.email), findsOneWidget);
  });

  testWidgets('confirming signs out the current device session', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(user: user);

    await _pumpPage(tester, repository);
    await tester.tap(
      find.byKey(const ValueKey<String>('profile-logout-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-logout-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
  });

  testWidgets('does not overflow on a compact viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester, _FakeAuthRepository(user: user));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(theme: RoamlyTheme.light, home: const ProfilePage()),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.user});

  final AuthUser user;
  int logoutCalls = 0;

  @override
  Future<Result<AuthUser?>> restoreSession() async {
    return Success<AuthUser?>(user);
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    throw UnimplementedError();
  }
}
