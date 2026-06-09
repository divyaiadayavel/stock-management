import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_management/features/auth/presentation/controllers/access_policy.dart';
import 'package:stock_management/features/auth/presentation/providers/access_provider.dart';

void main() {
  test('temporary mode allows every known role to every feature', () {
    const roles = [
      'Admin',
      'Manager',
      'Cashier',
      'Salesperson',
      'Inventory Staff',
      'Custom Role',
    ];

    for (final role in roles) {
      for (final feature in AppFeature.values) {
        expect(
          RoleAccessPolicy.canAccess(role: role, feature: feature),
          isTrue,
          reason:
              '$role should access ${RoleAccessPolicy.featureLabel(feature)}',
        );
      }
    }
  });

  test('provider exposes current temporary access snapshot', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final snapshot = container.read(roleAccessProvider);

    expect(snapshot.isTemporaryAllAccess, isTrue);
    expect(snapshot.canAccess(AppFeature.settings), isTrue);
    expect(snapshot.allowedFeatures, RoleAccessPolicy.allFeatures);
  });
}
