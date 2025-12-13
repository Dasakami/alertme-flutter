import 'package:flutter/material.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/models/emergency_contact.dart';

class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.deepBlue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: context.textStyles.bodyLarge?.semiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    contact.phoneNumber,
                    style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
                  ),
                  if (contact.email != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contact.email!,
                      style: context.textStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.sosRed),
            ),
          ],
        ),
      ),
    );
  }
}