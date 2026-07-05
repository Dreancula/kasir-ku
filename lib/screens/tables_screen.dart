import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/table_model.dart';
import '../providers/cart_provider.dart';
import '../config/app_config.dart';
import '../widgets/animations.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<TableModel> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    final rawData = await DatabaseHelper.instance.getAllTables();
    setState(() {
      _tables = rawData.map((map) => TableModel.fromMap(map)).toList();
      _isLoading = false;
    });
  }

  Future<void> _addTable() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.table_restaurant, color: AppConfig.primaryColor),
            SizedBox(width: 10),
            Text('Tambah Meja'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama/Nomor Meja',
            hintText: 'Contoh: Meja 1, VIP 2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await DatabaseHelper.instance.insertTable(name);
      _loadTables();
    }
  }

  Future<void> _onTableTap(TableModel table, CartProvider cart) async {
    if (table.status == 'kosong') {
      await DatabaseHelper.instance.updateTableStatus(table.id!, 'terisi');
      cart.setTable(table.id!, table.name);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    if (cart.tableId == table.id) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    if (cart.isDineIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selesaikan dulu pesanan di ${cart.tableName}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(table.name),
        content: const Text('Meja ini tercatat terisi. Mau apa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'batal'),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'kosongkan'),
            child: const Text('Kosongkan Meja'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'lanjut'),
            child: const Text('Buat Pesanan Baru'),
          ),
        ],
      ),
    );

    if (action == 'kosongkan') {
      await DatabaseHelper.instance.updateTableStatus(table.id!, 'kosong');
      _loadTables();
    } else if (action == 'lanjut') {
      cart.setTable(table.id!, table.name);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Hapus Meja'),
          ],
        ),
        content: Text('Hapus "${table.name}" dari daftar meja?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTable(table.id!);
      _loadTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final emptyCount = _tables.where((t) => t.status == 'kosong').length;
    final filledCount = _tables.length - emptyCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Meja'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary bar
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total',
                              '${_tables.length}',
                              Icons.table_restaurant,
                              AppConfig.primaryColor,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[200],
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Kosong',
                              '$emptyCount',
                              Icons.event_seat,
                              Colors.green,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[200],
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Terisi',
                              '$filledCount',
                              Icons.people,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grid meja
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          return FadeInUp(
                            delayMs: index * 60,
                            offset: 20,
                            child: _buildTableCard(table, cart),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTable,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Meja'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(TableModel table, CartProvider cart) {
    final isKosong = table.status == 'kosong';
    final isCurrentActive = cart.tableId == table.id;

    Color bgColor;
    Color textColor;
    Color iconColor;

    if (isCurrentActive) {
      bgColor = AppConfig.primaryColor;
      textColor = Colors.white;
      iconColor = Colors.white;
    } else if (isKosong) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      iconColor = Colors.green;
    } else {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      iconColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () => _onTableTap(table, cart),
      onLongPress: () => _deleteTable(table),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              table.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCurrentActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isKosong
                        ? Colors.green.shade100
                        : Colors.orange.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCurrentActive ? 'Aktif' : table.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isCurrentActive ? Colors.white : textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInUp(
            child: Icon(
              Icons.table_restaurant_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delayMs: 150,
            child: Text(
              'Belum ada meja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delayMs: 300,
            child: Text(
              'Tekan tombol + untuk menambah meja',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
