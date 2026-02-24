class Formatters {
  /// Formats view count into a compact string (e.g., 1.2M, 10K).
  static String formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  /// Formats an ISO 8601 date string or DateTime into a relative time (e.g., '2 days ago').
  static String formatRelativeDate(dynamic dateInput) {
    if (dateInput == null) return 'Recent';
    
    DateTime date;
    if (dateInput is String) {
      if (dateInput.isEmpty) return 'Recent';
      try {
        date = DateTime.parse(dateInput);
      } catch (e) {
        return 'Recent';
      }
    } else if (dateInput is DateTime) {
      date = dateInput;
    } else {
      return 'Recent';
    }

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }
}
