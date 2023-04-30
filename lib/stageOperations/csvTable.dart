
import 'dart:io';

class CsvRow<T> {
  List<T> values;
  String? rest;

  CsvRow(this.values, [this.rest]);
}

class CsvTable<T> {
  String? lineSeparatorHint;
  String get lineSeparator => lineSeparatorHint ?? "\r\n";
  List<CsvRow<T>> rows;
  List<String> rest;
  bool hasEndBlankLine = false;

  CsvTable({
    required this.rows,
    this.rest = const [],
    this.hasEndBlankLine = false,
    this.lineSeparatorHint,
  });

  Iterable<T> getColumn(int index) => rows.map((e) => e.values[index]);
}

class CsvNumTable extends CsvTable<int> {
  CsvNumTable({
    required super.rows,
    super.rest = const [],
    super.hasEndBlankLine = false,
    super.lineSeparatorHint,
  });

  static CsvNumTable fromCsv(String csv, [int maxColumns = -1]) {
    String lineSeparator;
    if (csv.contains("\r\n"))
      lineSeparator = "\r\n";
    else
      lineSeparator = "\n";
    var lines = csv
      .split(lineSeparator)
      .toList();
    List<CsvRow<int>> rows = [];
    int addRestFrom = -1;
    bool hasEndBlankLine = false;
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      var values = line.split(",");
      String? rest;
      if (maxColumns > 0 && values.length > maxColumns) {
        rest = values.sublist(maxColumns).join(",");
        values = values.sublist(0, maxColumns);
      }
      if (i == lines.length - 1 && line == "") {
        hasEndBlankLine = true;
        break;
      }
      try {
        rows.add(CsvRow(values.map((e) => int.parse(e)).toList(), rest));
      } catch (e, trace) {
        print("Error parsing line $i: $line");
        print(e);
        print(trace);
        addRestFrom = i;
        break;
      }
    }
    List<String> rest = const [];
    if (addRestFrom != -1) {
      rest = lines.sublist(addRestFrom);
    }
    return CsvNumTable(
        rows: rows,
        rest: rest,
        hasEndBlankLine: hasEndBlankLine,
        lineSeparatorHint: lineSeparator,
    );
  }
  static Future<CsvNumTable> fromFile(File file, [int maxColumns = -1]) async {
    return fromCsv(await file.readAsString(), maxColumns);
  }

  String toCsv() {
    var sb = StringBuffer();
    for (int i = 0; i < rows.length; i++) {
      var row = rows[i];
      var cells = row.values.map((e) => e.toString());
      if (row.rest != null)
        cells = cells.followedBy([row.rest!]);
      sb.write(cells.join(","));
      if (i != rows.length - 1)
        sb.write(lineSeparator);
    }
    if (hasEndBlankLine)
      sb.write(lineSeparator);
    return sb.toString();
  }

  Future<void> toFile(File file) async {
    print("Saving ${file.path}");
    await file.writeAsString(toCsv());
  }
}
