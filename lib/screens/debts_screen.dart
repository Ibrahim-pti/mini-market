import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';
import '../providers/debt_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {ToastType type = ToastType.info}) {
    showAppToast(context, msg, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Top Stat Cards
            _buildStatCards(debtProvider),

            // Search and Filter Bar
            _buildActionBar(debtProvider),

            // Content List / Grid
            Expanded(
              child: debtProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : debtProvider.debts.isEmpty
                      ? _buildEmptyState()
                      : _buildDebtsList(debtProvider, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(DebtProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 800;

        final cards = [
          _StatCard(
            title: 'کۆی قەرزی سەر کڕیاران (لای خەڵکە)',
            amount: provider.totalCustomerDebt,
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF10B981), // Emerald
            currencyFormat: _currencyFormat,
          ),
          _StatCard(
            title: 'کۆی پارەی وەرگیراو (دراوە)',
            amount: provider.totalPaidDebt,
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF4F46E5), // Indigo
            currencyFormat: _currencyFormat,
          ),
          _StatCard(
            title: 'کڕیاری قەرزدار (نەدراوە)',
            amount: provider.activeDebtorsCount.toDouble(),
            isCount: true,
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF8B5CF6), // Violet
            currencyFormat: _currencyFormat,
          ),
        ];

        if (wide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: cards
                  .map((c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: c,
                        ),
                      ))
                  .toList(),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 12),
                cards[2],
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildActionBar(DebtProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final searchField = SizedBox(
            height: 48,
            child: TextField(
              controller: _searchCtrl,
              onChanged: provider.search,
              decoration: InputDecoration(
                hintText: 'گەڕان بەپێی ناوی کڕیار، مۆبایل، تێبینی...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.search('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          );

          final filterChips = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statusChip(
                label: 'هەمووی',
                selected: provider.selectedStatus == 'all',
                onSelected: () => provider.filterByStatus('all'),
              ),
              _statusChip(
                label: 'نەدراوە',
                selected: provider.selectedStatus == 'unpaid',
                onSelected: () => provider.filterByStatus('unpaid'),
              ),
              _statusChip(
                label: 'تەواوبوو (دراوە)',
                selected: provider.selectedStatus == 'paid',
                onSelected: () => provider.filterByStatus('paid'),
              ),
              if (provider.overdueDebtsCount > 0)
                _statusChip(
                  label: 'بەسەرچوو (${provider.overdueDebtsCount})',
                  selected: provider.selectedStatus == 'overdue',
                  color: AppColors.rose,
                  onSelected: () => provider.filterByStatus('overdue'),
                ),
            ],
          );

          final addBtn = ElevatedButton.icon(
            onPressed: () => _showAddEditDebtDialog(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'زیادکردنی قەرزی کڕیار',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: searchField),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: filterChips),
                const SizedBox(width: 16),
                addBtn,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    addBtn,
                  ],
                ),
                const SizedBox(height: 12),
                filterChips,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? c : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? c : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'هیچ قەرزێکی کڕیار نییە',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'دەتوانیت قەرزی کڕیاری نوێ زیاد بکەیت',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDebtDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('زیادکردنی قەرزی کڕیار'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(DebtProvider provider, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = constraints.maxWidth > 1400
            ? 3
            : (constraints.maxWidth > 850 ? 2 : 1);

        if (cols == 1) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: provider.debts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _DebtCard(
              debt: provider.debts[i],
              currencyFormat: _currencyFormat,
              dateFormat: _dateFormat,
              onPayment: () => _showPaymentDialog(provider.debts[i]),
              onHistory: () => _showHistoryDialog(provider.debts[i]),
              onEdit: () => _showAddEditDebtDialog(debt: provider.debts[i]),
              onDelete: () => _confirmDelete(provider.debts[i]),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 270,
          ),
          itemCount: provider.debts.length,
          itemBuilder: (context, i) => _DebtCard(
            debt: provider.debts[i],
            currencyFormat: _currencyFormat,
            dateFormat: _dateFormat,
            onPayment: () => _showPaymentDialog(provider.debts[i]),
            onHistory: () => _showHistoryDialog(provider.debts[i]),
            onEdit: () => _showAddEditDebtDialog(debt: provider.debts[i]),
            onDelete: () => _confirmDelete(provider.debts[i]),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // DIALOGS & ACTIONS
  // -------------------------------------------------------------

  Future<void> _showAddEditDebtDialog({Debt? debt}) async {
    final isEdit = debt != null;
    final nameCtrl = TextEditingController(text: debt?.personName ?? '');
    final phoneCtrl = TextEditingController(text: debt?.phone ?? '');
    final amountCtrl = TextEditingController(
      text: debt != null ? debt.amount.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController(text: debt?.notes ?? '');
    DateTime selectedDate = debt?.date ?? DateTime.now();
    DateTime? selectedDueDate = debt?.dueDate;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEdit ? 'دەستکاریکردنی قەرزی کڕیار' : 'تۆمارکردنی قەرزی کڕیار',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ناوی کڕیار *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'تکایە ناوی کڕیار بنووسە' : null,
                    ),
                    const SizedBox(height: 14),

                    // Phone & Amount Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'ژمارەی مۆبایل (ئارەزوومەندانە)',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'بڕی قەرز (د.ع) *',
                              prefixIcon: Icon(Icons.attach_money_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'تکایە بڕ بنووسە';
                              }
                              final val = double.tryParse(v.replaceAll(',', ''));
                              if (val == null || val <= 0) {
                                return 'بڕی دروست بنووسە';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date Pickers Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('بەرواری قەرز', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                      Text(_dateFormat.format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDueDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.event_available_rounded, size: 18, color: AppColors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('کاتی دانەوە (بژاردە)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                        Text(
                                          selectedDueDate != null ? _dateFormat.format(selectedDueDate!) : 'دیاری نەکراوە',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: selectedDueDate != null ? AppColors.ink : AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedDueDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => setDialogState(() => selectedDueDate = null),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'تێبینی (ئارەزوومەندانە)',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('پاشگەزبوونەوە', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final provider = context.read<DebtProvider>();
                final amount = double.parse(amountCtrl.text.replaceAll(',', ''));

                if (isEdit) {
                  final updated = debt.copyWith(
                    personName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    amount: amount,
                    type: 'customer',
                    date: selectedDate,
                    dueDate: selectedDueDate,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  final ok = await provider.updateDebt(updated);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  _toast(
                    ok ? 'قەرزەکە بە سەرکەوتوویی دەستکاری کرا' : 'هەڵەیەک ڕوویدا لە دەستکاریکردن',
                    type: ok ? ToastType.success : ToastType.error,
                  );
                } else {
                  final newDebt = Debt(
                    personName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    amount: amount,
                    type: 'customer',
                    date: selectedDate,
                    dueDate: selectedDueDate,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  final ok = await provider.addDebt(newDebt);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  _toast(
                    ok ? 'قەرزەکە بە سەرکەوتوویی تۆمارکرا' : 'هەڵەیەک ڕوویدا لە تۆمارکردن',
                    type: ok ? ToastType.success : ToastType.error,
                  );
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isEdit ? 'پاشەکەوتکردن' : 'تۆمارکردن'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(Debt debt) async {
    final amountCtrl = TextEditingController(text: debt.remainingAmount.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    DateTime payDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('وەرگرتنی پارەی قەرز لە کڕیار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      'کڕیار: ${debt.personName}',
                      style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debt Summary Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('کۆی قەرز', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(
                              '${_currencyFormat.format(debt.amount)} د.ع',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('دراوە', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(
                              '${_currencyFormat.format(debt.paidAmount)} د.ع',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ماوەتەوە', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(
                              '${_currencyFormat.format(debt.remainingAmount)} د.ع',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.rose),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Amount Fill Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickAmountBtn('تەواوی ماوە (${_currencyFormat.format(debt.remainingAmount)})', debt.remainingAmount, amountCtrl),
                      if (debt.remainingAmount > 10000)
                        _quickAmountBtn('نیوە (${_currencyFormat.format(debt.remainingAmount / 2)})', debt.remainingAmount / 2, amountCtrl),
                      if (debt.remainingAmount >= 25000)
                        _quickAmountBtn('٢٥,٠٠٠', 25000, amountCtrl),
                      if (debt.remainingAmount >= 50000)
                        _quickAmountBtn('٥٠,٠٠٠', 50000, amountCtrl),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'بڕی پارەی وەرگیراو (د.ع) *',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      suffixText: 'د.ع',
                      suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'تکایە بڕ بنووسە';
                      final val = double.tryParse(v.replaceAll(',', ''));
                      if (val == null || val <= 0) return 'بڕی دروست بنووسە';
                      if (val > debt.remainingAmount) {
                        return 'بڕەکە نابێت زیاتر بێت لە ماوە (${_currencyFormat.format(debt.remainingAmount)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'تێبینی لەسەر ئەم وەجبەیە (ئارەزوومەندانە)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('پاشگەزبوونەوە', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final provider = context.read<DebtProvider>();
                final payAmount = double.parse(amountCtrl.text.replaceAll(',', ''));

                final ok = await provider.addPayment(
                  debt.id!,
                  payAmount,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  date: payDate,
                );

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                _toast(
                  ok ? 'پارەدانەکە بە سەرکەوتوویی تۆمارکرا' : 'هەڵەیەک ڕوویدا لە تۆمارکردن',
                  type: ok ? ToastType.success : ToastType.error,
                );
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('پەسەندکردنی وەرگرتن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountBtn(String label, double amount, TextEditingController ctrl) {
    return InkWell(
      onTap: () => ctrl.text = amount.toStringAsFixed(0),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _showHistoryDialog(Debt debt) async {
    final provider = context.read<DebtProvider>();
    final payments = await provider.getPaymentsForDebt(debt.id!);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مێژووی قیست و وەجبەکان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      'کڕیار: ${debt.personName}',
                      style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 380,
            child: payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text('تا ئێستا هیچ بڕێک نەدراوەتەوە', style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 20),
                        ),
                        title: Text(
                          '${_currencyFormat.format(p.amount)} د.ع',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${_dateFormat.format(p.date)}${p.notes != null && p.notes!.isNotEmpty ? " • ${p.notes}" : ""}',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: AppColors.rose, size: 20),
                          tooltip: 'سڕینەوەی ئەم وەجبەیە',
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('سڕینەوەی وەجبە'),
                                content: const Text('دڵنیایت لە سڕینەوەی ئەم بڕە؟ دەگەڕێتەوە سەر ماوەی قەرزەکە.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('نەخێر')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                                    child: const Text('بەڵێ، بسڕەوە'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && p.id != null) {
                              await provider.deletePayment(p.id!, debt.id!, p.amount);
                              final updated = await provider.getPaymentsForDebt(debt.id!);
                              setDialogState(() {
                                payments.clear();
                                payments.addAll(updated);
                              });
                              _toast('وەجبەکە سڕایەوە', type: ToastType.info);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('داخستن'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Debt debt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.rose),
            const SizedBox(width: 10),
            const Text('سڕینەوەی قەرز'),
          ],
        ),
        content: Text('دڵنیایت لە سڕینەوەی قەرزی کڕیار "${debt.personName}" بە بڕی ${_currencyFormat.format(debt.amount)} د.ع؟ هەموو مێژووی قیستەکانیش دەسڕێنەوە.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('نەخێر', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('بەڵێ، بسڕەوە'),
          ),
        ],
      ),
    );

    if (ok == true && debt.id != null) {
      final provider = context.read<DebtProvider>();
      final success = await provider.deleteDebt(debt.id!);
      _toast(
        success ? 'قەرزەکە بە سەرکەوتوویی سڕایەوە' : 'هەڵەیەک ڕوویدا لە کاتی سڕینەوە',
        type: success ? ToastType.success : ToastType.error,
      );
    }
  }
}

// -------------------------------------------------------------
// HELPER WIDGETS
// -------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isCount;
  final NumberFormat currencyFormat;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.isCount = false,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCount
                      ? '${amount.toInt()} کڕیار'
                      : '${currencyFormat.format(amount)} د.ع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onPayment;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onPayment,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const typeColor = Color(0xFF10B981);
    final isFullyPaid = debt.isFullyPaid;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: debt.isOverdue
              ? AppColors.rose.withValues(alpha: 0.5)
              : (isFullyPaid ? const Color(0xFF10B981).withValues(alpha: 0.3) : AppColors.border),
          width: debt.isOverdue || isFullyPaid ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Phone & Menu
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: typeColor.withValues(alpha: 0.15),
                child: Text(
                  debt.personName.isNotEmpty ? debt.personName.characters.first : '?',
                  style: const TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    if (debt.phone != null && debt.phone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            debt.phone!,
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // More Actions Menu (Edit / Delete)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppColors.muted, size: 20),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('دەستکاریکردن'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
                        const SizedBox(width: 8),
                        Text('سڕینەوە', style: TextStyle(color: AppColors.rose)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amounts breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountCol('کۆی قەرز', '${currencyFormat.format(debt.amount)} د.ع', AppColors.ink),
              _amountCol('دراوە', '${currencyFormat.format(debt.paidAmount)} د.ع', const Color(0xFF10B981)),
              _amountCol(
                'ماوەتەوە',
                '${currencyFormat.format(debt.remainingAmount)} د.ع',
                isFullyPaid ? const Color(0xFF10B981) : AppColors.rose,
                isBold: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: debt.amount > 0 ? (debt.paidAmount / debt.amount).clamp(0.0, 1.0) : 0.0,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullyPaid ? const Color(0xFF10B981) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date info & Overdue warning
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(debt.date),
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              if (debt.dueDate != null) ...[
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: AppColors.muted)),
                const SizedBox(width: 8),
                Text(
                  'کاتی دانەوە: ${dateFormat.format(debt.dueDate!)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: debt.isOverdue ? AppColors.rose : AppColors.muted,
                    fontWeight: debt.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
              const Spacer(),
              if (isFullyPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('تەواوبوو', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                )
              else if (debt.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('کاتی بەسەرچووە', style: TextStyle(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Spacer(),

          // Action Buttons: History & Pay
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('مێژووی قیستەکان', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isFullyPaid ? null : onPayment,
                  icon: Icon(isFullyPaid ? Icons.check_circle_rounded : Icons.payments_rounded, size: 16),
                  label: Text(
                    isFullyPaid ? 'تەواو دراوە' : 'وەرگرتنی پارە',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFullyPaid ? AppColors.surfaceAlt : const Color(0xFF10B981),
                    foregroundColor: isFullyPaid ? AppColors.muted : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountCol(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
