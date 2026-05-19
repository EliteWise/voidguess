import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

class AchievementNotification extends StatelessWidget {
  final String title;
  final String achievementName;
  final String description;
  final VoidCallback? onDismiss;

  const AchievementNotification({
    super.key,
    required this.title,
    required this.achievementName,
    required this.description,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.hint.withValues(alpha: 0.18),
                blurRadius: 34,
                spreadRadius: -8,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ColoredBox(
              color: const Color(0xFF101012),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFF2A8),
                            AppTheme.hint,
                            Color(0xFFFF6D00),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.hint.withValues(alpha: 0.26),
                                    AppTheme.hint.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFF2A8,
                                  ).withValues(alpha: 0.55),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                                color: AppTheme.hint,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.inter(
                                      color: AppTheme.hint,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    achievementName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.inter(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ).copyWith(height: 1.25),
                                  ),
                                ],
                              ),
                            ),
                            if (onDismiss != null) ...[
                              const SizedBox(width: 8),
                              InkResponse(
                                onTap: onDismiss,
                                radius: 18,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                                    color: AppTheme.textSecondary,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
