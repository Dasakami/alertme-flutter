import 'package:flutter/material.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/models/emergency_contact.dart';

class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onDelete,
    this.onSetPrimary,
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
                color: contact.isPrimary
                    ? AppColors.softCyan.withValues(alpha: 0.2)
                    : AppColors.deepBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                contact.isPrimary ? Icons.star : Icons.person,
                color: contact.isPrimary ? AppColors.softCyan : AppColors.deepBlue,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: context.textStyles.bodyLarge?.semiBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Основной',
                            style: context.textStyles.labelSmall?.withColor(
                              AppColors.softCyan,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    contact.phoneNumber,
                    style: context.textStyles.bodyMedium?.withColor(
                      AppColors.textSecondary,
                    ),
                  ),
                  if (contact.relation != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contact.relation!,
                      style: context.textStyles.bodySmall,
                    ),
                  ],
if (contact.telegramUsername != null) ...[
  const SizedBox(height: AppSpacing.xs),
  Row(
    children: [
      const Icon(Icons.telegram, size: 14, color: AppColors.softCyan),
      const SizedBox(width: 4),
      Text(
        '@${contact.telegramUsername}',
        style: context.textStyles.bodySmall?.withColor(AppColors.softCyan),
      ),
    ],
  ),
],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'primary' && onSetPrimary != null) {
                  onSetPrimary!();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                if (!contact.isPrimary && onSetPrimary != null)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Сделать основным'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: AppColors.sosRed),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: AppColors.sosRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}