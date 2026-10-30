import 'package:flutter/foundation.dart';

@immutable
class TaskModel {
  const TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.assigneeId,
    this.status = 'Cần làm',
    this.priority = 'Trung bình',
    this.dueDate,
    this.outputType = 'none',
    this.outputRequired = false,
    this.outputLink = '',
    this.reviewComment = '',
  });

  final String id;
  final String projectId;
  final String title;
  final String assigneeId;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String outputType;
  final bool outputRequired;
  final String outputLink;
  final String reviewComment;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: _text(json['id'] ?? json['_id']),
    projectId: _text(json['projectId']),
    title: _text(json['title'], 'Công việc chưa đặt tên'),
    assigneeId: _text(json['assigneeId']),
    status: _text(json['status'], 'Cần làm'),
    priority: _text(json['priority'], 'Trung bình'),
    dueDate: _dateTime(json['dueDate']),
    outputType: _text(json['outputType'], 'none'),
    outputRequired: json['outputRequired'] == true,
    outputLink: _text(json['outputLink']),
    reviewComment: _text(json['reviewComment']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'assigneeId': assigneeId,
    'status': status,
    'priority': priority,
    'dueDate': dueDate?.toIso8601String(),
    'outputType': outputType,
    'outputRequired': outputRequired,
    'outputLink': outputLink,
    'reviewComment': reviewComment,
  };
}

String _text(dynamic value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;

DateTime? _dateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
