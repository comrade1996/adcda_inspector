import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:form_builder_validators/localization/l10n.dart';

/// Custom delegate for FormBuilderLocalizations that adds support for Urdu
class UrduFormBuilderLocalizations extends FormBuilderLocalizationsImpl {
  const UrduFormBuilderLocalizations();
  
  static const LocalizationsDelegate<FormBuilderLocalizations> delegate =
      _UrduFormBuilderLocalizationsDelegate();

  @override
  String get requiredErrorText => 'یہ فیلڈ درکار ہے';

  @override
  String equalErrorText(Object value) => 'یہ قیمت $value کے برابر ہونی چاہیے';

  @override
  String notEqualErrorText(Object value) => 'یہ قیمت $value کے برابر نہیں ہونی چاہیے';

  @override
  String minErrorText(Object min) => 'قیمت $min سے زیادہ یا برابر ہونی چاہیے';

  @override
  String minLengthErrorText(Object minLength) => 'متن کم از کم $minLength حروف لمبا ہونا چاہیے';

  @override
  String maxErrorText(Object max) => 'قیمت $max سے کم یا برابر ہونی چاہیے';

  @override
  String maxLengthErrorText(Object maxLength) => 'متن $maxLength حروف سے زیادہ لمبا نہیں ہونا چاہیے';

  @override
  String get emailErrorText => 'ایک درست ای میل ایڈریس درج کریں';

  @override
  String get urlErrorText => 'ایک درست URL درج کریں';

  @override
  String get matchErrorText => 'یہ قیمت پیٹرن سے مطابقت نہیں رکھتی';

  @override
  String get numericErrorText => 'یہ فیلڈ عددی ہونا چاہیے';

  @override
  String get integerErrorText => 'یہ فیلڈ ایک عدد صحیح ہونا چاہیے';

  @override
  String get creditCardErrorText => 'ایک درست کریڈٹ کارڈ نمبر درج کریں';

  @override
  String get ipErrorText => 'ایک درست IP ایڈریس درج کریں';

  @override
  String get dateStringErrorText => 'ایک درست تاریخ درج کریں';
}

/// Custom delegate for FormBuilderLocalizations that adds support for Urdu
class _UrduFormBuilderLocalizationsDelegate
    extends LocalizationsDelegate<FormBuilderLocalizations> {
  const _UrduFormBuilderLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'ur';
  }

  @override
  Future<FormBuilderLocalizations> load(Locale locale) async {
    return const UrduFormBuilderLocalizations();
  }

  @override
  bool shouldReload(_UrduFormBuilderLocalizationsDelegate old) => false;
}
