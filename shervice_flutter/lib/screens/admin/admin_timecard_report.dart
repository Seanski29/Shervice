import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as excel;

import '../../constant.dart';
import '../../utils/file_download.dart';

String _getDayOfWeek(DateTime date) {
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return days[date.weekday - 1];
}

String formatTableHeader(String value) {
  final lowerVal = value.trim().toLowerCase();
  if (lowerVal == 'employee') return 'Employee';
  if (lowerVal == 'pay_period') return 'Pay Period';
  if (lowerVal == 'day') return 'Day';
  if (lowerVal == 'date') return 'Date';
  if (lowerVal == 'in_time' || lowerVal == 'in') return 'IN';
  if (lowerVal == 'out_time' || lowerVal == 'out') return 'OUT';
  if (lowerVal == 'work_time' || lowerVal == 'work_hours') return 'Work Time';
  if (lowerVal == 'daily_total' || lowerVal == 'total_hours') return 'Daily Total';
  if (lowerVal == 'note' || lowerVal == 'notes' || lowerVal == 'remarks') return 'Note';

  final cleaned = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (cleaned.isEmpty) return 'Column';

  final words = cleaned.split(' ');
  return words.map((word) {
    if (word.isEmpty) return '';
    final lowerWord = word.toLowerCase();
    if (lowerWord == 'id' || lowerWord == 'ids') return 'ID';
    if (word.length <= 2) return lowerWord.toUpperCase();
    return lowerWord[0].toUpperCase() + lowerWord.substring(1);
  }).join(' ');
}

String _formatTimeValue(String val) {
  if (val.isEmpty || val == 'null' || val == 'NaN') return '-';
  final amPmRegex = RegExp(r'^\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)$');
  if (amPmRegex.hasMatch(val.trim())) return val.trim().toUpperCase();
  
  try {
    final parsed = DateTime.parse(val);
    return _formatDateTimeToTime(parsed);
  } catch (_) {}
  
  try {
    final parts = val.trim().split(' ');
    if (parts.length == 2) {
      final timeParts = parts[1].split(':');
      if (timeParts.length >= 2) {
        return _formatHoursMinutes(int.parse(timeParts[0]), int.parse(timeParts[1]));
      }
    }
  } catch (_) {}
  
  try {
    final parts = val.trim().split(':');
    if (parts.length >= 2) {
      return _formatHoursMinutes(int.parse(parts[0]), int.parse(parts[1]));
    }
  } catch (_) {}
  
  return val;
}

String _formatDateTimeToTime(DateTime dt) => _formatHoursMinutes(dt.hour, dt.minute);

String _formatHoursMinutes(int hour, int minute) {
  final ampm = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMin = minute.toString().padLeft(2, '0');
  return '${displayHour.toString().padLeft(2, '0')}:$displayMin $ampm';
}

String _formatDurationValue(String val) {
  if (val.isEmpty || val == 'null' || val == 'NaN') return '-';
  final trimmed = val.trim();
  final doubleValue = double.tryParse(trimmed);
  
  if (doubleValue != null) {
    final hours = doubleValue.floor();
    final minutes = ((doubleValue - hours) * 60).round();
    if (hours == 0 && minutes == 0) return '0h 0m';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
  
  try {
    final parts = trimmed.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        if (hours == 0 && minutes == 0) return '0h 0m';
        if (hours == 0) return '${minutes}m';
        if (minutes == 0) return '${hours}h';
        return '${hours}h ${minutes}m';
      }
    }
  } catch (_) {}
  
  if (trimmed.contains('h') || trimmed.contains('m')) return trimmed;
  return val;
}

String _formatDateValue(String val) {
  if (val.isEmpty || val == 'null' || val == 'NaN') return '-';
  try {
    final cleanDate = val.trim().split('T').first;
    final parsed = DateTime.tryParse(cleanDate);
    if (parsed != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    }
    return cleanDate;
  } catch (_) {
    return val;
  }
}

class _TimecardDataSource extends DataTableSource {
  _TimecardDataSource({required this.columns, required this.rows});

  final List<String> columns;
  final List<Map<String, String>> rows;

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;

