import 'package:flutter_test/flutter_test.dart';
import 'package:well_spent/services/csv_import_service.dart';

void main() {
  test('parseCsvRows handles quoted values and headers', () {
    final rows = CsvImportService.parseCsvRows('title,amount,category\n"Coffee","4.5","food"');

    expect(rows.first, ['title', 'amount', 'category']);
    expect(rows.last, ['Coffee', '4.5', 'food']);
  });
}
