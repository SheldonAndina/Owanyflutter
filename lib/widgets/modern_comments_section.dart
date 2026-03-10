import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/owany_theme.dart';
import '../generated_l10n/app_localizations.dart';

/// Comment Item DTO
class CommentItemWidget {
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;
  final bool isInternal;
  final List<String> attachmentUrls;
  final String? avatarUrl;

  const CommentItemWidget({
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.isInternal = false,
    this.attachmentUrls = const [],
    this.avatarUrl,
  });
}

/// Modern Comments Section Widget
class ModernCommentsSection extends StatefulWidget {
  final List<CommentItemWidget> comments;
  final TextEditingController messageController;
  final bool isInternal;
  final Function(bool) onInternalToggle;
  final VoidCallback onAddComment;
  final VoidCallback? onAddAttachment;
  final bool isLoading;
  final bool canAddInternal;
  final double maxWidth;

  const ModernCommentsSection({
    required this.comments,
    required this.messageController,
    required this.isInternal,
    required this.onInternalToggle,
    required this.onAddComment,
    this.onAddAttachment,
    required this.isLoading,
    this.canAddInternal = false,
    this.maxWidth = double.infinity,
    super.key,
  });

  @override
  State<ModernCommentsSection> createState() => _ModernCommentsSectionState();
}

class _ModernCommentsSectionState extends State<ModernCommentsSection> {
  final List<String> _selectedAttachments = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = OwanyTheme.isDark(context);

    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: OwanyTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comentários',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.comments.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: OwanyTheme.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comments list
          if (widget.comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: OwanyTheme.textMutedColor(context)
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum comentário ainda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: OwanyTheme.textMutedColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.comments.length,
              itemBuilder: (context, index) =>
                  _buildCommentItem(context, widget.comments[index]),
            ),

          const SizedBox(height: 24),

          // Compose comment section
          Container(
            decoration: BoxDecoration(
              color: dark ? OwanyTheme.darkSurface : OwanyTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: OwanyTheme.borderColor(context),
              ),
            ),
            child: Column(
              children: [
                // Text input
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: widget.messageController,
                    maxLines: 4,
                    minLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Escreva um comentário aqui...',
                      hintStyle: TextStyle(
                        color: OwanyTheme.textMutedColor(context)
                            .withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                ),

                // Attachments preview
                if (_selectedAttachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 8,
                      children: _selectedAttachments.map((file) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: OwanyTheme.primaryOrange
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: OwanyTheme.primaryOrange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attachment_rounded,
                                size: 14,
                                color: OwanyTheme.primaryOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                file.split('/').last,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: OwanyTheme.primaryOrange,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAttachments.remove(file);
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: OwanyTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Attachment button
                      if (widget.onAddAttachment != null)
                        Tooltip(
                          message: 'Anexar arquivo',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onAddAttachment,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.attachment_rounded,
                                  color: OwanyTheme.primaryOrange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Internal toggle
                      if (widget.canAddInternal)
                        Tooltip(
                          message:
                              'Comentário ${widget.isInternal ? 'interno' : 'público'}',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  widget.onInternalToggle(!widget.isInternal),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isInternal
                                        ? OwanyTheme.warning.withValues(
                                        alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: widget.isInternal
                                          ? OwanyTheme.warning
                                          : OwanyTheme.borderColor(context),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.isInternal
                                            ? Icons.lock_rounded
                                            : Icons.public_rounded,
                                        color: widget.isInternal
                                            ? OwanyTheme.warning
                                            : OwanyTheme.textMutedColor(
                                            context),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.isInternal
                                            ? 'Interno'
                                            : 'Público',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isInternal
                                              ? OwanyTheme.warning
                                              : OwanyTheme.textMutedColor(
                                              context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Send button
                      ElevatedButton.icon(
                        onPressed: widget.isLoading ? null : widget.onAddComment,
                        style: OwanyTheme.primaryButtonStyle(),
                        icon: widget.isLoading
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          widget.isLoading ? 'Enviando...' : 'Enviar',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommentItemWidget comment,
  ) {
    final dark = OwanyTheme.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: comment.isInternal
              ? OwanyTheme.warning.withValues(alpha: 0.06)
              : dark
              ? OwanyTheme.darkSurfaceElevated
              : OwanyTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: comment.isInternal
                ? OwanyTheme.warning.withValues(alpha: 0.2)
                : OwanyTheme.borderColor(context),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author and timestamp
            Row(
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      comment.userName.isEmpty
                          ? '?'
                          : comment.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.primaryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.isInternal)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: OwanyTheme.warning
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 10,
                                    color: OwanyTheme.warning,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Interno',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: OwanyTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: OwanyTheme.textMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Message
            Text(
              comment.message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: OwanyTheme.textPrimary(context),
                height: 1.5,
              ),
            ),

            // Attachments
            if (comment.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: comment.attachmentUrls.map((url) {
                  final fileName = url.split('/').last;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attachment_rounded,
                          size: 14,
                          color: OwanyTheme.primaryOrange,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: OwanyTheme.primaryOrange,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
