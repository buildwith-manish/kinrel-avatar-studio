import 'package:flutter/material.dart';

import '../models/avatar_layer.dart';
import '../theme/avatar_studio_theme.dart';

/// A single horizontal scrollable picker row for one [AvatarLayer].
///
/// Shows the layer label on the left, and a horizontally scrolling list
/// of options on the right. Tapping an option calls [onSelected] with
/// the option ID. The currently-selected option is highlighted.
///
/// A "None" chip is shown at the start of the list for nullable layers
/// (everything except [AvatarLayer.baseBody] and [AvatarLayer.clothing]).
class LayerOptionPicker extends StatelessWidget {
  const LayerOptionPicker({
    super.key,
    required this.layer,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.allowNone = true,
  });

  final AvatarLayer layer;
  final List<LayerOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  /// Whether to show a "None" chip at the start. Should be false for
  /// required layers (base body, clothing).
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                layer.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AvatarStudioTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (layer.isV1Skipped)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AvatarStudioTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'V2',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AvatarStudioTheme.textSecondary,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${options.length} option${options.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AvatarStudioTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: options.length + (allowNone ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (allowNone && index == 0) {
                  return _OptionChip(
                    label: 'None',
                    selected: selectedId == null,
                    onTap: () => onSelected(null),
                    color: AvatarStudioTheme.surfaceMuted,
                  );
                }
                final option = options[allowNone ? index - 1 : index];
                return _OptionChip(
                  label: option.label,
                  sublabel: option.sublabel,
                  selected: selectedId == option.id,
                  onTap: () => onSelected(option.id),
                  color: option.swatch,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
    this.color,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AvatarStudioTheme.selectedSoft
          : AvatarStudioTheme.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AvatarStudioTheme.selected
                  : AvatarStudioTheme.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (color != null)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AvatarStudioTheme.selected
                      : AvatarStudioTheme.textPrimary,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AvatarStudioTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable option for a layer.
class LayerOption {
  const LayerOption({
    required this.id,
    required this.label,
    this.sublabel,
    this.swatch,
  });

  final String id;
  final String label;
  final String? sublabel;
  final Color? swatch;
}
