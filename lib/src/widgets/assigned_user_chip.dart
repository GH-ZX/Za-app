import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';

class AssignedUserChip extends StatelessWidget {
  final String? userId;
  final double avatarRadius;

  const AssignedUserChip({super.key, required this.userId, this.avatarRadius = 12});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (userId == null || userId!.isEmpty) {
      return Chip(label: Text(l10n.unassigned), avatar: const Icon(Icons.person_outline));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Chip(label: Text(l10n.loading));
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return Chip(label: Text(l10n.unassigned));

        final displayName = (data['displayName'] as String?)?.trim();
        final email = (data['email'] as String?) ?? '';
        final title = (displayName?.isNotEmpty ?? false) ? displayName! : email;

        return Chip(
          avatar: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(title.isNotEmpty ? title[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          label: Text(title),
        );
      },
    );
  }
}