    final row = rows[index];
    return DataRow(
      cells: columns.map((column) {
        String rawValue = row[column] ?? '';
        String displayValue = rawValue;

        if (column == 'in_time' || column == 'out_time') displayValue = _formatTimeValue(rawValue);
        else if (column == 'work_time' || column == 'daily_total') displayValue = _formatDurationValue(rawValue);
        else if (column == 'date') displayValue = _formatDateValue(rawValue);
        else if (column == 'day') displayValue = displayValue.toUpperCase();

        return DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 180),
            child: Text(displayValue, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        );
      }).toList(),
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

  final List<String> _masterColumns = [
    'employee', 'pay_period', 'day', 'date', 'in_time', 'out_time', 'work_time', 'daily_total', 'note',
  ];
  
  List<String> _columns = [];
  List<Map<String, String>> _rows = [];

  @override
  void initState() {
    super.initState();
    _columns = _masterColumns;
    _loadTimecardData();
  }

  Future<void> _loadTimecardData() async {
    setState(() => _isLoadingSystemData = true);
    try {
      final response = await http.get(Uri.parse('$backendUrl/admin/timecards'));
      if (response.statusCode != 200) throw Exception();
      
      final decoded = jsonDecode(response.body);
      final rawList = decoded is Map ? decoded['data'] ?? decoded['timecards'] ?? [] : decoded ?? [];
      final normalized = _normalizeTimecardRows(rawList);

      if (!mounted) return;
      setState(() {
        _sourceFileName = 'System timecard records';
        _columns = _masterColumns;
        _rows = normalized;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceFileName = 'System data unavailable';
        _columns = _masterColumns;
        _rows = [];
      });
    } finally {
      if (mounted) setState(() => _isLoadingSystemData = false);
    }
  }

  List<Map<String, String>> _normalizeTimecardRows(List<dynamic> rawList) {
    final normalized = <Map<String, String>>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      final map = item as Map<String, dynamic>;

      String employeeId = '';
      String employeeName = '';
      if (map['user_account'] is Map) {
        final userAccount = map['user_account'] as Map<String, dynamic>;
        employeeId = (userAccount['id'] ?? userAccount['user_id'] ?? '').toString();
        employeeName = (userAccount['full_name'] ?? userAccount['username'] ?? '').toString();
      } else {
        employeeId = (map['employee_id'] ?? '').toString();
        employeeName = (map['employee_name'] ?? '').toString();
      }

      String dateStr = (map['date'] ?? map['work_date'] ?? '').toString();
      String inTime = (map['in_time'] ?? map['time_in'] ?? '').toString();
      String outTime = (map['out_time'] ?? map['time_out'] ?? '').toString();
      String workTime = (map['work_time'] ?? map['work_hours'] ?? '').toString();
      String dailyTotal = (map['daily_total'] ?? map['total_hours'] ?? '').toString();
      String payPeriod = (map['pay_period'] ?? '').toString();
      String note = (map['note'] ?? map['notes'] ?? '').toString();
      String dayOfWeek = 'NaN';

      if (dateStr.isNotEmpty && dateStr != 'null') {
        try {
          final date = DateTime.parse(dateStr);
          dayOfWeek = _getDayOfWeek(date);
        } catch (_) { dayOfWeek = 'NaN'; }
      }

      normalized.add({
        'employee': employeeName.isNotEmpty && employeeId.isNotEmpty ? '$employeeName ($employeeId)' : (employeeName.isNotEmpty ? employeeName : 'Unknown'),
        'pay_period': payPeriod.isNotEmpty && payPeriod != 'null' ? payPeriod : 'NaN',
        'day': dayOfWeek,
        'date': dateStr.isNotEmpty && dateStr != 'null' ? dateStr : 'NaN',
        'in_time': inTime.isNotEmpty && inTime != 'null' ? inTime : 'NaN',
        'out_time': outTime.isNotEmpty && outTime != 'null' ? outTime : 'NaN',
        'work_time': workTime.isNotEmpty && workTime != 'null' ? workTime : 'NaN',
        'daily_total': dailyTotal.isNotEmpty && dailyTotal != 'null' ? dailyTotal : 'NaN',
        'note': note.isNotEmpty && note != 'null' ? note : 'NaN',
      });
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file was selected.')));
        return;
      }

