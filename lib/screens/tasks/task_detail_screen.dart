import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import 'task_store.dart';

const Color _background = Color(0xFFF7F7FB);
const Color _textPrimary = Color(0xFF282638);
const Color _textSecondary = Color(0xFF858397);
const Color _purple = Color(0xFF867CB3);
const Color _green = Color(0xFF439751);
const Color _pink = Color(0xFFF472B6);

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskModel task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskStore _store = TaskStore.instance;
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _syncTask();
  }

  void _syncTask() {
    for (final task in _store.tasks) {
      if (task['id']?.toString() == widget.task.id) {
        _task = TaskModel.fromJson(task);
        return;
      }
    }
  }

  Color get _statusColor {
    switch (_task.status) {
      case 'Hoàn thành':
        return _green;
      case 'Đang làm':
        return const Color(0xFF4285F4);
      case 'Chờ duyệt':
      case 'Cần bạn duyệt':
        return const Color(0xFFDB9B18);
      case 'Cần sửa':
        return _pink;
      default:
        return _textSecondary;
    }
  }

  Color get _priorityColor {
    switch (_task.priority) {
      case 'Cao':
        return const Color(0xFFB94B54);
      case 'Thấp':
        return _green;
      default:
        return const Color(0xFFDB9B18);
    }
  }

  String get _projectName {
    final project = _store.projectById(_task.projectId);
    return project?['name']?.toString() ?? 'Dự án';
  }

  Future<void> _startTask() async {
    try {
      _store.startTask(_task.id);
      _refreshTask();
      _showMessage('Đã chuyển công việc sang Đang làm.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _submitTask() async {
    final controller = TextEditingController(text: _task.outputLink);
    final outputLink = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gửi kết quả công việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_task.title),
            if (_task.outputType != 'none') ...[
              const SizedBox(height: 12),
              Text(
                _task.outputRequired
                    ? 'Công việc này yêu cầu đường dẫn đầu ra.'
                    : 'Bạn có thể bổ sung đường dẫn kết quả.',
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Đường dẫn kết quả',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final link = controller.text.trim();
              if (_task.outputType != 'none' &&
                  _task.outputRequired &&
                  link.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đường dẫn kết quả.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, link);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (outputLink == null) return;
    try {
      _store.submitTask(_task.id, outputLink: outputLink);
      _refreshTask();
      _showMessage(
        _store.roleInProject(_task.projectId) == 'Leader'
            ? 'Đã hoàn thành công việc.'
            : 'Đã gửi công việc cho Leader duyệt.',
      );
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _reviewTask({required bool approve}) async {
    if (approve) {
      try {
        _store.approveTask(_task.id);
        _refreshTask();
        _showMessage('Đã duyệt công việc.');
      } catch (error) {
        _showMessage(error.toString());
      }
      return;
    }

    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yêu cầu chỉnh sửa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Nhận xét',
            hintText: 'Nêu rõ phần cần chỉnh sửa',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (comment == null) return;
    try {
      _store.requestTaskChanges(_task.id, comment: comment);
      _refreshTask();
      _showMessage('Đã yêu cầu chỉnh sửa công việc.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  void _refreshTask() {
    if (!mounted) return;
    setState(_syncTask);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa có hạn';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: _textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    final canEdit = _store.canEditTask(_task.id);
    final canStart =
        canEdit && (_task.status == 'Cần làm' || _task.status == 'Cần sửa');
    final canSubmit =
        canEdit && (_task.status == 'Đang làm' || _task.status == 'Cần sửa');
    final canReview = _store.canReviewTask(_task.id);

    return [
      if (canStart)
        OutlinedButton.icon(
          onPressed: _startTask,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Bắt đầu'),
        ),
      if (canSubmit)
        FilledButton.icon(
          onPressed: _submitTask,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Gửi kết quả'),
        ),
      if (canReview) ...[
        FilledButton.icon(
          onPressed: () => _reviewTask(approve: true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Duyệt'),
          style: FilledButton.styleFrom(backgroundColor: _green),
        ),
        OutlinedButton.icon(
          onPressed: () => _reviewTask(approve: false),
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text('Yêu cầu sửa'),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text(
            _projectName,
            style: const TextStyle(
              color: _purple,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _task.title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(_task.status, _statusColor),
              _tag('Ưu tiên ${_task.priority}', _priorityColor),
            ],
          ),
          _section(
            title: 'Thông tin',
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.folder_outlined,
                  label: 'Dự án',
                  value: _projectName,
                ),
                _infoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Người nhận',
                  value: _store.memberName(_task.assigneeId),
                ),
                _infoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Hạn hoàn thành',
                  value: _formatDate(_task.dueDate),
                ),
                _infoRow(
                  icon: Icons.output_rounded,
                  label: 'Đầu ra',
                  value: _task.outputType == 'none'
                      ? 'Không yêu cầu'
                      : '${_task.outputType}${_task.outputRequired ? ' (bắt buộc)' : ''}',
                ),
              ],
            ),
          ),
          if (_task.outputLink.isNotEmpty)
            _section(
              title: 'Kết quả đã gửi',
              child: SelectableText(
                _task.outputLink,
                style: const TextStyle(
                  color: _purple,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          if (_task.reviewComment.isNotEmpty)
            _section(
              title: 'Nhận xét cần xử lý',
              child: Text(
                _task.reviewComment,
                style: const TextStyle(
                  color: Color(0xFFB94B83),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFECEBF2))),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
