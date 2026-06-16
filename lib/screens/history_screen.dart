import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(String sessionId)? onFileSelected;
  const HistoryScreen({super.key, this.onFileSelected});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic>? _files;
  List<dynamic>? _samples;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ApiService('history');
      final results = await Future.wait([api.getHistory(), api.getSamples()]);
      setState(() {
        _files = results[0]['files'];
        _samples = results[1]['files'];
      });
    } catch (e) {
      setState(() => _error = 'Failed to load data. Is the backend running?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredFiles {
    if (_files == null || _searchQuery.isEmpty) return _files ?? [];
    return _files!.where((f) {
      final name = (f['filename'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFiles;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(top: -60, right: -60, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFE8C547).withValues(alpha: 0.1), Colors.transparent])))),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('History & Tracking', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8), letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text('Browse your uploaded reports or try sample datasets.', style: TextStyle(fontSize: 14, color: Color(0xFFB0A890), height: 1.4)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search files...',
                            hintStyle: TextStyle(color: Color(0xFF6B6560)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: const TextStyle(color: Color(0xFFF5F0E8), fontSize: 14),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(onTap: () => _searchCtrl.clear(), child: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B6560))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                    const Spacer(),
                    if (_files != null)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF3A3020), borderRadius: BorderRadius.circular(8)), child: Text('${filtered.length} files', style: const TextStyle(fontSize: 12, color: Color(0xFFE8C547), fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: Color(0xFFE8C547))))
                else if (_error != null)
                  _buildErrorState()
                else if (_files == null || _files!.isEmpty)
                  _buildEmptyState()
                else if (filtered.isEmpty)
                  _buildNoResults()
                else
                  ...(filtered.map((f) => _buildFileCard(f as Map<String, dynamic>))),
                const SizedBox(height: 32),
                _buildSampleSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF4FC3F7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.dataset_rounded, size: 18, color: Color(0xFF4FC3F7))),
            const SizedBox(width: 10),
            const Text('Sample Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
            const Spacer(),
            if (_samples != null)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1A3A3A), borderRadius: BorderRadius.circular(8)), child: Text('${_samples!.length} datasets', style: const TextStyle(fontSize: 12, color: Color(0xFF4FC3F7), fontWeight: FontWeight.w500))),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Pre-loaded datasets to explore the app features.', style: TextStyle(fontSize: 13, color: Color(0xFF6B6560), height: 1.4)),
        const SizedBox(height: 16),
        if (_samples == null || _samples!.isEmpty)
          _buildEmptySamples()
        else
          ...(_samples!.map((s) => _buildSampleCard(s as Map<String, dynamic>))),
      ],
    );
  }

  Widget _buildEmptySamples() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF1A3A3A), borderRadius: BorderRadius.circular(36)), child: const Icon(Icons.folder_off_rounded, size: 36, color: Color(0xFF4FC3F7))),
            const SizedBox(height: 20),
            const Text('No sample data available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const SizedBox(height: 8),
            const Text('Sample datasets were not found on the server.', style: TextStyle(fontSize: 14, color: Color(0xFFB0A890))),
          ]),
        ),
      ),
    );
  }

  void _onTapSample(String filename) async {
    try {
      final api = ApiService('samples');
      final result = await api.loadSample(filename);
      if (widget.onFileSelected != null) {
        widget.onFileSelected!(result['session_id'] as String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sample: $e'), backgroundColor: const Color(0xFFF56565), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Widget _buildSampleCard(Map<String, dynamic> file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _onTapSample(file['filename']?.toString() ?? ''),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0A1A1A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF4FC3F7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.dataset_rounded, color: Color(0xFF4FC3F7), size: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file['description'] ?? file['filename'] ?? 'unknown.csv', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.insert_drive_file_outlined, size: 12, color: const Color(0xFF4FC3F7)),
                          const SizedBox(width: 4),
                          Text(file['filename'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFB0A890))),
                          const SizedBox(width: 14),
                          Icon(Icons.grid_view_rounded, size: 12, color: const Color(0xFF4FC3F7)),
                          const SizedBox(width: 4),
                          Text('Ready to use', style: const TextStyle(fontSize: 12, color: Color(0xFF4FC3F7))),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF4FC3F7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF4FC3F7)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF4A1A1A), borderRadius: BorderRadius.circular(36)), child: const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFFF56565))),
            const SizedBox(height: 20),
            const Text('Backend Offline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFFB0A890)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF3A3020), borderRadius: BorderRadius.circular(36)), child: const Icon(Icons.upload_file_rounded, size: 36, color: Color(0xFFD4AF37))),
            const SizedBox(height: 20),
            const Text('No files uploaded yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const SizedBox(height: 8),
            const Text('Upload CSV files from the Home tab or try the Sample Data below.', style: TextStyle(fontSize: 14, color: Color(0xFFB0A890))),
          ]),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF3A3020), borderRadius: BorderRadius.circular(36)), child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFFD4AF37))),
            const SizedBox(height: 20),
            const Text('No matching files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const SizedBox(height: 8),
            Text("No files match \"$_searchQuery\"", style: const TextStyle(fontSize: 14, color: Color(0xFFB0A890))),
          ]),
        ),
      ),
    );
  }

  void _deleteFile(String sessionId, String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Dataset', style: TextStyle(color: Color(0xFFF5F0E8))),
        content: Text('Delete "$filename"? This cannot be undone.', style: const TextStyle(color: Color(0xFFB0A890))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6560)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFF56565)))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final api = ApiService('history');
        await api.deleteHistory(sessionId);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: const Color(0xFFF56565), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), duration: const Duration(seconds: 3)),
          );
        }
      }
    }
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final size = file['size'] as int;
    final sizeStr = size > 1024 * 1024
        ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(size / 1024).toStringAsFixed(1)} KB';
    final dateStr = file['uploaded_at']?.toString() ?? '';
    final displayDate = dateStr.length >= 19 ? dateStr.substring(0, 19).replaceAll('T', ' ') : dateStr;
    final sessionId = file['session_id']?.toString() ?? '';
    final filename = file['filename']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onFileSelected?.call(sessionId),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF3A3020).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description_rounded, color: Color(0xFFE8C547), size: 22)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(filename, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.insert_drive_file_outlined, size: 12, color: const Color(0xFFD4AF37)),
                            const SizedBox(width: 4),
                            Text(sizeStr, style: const TextStyle(fontSize: 12, color: Color(0xFFB0A890))),
                            const SizedBox(width: 14),
                            Icon(Icons.access_time_rounded, size: 12, color: const Color(0xFFD4AF37)),
                            const SizedBox(width: 4),
                            Text(displayDate, style: const TextStyle(fontSize: 12, color: Color(0xFFB0A890))),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _deleteFile(sessionId, filename),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF4A1A1A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF56565)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => widget.onFileSelected?.call(sessionId),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF3A3020).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_outward_rounded, size: 16, color: Color(0xFFD4AF37)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
