import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferJobListUpsertCommand {
  const TransferJobListUpsertCommand._();

  static List<TransferJob> upsert({
    required List<TransferJob> currentJobs,
    required TransferJob nextJob,
  }) {
    final jobs = [
      for (final job in currentJobs)
        if (job.id != nextJob.id) job,
      nextJob,
    ]..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return jobs;
  }
}
