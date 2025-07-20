class Message {
  final String role;
  final String content;

  Message({required this.role, required this.content});

  Message copyWith({String? content}) {
    return Message(role: role, content: content ?? this.content);
  }

  @override
  String toString() {
    return 'Message(role: $role, content: $content)';
  }
}
