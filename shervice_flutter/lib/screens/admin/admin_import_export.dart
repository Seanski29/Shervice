import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

class _ReportDataSource extends DataTableSource {
  _ReportDataSource({required this.columns, required this.rows});

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
            child: Text(
              displayValue,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
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

class AdminImportExport extends StatefulWidget {
  const AdminImportExport({super.key});

  @override
  State<AdminImportExport> createState() => _AdminImportExportState();
}

class _AdminImportExportState extends State<AdminImportExport> {
  final List<String> _reportTypes = ['Trips', 'Maintenance', 'Timecard'];
  String _selectedReportType = 'Trips';
  bool _isImporting = false;
  bool _isLoadingSystemData = false;
  final int _rowsPerPage = 10;
  String _sourceFileName = 'No file selected';
  
  final List<String> _timecardColumns = [
    'employee', 'pay_period', 'day', 'date', 'in_time', 'out_time', 'work_time', 'daily_total', 'note',
  ];

  List<String> _columns = [];
  List<Map<String, String>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentReportData();
  }

  bool get _canImportCurrentReport => _selectedReportType == 'Attendance' || _selectedReportType == 'Timecard';

  Future<void> _loadCurrentReportData() async {
    if (_selectedReportType == 'Attendance') return;
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
          _rows = [{'report_type': _selectedReportType, 'status': 'No records found', 'generated_at': DateTime.now().toIso8601String()}];
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final rawList = _selectedReportType == 'Trips'
          ? ((decoded is Map ? decoded['trips'] : decoded) ?? [])
          : _selectedReportType == 'Maintenance'
          ? ((decoded is Map ? decoded['data'] : decoded) ?? [])
          : ((decoded is Map ? decoded['data'] ?? decoded['timecards'] : decoded) ?? []);

      final normalized = _normalizeSystemRows(rawList);
      
      final columns = _selectedReportType == 'Timecard' 
          ? _timecardColumns 
          : (normalized.isNotEmpty ? _buildColumns(normalized.first.keys.toList()) : ['report_type', 'status', 'generated_at']);

      if (!mounted) return;
      setState(() {
        _sourceFileName = 'System $_selectedReportType records';
        _columns = columns;
        _rows = normalized.isNotEmpty
            ? normalized
            : [{'report_type': _selectedReportType, 'status': 'No records found', 'generated_at': DateTime.now().toIso8601String()}];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceFileName = 'System data unavailable';
        _columns = ['report_type', 'status', 'generated_at'];
        _rows = [{'report_type': _selectedReportType, 'status': 'No records found', 'generated_at': DateTime.now().toIso8601String()}];
      });
    } finally {
      if (mounted) setState(() => _isLoadingSystemData = false);
    }
  }

  List<Map<String, String>> _normalizeSystemRows(List<dynamic> rawList) {
    final normalized = <Map<String, String>>[];

    for (final item in rawList) {
      if (item is! Map) continue;

      final flat = <String, String>{};
      final map = item as Map<String, dynamic>;

      if (_selectedReportType == 'Timecard') {
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

        flat['employee'] = employeeName.isNotEmpty && employeeId.isNotEmpty ? '$employeeName ($employeeId)' : (employeeName.isNotEmpty ? employeeName : 'Unknown');
        flat['pay_period'] = payPeriod.isNotEmpty && payPeriod != 'null' ? payPeriod : 'NaN';
        flat['day'] = dayOfWeek;
        flat['date'] = dateStr.isNotEmpty && dateStr != 'null' ? dateStr : 'NaN';
        flat['in_time'] = inTime.isNotEmpty && inTime != 'null' ? inTime : 'NaN';
        flat['out_time'] = outTime.isNotEmpty && outTime != 'null' ? outTime : 'NaN';
        flat['work_time'] = workTime.isNotEmpty && workTime != 'null' ? workTime : 'NaN';
        flat['daily_total'] = dailyTotal.isNotEmpty && dailyTotal != 'null' ? dailyTotal : 'NaN';
        flat['note'] = note.isNotEmpty && note != 'null' ? note : 'NaN';
        normalized.add(flat);
        continue;
      }

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

        flat[key] = _normalizeCellValue(value);
      }
      if (flat.isNotEmpty) normalized.add(flat);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No spreadsheet file was selected.')));
        return;
      }

      final file = result.first;
      final lowerName = file.name.toLowerCase();
      final fileBytes = await file.readAsBytes();

