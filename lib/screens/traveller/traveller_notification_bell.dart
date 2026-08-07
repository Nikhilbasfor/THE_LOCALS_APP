import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_colors.dart';

class TravellerNotificationBell extends StatelessWidget {
  final AuthRepository _authRepo = AuthRepository();
  final NotificationRepository _notifRepo = NotificationRepository();

  TravellerNotificationBell({super.key});

  void _showNotificationBottomSheet(BuildContext context, List<NotificationModel> notifications) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                  ),
                  if (notifications.any((n) => !n.read))
                    TextButton(
                      onPressed: () {
                        final unreadIds = notifications.where((n) => !n.read).map((n) => n.id).toList();
                        _notifRepo.markAllAsRead(unreadIds);
                      },
                      child: const Text('Mark all as read', style: TextStyle(color: AppColors.travellerForestDark, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const Divider(color: Colors.black12),
              if (notifications.isEmpty) ...[
                const SizedBox(height: 30),
                const Center(
                  child: Text('No notifications yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
                const SizedBox(height: 30),
              ] else
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.black12, height: 1),
                    itemBuilder: (context, idx) {
                      final n = notifications[idx];
                      return ListTile(
                        onTap: () {
                          if (!n.read) _notifRepo.markAsRead(n.id);
                        },
                        leading: CircleAvatar(
                          backgroundColor: n.read ? Colors.grey[200] : AppColors.travellerSoftMint,
                          child: Icon(
                            n.type == 'booking_status' ? Icons.confirmation_number : Icons.notifications,
                            color: AppColors.travellerForestDark,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        subtitle: Text(
                          n.message,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: !n.read
                            ? const CircleAvatar(radius: 4, backgroundColor: AppColors.brandRed)
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepo.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<NotificationModel>>(
      stream: _notifRepo.getUserNotificationsStream(user.uid),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        final hasUnread = list.any((n) => !n.read);

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => _showNotificationBottomSheet(context, list),
            ),
            if (hasUnread)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.brandRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
