import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_avatar.dart';
import 'room_metadata_patch.dart';
import 'room_management_page.dart';

class DesktopRoomDetailsPanel extends ConsumerWidget {
  final String roomId;
  final String roomName;
  final String? avatarUrl;
  final VoidCallback? onRoomLeft;
  final ValueChanged<RoomMetadataPatch>? onRoomDetailsChanged;

  const DesktopRoomDetailsPanel({
    super.key,
    required this.roomId,
    required this.roomName,
    this.avatarUrl,
    this.onRoomLeft,
    this.onRoomDetailsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final membersAsync = ref.watch(roomMembersProvider(roomId));

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Row(
              children: [
                AppAvatar(
                  fallback: roomName,
                  size: 40,
                  radius: AppRadii.content,
                  url: avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    roomName,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: '房间管理',
                  icon: Icon(
                    Icons.settings_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoomManagementPage(
                        roomId: roomId,
                        roomName: roomName,
                        avatarUrl: avatarUrl,
                        onRoomClosed: onRoomLeft,
                        onRoomDetailsChanged: onRoomDetailsChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colorScheme.surfaceContainerHighest, height: 1),
          Expanded(
            child: membersAsync.when(
              data: (members) => ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: members.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Text(
                        '成员 ${members.length}',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  final member = members[index - 1];
                  return ListTile(
                    dense: true,
                    leading: AppAvatar(
                      fallback: member.name,
                      size: 36,
                      radius: 18,
                      url: member.avatarUrl,
                    ),
                    title: Text(
                      member.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      member.id,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (_, _) => Center(
                child: Text(
                  '无法加载成员',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
