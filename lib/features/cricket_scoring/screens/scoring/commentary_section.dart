// lib\features\cricket_scoring\screens\scoring\commentary_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/commentary_event_model.dart';

class CommentarySection extends StatefulWidget {
  final List<CommentaryEventModel> commentary;
  final Function(String) onAddComment;

  const CommentarySection({
    super.key,
    required this.commentary,
    required this.onAddComment,
  });

  @override
  State<CommentarySection> createState() => _CommentarySectionState();
}

class _CommentarySectionState extends State<CommentarySection> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Commentary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Type your commentary here...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          widget.onAddComment(value.trim());
                          _commentController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (_commentController.text.trim().isNotEmpty) {
                          widget.onAddComment(_commentController.text.trim());
                          _commentController.clear();
                        }
                      },
                      icon: const Icon(Icons.send, color: Colors.white),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: widget.commentary.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.commentary.length,
            itemBuilder: (context, index) {
              final comment = widget.commentary[index];
              return _buildCommentaryItem(comment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No commentary yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the first comment to get started!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryItem(CommentaryEventModel comment) {
    final isHighlighted = _isHighlightedEvent(comment.eventType);
    final eventColor = _getEventColor(comment.eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isHighlighted ? eventColor.withOpacity(0.15) : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted ? eventColor : Colors.blue[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isHighlighted ? eventColor : Colors.blue).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${comment.overNumber}.${comment.ballNumber + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? eventColor : Colors.blue[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(comment.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHighlighted ? eventColor.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted ? eventColor.withOpacity(0.4) : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: isHighlighted ? eventColor : Colors.grey[800],
                            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (comment.isAutomatic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'AUTO',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (isHighlighted)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getEventIcon(comment.eventType),
                            size: 12,
                            color: eventColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getEventLabel(comment.eventType),
                            style: TextStyle(
                              color: eventColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isHighlightedEvent(String eventType) {
    return ['wicket', 'six', 'four', 'runs'].contains(eventType);
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'wicket':
        return Colors.red;
      case 'six':
        return Colors.purple;
      case 'four':
        return Colors.blue;
      case 'runs':
        return Colors.green;
      case 'dot':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'wicket':
        return Icons.sports_cricket;
      case 'six':
        return Icons.trending_up;
      case 'four':
        return Icons.trending_up;
      case 'runs':
        return Icons.sports_baseball;
      case 'dot':
        return Icons.circle;
      default:
        return Icons.comment;
    }
  }

  String _getEventLabel(String eventType) {
    switch (eventType) {
      case 'wicket':
        return 'WICKET';
      case 'six':
        return 'SIX';
      case 'four':
        return 'FOUR';
      case 'runs':
        return 'RUNS';
      case 'dot':
        return 'DOT';
      default:
        return 'COMMENT';
    }
  }
}