import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';

class WorkerSelectSheet extends StatefulWidget {
  final List<String> allWorkers;
  final String role; // 'worker' or 'kensa'
  final String factory;
  final Function(String) onSelected;

  const WorkerSelectSheet({
    super.key,
    required this.allWorkers,
    required this.role,
    required this.factory,
    required this.onSelected,
  });

  static void show({
    required BuildContext context,
    required List<String> allWorkers,
    required String role,
    required String factory,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkerSelectSheet(
        allWorkers: allWorkers,
        role: role,
        factory: factory,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<WorkerSelectSheet> createState() => _WorkerSelectSheetState();
}

class _WorkerSelectSheetState extends State<WorkerSelectSheet> {
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualController = TextEditingController();
  List<String> _filteredWorkers = [];
  List<String> _recentWorkers = [];
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    _filteredWorkers = List.from(widget.allWorkers);
    _loadRecents();
    _searchController.addListener(_filterList);
  }

  void _loadRecents() async {
    final list = await _storageService.getRecentWorkers(widget.factory, widget.role);
    setState(() {
      _recentWorkers = list;
    });
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWorkers = widget.allWorkers
          .where((name) => name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _deleteRecent(String name) async {
    await _storageService.deleteRecentWorker(widget.factory, widget.role, name);
    _loadRecents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + keyboardHeight),
      height: MediaQuery.of(context).size.height * (_isManualMode ? 0.45 : 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppConfig.borderSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.role == 'worker' ? '作業者を選択 / Select Operator' : '検査者を選択 / Select Inspector',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isManualMode = !_isManualMode;
                  });
                },
                icon: Icon(
                  _isManualMode ? Icons.list_alt : Icons.edit,
                  color: AppConfig.primaryAccent,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isManualMode) ...[
            Text(
              '作業者名を手動で入力してください:',
              style: TextStyle(color: AppConfig.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualController,
              autofocus: true,
              style: const TextStyle(color: AppConfig.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppConfig.cardColor,
                hintText: '名前を入力 / Enter Name',
                hintStyle: const TextStyle(color: AppConfig.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide: const BorderSide(color: AppConfig.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide: const BorderSide(color: AppConfig.primaryAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isManualMode = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppConfig.borderSecondary),
                      shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                    ),
                    child: const Text('戻る / Back', style: TextStyle(color: AppConfig.textSecondary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final val = _manualController.text.trim();
                      if (val.isNotEmpty) {
                        widget.onSelected(val);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                    ),
                    child: const Text('確定 / Confirm', style: TextStyle(color: AppConfig.onAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ] else ...[
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppConfig.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppConfig.textMuted),
                filled: true,
                fillColor: AppConfig.cardColor,
                hintText: '検索 / Search...',
                hintStyle: const TextStyle(color: AppConfig.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide: const BorderSide(color: AppConfig.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide: const BorderSide(color: AppConfig.primaryAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Recents Block
            if (_recentWorkers.isNotEmpty) ...[
              Text(
                '最近使用した作業者 / Recent Selection',
                style: TextStyle(fontSize: 14, color: AppConfig.warningColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentWorkers.length,
                  itemBuilder: (context, index) {
                    final name = _recentWorkers[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: InputChip(
                        label: Text(name),
                        labelStyle: const TextStyle(color: AppConfig.textPrimary, fontWeight: FontWeight.bold),
                        backgroundColor: AppConfig.cardColor,
                        shadowColor: Colors.black26,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: AppConfig.radiusMd),
                        onPressed: () {
                          widget.onSelected(name);
                          Navigator.pop(context);
                        },
                        onDeleted: () => _deleteRecent(name),
                        deleteIcon: const Icon(Icons.close, size: 16, color: AppConfig.ngColor),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'すべての作業者 / All Workers',
              style: TextStyle(fontSize: 14, color: AppConfig.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredWorkers.isEmpty
                  ? Center(child: Text('見つかりません / No workers found', style: TextStyle(color: AppConfig.textMuted)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final name = _filteredWorkers[index];
                        return InkWell(
                          onTap: () {
                            widget.onSelected(name);
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppConfig.cardColor,
                              border: Border.all(color: AppConfig.borderSecondary),
                              borderRadius: AppConfig.borderRadius,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppConfig.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
