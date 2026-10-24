import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const appName = 'CHEVALLIER LE PAGE MARIE FRANC';
const companyName = 'CHEVALLIER LE PAGE MARIE FRANCOISE NADINE JEANNINE';
const supportEmail = 'contact@chevallierlepage.fr';
const screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const localStoreChannel = MethodChannel('marie_franc_ops/local_store');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OperationsApp());
}

class OperationsApp extends StatelessWidget {
  const OperationsApp({super.key, this.repository});

  final OperationsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: OpsWorkspace(repository: repository ?? OperationsRepository()),
    );
  }
}

ThemeData buildTheme() {
  const primary = Color(0xFFFF1FEC);
  const secondary = Color(0xFFA11FFF);
  const accent = Color(0xFF321FFF);
  const surface = Color(0xFFF4F7FA);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        onPrimary: Colors.white,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: primary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE4EEF1),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}

enum WorkType { facility, asset, container, payroll }

extension WorkTypeDetails on WorkType {
  String get label => switch (this) {
    WorkType.facility => 'Facilities',
    WorkType.asset => 'Assets',
    WorkType.container => 'Containers',
    WorkType.payroll => 'Payroll',
  };

  String get singular => switch (this) {
    WorkType.facility => 'Facility booking',
    WorkType.asset => 'Asset record',
    WorkType.container => 'Container move',
    WorkType.payroll => 'Payroll report',
  };

  IconData get icon => switch (this) {
    WorkType.facility => Icons.meeting_room_outlined,
    WorkType.asset => Icons.inventory_2_outlined,
    WorkType.container => Icons.local_shipping_outlined,
    WorkType.payroll => Icons.payments_outlined,
  };
}

const statuses = ['Planned', 'Active', 'Review', 'Complete'];

class OpsRecord {
  const OpsRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.detail,
    required this.status,
    required this.dueDate,
    required this.amount,
  });

  final String id;
  final WorkType type;
  final String title;
  final String owner;
  final String detail;
  final String status;
  final DateTime dueDate;
  final int amount;

  OpsRecord copyWith({
    WorkType? type,
    String? title,
    String? owner,
    String? detail,
    String? status,
    DateTime? dueDate,
    int? amount,
  }) {
    return OpsRecord(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'owner': owner,
    'detail': detail,
    'status': status,
    'dueDate': dueDate.toIso8601String(),
    'amount': amount,
  };

  factory OpsRecord.fromJson(Map<String, Object?> json) {
    return OpsRecord(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: WorkType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => WorkType.facility,
      ),
      title: json['title']?.toString() ?? 'Untitled operation',
      owner: json['owner']?.toString() ?? 'Operations team',
      detail: json['detail']?.toString() ?? '',
      status: json['status']?.toString() ?? statuses.first,
      dueDate:
          DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
          DateTime.now(),
      amount: int.tryParse(json['amount']?.toString() ?? '') ?? 0,
    );
  }
}

class OperationsRepository {
  static const _storageKey = 'operations_records_v1';

  Future<List<OpsRecord>> loadRecords() async {
    if (screenshotMode) {
      return screenshotRecords();
    }

    final raw = await localStoreChannel.invokeMethod<String>('read', {
      'key': _storageKey,
    });
    if (raw == null || raw.isEmpty) {
      return starterRecords();
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final records = decoded
          .whereType<Map<String, Object?>>()
          .map(OpsRecord.fromJson)
          .toList();
      return records.isEmpty ? starterRecords() : records;
    } on FormatException {
      return starterRecords();
    }
  }

  Future<void> saveRecords(List<OpsRecord> records) async {
    if (screenshotMode) {
      return;
    }

    await localStoreChannel.invokeMethod<void>('write', {
      'key': _storageKey,
      'value': jsonEncode(records.map((record) => record.toJson()).toList()),
    });
  }

  static List<OpsRecord> starterRecords() {
    final now = DateTime.now();
    return [
      OpsRecord(
        id: 'starter-facility',
        type: WorkType.facility,
        title: 'CHEVALLIER LE PAGE MARIE FRANC',
        owner: 'Site operations',
        detail: 'Reserve bay 2 for supplier intake and pallet staging.',
        status: 'Active',
        dueDate: now.add(const Duration(days: 1)),
        amount: 4,
      ),
      OpsRecord(
        id: 'starter-asset',
        type: WorkType.asset,
        title: 'Forklift battery inspection',
        owner: 'Maintenance',
        detail: 'Record charger condition and next service window.',
        status: 'Planned',
        dueDate: now.add(const Duration(days: 3)),
        amount: 2,
      ),
      OpsRecord(
        id: 'starter-container',
        type: WorkType.container,
        title: 'Container FR-204 handoff',
        owner: 'Logistics desk',
        detail: 'Confirm seal, bay assignment, and outbound carrier time.',
        status: 'Review',
        dueDate: now.add(const Duration(days: 2)),
        amount: 1,
      ),
      OpsRecord(
        id: 'starter-payroll',
        type: WorkType.payroll,
        title: 'Week 21 payroll check',
        owner: 'Payroll lead',
        detail: 'Compare overtime notes with approved shift changes.',
        status: 'Planned',
        dueDate: now.add(const Duration(days: 5)),
        amount: 18,
      ),
    ];
  }

