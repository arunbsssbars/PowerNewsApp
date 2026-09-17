import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();

  // ML Data State
  List<dynamic> _mlData = [];
  bool _isLoadingMl = false;

  // Keywords State
  List<String> _baseKeywords = [];
  List<String> _dynamicKeywords = [];
  bool _isLoadingKeywords = false;
  final TextEditingController _keywordInputController = TextEditingController();

  // Health State
  Map<String, dynamic>? _healthData;
  Map<String, dynamic>? _memoryData;
  bool _isLoadingHealth = false;

  // Web HQ Mode
  bool _isWebHQMode = false;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initWebView();
    _loadAllTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordInputController.dispose();
    super.dispose();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://powernewsapp-backend.onrender.com/admin/'));
  }

  Map<String, String> _getHeaders() {
    final token = _auth.currentUser?.idToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String get _baseUrl => ApiService.renderCloudHost;

  Future<void> _loadAllTabs() async {
    _fetchMlData();
    _fetchKeywords();
    _fetchHealth();
  }

  // --- ML Training API ---
  Future<void> _fetchMlData() async {
    setState(() => _isLoadingMl = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/training-data?limit=25'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _mlData = decoded['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching ML data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMl = false);
    }
  }

  Future<void> _updateMlStatus(String id, String status) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/training-data/$id/status'),
        headers: _getHeaders(),
        body: jsonEncode({'status': status}),
      );
      if (res.statusCode == 200) {
        setState(() {
          final idx = _mlData.indexWhere((item) => item['id'] == id);
          if (idx != -1) {
            _mlData[idx]['mlStatus'] = status;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated status to "$status"'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Error updating status: $e');
    }
  }

  // --- Keywords API ---
  Future<void> _fetchKeywords() async {
    setState(() => _isLoadingKeywords = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/keywords'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _baseKeywords = List<String>.from(decoded['baseKeywords'] ?? []);
          _dynamicKeywords = List<String>.from(decoded['dynamicKeywords'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching keywords: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKeywords = false);
    }
  }

  Future<void> _autoDiscoverKeywords() async {
    setState(() => _isLoadingKeywords = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/keywords/auto-discover'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final newlyAdded = List<String>.from(decoded['newlyAdded'] ?? []);
        await _fetchKeywords();
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Discovery Complete'),
                ],
              ),
              content: Text(
                newlyAdded.isNotEmpty
                    ? '🎯 Gemini auto-discovered and added ${newlyAdded.length} new keywords:\n\n${newlyAdded.join(", ")}'
                    : '✅ Checked recent power news against active list. All emerging entities are already captured!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Auto-discovery error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKeywords = false);
    }
  }

  Future<void> _addCustomKeyword() async {
    final text = _keywordInputController.text.trim();
    if (text.isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/keywords/add'),
        headers: _getHeaders(),
        body: jsonEncode({'keyword': text}),
      );
      if (res.statusCode == 200) {
        _keywordInputController.clear();
        _fetchKeywords();
      }
    } catch (e) {
      debugPrint('[Admin] Add keyword error: $e');
    }
  }

  Future<void> _deleteKeyword(String kw) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/api/admin/keywords/${Uri.encodeComponent(kw)}'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        _fetchKeywords();
      }
    } catch (e) {
      debugPrint('[Admin] Delete keyword error: $e');
    }
  }

  // --- Health API ---
  Future<void> _fetchHealth() async {
    setState(() => _isLoadingHealth = true);
    try {
      final healthRes = await http.get(Uri.parse('$_baseUrl/api/health'), headers: _getHeaders());
      final memRes = await http.get(Uri.parse('$_baseUrl/api/memory'), headers: _getHeaders());
      if (healthRes.statusCode == 200) {
        _healthData = jsonDecode(healthRes.body);
      }
      if (memRes.statusCode == 200) {
        _memoryData = jsonDecode(memRes.body);
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching health: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHealth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Admin privileges required. Please sign in with arunbsssbars@gmail.com.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin HQ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isWebHQMode ? 'Switch to Native Mobile View' : 'Launch Full Web HQ',
            icon: Icon(_isWebHQMode ? Icons.smartphone_rounded : Icons.open_in_browser_rounded),
            onPressed: () => setState(() => _isWebHQMode = !_isWebHQMode),
          ),
          IconButton(
            tooltip: 'Refresh Current Data',
            icon: const Icon(Icons.sync_rounded),
            onPressed: _loadAllTabs,
          ),
        ],
        bottom: _isWebHQMode
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2563EB),
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                tabs: const [
                  Tab(text: 'ML Queue', icon: Icon(Icons.model_training_rounded, size: 18)),
                  Tab(text: 'Keywords', icon: Icon(Icons.auto_awesome_rounded, size: 18)),
                  Tab(text: 'Health', icon: Icon(Icons.monitor_heart_rounded, size: 18)),
                ],
              ),
      ),
      body: _isWebHQMode
          ? WebViewWidget(controller: _webViewController)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMlQueueTab(isDark),
                _buildKeywordsTab(isDark),
                _buildHealthTab(isDark),
              ],
            ),
    );
  }

  // --- Tab 1: ML Queue ---
  Widget _buildMlQueueTab(bool isDark) {
    if (_isLoadingMl) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mlData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('No training records found in queue.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchMlData, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMlData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mlData.length,
        itemBuilder: (context, index) {
          final item = _mlData[index];
          final id = item['id'] ?? '';
          final title = item['title'] ?? 'Untitled';
          final publisher = item['publisher'] ?? 'Unknown';
          final score = item['calculatedScore'] ?? 0;
          final status = item['mlStatus'] ?? 'pending';
          final geminiSummary = item['geminiSummary'] ?? '';
          final originalText = item['originalText'] ?? '';

          Color statusColor = Colors.grey;
          if (status == 'approved') statusColor = const Color(0xFF10B981);
          if (status == 'rejected') statusColor = const Color(0xFFEF4444);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 0.8),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(publisher, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 10),
                      Text('Score: $score', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2563EB))),
                        const SizedBox(height: 4),
                        Text(geminiSummary.isNotEmpty ? geminiSummary : originalText, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                        onPressed: () => _updateMlStatus(id, 'rejected'),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _updateMlStatus(id, 'approved'),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Tab 2: Keywords ---
  Widget _buildKeywordsTab(bool isDark) {
    final total = _baseKeywords.length + _dynamicKeywords.length;

    return RefreshIndicator(
      onRefresh: _fetchKeywords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto-Discovery Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Automated Entity Discovery',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gemini analyzes live news feeds to discover missing power sector entities and automatically adds them to the scoring engine.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isLoadingKeywords
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Auto-Discover & Add Missing Keywords', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: _isLoadingKeywords ? null : _autoDiscoverKeywords,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Add Custom Keyword Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordInputController,
                  decoration: InputDecoration(
                    hintText: 'Add custom keyword...',
                    hintStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _addCustomKeyword(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addCustomKeyword,
                child: const Text('Add'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Active Keywords Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Keywords ($total)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                '${_dynamicKeywords.length} Dynamic / ${_baseKeywords.length} Base',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Dynamic keywords first
              ..._dynamicKeywords.map((kw) => Chip(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 0.8),
                    avatar: const Icon(Icons.bolt, size: 14, color: Color(0xFF2563EB)),
                    label: Text(kw, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF2563EB)),
                    onDeleted: () => _deleteKeyword(kw),
                  )),
              // Base keywords
              ..._baseKeywords.map((kw) => Chip(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    label: Text(kw, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12)),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 3: System Health ---
  Widget _buildHealthTab(bool isDark) {
    if (_isLoadingHealth) {
      return const Center(child: CircularProgressIndicator());
    }

    final uptime = _healthData?['uptimeFormatted'] ?? 'Online';
    final articles = _healthData?['rawScrapedArticles'] ?? 0;
    final summaries = _healthData?['totalAiSummaries'] ?? 0;
    final rssMb = _memoryData?['rssMb'] ?? 'N/A';
    final heapMb = _memoryData?['heapUsedMb'] ?? 'N/A';

    return RefreshIndicator(
      onRefresh: _fetchHealth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHealthTile('Server Uptime', uptime, Icons.timer_outlined, const Color(0xFF10B981), isDark),
          _buildHealthTile('Articles Scraped', '$articles articles', Icons.article_outlined, const Color(0xFF2563EB), isDark),
          _buildHealthTile('AI Summaries in RAM', '$summaries ready', Icons.auto_awesome_rounded, const Color(0xFF8B5CF6), isDark),
          _buildHealthTile('RAM Memory (RSS)', '$rssMb MB', Icons.memory_rounded, const Color(0xFFF59E0B), isDark),
          _buildHealthTile('V8 Heap Used', '$heapMb MB', Icons.storage_rounded, const Color(0xFF06B6D4), isDark),
        ],
      ),
    );
  }

  Widget _buildHealthTile(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
      ),
    );
  }
}
