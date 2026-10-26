import 'package:flutter/material.dart';

import '../app_copy.dart';

/// A launcher describes an existing session command, never owns game state.
class BridgePracticeAction {
  const BridgePracticeAction(
    this.title,
    this.description,
    this.icon,
    this.control,
  );
  final String title;
  final String description;
  final IconData icon;
  final Widget control;
}

class BridgePracticeHub extends StatelessWidget {
  const BridgePracticeHub({
    super.key,
    required this.copy,
    required this.settings,
    required this.actions,
    required this.started,
  });
  final AppCopy copy;
  final Widget settings;
  final List<BridgePracticeAction> actions;
  final bool started;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        key: const Key('practice_hub'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF123F39), Color(0xFF22645A)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.style_rounded, color: Color(0xFFE3C78B), size: 32),
            const SizedBox(height: 12),
            Text(
              copy.t(started ? 'hubOtherPractice' : 'hubTitle'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.t('hubSubtitle'),
              style: const TextStyle(color: Color(0xFFE1EEE7)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      settings,
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960
              ? 3
              : constraints.maxWidth >= 640
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final action in actions)
                SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            action.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            action.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(action.description),
                          const SizedBox(height: 16),
                          action.control,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