  static List<OpsRecord> screenshotRecords() {
    return [
      OpsRecord(
        id: 'shot-facility',
        type: WorkType.facility,
        title: 'Afternoon meeting room block',
        owner: 'Front office',
        detail: 'Hold rooms A and C for supplier reviews and visitor badges.',
        status: 'Active',
        dueDate: DateTime(2026, 5, 12),
        amount: 6,
      ),
      OpsRecord(
        id: 'shot-asset',
        type: WorkType.asset,
        title: 'Scanner fleet renewal',
        owner: 'Asset desk',
        detail: 'Tag 12 handheld scanners and assign storage lockers.',
        status: 'Review',
        dueDate: DateTime(2026, 5, 14),
        amount: 12,
      ),
      OpsRecord(
        id: 'shot-container',
        type: WorkType.container,
        title: 'Containers awaiting release',
        owner: 'Logistics desk',
        detail: 'Check customs notes before releasing FR-204 and FR-211.',
        status: 'Planned',
        dueDate: DateTime(2026, 5, 13),
        amount: 2,
      ),
      OpsRecord(
        id: 'shot-payroll',
        type: WorkType.payroll,
        title: 'Payroll exceptions review',
        owner: 'Payroll lead',
        detail: 'Resolve missing approvals for weekend maintenance shifts.',
        status: 'Active',
        dueDate: DateTime(2026, 5, 15),
        amount: 7,
      ),
      OpsRecord(
        id: 'shot-facility-2',
        type: WorkType.facility,
        title: 'Storage zone audit',
        owner: 'Compliance',
        detail: 'Confirm aisle clearance before the evening handover.',
        status: 'Complete',
        dueDate: DateTime(2026, 5, 11),
        amount: 3,
      ),
    ];
  }
}

class OpsWorkspace extends StatefulWidget {
  const OpsWorkspace({super.key, required this.repository});

  final OperationsRepository repository;

  @override
  State<OpsWorkspace> createState() => _OpsWorkspaceState();
}

class _OpsWorkspaceState extends State<OpsWorkspace> {
  var _index = 0;
  var _loading = true;
  List<OpsRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await widget.repository.loadRecords();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _save(List<OpsRecord> records) async {
    setState(() => _records = records);
    await widget.repository.saveRecords(records);
  }

  Future<void> _upsertRecord(OpsRecord record) async {
    final records = [..._records];
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    await _save(records);
  }

  Future<void> _deleteRecord(OpsRecord record) async {
    await _save(_records.where((item) => item.id != record.id).toList());
  }

  Future<void> _openEditor([OpsRecord? record]) async {
    final result = await Navigator.of(context).push<OpsRecord>(
      MaterialPageRoute(builder: (_) => RecordFormPage(record: record)),
    );
    if (result == null) {
      return;
    }
    await _upsertRecord(result);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.type.singular} saved locally')),
      );
    }
  }

  Future<void> _openDetail(OpsRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RecordDetailPage(
          record: record,
          onChanged: _upsertRecord,
          onDelete: _deleteRecord,
          onEdit: _openEditor,
        ),
      ),
    );
  }

  Future<void> _clearRecords() async {
    await _save(OperationsRepository.starterRecords());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Local workspace reset')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      OverviewPage(records: _records, onRecordTap: _openDetail),
      WorkPage(records: _records, onRecordTap: _openDetail),
      ReportsPage(records: _records),
      SettingsPage(onClear: _clearRecords),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(_index))),
      body: screens[_index],
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              key: const ValueKey('add-record'),
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New record'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav-overview'),
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            key: ValueKey('nav-work'),
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Work',
          ),
          NavigationDestination(
            key: ValueKey('nav-reports'),
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Reports',
          ),
          NavigationDestination(
            key: ValueKey('nav-settings'),
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) => switch (index) {
    0 => 'Operations overview',
    1 => 'Work register',
    2 => 'Payroll and tracking',
    _ => 'Settings',
  };
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.records,
    required this.onRecordTap,
  });

  final List<OpsRecord> records;
  final ValueChanged<OpsRecord> onRecordTap;

  @override
  Widget build(BuildContext context) {
    final active = records.where((item) => item.status == 'Active').length;
    final review = records.where((item) => item.status == 'Review').length;
    final complete = records.where((item) => item.status == 'Complete').length;
    final dueSoon = records
        .where((item) => item.dueDate.difference(DateTime.now()).inDays <= 3)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.asset(
                'docs/featured.png',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Text(
                  'Facility booking, assets, containers, and payroll in one offline workspace.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width > 620 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: width > 620 ? 1.55 : 1.32,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  label: 'Active',
                  value: active.toString(),
                  icon: Icons.bolt_outlined,
                ),
                MetricCard(
                  label: 'In review',
                  value: review.toString(),
                  icon: Icons.rate_review_outlined,
                ),
                MetricCard(
                  label: 'Due soon',
                  value: dueSoon.toString(),
                  icon: Icons.schedule_outlined,
                ),
                MetricCard(
                  label: 'Complete',
                  value: complete.toString(),
                  icon: Icons.verified_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Priority queue',
          trailing: '${records.length} local records',
        ),
        const SizedBox(height: 8),
        ...records
            .take(4)
            .map(
              (record) =>
                  RecordTile(record: record, onTap: () => onRecordTap(record)),
            ),
      ],
    );
  }
}