      final file = result.first;
      final lowerName = file.name.toLowerCase();
      final fileBytes = await file.readAsBytes();
      List<List<dynamic>> rawRows = [];
      
      if (lowerName.endsWith('.xls')) {
        rawRows = await _convertLegacyXlsDirectly(fileBytes, file.name);
        if (!mounted) return;
        if (rawRows.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read .xls file. Please save as .xlsx.')));
          return;
        }
      } else {
        rawRows = _extractRawRows(fileBytes, lowerName.endsWith('.csv'));
      }

      final parsedRows = _applySmartHeuristics(rawRows);

      if (!mounted) return;
      if (parsedRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid timecard records found in this file.')));
        return;
      }

      setState(() {
        _sourceFileName = file.name;
        _columns = _masterColumns;
        _rows = parsedRows;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully mapped ${parsedRows.length} biometric rows.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  List<List<dynamic>> _extractRawRows(Uint8List bytes, bool isCsv) {
    List<List<dynamic>> rawRows = [];
    if (isCsv) {
      final content = utf8.decode(bytes);
      final lines = const LineSplitter().convert(content);
      for (var line in lines) {
        List<String> values = [];
        StringBuffer buffer = StringBuffer();
        bool inQuotes = false;
        for (int i = 0; i < line.length; i++) {
          if (line[i] == '"') {
            if (inQuotes && i + 1 < line.length && line[i + 1] == '"') { buffer.write('"'); i++; } 
            else { inQuotes = !inQuotes; }
          } else if (line[i] == ',' && !inQuotes) {
            values.add(buffer.toString()); buffer.clear();
          } else { buffer.write(line[i]); }
        }
        values.add(buffer.toString());
        rawRows.add(values);
      }
    } else {
      final workbook = excel.Excel.decodeBytes(bytes);
      if (workbook.tables.isNotEmpty) {
        final sheet = workbook.tables[workbook.tables.keys.first]!;
        rawRows = sheet.rows;
      }
    }
    return rawRows;
  }

  Future<List<List<dynamic>>> _convertLegacyXlsDirectly(Uint8List fileBytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/admin/timecards/upload-legacy-xls'));
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) return [];
      
      final decoded = jsonDecode(response.body);
      final rows = decoded['rows'] as List<dynamic>? ?? const [];
      return rows.map<List<dynamic>>((row) {
        final map = row as Map<String, dynamic>;
        return map.values.toList();
      }).toList();
    } catch (_) { return []; }
  }

