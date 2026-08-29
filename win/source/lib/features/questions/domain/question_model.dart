import 'package:notebook_app/features/groups/domain/group_model.dart';

class Question {
  final String id;
  final String question;
  final String? answer;
  final bool isAnswered;
  final String? groupId;
  final ItemVisibility visibility;
  final String? authorName;
  final bool isMine;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.question,
    this.answer,
    this.isAnswered = false,
    this.groupId,
    this.visibility = ItemVisibility.personal,
    this.authorName,
    this.isMine = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isShared => visibility == ItemVisibility.shared;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      isAnswered: json['isAnswered'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      visibility: visibilityFromString(json['visibility'] as String?),
      authorName: json['authorName'] as String?,
      isMine: json['isMine'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Question copyWith({
    String? question,
    String? answer,
    bool? isAnswered,
    ItemVisibility? visibility,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isAnswered: isAnswered ?? this.isAnswered,
      groupId: groupId,
      visibility: visibility ?? this.visibility,
      authorName: authorName,
      isMine: isMine,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
