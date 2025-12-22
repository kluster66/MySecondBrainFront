import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const BrainCaptureApp());
}

class BrainCaptureApp extends StatelessWidget {
  const BrainCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brain Capture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const CaptureScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.send_rounded),
            label: 'Capturer',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}

// --- ÉCRAN DE CAPTURE ---

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedModel = 'gemini';
  bool _isLoading = false;

  // Suppression du 'const' ici pour éviter les erreurs de type
  final List<DropdownMenuItem<String>> _modelItems = [
    const DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek (Code/Structure)')),
    const DropdownMenuItem(value: 'gemini', child: Text('Gemini (Context/Vitesse)')),
    const DropdownMenuItem(value: 'claude', child: Text('Claude (Nuance)')),
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _uploadToGithub() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('gh_token');
    final owner = prefs.getString('gh_owner');
    final repo = prefs.getString('gh_repo');
    final path = prefs.getString('gh_path') ?? '00_Inbox/_drafts';

    if (!mounted) return;

    if (token == null || owner == null || repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Configuration GitHub manquante')),
      );
      return;
    }

    if (_urlController.text.isEmpty && _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ URL ou Note requise')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd-HHmm').format(now);
      
      String slug = _urlController.text
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .replaceAll('https', '')
          .replaceAll('http', '')
          .replaceAll('www', '');
      if (slug.length > 20) slug = slug.substring(0, 20);
      if (slug.isEmpty) slug = "note";

      final filename = '${timestamp}_$slug.json';
      final filePath = '$path/$filename';

      final payload = {
        "url": _urlController.text,
        "added_at": now.toIso8601String(),
        "note": _noteController.text,
        "model_pref": _selectedModel
      };

      final jsonContent = jsonEncode(payload);
      final bytes = utf8.encode(jsonContent);
      final base64Content = base64Encode(bytes);

      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$filePath');
      
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/vnd.github.v3+json',
        },
        body: jsonEncode({
          "message": "Capture Mobile: $slug",
          "content": base64Content,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Envoyé à la Queue avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _urlController.clear();
        _noteController.clear();
      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brain Capture'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL à traiter',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes / Contexte',
                hintText: 'Pourquoi c\'est intéressant ?',
                prefixIcon: Icon(Icons.note_alt_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedModel,
              items: _modelItems,
              onChanged: (val) => setState(() => _selectedModel = val!),
              decoration: const InputDecoration(
                labelText: 'Modèle IA',
                prefixIcon: Icon(Icons.smart_toy_outlined),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _uploadToGithub,
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Envoi...' : 'Envoyer à la Queue'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ÉCRAN DE RÉGLAGES ---

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _ownerController.dispose();
    _repoController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _tokenController.text = prefs.getString('gh_token') ?? '';
      _ownerController.text = prefs.getString('gh_owner') ?? '';
      _repoController.text = prefs.getString('gh_repo') ?? '';
      _pathController.text = prefs.getString('gh_path') ?? '00_Inbox/_drafts';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gh_token', _tokenController.text);
    await prefs.setString('gh_owner', _ownerController.text);
    await prefs.setString('gh_repo', _repoController.text);
    await prefs.setString('gh_path', _pathController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration sauvegardée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le token est stocké localement sur votre appareil.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'GitHub Token (PAT)',
              helperText: 'Droits requis: repo ou public_repo',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _repoController,
                  decoration: const InputDecoration(
                    labelText: 'Repository',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: 'Chemin Inbox',
              hintText: '00_Inbox/_drafts',
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}