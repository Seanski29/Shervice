import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

class _ReportDataSource extends DataTableSource {
  _ReportDataSource({required this.columns, required this.rows});

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

class AdminImportExport extends StatefulWidget {
  const AdminImportExport({super.key});

  @override
  State<AdminImportExport> createState() => _AdminImportExportState();
}

class _AdminImportExportState extends State<AdminImportExport> {
  final List<String> _reportTypes = [
    'Trips',
    'Maintenance',
    'Attendance',
    'Timecard',
  ];
  String _selectedReportType = 'Trips';
  bool _isImporting = false;
  bool _isLoadingSystemData = false;
  final int _rowsPerPage = 10;
  String _sourceFileName = 'No file selected';
  List<String> _columns = [];
  List<Map<String, String>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentReportData();
  }

  bool get _canImportCurrentReport =>
      _selectedReportType == 'Attendance' || _selectedReportType == 'Timecard';

  Future<void> _loadCurrentReportData() async {
    if (_selectedReportType == 'Attendance') {
      return;
    }

    setState(() => _isLoadingSystemData = true);

    try {
      final endpoint = _selectedReportType == 'Trips'
          ? '$backendUrl/trips'
          : _selectedReportType == 'Maintenance'
          ? '$backendUrl/vehicles/maintenance'
          : '$backendUrl/admin/timecards';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _sourceFileName = 'No system data available';
          _columns = ['report_type', 'status', 'generated_at'];
          _rows = [
            {
              'report_type': _selectedReportType,
              'status': 'No records found',
              'generated_at': DateTime.now().toIso8601String(),
            },
          ];
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final rawList = _selectedReportType == 'Trips'
          ? ((decoded is Map ? decoded['trips'] : decoded) ?? [])
          : _selectedReportType == 'Maintenance'
          ? ((decoded is Map ? decoded['data'] : decoded) ?? [])
          : ((decoded is Map
                    ? decoded['data'] ?? decoded['timecards']
                    : decoded) ??
                []);

      final normalized = _normalizeSystemRows(rawList);
      final columns = normalized.isNotEmpty
          ? _buildColumns(normalized.first.keys.toList())
          : ['report_type', 'status', 'generated_at'];

      if (!mounted) return;

      setState(() {
        _sourceFileName = _selectedReportType == 'Trips'
            ? 'System trip records'
            : _selectedReportType == 'Maintenance'
            ? 'System maintenance records'
            : 'System timecard records';
        _columns = columns;
        _rows = normalized.isNotEmpty
            ? normalized
            : [
                {
                  'report_type': _selectedReportType,
                  'status': 'No records found',
                  'generated_at': DateTime.now().toIso8601String(),
                },
              ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceFileName = 'System data unavailable';
        _columns = ['report_type', 'status', 'generated_at'];
        _rows = [
          {
            'report_type': _selectedReportType,
            'status': 'No records found',
            'generated_at': DateTime.now().toIso8601String(),
          },
        ];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSystemData = false);
      }
    }
  }

  List<Map<String, String>> _normalizeSystemRows(List<dynamic> rawList) {
    final normalized = <Map<String, String>>[];

    for (final item in rawList) {
      if (item is! Map) {
        continue;
      }

      final flat = <String, String>{};
      final map = item as Map<String, dynamic>;

      for (final entry in map.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        if (key == 'user_account' && value is Map) {
          final userName = value['full_name'] ?? value['username'] ?? '';
          flat['driver_name'] = _normalizeCellValue(userName);
          continue;
        }

        if (key == 'vehicle' && value is Map) {
          final plate = value['plate_number'] ?? '';
          final vehicleType = value['bus_type'] ?? '';
          flat['plate_number'] = _normalizeCellValue(plate);
          flat['bus_type'] = _normalizeCellValue(vehicleType);
          continue;
        }

        if (key == 'oic_profile' && value is Map) {
          final company = value['company_name'] ?? '';
          flat['company_name'] = _normalizeCellValue(company);
          continue;
        }

        if (value is Map) {
          flat[key] = _normalizeCellValue(value);
        } else if (value is List) {
          flat[key] = _normalizeCellValue(value);
        } else {
          flat[key] = _normalizeCellValue(value);
        }
      }

      if (flat.isNotEmpty) {
        normalized.add(flat);
      }
    }

    return normalized;
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

        final normalizedColumns = _buildColumns(
          convertedRows.first.keys.toList(),
        );

        setState(() {
          _sourceFileName = '${file.name} (converted in-app)';
          _columns = normalizedColumns;
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

      final normalizedColumns = _buildColumns(parsedRows.first.keys.toList());

      setState(() {
        _sourceFileName = file.name;
        _columns = normalizedColumns;
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
        Uri.parse('$backendUrl/admin/attendance/upload-legacy-xls'),
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
    if (!_canImportCurrentReport) {
      return [];
    }

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

  List<String> _buildColumns(List<String> keys) {
    final seen = <String>{};
    final unique = <String>[];

    for (final key in keys) {
      final cleaned = key.trim();
      if (cleaned.isEmpty) {
        continue;
      }

      final normalized = seen.contains(cleaned)
          ? '${cleaned}_${seen.length}'
          : cleaned;
      seen.add(cleaned);
      unique.add(normalized);
    }

    return unique.isEmpty ? ['No columns detected'] : unique;
  }

  Uint8List _convertRowsToXlsx(List<Map<String, String>> rows) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sheet1'];
    if (sheet == null) {
      return Uint8List(0);
    }

    final columns = _columns.isNotEmpty ? _columns : ['Column 1'];
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

  Uint8List _convertLegacyXlsToXlsx(Uint8List bytes, String fileName) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sheet1'];
    if (sheet == null) {
      return Uint8List(0);
    }

    final compatibilityRows = [
      ['Compatibility template', 'Legacy .xls is not directly readable'],
      ['Original file', fileName],
      ['Action required', 'Open in Excel and save as .xlsx or .csv'],
      ['Supported formats', '.xlsx and .csv only'],
      [
        'Required columns',
        'Employee ID, Employee Name, Date, Time In, Time Out, Status',
      ],
      ['Sample row', '1001, Juan Dela Cruz, 2026-08-29, 07:30, 17:30, Present'],
    ];

    for (int rowIndex = 0; rowIndex < compatibilityRows.length; rowIndex++) {
      final row = compatibilityRows[rowIndex];
      sheet.insertRowIterables(
        row.map((value) => excel.TextCellValue(value)).toList(),
        rowIndex,
      );
    }

    final converted = workbook.save();
    if (converted == null) {
      return Uint8List(0);
    }

    return Uint8List.fromList(converted);
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
    if (_selectedReportType == 'Attendance' && _columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import attendance data before exporting it.'),
        ),
      );
      return;
    }

    final exportColumns = _selectedReportType == 'Attendance'
        ? _columns
        : (_rows.isEmpty
              ? ['report_type', 'status', 'generated_at']
              : _columns);

    final exportRows = _selectedReportType == 'Attendance'
        ? (_rows.isEmpty
              ? [
                  {for (final column in exportColumns) column: ''},
                ]
              : _rows)
        : (_rows.isEmpty
              ? [
                  {
                    'report_type': _selectedReportType,
                    'status': 'No records found',
                    'generated_at': DateTime.now().toIso8601String(),
                  },
                ]
              : _rows);

    final isAttendanceExport = _selectedReportType == 'Attendance';

    final csvRows = <List<String>>[
      exportColumns,
      ...exportRows.map(
        (row) => exportColumns
            .map((column) => _escapeCsv(row[column] ?? ''))
            .toList(),
      ),
    ];

    final csv = csvRows
        .map((row) => row.map((value) => value).join(','))
        .join('\n');

    final fileName = isAttendanceExport
        ? 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : '${_selectedReportType.toLowerCase()}_report_${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      final bytes = isAttendanceExport
          ? _convertRowsToXlsx(
              _rows.isEmpty
                  ? [
                      {for (final column in exportColumns) column: ''},
                    ]
                  : _rows,
            )
          : utf8.encode(csv);

      if (kIsWeb) {
        await downloadFileBytes(fileName: fileName, bytes: bytes);
      } else {
        await FilePicker.saveFile(fileName: fileName, bytes: bytes);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported $fileName')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export report: $error')),
      );
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tableColumns = _columns.isEmpty
        ? const [DataColumn(label: Text('No data'))]
        : _columns
              .map(
                (column) => DataColumn(label: Text(formatTableHeader(column))),
              )
              .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          'Import & Export',
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
                          'Import attendance and timecard data from biometric Excel files. Export system-generated reports for trips, maintenance, and timecards.',
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
                    onPressed: _isImporting || !_canImportCurrentReport
                        ? null
                        : _pickExcelFile,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _isImporting
                          ? 'Importing...'
                          : _canImportCurrentReport
                          ? 'Import Excel'
                          : 'Import Locked',
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _exportCurrentReport,
                    icon: const Icon(Icons.download_outlined),
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
                    Icon(
                      Icons.description_outlined,
                      color: Colors.blue.shade500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _canImportCurrentReport
                            ? 'Active file: $_sourceFileName'
                            : 'Import is only available for attendance records.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _reportTypes.map((type) {
                  final isSelected = _selectedReportType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    avatar: Icon(
                      type == 'Trips'
                          ? Icons.route_outlined
                          : type == 'Maintenance'
                          ? Icons.build_outlined
                          : type == 'Timecard'
                          ? Icons.schedule_outlined
                          : Icons.how_to_reg_outlined,
                      size: 18,
                    ),
                    onSelected: (_) async {
                      setState(() => _selectedReportType = type);
                      if (type != 'Attendance') {
                        await _loadCurrentReportData();
                      }
                    },
                    selectedColor: Colors.blue.shade100,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.blue.shade900
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (_isLoadingSystemData && !_canImportCurrentReport)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading system report data...'),
                      ],
                    ),
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
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
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
                        'No report data imported yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _canImportCurrentReport
                            ? 'Select a biometric .xlsx or .csv file to preview records here. Legacy .xls files are auto-converted to .xlsx for compatibility.'
                            : 'Trips, maintenance, and timecard reports are generated from the system and exported here.',
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
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: PaginatedDataTable(
                      columns: tableColumns,
                      source: _ReportDataSource(columns: _columns, rows: _rows),
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
      ),
    );
  }
}
