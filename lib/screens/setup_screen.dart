import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';
import '../models/equipment_model.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String _selectedFactory = AppConfig.defaultFactory;
  String _selectedMachine = AppConfig.defaultMachine;

  List<String> _factories = [];
  List<Equipment> _equipments = [];
  bool _loadingFactories = true;
  bool _loadingEquipments = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _loadFactories();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadFactories() async {
    setState(() {
      _loadingFactories = true;
    });
    try {
      final list = await _apiService.fetchFactories();
      setState(() {
        _factories = list;
        if (_factories.isNotEmpty) {
          if (!_factories.contains(_selectedFactory)) {
            _selectedFactory = _factories.first;
          }
        }
        _loadingFactories = false;
      });
      _loadEquipments();
    } catch (e) {
      setState(() {
        _factories = ['小瀬', '波崎', '大宮'];
        _loadingFactories = false;
      });
      _loadEquipments();
    }
  }

  Future<void> _loadEquipments() async {
    setState(() {
      _loadingEquipments = true;
    });
    try {
      final list = await _apiService.fetchEquipmentList(_selectedFactory);
      setState(() {
        _equipments = list;
        final hasMatch = _equipments.any((eq) => eq.name == _selectedMachine);
        if (!hasMatch && _equipments.isNotEmpty) {
          _selectedMachine = _equipments.first.name;
        }
        _loadingEquipments = false;
      });
    } catch (e) {
      setState(() {
        _equipments = [];
        _loadingEquipments = false;
      });
    }
  }

  void _proceed() async {
    final provider = context.read<ReportProvider>();
    await provider.initEnvironment(_selectedFactory, _selectedMachine);
    provider.setAppStage(AppStage.scan);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / Header
                        _buildHeader(),
                        const SizedBox(height: 48),

                        // Factory Selector
                        _buildSectionLabel('工場 / Factory'),
                        const SizedBox(height: 12),
                        _buildFactorySelector(),
                        const SizedBox(height: 28),

                        // Machine Selector
                        _buildSectionLabel('設備番号 / Machine'),
                        const SizedBox(height: 12),
                        _buildMachineGrid(),
                        const SizedBox(height: 48),

                        // Proceed Button
                        _buildProceedButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppConfig.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppConfig.primaryAccent.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.factory_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'DCP iReporter',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppConfig.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '作業環境を選択してください\nPlease select your work environment',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppConfig.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppConfig.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFactorySelector() {
    if (_loadingFactories) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppConfig.primaryAccent,
          ),
        ),
      );
    }

    return Row(
      children: _factories.map((factory) {
        final selected = _selectedFactory == factory;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: factory != _factories.last ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                if (_selectedFactory == factory) return;
                setState(() {
                  _selectedFactory = factory;
                });
                _loadEquipments();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: selected ? AppConfig.primaryGradient : null,
                  color: selected ? null : AppConfig.cardColor,
                  borderRadius: AppConfig.borderRadius,
                  border: Border.all(
                    color: selected ? AppConfig.primaryAccent : AppConfig.borderSecondary,
                    width: selected ? 0 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppConfig.primaryAccent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  factory,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppConfig.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMachineGrid() {
    if (_loadingEquipments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppConfig.primaryAccent,
          ),
        ),
      );
    }

    if (_equipments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Text(
            '設備データがありません\nNo equipment found',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppConfig.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _equipments.length,
      itemBuilder: (context, i) {
        final eq = _equipments[i];
        final selected = _selectedMachine == eq.name;
        return _buildEquipmentCard(eq, selected);
      },
    );
  }

  Widget _buildEquipmentCard(Equipment eq, bool selected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedMachine = eq.name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppConfig.primaryAccent.withOpacity(0.12) : AppConfig.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppConfig.primaryAccent : AppConfig.borderSecondary,
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppConfig.primaryAccent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: eq.imageUrl.isNotEmpty
                    ? Image.network(
                        eq.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppConfig.backgroundColor,
                            child: const Icon(
                              Icons.precision_manufacturing_rounded,
                              color: AppConfig.textMuted,
                              size: 32,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppConfig.backgroundColor,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConfig.primaryAccent,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppConfig.backgroundColor,
                        child: const Icon(
                          Icons.precision_manufacturing_rounded,
                          color: AppConfig.textMuted,
                          size: 32,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eq.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppConfig.primaryAccent : AppConfig.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eq.model.isNotEmpty ? 'Model: ${eq.model}' : 'Maker: ${eq.manufacturer.isNotEmpty ? eq.manufacturer : "-"}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppConfig.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (eq.voltage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConfig.borderSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            eq.voltage,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      if (eq.weight > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConfig.borderSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${eq.weight.toInt()}kg',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return Consumer<ReportProvider>(
      builder: (_, provider, __) {
        return SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _proceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
              shadowColor: AppConfig.primaryAccent.withOpacity(0.5),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '開始する  /  Start',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 22),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
