import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/models/food_record.dart';
import 'package:foodlens_ai_app/repositories/food_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('local repository persists records across instances', () async {
    final eatenAt = DateTime(2026, 6, 28, 12, 30);
    final first = LocalFoodRepository();
    await first.save(
      FoodRecord.empty(
        'local-1',
      ).copyWith(foodName: '雞胸便當', calories: 520, cost: 120, eatenAt: eatenAt),
    );

    final second = LocalFoodRepository();
    final records = await second.watchRecords().first;

    expect(records, hasLength(1));
    expect(records.single.foodName, '雞胸便當');
    expect(records.single.calories, 520);
    expect(records.single.eatenAt, eatenAt);
  });

  test('local repository deletes persisted records', () async {
    final repository = LocalFoodRepository();
    final record = FoodRecord.empty('local-2').copyWith(foodName: '沙拉');
    await repository.save(record);
    await repository.delete(record);

    final reopened = LocalFoodRepository();
    expect(await reopened.watchRecords().first, isEmpty);
  });
}
