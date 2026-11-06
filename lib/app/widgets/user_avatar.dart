import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../theme/app_colors.dart';
import 'people.dart';

/// A rep's initials in a colour that stays the same on every screen.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, required this.userId, this.size = 28});

  final String userId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(salesDatasetProvider);
    final palette = context.pulse;
    final user = dataset.usersById[userId];
    final index = dataset.users.indexWhere((u) => u.id == userId);
    return InitialsAvatar(
      name: user?.displayName ?? '?',
      size: size,
      color: palette
          .avatarColors[(index < 0 ? 0 : index) % palette.avatarColors.length],
    );
  }
}
