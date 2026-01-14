import 'package:easy_localization/easy_localization.dart';

bool isEnglish() => tr('and') == 'and'; // Quick hack, find a better way

String lowerCaseIfEnglish(String str) => isEnglish() ? str.toLowerCase() : str;
