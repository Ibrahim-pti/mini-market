import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sale_model.dart';
import '../models/item_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  double _todayRevenue = 0.0;
  double _todayGrossProfit = 0.0;
  double _todayExpenses = 0.0;
  int _todaySalesCount = 0;
  List<double> _weeklyRevenue = [];
  List<Sale> _recentSales = [];
  List<Map<String, dynamic>> _topSellingItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    double rev = await provider.getTodayRevenue();
    double profit = await provider.getTodayProfit();
    double exp = await provider.getTodayExpenses();
    int count = await provider.getTodaySalesCount();
    List<double> weekly = await provider.getWeeklyRevenue();
    List<Sale> recent = await provider.getRecentSales(limit: 6);
    List<Map<String, dynamic>> topSelling =
        await provider.getTopSellingItems(limit: 5);
    if (mounted) {
      setState(() {
        _todayRevenue = rev;
        _todayGrossProfit = profit;
        _todayExpenses = exp;
        _todaySalesCount = count;
        _weeklyRevenue = weekly;
        _recentSales = recent;
        _topSellingItems = topSelling;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);
    final lowStock = provider.getLowStockItems();

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(wide ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 22),
                  _statCards(provider, lowStock.length),
                  const SizedBox(height: 20),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _chartCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _topSellingCard()),
                      ],
                    )
                  else ...[
                    _chartCard(),
                    const SizedBox(height: 20),
                    _topSellingCard(),
                  ],
                  const SizedBox(height: 20),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _recentSalesCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _lowStockCard(lowStock)),
                      ],
                    )
                  else ...[
                    _recentSalesCard(),
                    const SizedBox(height: 20),
                    _lowStockCard(lowStock),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ----------------------------- Header -----------------------------
  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بەخێربێیتەوە 👋',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE، yyyy-MM-dd').format(DateTime.now()),
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          shape: CircleBorder(side: BorderSide(color: AppColors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _loadDashboardData,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.refresh_rounded,
                  color: AppColors.inkSoft, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------- Stat cards -----------------------------
  Widget _statCards(InventoryProvider provider, int lowStockCount) {
    final netProfit = _todayGrossProfit - _todayExpenses;
    return LayoutBuilder(builder: (context, c) {
      final cards = [
        _statCard(
          title: 'فرۆشتنی ئەمڕۆ',
          value: '${_currencyFormat.format(_todayRevenue)} د.ع',
          icon: Icons.payments_rounded,
          color: AppColors.primary,
        ),
        _statCard(
          title: 'قازانجی ئەمڕۆ',
          value: '${_currencyFormat.format(netProfit)} د.ع',
          icon: Icons.trending_up_rounded,
          color: AppColors.emerald,
        ),
        _statCard(
          title: 'ژمارەی فرۆشراو',
          value: '$_todaySalesCount',
          icon: Icons.receipt_long_rounded,
          color: AppColors.violet,
        ),
        _statCard(
          title: 'کاڵای کەم ستۆک',
          value: '$lowStockCount',
          icon: Icons.warning_amber_rounded,
          color: AppColors.amber,
        ),
      ];
      int cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 520 ? 2 : 1);
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: cols == 1 ? 3.6 : 1.6,
        children: cards,
      );
    });
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  // ----------------------------- Chart -----------------------------
  Widget _chartCard() {
    final maxVal = _weeklyRevenue.isEmpty
        ? 1.0
        : _weeklyRevenue.reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'فرۆشتنی ٧ ڕۆژی ڕابردوو',
            trailing: AppBadge(text: 'ڕۆژانە', color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _weeklyRevenue.isEmpty
                ? _emptyHint('هیچ داتایەک نییە')
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: AppColors.border, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.now().subtract(
                                  Duration(days: 6 - value.toInt()));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(DateFormat('MM/dd').format(date),
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 11)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              return Text('${(value / 1000).toStringAsFixed(0)}k',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 11));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _weeklyRevenue
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, p, b, i) =>
                                FlDotCirclePainter(
                              radius: 3.5,
                              color: AppColors.surface,
                              strokeWidth: 2,
                              strokeColor: AppColors.primary,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.10),
                          ),
                        ),
                      ],
                      maxY: maxVal * 1.25 + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ----------------------------- Top selling -----------------------------
  Widget _topSellingCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: 'بەرهەمە پڕفرۆشەکان'),
          const SizedBox(height: 16),
          if (_topSellingItems.isEmpty)
            _emptyHint('هیچ داتایەک نییە')
          else
            ..._topSellingItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.inventory_2_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.ink)),
                          Text('${item['total_sold']} دانە فرۆشراوە',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${_currencyFormat.format(item['price'])} د.ع',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.ink)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ----------------------------- Recent sales -----------------------------
  Widget _recentSalesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: 'دوایین فرۆشراوەکان'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('فرۆشراو',
                      style: TextStyle(color: AppColors.muted, fontSize: 12))),
              Expanded(
                  flex: 3,
                  child: Text('ڕێکەوت و کات',
                      style: TextStyle(color: AppColors.muted, fontSize: 12))),
              Expanded(
                  flex: 2,
                  child: Text('کۆی گشتی',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: AppColors.muted, fontSize: 12))),
            ],
          ),
          Divider(height: 22, color: AppColors.border),
          if (_recentSales.isEmpty)
            _emptyHint('هیچ فرۆشتنێک نییە')
          else
            ..._recentSales.map((sale) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text('#${sale.id}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                          DateFormat('yyyy-MM-dd  HH:mm').format(sale.date),
                          style: TextStyle(
                              fontSize: 13, color: AppColors.inkSoft)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                          '${_currencyFormat.format(sale.totalAmount)} د.ع',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emerald)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ----------------------------- Low stock -----------------------------
  Widget _lowStockCard(List<Item> lowStock) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'کاڵای کەم ستۆک',
            trailing: AppBadge(
                text: '${lowStock.length}', color: AppColors.rose),
          ),
          const SizedBox(height: 16),
          if (lowStock.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.emerald, size: 40),
                    const SizedBox(height: 10),
                    Text('هەموو کاڵاکان بەردەستن',
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...lowStock.take(6).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: AppColors.rose, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.ink)),
                    ),
                    AppBadge(
                        text: '${item.quantity} دانە',
                        color: AppColors.rose),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Text(text, style: TextStyle(color: AppColors.muted)),
      ),
    );
  }
}
