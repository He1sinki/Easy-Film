import 'package:easy_film/app/theme/app_theme.dart';
import 'package:easy_film/features/settings/domain/settings_form_model.dart';
import 'package:easy_film/features/settings/presentation/settings_controller.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.controller});

  final SettingsController? controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  final _qbUrl = TextEditingController();
  final _qbUser = TextEditingController();
  final _qbPass = TextEditingController();
  final _fbUrl = TextEditingController();
  final _fbUser = TextEditingController();
  final _fbPass = TextEditingController();
  final _target = TextEditingController();
  final _c411Url = TextEditingController();
  final _c411ApiKey = TextEditingController();

  bool _showQbPass = false;
  bool _showFbPass = false;
  bool _showC411ApiKey = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsController();
    _controller.addListener(_syncControllers);
    _controller.load();
  }

  void _syncControllers() {
    final model = _controller.model;
    if (_qbUrl.text != model.qbittorrentUrl) _qbUrl.text = model.qbittorrentUrl;
    if (_qbUser.text != model.qbittorrentUsername)
      _qbUser.text = model.qbittorrentUsername;
    if (_qbPass.text != model.qbittorrentPassword)
      _qbPass.text = model.qbittorrentPassword;
    if (_fbUrl.text != model.filebrowserUrl) _fbUrl.text = model.filebrowserUrl;
    if (_fbUser.text != model.filebrowserUsername)
      _fbUser.text = model.filebrowserUsername;
    if (_fbPass.text != model.filebrowserPassword)
      _fbPass.text = model.filebrowserPassword;
    if (_target.text != model.targetFolder) _target.text = model.targetFolder;
    if (_c411Url.text != model.c411ApiBaseUrl)
      _c411Url.text = model.c411ApiBaseUrl;
    if (_c411ApiKey.text != model.c411ApiKey)
      _c411ApiKey.text = model.c411ApiKey;

    // Show snackbar for success/error
    if (_controller.success != null && mounted) {
      _showSnackBar(_controller.success!, isError: false);
      _controller.success = null;
    }
    if (_controller.error != null && mounted) {
      _showSnackBar(_controller.error!, isError: true);
      _controller.error = null;
    }

    setState(() {});
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color:
                  isError ? const Color(0xFFEF5350) : const Color(0xFF81C784),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_syncControllers);
    _controller.dispose();
    _qbUrl.dispose();
    _qbUser.dispose();
    _qbPass.dispose();
    _fbUrl.dispose();
    _fbUser.dispose();
    _fbPass.dispose();
    _target.dispose();
    _c411Url.dispose();
    _c411ApiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── qBittorrent & FileBrowser ──
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildQbSection()),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _buildFbSection()),
                    ],
                  )
                else ...[
                  _buildQbSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFbSection(),
                ],
                const SizedBox(height: AppSpacing.lg),

                // ── c411 section ──
                _buildC411Section(),
                const SizedBox(height: AppSpacing.lg),

                // ── Target folder section ──
                _SettingsSection(
                  icon: Icons.movie_rounded,
                  iconColor: const Color(0xFF4DD0E1),
                  title: 'Dossier média',
                  subtitle: 'Chemin racine utilisé pour explorer les vidéos.',
                  children: [
                    TextField(
                      controller: _target,
                      decoration: const InputDecoration(
                        labelText: 'Dossier cible',
                        hintText: '/Films',
                        prefixIcon: Icon(Icons.folder_open_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Save button ──
                FilledButton(
                  onPressed: _controller.isLoading ? null : _save,
                  child: _controller.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sauvegarder'),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Version ──
                Center(
                  child: Text(
                    'Easy Film v0.1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQbSection() {
    return _SettingsSection(
      icon: Icons.downloading_rounded,
      iconColor: const Color(0xFF6C63FF),
      title: 'qBittorrent',
      subtitle: 'Utilisé pour ajouter, suivre et contrôler les torrents.',
      children: [
        TextField(
          controller: _qbUrl,
          decoration: const InputDecoration(
            labelText: 'URL / IP',
            hintText: 'http://localhost:8081',
            prefixIcon: Icon(Icons.link_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _qbUser,
          decoration: const InputDecoration(
            labelText: 'Identifiant',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _qbPass,
          obscureText: !_showQbPass,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                  _showQbPass
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20),
              onPressed: () => setState(() => _showQbPass = !_showQbPass),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _controller.isTestingQb
                ? null
                : () {
                    _syncModelFromFields();
                    _controller.testQbConnection();
                  },
            icon: _controller.isTestingQb
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering_rounded, size: 18),
            label: const Text('Tester'),
          ),
        ),
      ],
    );
  }

  Widget _buildFbSection() {
    return _SettingsSection(
      icon: Icons.folder_rounded,
      iconColor: const Color(0xFFFFA726),
      title: 'FileBrowser',
      subtitle:
          'Permet de naviguer dans les fichiers et lancer les téléchargements.',
      children: [
        TextField(
          controller: _fbUrl,
          decoration: const InputDecoration(
            labelText: 'URL (HTTPS ou HTTP local)',
            hintText: 'http://localhost:8080',
            prefixIcon: Icon(Icons.link_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _fbUser,
          decoration: const InputDecoration(
            labelText: 'Identifiant',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _fbPass,
          obscureText: !_showFbPass,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                  _showFbPass
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20),
              onPressed: () => setState(() => _showFbPass = !_showFbPass),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _controller.isTestingFb
                ? null
                : () {
                    _syncModelFromFields();
                    _controller.testFbConnection();
                  },
            icon: _controller.isTestingFb
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering_rounded, size: 18),
            label: const Text('Tester'),
          ),
        ),
      ],
    );
  }

  Widget _buildC411Section() {
    return _SettingsSection(
      icon: Icons.hub_rounded,
      iconColor: const Color(0xFFFF6B6B),
      title: 'c411',
      subtitle: 'Source des resultats torrents (API REST).',
      children: [
        TextField(
          controller: _c411Url,
          decoration: const InputDecoration(
            labelText: 'URL API',
            hintText: 'https://c411.org',
            prefixIcon: Icon(Icons.link_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _c411ApiKey,
          obscureText: !_showC411ApiKey,
          decoration: InputDecoration(
            labelText: 'API key (Bearer token)',
            hintText: 'xxxx...',
            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showC411ApiKey
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _showC411ApiKey = !_showC411ApiKey),
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    _syncModelFromFields();
    _controller.save();
  }

  void _syncModelFromFields() {
    _controller.update(
      SettingsFormModel(
        qbittorrentUrl: _qbUrl.text.trim(),
        qbittorrentUsername: _qbUser.text.trim(),
        qbittorrentPassword: _qbPass.text,
        filebrowserUrl: _fbUrl.text.trim(),
        filebrowserUsername: _fbUser.text.trim(),
        filebrowserPassword: _fbPass.text,
        targetFolder: _target.text.trim(),
        c411ApiBaseUrl: _c411Url.text.trim(),
        c411ApiKey: _c411ApiKey.text.trim(),
      ),
    );
  }
}

// ── Settings section card ────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}
