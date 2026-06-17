import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferJobUpdateLookupCommand {
  const TransferJobUpdateLookupCommand._();

  static TransferJob? updateById({
    required List<TransferJob> jobs,
    required String jobId,
    required TransferJob Function(TransferJob currentJob) update,
  }) {
    for (final job in jobs) {
      if (job.id == jobId) {
        return update(job);
      }
    }
    return null;
  }
}