class WorkPage extends StatefulWidget {
  const WorkPage({super.key, required this.records, required this.onRecordTap});

  final List<OpsRecord> records;
  final ValueChanged<OpsRecord> onRecordTap;

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  WorkType? _filter;

  @override
  Widget build(BuildContext context) {
    final records = _filter == null
        ? widget.records
        : widget.records.where((item) => item.type == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              ...WorkType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.label),
                    avatar: Icon(type.icon, size: 18),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionHeader(
          title: _filter == null ? 'All operating records' : _filter!.label,
          trailing: '${records.length} shown',
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyState()
        else
          ...records.map(
            (record) => RecordTile(
              record: record,
              onTap: () => widget.onRecordTap(record),
            ),
          ),
      ],
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.records});

  final List<OpsRecord> records;

  @override
  Widget build(BuildContext context) {
    final payroll = records.where((item) => item.type == WorkType.payroll);
    final payrollExceptions = payroll.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final containers = records.where((item) => item.type == WorkType.container);
    final activeContainers = containers
        .where((item) => item.status != 'Complete')
        .length;
    final completion = records.isEmpty
        ? 0
        : (records.where((item) => item.status == 'Complete').length /
                  records.length *
                  100)
              .round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionHeader(
          title: 'Operating status',
          trailing: '$completion% complete',
        ),
        const SizedBox(height: 8),
        StatusProgress(records: records),
        const SizedBox(height: 14),
        ReportCard(
          icon: Icons.payments_outlined,
          title: 'Payroll report',
          value: '$payrollExceptions exceptions',
          detail: 'Review local payroll notes before the weekly export.',
        ),
        ReportCard(
          icon: Icons.local_shipping_outlined,
          title: 'Container tracking',
          value: '$activeContainers open moves',
          detail: 'Monitor pending handoffs, seal checks, and carrier windows.',
        ),
        ReportCard(
          icon: Icons.inventory_2_outlined,
          title: 'Asset management',
          value: '${_countFor(WorkType.asset)} assets',
          detail: 'Keep inspection and assignment records available offline.',
        ),
        ReportCard(
          icon: Icons.meeting_room_outlined,
          title: 'Facility booking',
          value: '${_countFor(WorkType.facility)} bookings',
          detail: 'Track rooms, loading bays, and shared site resources.',
        ),
      ],
    );
  }

  int _countFor(WorkType type) =>
      records.where((item) => item.type == type).length;
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        CardBlock(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('docs/icon.png', width: 46, height: 46),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text('Offline operations workspace'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const InfoLine(
                icon: Icons.business_outlined,
                title: 'Provider',
                detail: companyName,
              ),
              const InfoLine(
                icon: Icons.lock_outline,
                title: 'Privacy',
                detail:
                    'Records stay on this device. No account or cloud sync is used.',
              ),
              const InfoLine(
                icon: Icons.mail_outline,
                title: 'Support',
                detail: supportEmail,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CardBlock(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local data',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Facility bookings, asset records, container checkpoints, payroll notes, and preferences are stored only in local app storage.',
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset local workspace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({
    super.key,
    required this.record,
    required this.onChanged,
    required this.onDelete,
    required this.onEdit,
  });

  final OpsRecord record;
  final ValueChanged<OpsRecord> onChanged;
  final ValueChanged<OpsRecord> onDelete;
  final ValueChanged<OpsRecord> onEdit;

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late OpsRecord _record = widget.record;

  Future<void> _setStatus(String status) async {
    final updated = _record.copyWith(status: status);
    setState(() => _record = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => widget.onEdit(_record),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordIcon(type: _record.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _record.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(_record.type.singular),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                InfoLine(
                  icon: Icons.person_outline,
                  title: 'Owner',
                  detail: _record.owner,
                ),
                InfoLine(
                  icon: Icons.calendar_today_outlined,
                  title: 'Due date',
                  detail: formatDate(_record.dueDate),
                ),
                InfoLine(
                  icon: Icons.format_list_numbered,
                  title: metricLabel(_record.type),
                  detail: _record.amount.toString(),
                ),
                const Divider(height: 26),
                Text(_record.detail),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statuses
                      .map(
                        (status) => ChoiceChip(
                          label: Text(status),
                          selected: _record.status == status,
                          onSelected: (_) => _setStatus(status),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              widget.onDelete(_record);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove record'),
          ),
        ],
      ),
    );
  }
}

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({super.key, this.record});

  final OpsRecord? record;

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _ownerController;
  late final TextEditingController _detailController;
  late final TextEditingController _amountController;
  late WorkType _type;
  late String _status;
  var _dueInDays = 1;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? WorkType.facility;
    _status = record?.status ?? 'Planned';
    _titleController = TextEditingController(text: record?.title ?? '');
    _ownerController = TextEditingController(text: record?.owner ?? '');
    _detailController = TextEditingController(text: record?.detail ?? '');
    _amountController = TextEditingController(
      text: record == null ? '1' : record.amount.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _detailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final record = OpsRecord(
      id: widget.record?.id ?? now.microsecondsSinceEpoch.toString(),
      type: _type,
      title: _titleController.text.trim(),
      owner: _ownerController.text.trim(),
      detail: _detailController.text.trim(),
      status: _status,
      dueDate: now.add(Duration(days: _dueInDays)),
      amount: int.tryParse(_amountController.text.trim()) ?? 1,
    );
    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'New record' : 'Edit record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<WorkType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Record type'),
              items: WorkType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.singular),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              validator: requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'Owner or team'),
              textInputAction: TextInputAction.next,
              validator: requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailController,
              decoration: const InputDecoration(labelText: 'Notes'),
              minLines: 3,
              maxLines: 5,
              validator: requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: metricLabel(_type)),
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Enter a number above zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: statuses
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _dueInDays,
              decoration: const InputDecoration(labelText: 'Due window'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Today')),
                DropdownMenuItem(value: 1, child: Text('Tomorrow')),
                DropdownMenuItem(value: 3, child: Text('Within 3 days')),
                DropdownMenuItem(value: 7, child: Text('Within 7 days')),
              ],
              onChanged: (value) => setState(() => _dueInDays = value ?? 1),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save locally'),
            ),
          ],
        ),
      ),
    );
  }
}

