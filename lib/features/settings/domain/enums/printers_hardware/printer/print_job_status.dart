/// Status of a print job.
enum PrintJobStatus {
  pending,
  preparing,
  printing,
  completed,
  cancelled,
  failed;

  String get label {
    switch (this) {
      case PrintJobStatus.pending:
        return 'Pending';
      case PrintJobStatus.preparing:
        return 'Preparing…';
      case PrintJobStatus.printing:
        return 'Printing…';
      case PrintJobStatus.completed:
        return 'Completed';
      case PrintJobStatus.cancelled:
        return 'Cancelled';
      case PrintJobStatus.failed:
        return 'Failed';
    }
  }

  bool get isFinished => this == PrintJobStatus.completed || this == PrintJobStatus.cancelled || this == PrintJobStatus.failed;
}