      if (_canImportCurrentReport) {
        List<List<dynamic>> rawRows = [];
        if (lowerName.endsWith('.xls')) {
          rawRows = await _convertLegacyXlsDirectlyToRaw(fileBytes, file.name);
          if (rawRows.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read .xls file. Save as .xlsx and try again.')));
            return;
          }
        } else {
          rawRows = _extractRawRows(fileBytes, lowerName.endsWith('.csv'));
        }

        final parsedRows = _applySmartHeuristics(rawRows);
        
        if (!mounted) return;
        if (parsedRows.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid biometric records found.')));
          return;
        }

        setState(() {
          _sourceFileName = file.name;
          _columns = _timecardColumns;
          _rows = parsedRows;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${parsedRows.length} biometric rows from ${file.name}')));
        return;
      }

      if (lowerName.endsWith('.xls')) {
        final convertedRows = await _convertLegacyXlsDirectly(fileBytes, file.name);
        if (!mounted) return;
        if (convertedRows.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The legacy .xls file could not be read. Please save it as .xlsx.')));
          return;
        }
        setState(() {
          _sourceFileName = '${file.name} (converted)';
          _columns = _buildColumns(convertedRows.first.keys.toList());
          _rows = convertedRows;
        });
        return;
      }

      final parsedRows = _parseSpreadsheet(file.name, fileBytes);
      if (!mounted) return;
      if (parsedRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File does not contain readable rows.')));
        return;
      }
      
      setState(() {
        _sourceFileName = file.name;
        _columns = _buildColumns(parsedRows.first.keys.toList());
        _rows = parsedRows;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to read the spreadsheet: $error')));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ─── UPDATED SMART HEURISTIC PARSER FOR BIOMETRICS ───
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

  Future<List<List<dynamic>>> _convertLegacyXlsDirectlyToRaw(Uint8List fileBytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/admin/attendance/upload-legacy-xls'));
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) return [];
      
      final decoded = jsonDecode(response.body);
      final rows = decoded['rows'] as List<dynamic>? ?? const [];
      return rows.map<List<dynamic>>((row) => (row as Map).values.toList()).toList();
    } catch (_) { return []; }
  }

  List<Map<String, String>> _applySmartHeuristics(List<List<dynamic>> rawRows) {
    String currentEmployee = 'Unknown';
    String currentPayPeriod = 'NaN';
    String currentDate = 'NaN';
    String currentDay = 'NaN';

    final parsedRows = <Map<String, String>>[];

    for (var row in rawRows) {
      bool hasEmployeeLabel = false;
      bool hasPayPeriodLabel = false;

      // 1. Check for headers/labels in the current row
      for (int c = 0; c < row.length; c++) {
        String val = _normalizeCellValue(row[c]).trim();
        String lowerVal = val.toLowerCase();

        if (lowerVal == 'employee' || lowerVal == 'name') hasEmployeeLabel = true;
        if (lowerVal.contains('pay period')) hasPayPeriodLabel = true;
        
        if (RegExp(r'\d{2,4}[-/]\d{1,2}[-/]\d{1,4}.*?\d{2,4}[-/]\d{1,2}[-/]\d{1,4}').hasMatch(val)) {
          currentPayPeriod = val;
        }
      }

      // 2. Update active employee if found on this row
      if (hasEmployeeLabel) {
        for (int c = 0; c < row.length; c++) {
          String val = _normalizeCellValue(row[c]).trim();
          String lowerVal = val.toLowerCase();
          if (val.isNotEmpty && lowerVal != 'employee' && lowerVal != 'name') {
            currentEmployee = val;
            break;
          }
        }
      }

      // 3. Update active pay period if found on this row
      if (hasPayPeriodLabel) {
        for (int c = 0; c < row.length; c++) {
          String val = _normalizeCellValue(row[c]).trim();
          String lowerVal = val.toLowerCase();
          if (val.isNotEmpty && !lowerVal.contains('pay period')) {
            currentPayPeriod = val;
            break;
          }
        }
      }

      // 4. Extract Data (Times, Dates, Days)
      String rowDate = '';
      String rowDay = '';
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
            rowDate = datePart; times.add(timePart); continue;
          } else {
            rowDate = datePart; continue;
          }
        }

        if (RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$').hasMatch(val)) {
          rowDate = val; continue;
        }

        final upperVal = val.toUpperCase();
        if (['SUN','MON','TUE','WED','THU','FRI','SAT'].contains(upperVal)) {
          rowDay = upperVal; continue;
        }

        if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(val)) {
          times.add(val.substring(0, 5)); continue; 
        }
        texts.add(val);
      }

      // 5. The "Waterfall" Fix: Inherit missing dates/days from previous rows
      if (rowDate.isNotEmpty) currentDate = rowDate;
      if (rowDay.isNotEmpty) currentDay = rowDay;

