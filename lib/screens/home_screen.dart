import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/chart_image.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  final String? initialSessionId;
  const HomeScreen({super.key, this.initialSessionId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isDragging = false;
  bool _isLoading = false;
  String? _uploadedFileName;
  Map<String, dynamic>? _uploadResult;
  Map<String, dynamic>? _dataInfo;
  Map<String, dynamic>? _trainResult;
  List<dynamic>? _preview;
  String? _error;
  late final String _sessionId;
  late ApiService _api;

  final TextEditingController _targetCtrl = TextEditingController();
  final TextEditingController _featuresCtrl = TextEditingController();
  String _selectedModel = 'Linear Regression';
  List<String> _numericColumns = [];

  String _selectedChartType = 'Scatter';
  String _selectedXAxis = '';
  String _selectedYAxis = '';
  String? _chartImageUrl;
  String? _correlationImageUrl;
  bool _isChartLoading = false;
  bool _isCorrelationLoading = false;
  List<String> _trainedFeatures = [];
  Map<String, TextEditingController> _predictionInputs = {};
  Map<String, dynamic>? _predictionResult;
  bool _isPredicting = false;
  bool _isCleaning = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.initialSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _api = ApiService(_sessionId);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
    if (widget.initialSessionId != null) {
      _loadExistingSession();
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _featuresCtrl.dispose();
    _fadeController.dispose();
    for (var c in _predictionInputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFD4AF37).withValues(alpha: 0.15), Colors.transparent])))),
          Positioned(bottom: -80, left: -80, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFE8C547).withValues(alpha: 0.1), Colors.transparent])))),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFF5E0A0)), SizedBox(width: 6), Text('AI-Powered', style: TextStyle(fontSize: 12, color: Color(0xFFF5E0A0), fontWeight: FontWeight.w500))]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Transform Your\n', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8), letterSpacing: -0.5, height: 1.2)),
                        TextSpan(text: 'Reports Into Insights', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFF5E0A0), letterSpacing: -0.5, height: 1.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.5)),
                    ),
                    child: Row(children: [Icon(Icons.rocket_launch_rounded, size: 20, color: const Color(0xFFE8C547)), const SizedBox(width: 12), const Expanded(child: Text('Upload a CSV and let ML uncover patterns in your data automatically.', style: TextStyle(fontSize: 13, color: Color(0xFFB0A890), height: 1.4)))]),
                  ),
                  const SizedBox(height: 32),
                  const Text('Upload CSV File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFF3A1010), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF56565).withValues(alpha: 0.3))),
                      child: Row(children: [Icon(Icons.error_outline_rounded, size: 18, color: const Color(0xFFF56565)), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFF56565), fontSize: 13)))]),
                    ),
                  GestureDetector(
                    onTap: _isLoading ? null : _pickFile,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            _isDragging ? const Color(0xFF3A3020) : const Color(0xFF141414).withValues(alpha: 0.6),
                            _isDragging ? const Color(0xFF141414) : const Color(0xFF0A0A0A).withValues(alpha: 0.4),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isDragging ? const Color(0xFFE8C547) : const Color(0xFF3A3020).withValues(alpha: 0.6), width: _isDragging ? 2 : 1),
                          boxShadow: _isDragging ? [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5)] : null,
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8C547)))
                            : Column(
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(color: (_isDragging ? const Color(0xFFE8C547) : const Color(0xFFD4AF37)).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                                    child: Icon(Icons.cloud_upload_outlined, size: 32, color: _isDragging ? const Color(0xFFF5E0A0) : const Color(0xFFD4AF37)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(_uploadedFileName ?? 'Drop your CSV here or tap to browse', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _isDragging ? const Color(0xFFF5F0E8) : const Color(0xFF8A7AAC))),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.description_outlined, size: 14, color: (_isDragging ? const Color(0xFFF5E0A0) : const Color(0xFFD4AF37)).withValues(alpha: 0.7)),
                                      const SizedBox(width: 6),
                                      Text('.csv files only', style: TextStyle(fontSize: 12, color: (_isDragging ? const Color(0xFFF5E0A0) : const Color(0xFFD4AF37)).withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (_uploadResult != null) ...[
                    const SizedBox(height: 20),
                    _buildUploadResult(),
                  ],
                  if (_dataInfo != null) ...[
                    const SizedBox(height: 28),
                    _buildDataInfo(),
                    const SizedBox(height: 16),
                    _buildDataCleaningButton(),
                    const SizedBox(height: 20),
                    _buildPreviewTable(),
                    const SizedBox(height: 28),
                    _buildVisualizationSection(),
                    const SizedBox(height: 28),
                    _buildMLSection(),
                  ],
                  if (_trainResult != null) ...[
                    const SizedBox(height: 28),
                    _buildTrainResult(),
                    const SizedBox(height: 28),
                    _buildPredictionSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadResult() {
    final r = _uploadResult!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0A2A0A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3))),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['filename'] ?? '', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${r['rows']} rows \u00b7 ${r['columns']} columns \u00b7 ${r['missing_values']} missing', style: const TextStyle(color: Color(0xFFB0A890), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataInfo() {
    final info = _dataInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dataset Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
        const SizedBox(height: 14),
        Row(
          children: [
            _metricCard('Rows', '${info['shape'][0]}', Icons.table_rows_rounded, const Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            _metricCard('Columns', '${info['shape'][1]}', Icons.view_column_rounded, const Color(0xFF4CAF50)),
            const SizedBox(width: 10),
            _metricCard('Missing', '${info['missing_values']}', Icons.warning_amber_rounded, const Color(0xFFD4AF37)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_preview == null || _preview!.isEmpty) return const SizedBox.shrink();
    final columns = (_preview!.first as Map<String, dynamic>).keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Data Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF3A3020), borderRadius: BorderRadius.circular(6)), child: Text('${_preview!.length} rows', style: const TextStyle(fontSize: 11, color: Color(0xFFE8C547)))),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
              padding: const EdgeInsets.all(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 36,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF3A3020).withValues(alpha: 0.6)),
                  dataRowColor: WidgetStateProperty.all(Colors.transparent),
                  columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(color: Color(0xFFE8C547), fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
                  rows: _preview!.map((row) {
                    final r = row as Map<String, dynamic>;
                    return DataRow(cells: columns.map((c) => DataCell(Text('${r[c]}', style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 12)))).toList());
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMLSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.psychology_rounded, size: 18, color: Color(0xFFE8C547))),
                  const SizedBox(width: 10),
                  const Text('Machine Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Target Variable', style: TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Autocomplete<String>(
                          optionsBuilder: (textEditingValue) => _numericColumns.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                          onSelected: (v) => _targetCtrl.text = v,
                          fieldViewBuilder: (ctx, controller, focusNode, onSubmit) => TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'e.g. price',
                              hintStyle: const TextStyle(color: Color(0xFF6B6560)),
                              filled: true,
                              fillColor: const Color(0xFF0A0A0A).withValues(alpha: 0.6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Features (comma-sep)', style: TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _featuresCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. age, income',
                            hintStyle: const TextStyle(color: Color(0xFF6B6560)),
                            filled: true,
                            fillColor: const Color(0xFF0A0A0A).withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Model', style: TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: const Color(0xFF0A0A0A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedModel,
                              dropdownColor: const Color(0xFF141414),
                              items: ['Linear Regression', 'Decision Tree', 'Random Forest'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14)))).toList(),
                              onChanged: (v) => setState(() => _selectedModel = v!),
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFFE8C547)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _trainModel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF3A3020),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow_rounded, size: 18), SizedBox(width: 6), Text('Train Model', style: TextStyle(fontWeight: FontWeight.w600))]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainResult() {
    final r = _trainResult!;
    final metrics = r['metrics'] as Map<String, dynamic>;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.analytics_rounded, size: 18, color: Color(0xFFE8C547))),
                  const SizedBox(width: 10),
                  const Text('Model Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                  const Spacer(),
                  _buildFeedbackBadge(r['feedback_type']),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _metricCardSmall('MAE', (metrics['MAE'] as num).toStringAsFixed(4)),
                  const SizedBox(width: 8),
                  _metricCardSmall('MSE', (metrics['MSE'] as num).toStringAsFixed(4)),
                  const SizedBox(width: 8),
                  _metricCardSmall('RMSE', (metrics['RMSE'] as num).toStringAsFixed(4)),
                  const SizedBox(width: 8),
                  _metricCardSmall('R\u00b2', (metrics['R2'] as num).toStringAsFixed(4)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metricCardSmall('CV Mean', (r['cv_mean'] as num).toStringAsFixed(4)),
                  const SizedBox(width: 8),
                  _metricCardSmall('CV Std', (r['cv_std'] as num).toStringAsFixed(4)),
                ],
              ),
              if (r['feedback_message'] != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF3A3020).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(_feedbackIcon(r['feedback_type']), color: _feedbackColor(r['feedback_type']), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r['feedback_message'], style: TextStyle(color: _feedbackColor(r['feedback_type']), fontSize: 13))),
                    ],
                  ),
                ),
              ],
              if (r['feature_importance'] != null) ...[
                const SizedBox(height: 18),
                const Text('Feature Importance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
                const SizedBox(height: 10),
                ...(_buildFeatureImportance(r['feature_importance'] as List<dynamic>)),
              ],
              const SizedBox(height: 20),
              _buildDiagnosticPlots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticPlots() {
    final r = _trainResult!;
    final hasActualPred = r['actual_vs_predicted_img'] != null;
    final hasResiduals = r['residuals_img'] != null;
    if (!hasActualPred && !hasResiduals) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.insert_chart_rounded, size: 18, color: Color(0xFFE8C547))),
            const SizedBox(width: 10),
            const Text('Diagnostic Plots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
          ],
        ),
        const SizedBox(height: 16),
        if (hasActualPred) ...[
          const Text('Actual vs Predicted', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB0A890))),
          const SizedBox(height: 8),
          ChartImage.base64(base64Data: r['actual_vs_predicted_img'] as String, height: 380),
          const SizedBox(height: 20),
        ],
        if (hasResiduals) ...[
          const Text('Residuals Plot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB0A890))),
          const SizedBox(height: 8),
          ChartImage.base64(base64Data: r['residuals_img'] as String, height: 380),
        ],
      ],
    );
  }

  Widget _buildVisualizationSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFFE8C547))),
                  const SizedBox(width: 10),
                  const Text('Data Visualization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chart Type', style: TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: const Color(0xFF0A0A0A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedChartType,
                              dropdownColor: const Color(0xFF141414),
                              items: ['Scatter', 'Line', 'Bar', 'Histogram', 'Box Plot'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14)))).toList(),
                              onChanged: (v) => setState(() => _selectedChartType = v!),
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFFE8C547)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('X Axis', style: TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: const Color(0xFF0A0A0A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedXAxis.isEmpty && _numericColumns.isNotEmpty ? _numericColumns.first : _selectedXAxis,
                              dropdownColor: const Color(0xFF141414),
                              items: _numericColumns.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14)))).toList(),
                              onChanged: (v) => setState(() => _selectedXAxis = v!),
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFFE8C547)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Y Axis', style: TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: const Color(0xFF0A0A0A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedYAxis.isEmpty && _numericColumns.length > 1 ? _numericColumns[1] : (_selectedYAxis.isEmpty && _numericColumns.length == 1 ? _numericColumns.first : _selectedYAxis),
                              dropdownColor: const Color(0xFF141414),
                              items: _numericColumns.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14)))).toList(),
                              onChanged: (v) => setState(() => _selectedYAxis = v!),
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFFE8C547)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isChartLoading ? null : _generateChart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF3A3020),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isChartLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow_rounded, size: 18), SizedBox(width: 6), Text('Generate Chart', style: TextStyle(fontWeight: FontWeight.w600))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isCorrelationLoading ? null : _loadCorrelation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3020), foregroundColor: const Color(0xFFF5E0A0), disabledBackgroundColor: const Color(0xFF141414),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                          elevation: 0,
                        ),
                        child: _isCorrelationLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF5E0A0)))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.grid_on_rounded, size: 18), SizedBox(width: 6), Text('Correlation Heatmap', style: TextStyle(fontWeight: FontWeight.w600))]),
                      ),
                    ),
                  ),
                ],
              ),
              if (_chartImageUrl != null) ...[
                const SizedBox(height: 20),
                ChartImage.network(imageUrl: _chartImageUrl!, height: 380),
              ],
              if (_correlationImageUrl != null) ...[
                const SizedBox(height: 20),
                ChartImage.network(imageUrl: _correlationImageUrl!, height: 480),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateChart() async {
    final xAxis = _selectedXAxis.isEmpty ? _numericColumns.first : _selectedXAxis;
    final yAxis = _selectedYAxis.isEmpty ? (_numericColumns.length > 1 ? _numericColumns[1] : _numericColumns.first) : _selectedYAxis;
    setState(() {
      _isChartLoading = true;
      _error = null;
      _chartImageUrl = '${AppConfig.apiBaseUrl}/visualization/chart-image'
          '?session_id=$_sessionId&chart_type=$_selectedChartType&x_axis=$xAxis&y_axis=$yAxis';
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _isChartLoading = false);
  }

  Future<void> _loadCorrelation() async {
    setState(() {
      _isCorrelationLoading = true;
      _error = null;
      _correlationImageUrl = '${AppConfig.apiBaseUrl}/visualization/correlation-image?session_id=$_sessionId';
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _isCorrelationLoading = false);
  }

  Widget _metricCardSmall(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFF0A0A0A).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.3))),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFE8C547), letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFB0A890), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBadge(String? type) {
    Color c;
    switch (type) {
      case 'success': c = const Color(0xFF4CAF50); break;
      case 'info': c = const Color(0xFFD4AF37); break;
      case 'warning': c = const Color(0xFFD4AF37); break;
      default: c = const Color(0xFFF56565);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(type ?? '', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  IconData _feedbackIcon(String? type) {
    switch (type) { case 'success': return Icons.emoji_events; case 'info': return Icons.info; case 'warning': return Icons.warning_amber_rounded; default: return Icons.error_outline_rounded; }
  }

  Color _feedbackColor(String? type) {
    switch (type) { case 'success': return const Color(0xFF4CAF50); case 'info': return const Color(0xFFD4AF37); case 'warning': return const Color(0xFFD4AF37); default: return const Color(0xFFF56565); }
  }

  List<Widget> _buildFeatureImportance(List<dynamic> importance) {
    importance.sort((a, b) => (b['Importance'] as num).compareTo(a['Importance'] as num));
    return importance.take(10).map((item) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(item['Feature'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFB0A890), overflow: TextOverflow.ellipsis))),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (item['Importance'] as num).toDouble().clamp(0, 1),
                backgroundColor: const Color(0xFF3A3020),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE8C547)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text((item['Importance'] as num).toStringAsFixed(3), style: const TextStyle(fontSize: 11, color: Color(0xFFE8C547)))),
        ],
      ),
    )).toList();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final String filename = picked.name;
    List<int> bytes;

    if (picked.bytes != null) {
      bytes = picked.bytes!;
    } else if (picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    } else {
      return;
    }

    setState(() { _isLoading = true; _error = null; _uploadResult = null; _dataInfo = null; _trainResult = null; _preview = null; _chartImageUrl = null; _correlationImageUrl = null; });

    try {
      final uploadRes = await _api.uploadFile(bytes: bytes, filename: filename);
      setState(() {
        _uploadResult = uploadRes;
        _uploadedFileName = uploadRes['filename'];
      });
      await _loadDataInfo();
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataInfo() async {
    try {
      final info = await _api.getDataInfo();
      final cols = await _api.getColumns();
      final preview = await _api.getDataPreview();
      setState(() {
        _dataInfo = info;
        _preview = preview;
        _numericColumns = List<String>.from(cols['numeric_columns']);
        _featuresCtrl.text = _numericColumns.take(3).join(', ');
        if (_numericColumns.isNotEmpty) _targetCtrl.text = _numericColumns.last;
        if (_numericColumns.length > 1) { _selectedXAxis = _numericColumns[0]; _selectedYAxis = _numericColumns[1]; }
        else if (_numericColumns.length == 1) { _selectedXAxis = _selectedYAxis = _numericColumns[0]; }
      });
    } catch (e) {
      setState(() => _error = 'Failed to load data info: $e');
    }
  }

  Future<void> _loadExistingSession() async {
    setState(() => _isLoading = true);
    try {
      final loadRes = await _api.loadSession();
      setState(() {
        _uploadResult = {
          'filename': loadRes['filename'],
          'rows': loadRes['rows'],
          'columns': loadRes['columns'],
        };
        _uploadedFileName = loadRes['filename'];
      });
      await _loadDataInfo();
    } catch (e) {
      setState(() => _error = 'Failed to load session: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanData() async {
    setState(() { _isCleaning = true; _error = null; });
    try {
      await _api.cleanData();
      await _loadDataInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data cleaned successfully'), backgroundColor: Color(0xFF4CAF50), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() => _error = 'Cleaning failed: $e');
    } finally {
      setState(() => _isCleaning = false);
    }
  }

  Future<void> _trainModel() async {
    if (_targetCtrl.text.isEmpty) {
      setState(() => _error = 'Please specify a target variable');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    try {
      final features = _featuresCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      _trainedFeatures = features;
      final result = await _api.trainModel(
        target: _targetCtrl.text.trim(),
        features: features,
        modelName: _selectedModel,
      );
      setState(() {
        _trainResult = result;
        _predictionInputs.forEach((_, c) => c.dispose());
        _predictionInputs = {for (var f in _trainedFeatures) f: TextEditingController()};
        _predictionResult = null;
      });
    } catch (e) {
      setState(() => _error = 'Training failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _predict() async {
    setState(() { _isPredicting = true; _error = null; });
    try {
      final inputData = <String, dynamic>{};
      for (var f in _trainedFeatures) {
        final value = _predictionInputs[f]?.text ?? '';
        inputData[f] = double.tryParse(value) ?? value;
      }
      final result = await _api.predict(inputData);
      setState(() => _predictionResult = result);
    } catch (e) {
      setState(() => _error = 'Prediction failed: $e');
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  Widget _buildDataCleaningButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isCleaning ? null : _cleanData,
              icon: _isCleaning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cleaning_services_rounded, size: 18),
              label: Text(_isCleaning ? 'Cleaning...' : 'Clean Missing Values'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionSection() {
    if (_trainedFeatures.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFE8C547))),
                  const SizedBox(width: 10),
                  const Text('Make a Prediction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                ],
              ),
              const SizedBox(height: 16),
              ..._trainedFeatures.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f, style: const TextStyle(fontSize: 11, color: Color(0xFFB0A890), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _predictionInputs[f] ?? TextEditingController(),
                      decoration: InputDecoration(
                        hintText: 'Enter $f',
                        hintStyle: const TextStyle(color: Color(0xFF6B6560)),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A).withValues(alpha: 0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPredicting ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: _isPredicting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome_rounded, size: 18), SizedBox(width: 6), Text('Predict', style: TextStyle(fontWeight: FontWeight.w600))]),
                ),
              ),
              if (_predictionResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF0A2A0A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Predicted ${_predictionResult!['target']}', style: const TextStyle(color: Color(0xFFB0A890), fontSize: 12)),
                            const SizedBox(height: 2),
                            Text((_predictionResult!['prediction'] as num).toStringAsFixed(4), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
