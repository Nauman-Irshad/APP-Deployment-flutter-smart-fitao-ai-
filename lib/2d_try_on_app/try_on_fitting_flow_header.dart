import 'package:flutter/material.dart';

import 'try_on_theme.dart';

/// Step 3 of: Live measurement → Size prediction → **2D Try On**.
class TryOnFittingFlowHeader extends StatelessWidget {
  const TryOnFittingFlowHeader({
    super.key,
    required this.onFindTailor,
    this.landmarkCount = 0,
  });

  final VoidCallback onFindTailor;
  final int landmarkCount;

  static const _steps = [
    'Live measurement',
    'Size prediction',
    '2D Try On',
  ];

  @override
  Widget build(BuildContext context) {
    const activeIndex = 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf0fdf4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '2D Shalwar Kameez Try On',
            textAlign: TextAlign.center,
            style: TryOnTheme.heading(size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Step 3 · Upload your photo and try on kurta',
            textAlign: TextAlign.center,
            style: TryOnTheme.body(size: 13, color: TryOnTheme.brownMuted),
          ),
          if (landmarkCount >= 30) ...[
            const SizedBox(height: 4),
            Text(
              'Photo loaded · $landmarkCount landmarks',
              textAlign: TextAlign.center,
              style: TryOnTheme.body(size: 12, weight: FontWeight.w600,
                  color: const Color(0xFF059669)),
            ),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_steps.length, (i) {
                final done = i < activeIndex;
                final active = i == activeIndex;
                return Padding(
                  padding: EdgeInsets.only(right: i < _steps.length - 1 ? 8 : 0),
                  child: _FlowChip(
                    label: _steps[i],
                    done: done,
                    active: active,
                    stepNum: i + 1,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Material(
            elevation: 3,
            shadowColor: const Color(0x40059669),
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF059669),
            child: InkWell(
              onTap: onFindTailor,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_search, color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Text(
                      'Find tailor',
                      style: TryOnTheme.body(
                        size: 18,
                        weight: FontWeight.w800,
                        color: TryOnTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({
    required this.label,
    required this.done,
    required this.active,
    required this.stepNum,
  });

  final String label;
  final bool done;
  final bool active;
  final int stepNum;

  @override
  Widget build(BuildContext context) {
    final bg = done || active ? const Color(0xFF059669) : Colors.grey.shade200;
    final fg = done || active ? Colors.white : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF047857) : bg,
        borderRadius: BorderRadius.circular(999),
        border: active ? Border.all(color: const Color(0xFF10b981), width: 2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: done || active ? Colors.white24 : Colors.grey.shade300,
            child: done
                ? Icon(Icons.check, size: 12, color: fg)
                : Text('$stepNum', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