  List<Map<String, String>> _applySmartHeuristics(List<List<dynamic>> rawRows) {
    String globalEmployee = 'Unknown';
    String globalPayPeriod = 'NaN';

    for (var row in rawRows) {
      for (int c = 0; c < row.length; c++) {
        String val = _normalizeCellValue(row[c]).trim();
        String lowerVal = val.toLowerCase();

        if (lowerVal == 'employee' || lowerVal == 'name') {
          if (c + 1 < row.length && _normalizeCellValue(row[c+1]).isNotEmpty) globalEmployee = _normalizeCellValue(row[c+1]);
        }
        if (lowerVal.contains('pay period')) {
          if (c + 1 < row.length && _normalizeCellValue(row[c+1]).isNotEmpty) globalPayPeriod = _normalizeCellValue(row[c+1]);
        }
        if (RegExp(r'\d{2,4}[-/]\d{1,2}[-/]\d{1,4}.*?\d{2,4}[-/]\d{1,2}[-/]\d{1,4}').hasMatch(val)) {
          globalPayPeriod = val;
        }
      }
    }

    final parsedRows = <Map<String, String>>[];

    for (var row in rawRows) {
      String date = '';
      String day = '';
      List<String> times = [];
      List<String> texts = [];

      for (var cell in row) {
        String val = _normalizeCellValue(cell).trim();
        if (val.isEmpty) continue;

        bool isIsoDate = val.contains('T') && RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(val);
        if (isIsoDate) {
          final datePart = val.split('T')[0];
          final timePart = val.split('T').length > 1 ? val.split('T')[1].substring(0, 5) : '';
          
          if (datePart == '1899-12-30' || datePart == '1899-12-31') {
            times.add(timePart); continue;
          } else if (timePart.isNotEmpty && timePart != '00:00') {
            date = datePart; times.add(timePart); continue;
          } else {
            date = datePart; continue;
          }
        }

        if (RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$').hasMatch(val)) {
          date = val; continue;
        }

        final upperVal = val.toUpperCase();
        if (['SUN','MON','TUE','WED','THU','FRI','SAT'].contains(upperVal)) {
          day = upperVal; continue;
        }

        if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(val)) {
          times.add(val.substring(0, 5)); continue; 
        }

        texts.add(val);
      }

      if (date.isNotEmpty || times.length >= 2) {
        String inTime = times.isNotEmpty ? times[0] : 'NaN';
        String outTime = times.length > 1 ? times[1] : 'NaN';
        String workTime = times.length > 2 ? times[2] : 'NaN';
        String dailyTotal = times.length > 3 ? times[3] : 'NaN';

        texts.removeWhere((t) => ['IN', 'OUT', 'Work Time', 'Daily Total', 'Note', 'Date', 'Day', 'Employee', 'Pay Period', 'File', 'Timecard Report', 'Column'].contains(t) || t == globalPayPeriod || t == globalEmployee);

        parsedRows.add({
          'employee': globalEmployee,
          'pay_period': globalPayPeriod,
          'day': day.isNotEmpty ? day : 'NaN',
          'date': date.isNotEmpty ? date : 'NaN',
          'in_time': inTime,
          'out_time': outTime,
          'work_time': workTime,
          'daily_total': dailyTotal,
          'note': texts.isNotEmpty ? texts.join(' | ') : 'NaN',
        });
      }
    }
    return parsedRows;
  }

  String _normalizeCellValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    if (value is num) return value.toString();
    return value.toString().trim();
  }

  Future<void> _exportCurrentReport() async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export.')));
      return;
    }

    try {
      final xlsx = _convertRowsToXlsx(_rows);
      final fileName = 'Timecard_Report_${DateTime.now().toIso8601String().split('T').first}.xlsx';
      await downloadFileBytes(fileName: fileName, bytes: xlsx);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported $fileName')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  Uint8List _convertRowsToXlsx(List<Map<String, String>> rows) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sheet1'];
    if (sheet == null) return Uint8List(0);

    final headerCells = _masterColumns.map((column) => excel.TextCellValue(formatTableHeader(column))).toList();
    sheet.insertRowIterables(headerCells, 0);

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = _masterColumns.map((column) {
        String rawValue = row[column] ?? '';
        String displayValue = rawValue;

        if (column == 'in_time' || column == 'out_time') displayValue = _formatTimeValue(rawValue);
        else if (column == 'work_time' || column == 'daily_total') displayValue = _formatDurationValue(rawValue);
        else if (column == 'date') displayValue = _formatDateValue(rawValue);
        else if (column == 'day') displayValue = displayValue.toUpperCase();

        return excel.TextCellValue(displayValue);
      }).toList();
      
      sheet.insertRowIterables(values, rowIndex + 1);
    }
    
    final bytes = workbook.save();
    return bytes != null ? Uint8List.fromList(bytes) : Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<DataColumn> tableColumns = _columns.map((col) => DataColumn(label: Text(formatTableHeader(col)))).toList();

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
                      Text('Timecard Report', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text('View, import, and export employee timecard records for payroll and analytics.', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isImporting ? null : _pickExcelFile,
                  icon: _isImporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file),
                  label: const Text('Import Timecard'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _rows.isEmpty ? null : _exportCurrentReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Analytics XLS'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: Colors.blue.shade500),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_sourceFileName, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                    child: Text('${_rows.length} rows', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingSystemData)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Loading system timecard data...')]),
              )
            else if (_rows.isEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.table_chart_outlined, size: 58, color: Colors.grey.shade500), const SizedBox(height: 16), Text('No timecard data loaded yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))), const SizedBox(height: 8), Text('Import timecard data from Excel or CSV files, or system timecard records will appear here.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)))]),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
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
                    headingRowColor: WidgetStatePropertyAll(isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
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