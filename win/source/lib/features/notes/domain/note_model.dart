import 'package:notebook_app/features/groups/domain/group_model.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final bool isFavorite;
  final String? groupId;
  final ItemVisibility visibility;
  final String? authorName;
  final bool isMine;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.isFavorite = false,
    this.groupId,
    this.visibility = ItemVisibility.personal,
    this.authorName,
    this.isMine = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isShared => visibility == ItemVisibility.shared;

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      visibility: visibilityFromString(json['visibility'] as String?),
      authorName: json['authorName'] as String?,
      isMine: json['isMine'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Note copyWith({
    String? title,
    String? content,
    bool? isFavorite,
    ItemVisibility? visibility,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      groupId: groupId,
      visibility: visibility ?? this.visibility,
      authorName: authorName,
      isMine: isMine,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