String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CardBlock(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: colors.tertiary),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return CardBlock(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record, required this.onTap});

  final OpsRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecordIcon(type: record.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.owner} - due ${formatDate(record.dueDate)}',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusChip(status: record.status),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(record.type.label),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecordIcon extends StatelessWidget {
  const RecordIcon({super.key, required this.type});

  final WorkType type;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.tertiary.withValues(alpha: 0.12),
      foregroundColor: Theme.of(context).colorScheme.tertiary,
      child: Icon(type.icon),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: statusColor(status).withValues(alpha: 0.14),
      side: BorderSide(color: statusColor(status).withValues(alpha: 0.35)),
      label: Text(status),
    );
  }
}

class StatusProgress extends StatelessWidget {
  const StatusProgress({super.key, required this.records});

  final List<OpsRecord> records;

  @override
  Widget build(BuildContext context) {
    final total = records.isEmpty ? 1 : records.length;
    return CardBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statuses.map((status) {
          final count = records.where((item) => item.status == status).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('$count'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: count / total,
                  color: statusColor(status),
                  backgroundColor: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          trailing,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return CardBlock(
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          const Text(
            'No records match this view',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class CardBlock extends StatelessWidget {
  const CardBlock({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

Color statusColor(String status) => switch (status) {
  'Active' => const Color(0xFF0D7C73),
  'Review' => const Color(0xFF9A6500),
  'Complete' => const Color(0xFF256D3A),
  _ => const Color(0xFF4A5568),
};

String metricLabel(WorkType type) => switch (type) {
  WorkType.facility => 'Hours or spaces',
  WorkType.asset => 'Asset count',
  WorkType.container => 'Container count',
  WorkType.payroll => 'Exceptions',
};

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
