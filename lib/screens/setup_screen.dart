import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFactory = AppConfig.defaultFactory;
  String _selectedMachine = AppConfig.defaultMachine;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Map<String, List<String>> _factoryMachines = {
    '小瀬': [
      'OZNC01', 'OZNC02', 'OZNC03', 'OZNC04', 'OZNC05',
      'OZNC06', 'OZNC07', 'OZNC08', 'OZNC09', 'OZNC10',
      'OZNC11', 'OZNC12', 'OZNC13', 'OZNC14', 'OZNC15',
      'OZNC16', 'OZNC17', 'OZNC18', 'OZNC19', 'OZNC20',
    ],
    '波崎': [
      'HKNC01', 'HKNC02', 'HKNC03', 'HKNC04', 'HKNC05',
      'HKNC06', 'HKNC07', 'HKNC08', 'HKNC09', 'HKNC10',
    ],
    '大宮': [
      'OMNC01', 'OMNC02', 'OMNC03', 'OMNC04', 'OMNC05',
    ],
  };

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _proceed() async {
    final provider = context.read<ReportProvider>();
    await provider.initEnvironment(_selectedFactory, _selectedMachine);
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

  List<String> get _machines =>
      _factoryMachines[_selectedFactory] ?? _factoryMachines['小瀬']!;

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
                    constraints: const BoxConstraints(maxWidth: 480),
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
    return Row(
      children: _factoryMachines.keys.map((factory) {
        final selected = _selectedFactory == factory;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: factory != _factoryMachines.keys.last ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedFactory = factory;
                // Reset machine if current is not available
                if (!(_factoryMachines[factory] ?? []).contains(_selectedMachine)) {
                  _selectedMachine = (_factoryMachines[factory] ?? []).first;
                }
              }),
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
    final machines = _machines;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: machines.length,
      itemBuilder: (context, i) {
        final machine = machines[i];
        final selected = _selectedMachine == machine;
        return GestureDetector(
          onTap: () => setState(() => _selectedMachine = machine),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? AppConfig.primaryAccent : AppConfig.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppConfig.primaryAccent : AppConfig.borderSecondary,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppConfig.primaryAccent.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                machine,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppConfig.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
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
