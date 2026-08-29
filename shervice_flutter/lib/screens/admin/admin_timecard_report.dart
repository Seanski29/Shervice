import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as excel;

import '../../constant.dart';
import '../../utils/file_download.dart';

String formatTableHeader(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (cleaned.isEmpty) {
    return 'Column';
  }

  final words = cleaned.split(' ');
  final formatted = words
      .map((word) {
        if (word.isEmpty) {
          return '';
        }

        final lower = word.toLowerCase();
        if (lower == 'id' || lower == 'ids') {
          return 'ID';
        }

        if (word.length <= 2) {
          return lower.toUpperCase();
        }

        return lower[0].toUpperCase() + lower.substring(1);
      })
      .join(' ');

  return formatted;
}

class _TimecardDataSource extends DataTableSource {
  _TimecardDataSource({required this.columns, required this.rows});

  final List<String> columns;
  final List<Map<String, String>> rows;

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) {
      return null;
    }

    final row = rows[index];
    return DataRow(
      cells: columns
          .map(
            (column) => DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 180),
                child: Text(
                  row[column] ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}

class AdminTimecardReport extends StatefulWidget {
  const AdminTimecardReport({super.key});

  @override
  State<AdminTimecardReport> createState() => _AdminTimecardReportState();
}

class _AdminTimecardReportState extends State<AdminTimecardReport> {
  bool _isImporting = false;
  bool _isLoadingSystemData = false;
  final int _rowsPerPage = 10;
  String _sourceFileName = 'No file selected';
  List<String> _columns = [];
  List<Map<String, String>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadTimecardData();
  }

  Future<void> _loadTimecardData() async {
    setState(() => _isLoadingSystemData = true);

    try {
      final response = await http.get(Uri.parse('$backendUrl/admin/timecards'));

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _sourceFileName = 'No timecard data available';
          _columns = [
            'employee',
            'pay_period',
            'day',
            'date',
            'in_time',
            'out_time',
            'work_time',
            'daily_total',
            'note',
          ];
          _rows = [];
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final rawList = decoded is Map
          ? decoded['data'] ?? decoded['timecards'] ?? []
          : decoded ?? [];

      final normalized = _normalizeTimecardRows(rawList);
      final columns = [
        'employee',
        'pay_period',
        'day',
        'date',
        'in_time',
        'out_time',
        'work_time',
        'daily_total',
        'note',
      ];

      if (!mounted) return;

      setState(() {
        _sourceFileName = 'System timecard records';
        _columns = columns;
        _rows = normalized;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceFileName = 'System data unavailable';
        _columns = [
          'employee',
          'pay_period',
          'day',
          'date',
          'in_time',
          'out_time',
          'work_time',
          'daily_total',
          'note',
        ];
        _rows = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSystemData = false);
      }
    }
  }

  List<Map<String, String>> _normalizeTimecardRows(List<dynamic> rawList) {
    final normalized = <Map<String, String>>[];

    for (final item in rawList) {
      if (item is! Map) {
        continue;
      }

      final flat = <String, String>{};
      final map = item as Map<String, dynamic>;

      // Extract employee info
      String employeeId = '';
      String employeeName = '';
      if (map['user_account'] is Map) {
        final userAccount = map['user_account'] as Map<String, dynamic>;
        employeeId = (userAccount['id'] ?? userAccount['user_id'] ?? '')
            .toString();
        employeeName =
            (userAccount['full_name'] ?? userAccount['username'] ?? '')
                .toString();
      } else {
        employeeId = (map['employee_id'] ?? '').toString();
        employeeName = (map['employee_name'] ?? '').toString();
      }

      // Extract dates and times
      String dateStr = (map['date'] ?? map['work_date'] ?? '').toString();
      String inTime = (map['in_time'] ?? map['time_in'] ?? '').toString();
      String outTime = (map['out_time'] ?? map['time_out'] ?? '').toString();
      String workTime = (map['work_time'] ?? map['work_hours'] ?? '')
          .toString();
      String dailyTotal = (map['daily_total'] ?? map['total_hours'] ?? '')
          .toString();
      String payPeriod = (map['pay_period'] ?? '').toString();
      String note = (map['note'] ?? map['notes'] ?? '').toString();

      // Extract day of week from date
      String dayOfWeek = 'NaN';
      if (dateStr.isNotEmpty && dateStr != 'null') {
        try {
          final date = DateTime.parse(dateStr);
          dayOfWeek = _getDayOfWeek(date);
        } catch (_) {
          dayOfWeek = 'NaN';
        }
      }

      flat['employee'] = employeeName.isNotEmpty && employeeId.isNotEmpty
          ? '$employeeName ($employeeId)'
          : employeeName.isNotEmpty
          ? employeeName
          : 'Unknown';
      flat['pay_period'] = payPeriod.isNotEmpty && payPeriod != 'null'
          ? payPeriod
          : 'NaN';
      flat['day'] = dayOfWeek;
      flat['date'] = dateStr.isNotEmpty && dateStr != 'null' ? dateStr : 'NaN';
      flat['in_time'] = inTime.isNotEmpty && inTime != 'null' ? inTime : 'NaN';
      flat['out_time'] = outTime.isNotEmpty && outTime != 'null'
          ? outTime
          : 'NaN';
      flat['work_time'] = workTime.isNotEmpty && workTime != 'null'
          ? workTime
          : 'NaN';
      flat['daily_total'] = dailyTotal.isNotEmpty && dailyTotal != 'null'
          ? dailyTotal
          : 'NaN';
      flat['note'] = note.isNotEmpty && note != 'null' ? note : 'NaN';

      if (flat.isNotEmpty) {
        normalized.add(flat);
      }
    }

    return normalized;
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }

  Future<void> _pickExcelFile() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx', 'csv'],
        withData: true,
      );

      if (result.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No spreadsheet file was selected.')),
        );
        return;
      }

      final file = result.first;
      final lowerName = file.name.toLowerCase();
      final fileBytes = await file.readAsBytes();

      if (lowerName.endsWith('.xls')) {
        final convertedRows = await _convertLegacyXlsDirectly(
          fileBytes,
          file.name,
        );

        if (!mounted) return;

        if (convertedRows.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The legacy .xls file could not be read or converted. Please save it as .xlsx or .csv and try again.',
              ),
            ),
          );
          return;
        }

        setState(() {
          _sourceFileName = '${file.name} (converted in-app)';
          _columns = [
            'employee',
            'pay_period',
            'day',
            'date',
            'in_time',
            'out_time',
            'work_time',
            'daily_total',
            'note',
          ];
          _rows = convertedRows;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Legacy .xls was converted and processed directly. ${convertedRows.length} rows loaded.',
            ),
          ),
        );
        return;
      }

      final parsedRows = _parseSpreadsheet(file.name, fileBytes);

      if (!mounted) return;

      if (parsedRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The selected file does not contain readable rows.'),
          ),
        );
        return;
      }

      setState(() {
        _sourceFileName = file.name;
        _columns = [
          'employee',
          'pay_period',
          'day',
          'date',
          'in_time',
          'out_time',
          'work_time',
          'daily_total',
          'note',
        ];
        _rows = parsedRows;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${parsedRows.length} rows from ${file.name}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to read the spreadsheet: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<List<Map<String, String>>> _convertLegacyXlsDirectly(
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/admin/timecards/upload-legacy-xls'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception('Backend conversion failed (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final rows = decoded['rows'] as List<dynamic>? ?? const [];

      return rows.map<Map<String, String>>((row) {
        final map = row as Map<String, dynamic>;
        return map.map(
          (key, value) => MapEntry(key.toString(), _normalizeCellValue(value)),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, String>> _parseSpreadsheet(
    String fileName,
    Uint8List bytes,
  ) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.csv')) {
      return _parseCsv(bytes);
    }

    if (lowerName.endsWith('.xlsx')) {
      return _parseExcel(bytes);
    }

    if (lowerName.endsWith('.xls')) {
      return [];
    }

    return [];
  }

  List<Map<String, String>> _parseExcel(Uint8List bytes) {
    final workbook = excel.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return [];
    }

    final firstSheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[firstSheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      return [];
    }

    final List<String> headers = [];
    for (int i = 0; i < sheet.rows.first.length; i++) {
      final value = _normalizeCellValue(sheet.rows.first[i]);
      headers.add(value.isEmpty ? 'Column ${i + 1}' : value);
    }

    final parsedRows = <Map<String, String>>[];
    for (final row in sheet.rows.skip(1)) {
      final record = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        final value = i < row.length ? _normalizeCellValue(row[i]) : '';
        record[headers[i]] = value;
      }

      if (record.values.any((value) => value.trim().isNotEmpty)) {
        parsedRows.add(record);
      }
    }

    return parsedRows;
  }

  List<Map<String, String>> _parseCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return [];

    final headers = _splitCsvLine(
      lines.first,
    ).map((value) => value.trim()).toList();
    final parsedRows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final record = <String, String>{};

      for (int index = 0; index < headers.length; index++) {
        final header = headers[index].isNotEmpty
            ? headers[index]
            : 'Column ${index + 1}';
        final value = index < values.length ? values[index].trim() : '';
        record[header] = value;
      }

      if (record.values.any((value) => value.trim().isNotEmpty)) {
        parsedRows.add(record);
      }
    }

    return parsedRows;
  }

  List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final character = line[i];

      if (character == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (character == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }

    values.add(buffer.toString());
    return values;
  }

  String _normalizeCellValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is num) {
      return value.toString();
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${_normalizeCellValue(entry.value)}')
          .join(', ');
    }
    if (value is Iterable) {
      return value.map((item) => _normalizeCellValue(item)).join(', ');
    }
    return value.toString().trim();
  }

  Future<void> _exportCurrentReport() async {
    if (_columns.isEmpty || _rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No timecard data to export.')),
      );
      return;
    }

    try {
      final xlsx = _convertRowsToXlsx(_rows);
      final fileName =
          'Timecard_Report_${DateTime.now().toIso8601String().split('T').first}.xlsx';
      await downloadFileBytes(fileName: fileName, bytes: xlsx);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported $fileName with ${_rows.length} records'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  Uint8List _convertRowsToXlsx(List<Map<String, String>> rows) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sheet1'];
    if (sheet == null) {
      return Uint8List(0);
    }

    final columns = _columns.isNotEmpty
        ? _columns
        : [
            'employee_id',
            'employee_name',
            'date',
            'in_time',
            'out_time',
            'work_hours',
            'daily_total',
            'notes',
          ];
    final headerCells = columns
        .map((column) => excel.TextCellValue(formatTableHeader(column)))
        .toList();
    sheet.insertRowIterables(headerCells, 0);

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = columns
          .map((column) => excel.TextCellValue(row[column] ?? ''))
          .toList();
      sheet.insertRowIterables(values, rowIndex + 1);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      return Uint8List(0);
    }

    return Uint8List.fromList(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<DataColumn> tableColumns = _columns
        .map((column) => DataColumn(label: Text(formatTableHeader(column))))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timecard Report'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timecard Report',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'View, import, and export employee timecard records for payroll and analytics.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accepted formats: .xlsx and .csv. Legacy .xls files are auto-converted to .xlsx.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isImporting ? null : _pickExcelFile,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: const Text('Import Timecard'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _rows.isEmpty ? null : _exportCurrentReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: Colors.blue.shade500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _sourceFileName,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_rows.length} rows',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingSystemData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading system timecard data...'),
                  ],
                ),
              )
            else if (_rows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 58,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No timecard data loaded yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Import timecard data from Excel or CSV files, or system timecard records will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PaginatedDataTable(
                    columns: tableColumns,
                    source: _TimecardDataSource(columns: _columns, rows: _rows),
                    rowsPerPage: _rowsPerPage,
                    availableRowsPerPage: const [10, 20, 50],
                    onPageChanged: (_) {},
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowColor: WidgetStatePropertyAll(
                      isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                    ),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 90,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
