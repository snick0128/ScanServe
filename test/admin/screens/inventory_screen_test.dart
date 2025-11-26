import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/admin/screens/inventory/inventory_screen.dart';
import 'package:scan_serve/services/menu_service.dart';
import 'package:scan_serve/services/inventory_service.dart';
import 'package:scan_serve/models/tenant_model.dart';

class FakeMenuService implements MenuService {
  @override
  Future<List<MenuItem>> getMenuItems(String tenantId) async {
    return [];
  }

  @override
  Future<List<Category>> getCategories(String tenantId) async {
    return [];
  }

  @override
  Future<List> loadMenuItemsForTenant(String tenantId) async {
    return [];
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInventoryService implements InventoryService {
  @override
  Future<void> updateStock(String tenantId, String categoryId, String itemId, int newStock, {bool isTracked = true}) async {}

  @override
  Future<void> decrementStock(String tenantId, String categoryId, String itemId, int quantity) async {}

  @override
  Stream<List<MenuItem>> getLowStockItems(String tenantId, {int threshold = 5}) {
    return Stream.value([]);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('InventoryScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryScreen(
              tenantId: 'test_tenant',
              menuService: FakeMenuService(),
              inventoryService: FakeInventoryService(),
            ),
          ),
        ),
      );

      expect(find.byType(InventoryScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
