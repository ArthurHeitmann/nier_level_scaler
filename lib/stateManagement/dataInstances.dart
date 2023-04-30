
import '../utils/version.dart';
import 'stages/stages.dart';
import 'statusInfo.dart';

late final StatusInfo statusInfo;
late final Stages stages;
const Version currentVersion = Version(1, 0, 0);

void initDataInstances() {
  statusInfo = StatusInfo();
  stages = Stages();
}
