import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';

enum TransferDataFrameRoute {
  dataStart,
  dataChunk,
  dataAck,
  dataNack,
  dataWindowUpdate,
  dataFinish,
  dataAbort,
}

extension TransferDataFrameRouteDirection on TransferDataFrameRoute {
  TransferDirection get expectedDirection {
    switch (this) {
      case TransferDataFrameRoute.dataStart:
      case TransferDataFrameRoute.dataChunk:
      case TransferDataFrameRoute.dataFinish:
      case TransferDataFrameRoute.dataAbort:
        return TransferDirection.incoming;
      case TransferDataFrameRoute.dataAck:
      case TransferDataFrameRoute.dataNack:
      case TransferDataFrameRoute.dataWindowUpdate:
        return TransferDirection.outgoing;
    }
  }
}

class TransferDataFrameDispatcher {
  const TransferDataFrameDispatcher();

  TransferDataFrameRoute routeFor(DataFrameType type) {
    switch (type) {
      case DataFrameType.dataStart:
        return TransferDataFrameRoute.dataStart;
      case DataFrameType.dataChunk:
        return TransferDataFrameRoute.dataChunk;
      case DataFrameType.dataAck:
        return TransferDataFrameRoute.dataAck;
      case DataFrameType.dataNack:
        return TransferDataFrameRoute.dataNack;
      case DataFrameType.dataWindowUpdate:
        return TransferDataFrameRoute.dataWindowUpdate;
      case DataFrameType.dataFinish:
        return TransferDataFrameRoute.dataFinish;
      case DataFrameType.dataAbort:
        return TransferDataFrameRoute.dataAbort;
    }
  }
}
