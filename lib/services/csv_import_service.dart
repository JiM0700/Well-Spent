/// Service for importing and exporting CSV data for expenses.
class CsvImportService {
  /// Parse CSV rows from a CSV string.
  /// Handles quoted values and proper CSV formatting.
  static List<List<String>> parseCsvRows(String csvString) {
    final rows = <List<String>>[];
    final lines = csvString.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final row = <String>[];
      var current = StringBuffer();
      var inQuotes = false;
      
      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        
        if (char == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            // Escaped quote
            current.write('"');
            i++;
          } else {
            // Toggle quote mode
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          // Field separator
          row.add(current.toString());
          current = StringBuffer();
        } else {
          current.write(char);
        }
      }
      
      // Add last field
      row.add(current.toString());
      rows.add(row);
    }
    
    return rows;
  }
}