      // If this row has times but the biometric machine left the date blank, inherit it!
      if (rowDate.isEmpty && times.isNotEmpty) {
        rowDate = currentDate;
        rowDay = currentDay;
      }

      // 6. Save the row if it contains actual timecard entries
      if (times.isNotEmpty) {
        String inTime = times.isNotEmpty ? times[0] : 'NaN';
        String outTime = times.length > 1 ? times[1] : 'NaN';
        String workTime = times.length > 2 ? times[2] : 'NaN';
        String dailyTotal = times.length > 3 ? times[3] : 'NaN';

        texts.removeWhere((t) => ['IN', 'OUT', 'Work Time', 'Daily Total', 'Note', 'Date', 'Day', 'Employee', 'Pay Period', 'File', 'Timecard Report', 'Column'].contains(t) || t == currentPayPeriod || t == currentEmployee);

        parsedRows.add({
          'employee': currentEmployee,
          'pay_period': currentPayPeriod,
          'day': rowDay.isNotEmpty ? rowDay : 'NaN',
          'date': rowDate.isNotEmpty ? rowDate : 'NaN',
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
  // ─── END SMART PARSER ───

  Future<List<Map<String, String>>> _convertLegacyXlsDirectly(Uint8List fileBytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/admin/attendance/upload-legacy-xls'));
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) throw Exception('Backend conversion failed (${response.statusCode})');
      
      final decoded = jsonDecode(response.body);
      final rows = decoded['rows'] as List<dynamic>? ?? const [];
      return rows.map<Map<String, String>>((row) {
        final map = row as Map<String, dynamic>;
        return map.map((key, value) => MapEntry(key.toString(), _normalizeCellValue(value)));
      }).toList();
    } catch (_) { return []; }
  }

  List<Map<String, String>> _parseSpreadsheet(String fileName, Uint8List bytes) {
    if (!_canImportCurrentReport) return [];
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.csv')) return _parseCsv(bytes);
    if (lowerName.endsWith('.xlsx')) return _parseExcel(bytes);
    return [];
  }

  List<Map<String, String>> _parseExcel(Uint8List bytes) {
    final workbook = excel.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) return [];
    final sheet = workbook.tables[workbook.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) return [];

    final List<String> headers = [];
    for (int i = 0; i < sheet.rows.first.length; i++) {
      final value = _normalizeCellValue(sheet.rows.first[i]);
      headers.add(value.isEmpty ? 'Column ${i + 1}' : value);
    }

    final parsedRows = <Map<String, String>>[];
    for (final row in sheet.rows.skip(1)) {
      final record = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        record[headers[i]] = i < row.length ? _normalizeCellValue(row[i]) : '';
      }
      if (record.values.any((value) => value.trim().isNotEmpty)) parsedRows.add(record);
    }
    return parsedRows;
  }

  List<Map<String, String>> _parseCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return [];

    final headers = _splitCsvLine(lines.first).map((value) => value.trim()).toList();
    final parsedRows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final record = <String, String>{};
      for (int index = 0; index < headers.length; index++) {
        final header = headers[index].isNotEmpty ? headers[index] : 'Column ${index + 1}';
        record[header] = index < values.length ? values[index].trim() : '';
      }
      if (record.values.any((value) => value.trim().isNotEmpty)) parsedRows.add(record);
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
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') { buffer.write('"'); i++; } 
        else { inQuotes = !inQuotes; }
      } else if (character == ',' && !inQuotes) {
        values.add(buffer.toString()); buffer.clear();
      } else { buffer.write(character); }
    }
    values.add(buffer.toString());
    return values;
  }

  List<String> _buildColumns(List<String> keys) {
    final seen = <String>{};
    final unique = <String>[];
    for (final key in keys) {
      final cleaned = key.trim();
      if (cleaned.isEmpty) continue;
      final normalized = seen.contains(cleaned) ? '${cleaned}_${seen.length}' : cleaned;
      seen.add(cleaned);
      unique.add(normalized);
    }
    return unique.isEmpty ? ['No columns detected'] : unique;
  }

  Uint8List _convertRowsToXlsx(List<Map<String, String>> rows) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sheet1'];
    if (sheet == null) return Uint8List(0);

    final isTimecard = _selectedReportType == 'Timecard' || _selectedReportType == 'Attendance';
    final columns = isTimecard ? _timecardColumns : (_columns.isNotEmpty ? _columns : ['Column 1']);
    
    final headerCells = columns.map((column) => excel.TextCellValue(formatTableHeader(column))).toList();
    sheet.insertRowIterables(headerCells, 0);

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = columns.map((column) {
        String rawValue = row[column] ?? '';
        String displayValue = rawValue;

        if (isTimecard) {
          if (column == 'in_time' || column == 'out_time') displayValue = _formatTimeValue(rawValue);
          else if (column == 'work_time' || column == 'daily_total') displayValue = _formatDurationValue(rawValue);
          else if (column == 'date') displayValue = _formatDateValue(rawValue);
          else if (column == 'day') displayValue = displayValue.toUpperCase();
        }

        return excel.TextCellValue(displayValue);
      }).toList();
      sheet.insertRowIterables(values, rowIndex + 1);
    }

    final bytes = workbook.save();
    return bytes != null ? Uint8List.fromList(bytes) : Uint8List(0);
  }

  String _normalizeCellValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    if (value is num) return value.toString();
    if (value is Map) return value.entries.map((entry) => '${entry.key}: ${_normalizeCellValue(entry.value)}').join(', ');
    if (value is Iterable) return value.map((item) => _normalizeCellValue(item)).join(', ');
    return value.toString().trim();
  }

  Future<void> _exportCurrentReport() async {
    if (_selectedReportType == 'Attendance' && _columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import attendance data before exporting it.')));
      return;
    }

    final isAttendanceExport = _selectedReportType == 'Attendance' || _selectedReportType == 'Timecard';
    final exportColumns = isAttendanceExport ? _timecardColumns : (_rows.isEmpty ? ['report_type', 'status', 'generated_at'] : _columns);

    final fileName = isAttendanceExport
        ? 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : '${_selectedReportType.toLowerCase()}_report_${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      final bytes = isAttendanceExport
          ? _convertRowsToXlsx(_rows.isEmpty ? [{for (final column in exportColumns) column: ''}] : _rows)
          : utf8.encode(<List<String>>[
              exportColumns,
              ...(_rows.isEmpty ? [{'report_type': _selectedReportType, 'status': 'No records found', 'generated_at': DateTime.now().toIso8601String()}] : _rows).map((row) => exportColumns.map((column) => _escapeCsv(row[column] ?? '')).toList())
            ].map((row) => row.map((value) => value).join(',')).join('\n'));

      if (kIsWeb) {
        await downloadFileBytes(fileName: fileName, bytes: bytes);
      } else {
        await FilePicker.saveFile(fileName: fileName, bytes: bytes);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported $fileName')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to export report: $error')));
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tableColumns = _columns.isEmpty
        ? const [DataColumn(label: Text('No data'))]
        : _columns.map((column) => DataColumn(label: Text(formatTableHeader(column)))).toList();

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
                        Text('Import & Export', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        Text('Import attendance and timecard data from biometric Excel files. Export system-generated reports for trips, maintenance, and timecards.', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        Text('Accepted formats: .xlsx and .csv. Legacy .xls files are auto-converted to .xlsx.', style: TextStyle(fontSize: 12, color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isImporting || !_canImportCurrentReport ? null : _pickExcelFile,
                    icon: _isImporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file_outlined),
                    label: Text(_isImporting ? 'Importing...' : _canImportCurrentReport ? 'Import Excel' : 'Import Locked'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _exportCurrentReport,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(_selectedReportType == 'Attendance' || _selectedReportType == 'Timecard' ? 'Export XLS' : 'Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: Colors.blue.shade500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _canImportCurrentReport ? 'Active file: $_sourceFileName' : 'Import is only available for attendance records.',
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                      child: Text('${_rows.length} rows', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
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
                    avatar: Icon(type == 'Trips' ? Icons.route_outlined : type == 'Maintenance' ? Icons.build_outlined : type == 'Timecard' ? Icons.schedule_outlined : Icons.how_to_reg_outlined, size: 18),
                    onSelected: (_) async {
                      setState(() => _selectedReportType = type);
                      if (type != 'Attendance' && type != 'Timecard') {
                        await _loadCurrentReportData();
                      } else {
                        await _loadCurrentReportData();
                      }
                    },
                    selectedColor: Colors.blue.shade100,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.blue.shade900 : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (_isLoadingSystemData && !_canImportCurrentReport)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                  child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Loading system report data...')])),
                )
              else if (_rows.isEmpty)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_chart_outlined, size: 58, color: Colors.grey.shade500),
                      const SizedBox(height: 16),
                      Text('No report data imported yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      Text(_canImportCurrentReport ? 'Select a biometric .xlsx or .csv file to preview records here. Legacy .xls files are auto-converted to .xlsx for compatibility.' : 'Trips, maintenance, and timecard reports are generated from the system and exported here.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B))),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
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
                      headingRowColor: WidgetStatePropertyAll(isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
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