import 'package:fluttertoast/fluttertoast.dart';
import 'package:snapalyze/shared/app_theme.dart';

class Utilis {
  static showErrorMessage(String? message) => Fluttertoast.showToast(
    msg: message ?? 'Something error',
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 3,
    backgroundColor: AppTheme.red,
    textColor: AppTheme.white,
    fontSize: 16.0,
  );
  static showSuccessMessage(String message) => Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 3,
    backgroundColor: AppTheme.green,
    textColor: AppTheme.white,
    fontSize: 16.0,
  );
}
