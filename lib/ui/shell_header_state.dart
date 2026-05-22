class ShellHeaderData {
  const ShellHeaderData({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShellHeaderData &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(title, subtitle);
}
