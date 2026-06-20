import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../models/daily_report.dart';
import '../models/sale_model.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late Future<List<DailySalesReport>> _future;

  // Active custom date range (null = unbounded).
  DateTime? _fromDate;
  DateTime? _toDate;

  static const List<String> _weekdays = [
    'دووشەممە', // 1 Monday
    'سێشەممە', // 2 Tuesday
    'چوارشەممە', // 3 Wednesday
    'پێنجشەممە', // 4 Thursday
    'هەینی', // 5 Friday
    'شەممە', // 6 Saturday
    'یەکشەممە', // 7 Sunday
  ];

  @override
  void initState() {
    super.initState();
    _future = context.read<InventoryProvider>().getDailySalesReport();
  }

  bool get _hasFilter => _fromDate != null || _toDate != null;

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'ئەمڕۆ';
    if (diff == 1) return 'دوێنێ';
    return _weekdays[date.weekday - 1];
  }

  List<DailySalesReport> _applyFilter(List<DailySalesReport> all) {
    return all.where((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      if (_fromDate != null) {
        final f = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (d.isBefore(f)) return false;
      }
      if (_toDate != null) {
        final t = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        if (d.isAfter(t)) return false;
      }
      return true;
    }).toList();
  }

  // ----------------------------- Filter logic ----------------------------

  bool _isPreset(int? days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (days == null) return _fromDate == null && _toDate == null;
    if (_fromDate == null || _toDate == null) return false;
    final f = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final t = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
    return t == today && f == today.subtract(Duration(days: days));
  }

  void _setPreset(int? days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      if (days == null) {
        _fromDate = null;
        _toDate = null;
      } else {
        _toDate = today;
        _fromDate = today.subtract(Duration(days: days));
      }
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ڕاپۆرتی فرۆشتنی ڕۆژانە',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'هەر ڕۆژێک چەند فرۆشراوە و چەند قازانجی تێدابووە — کرتە لە ڕۆژێک بکە بۆ بینینی فرۆشراوەکان',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          _filterBar(),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<DailySalesReport>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text('کێشەیەک ڕوویدا لە هێنانەوەی داتا'),
                  );
                }
                final reports = _applyFilter(snapshot.data ?? []);
                if (reports.isEmpty) return _emptyState();

                final grandTotal =
                    reports.fold<double>(0, (s, r) => s + r.total);
                final grandProfit =
                    reports.fold<double>(0, (s, r) => s + r.profit);
                final grandCount =
                    reports.fold<int>(0, (s, r) => s + r.invoiceCount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow(grandTotal, grandProfit, grandCount),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _dayCard(reports[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------- Inline filter ---------------------------

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'فلتەری ماوە',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasFilter)
                TextButton.icon(
                  onPressed: () => _setPreset(null),
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.rose),
                  label:
                      Text('سڕینەوە', style: TextStyle(color: AppColors.rose)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetChip('ئەمڕۆ', 0),
              _presetChip('٧ ڕۆژ', 6),
              _presetChip('٣٠ ڕۆژ', 29),
              _presetChip('هەموو', null),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _inlineDateField('لە بەرواری', _fromDate, true)),
              const SizedBox(width: 10),
              Expanded(child: _inlineDateField('بۆ بەرواری', _toDate, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, int? days) {
    final selected = _isPreset(days);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _setPreset(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.inkSoft,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _inlineDateField(String label, DateTime? value, bool isFrom) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _pickDate(isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? 'هەڵبژێرە' : _dateFormat.format(value),
                    style: TextStyle(
                      color: value == null ? AppColors.muted : AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            'هیچ فرۆشتنێک نییە لەم ماوەیەدا',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(double total, double profit, int count) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.payments_rounded,
            color: AppColors.emerald,
            label: 'کۆی فرۆشتن',
            value: '${_currencyFormat.format(total)} د.ع',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.trending_up_rounded,
            color: AppColors.primary,
            label: 'کۆی قازانج',
            value: '${_currencyFormat.format(profit)} د.ع',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.receipt_long_rounded,
            color: AppColors.amber,
            label: 'ژمارەی فرۆشراو',
            value: '$count',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _dayCard(DailySalesReport report) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _showDayInvoices(report),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.violetSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dayLabel(report.date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.day}  •  ${report.invoiceCount} فرۆشراو',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_currencyFormat.format(report.total)} د.ع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'قازانج: ${_currencyFormat.format(report.profit)}',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_left_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayInvoices(DailySalesReport report) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'فرۆشراوەکانی ${_dayLabel(report.date)} (${report.day})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${_currencyFormat.format(report.total)} د.ع',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                        color: AppColors.muted,
                        tooltip: 'داخستن',
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),
                Flexible(
                  child: FutureBuilder<List<Sale>>(
                    future: context
                        .read<InventoryProvider>()
                        .getSalesForDay(report.day),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final sales = snapshot.data ?? [];
                      if (sales.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'هیچ فرۆشراوێک نییە',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _invoiceTile(sales[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _invoiceTile(Sale sale) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.violetSoft,
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.receipt_rounded, size: 20),
          ),
          title: Text(
            'فرۆشراو #${sale.id}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            DateFormat('HH:mm').format(sale.date),
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          trailing: Text(
            '${_currencyFormat.format(sale.totalAmount)} د.ع',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.emerald,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            FutureBuilder<List<SaleLineItem>>(
              future: context
                  .read<InventoryProvider>()
                  .getSaleLineItems(sale.id ?? -1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final lines = snapshot.data ?? [];
                if (lines.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'هیچ کاڵایەک نییە',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return Column(
                  children: lines.map(_lineRow).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineRow(SaleLineItem line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${line.quantity}×',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line.name,
              style: TextStyle(color: AppColors.ink, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${_currencyFormat.format(line.subtotal)} د.ع',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
