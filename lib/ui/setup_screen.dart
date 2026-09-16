import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/model/model_downloader.dart';
import '../core/setup/setup_status_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _downloading = false;
  bool _failed = false;
  String _currentModel = '';
  double _currentFraction = 0;
  final Set<String> _completedModels = {};

  Future<void> _startSetup() async {
    setState(() {
      _downloading = true;
      _failed = false;
      _completedModels.clear();
    });

    try {
      await ModelDownloader.downloadAll(
        onProgress: (progress) {
          setState(() {
            _currentModel = progress.modelName;
            _currentFraction = progress.fraction;
            if (progress.fraction >= 1.0) {
              _completedModels.add(progress.modelName);
            }
          });
        },
      );

      await SetupStatus.markComplete();
      ref.invalidate(setupStatusProvider);
    } catch (_) {
      setState(() {
        _downloading = false;
        _failed = true;
      });
    }
  }

  String get _statusLabel {
    if (_currentModel == 'whisper') return 'Downloading speech model';
    if (_currentModel == 'gemma') return 'Downloading language model';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, size: 56, color: Color(0xFF6C5CE7)),
              const SizedBox(height: 24),
              const Text(
                'Setting up Recall',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'One-time download of on-device AI models. After this, '
                'Recall never needs the internet again — everything runs '
                'locally on your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Requires Wi-Fi — roughly 2GB',
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
              const SizedBox(height: 40),
              if (_downloading) ...[
                Text(
                  _statusLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _currentFraction,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF17171F),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6C5CE7)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_currentFraction * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModelChip(
                      label: 'Speech',
                      done: _completedModels.contains('whisper'),
                    ),
                    const SizedBox(width: 12),
                    _ModelChip(
                      label: 'Language',
                      done: _completedModels.contains('gemma'),
                    ),
                  ],
                ),
              ] else if (_failed) ...[
                const Text(
                  'Download failed — check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
                ),
                const SizedBox(height: 20),
                _StartButton(label: 'Retry', onPressed: _startSetup),
              ] else ...[
                _StartButton(label: 'Start setup', onPressed: _startSetup),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  final String label;
  final bool done;

  const _ModelChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
            : const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? const Color(0xFF2ECC71) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: done ? const Color(0xFF2ECC71) : Colors.white30,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: done ? const Color(0xFF2ECC71) : Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _StartButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
