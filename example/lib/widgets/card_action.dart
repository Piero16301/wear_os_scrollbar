import 'package:flutter/material.dart';

class CardAction extends StatelessWidget {
  const CardAction({
    required this.content,
    this.title,
    this.innerPadding = const EdgeInsets.all(7),
    this.onPressed,
    super.key,
  });

  final Widget content;
  final String? title;
  final EdgeInsetsGeometry innerPadding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var cardContent = content;

    if (title != null) {
      cardContent = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(
            title!,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontVariations: <FontVariation>[
                ...(Theme.of(context).textTheme.bodyMedium?.fontVariations ??
                        const <FontVariation>[])
                    .where((v) => v.axis != 'wght'),
                const FontVariation('wght', 700),
              ],
            ),
          ),
          content,
        ],
      );
    }

    Widget result = Padding(
      padding: innerPadding,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
          fontVariations: <FontVariation>[
            ...(Theme.of(context).textTheme.bodyMedium?.fontVariations ??
                    const <FontVariation>[])
                .where((v) => v.axis != 'wght'),
            const FontVariation('wght', 700),
          ],
        ),
        child: cardContent,
      ),
    );

    if (onPressed != null) {
      result = InkWell(onTap: onPressed, child: result);
    }

    return Card(
      clipBehavior: onPressed != null ? Clip.antiAlias : null,
      child: result,
    );
  }
}
