import 'package:flutter/material.dart';

import 'deployed_backend_status.dart';

/// Thin top strip on Edge/web only — never expands to full screen.
class DeployedBackendBanner extends StatelessWidget {
  const DeployedBackendBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DeployedBackendStatus.showOnWeb) {
      return const SizedBox.shrink();
    }

    final live = DeployedBackendStatus.isDeployedMode;
    final bg = live ? const Color(0xFF065F46) : const Color(0xFF92400E);
    const fg = Colors.white;

    return ColoredBox(
      color: bg,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  live ? Icons.cloud_done : Icons.computer,
                  color: fg,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live
                            ? 'Running on DEPLOYED servers'
                            : 'Running on LOCAL PC servers',
                        style: const TextStyle(
                          color: fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Size: ${_shortHost(DeployedBackendStatus.sizeApi)} · '
                        '3D: ${_shortHost(DeployedBackendStatus.mediaCdn)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: fg.withValues(alpha: 0.9),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _shortHost(String url) {
    try {
      final u = Uri.parse(url);
      return u.host.isNotEmpty ? u.host : url;
    } catch (_) {
      return url;
    }
  }

  static void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DeployedBackendStatus.modeLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...DeployedBackendStatus.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText(
                  line,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DeployedBackendStatus.isDeployedMode
                  ? 'Phone APK uses the same deployed links (no localhost).'
                  : 'Restart with: .\\RUN-EDGE-MARKETPLACE.ps1 (no -LocalSizeApi)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
