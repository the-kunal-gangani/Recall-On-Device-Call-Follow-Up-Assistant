import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

class SqlCipherInit {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;

    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    _initialized = true;
  }
}
