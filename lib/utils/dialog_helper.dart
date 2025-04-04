import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

class DialogHelper {
  static Future<void> showLocationPermissionDialog(BuildContext context) async {
    String title = 'الوصول إلى الموقع';
    String message = '';
    String instructions = '';

    if (Platform.isAndroid) {
      instructions = '''
1. افتح إعدادات الهاتف
2. ابحث عن "التطبيقات" أو "إدارة التطبيقات"
3. ابحث عن تطبيق ADCDA Inspector
4. انقر على "الأذونات"
5. ابحث عن "الموقع" وقم بتفعيله
6. أو يمكنك النقر على "فتح الإعدادات" أدناه للوصول المباشر

* إذا تم رفض الإذن بشكل دائم، فقد تحتاج إلى:
1. الذهاب إلى إعدادات > التطبيقات > ADCDA Inspector
2. الضغط على "تخزين ومسح البيانات"
3. الضغط على "مسح البيانات" أو "إعادة تعيين الأذونات"
4. إعادة تشغيل التطبيق وتفعيل إذن الموقع
''';
    } else if (Platform.isIOS) {
      instructions = '''
1. افتح إعدادات iOS
2. قم بالتمرير لأسفل وابحث عن تطبيق ADCDA Inspector
3. انقر على اسم التطبيق
4. ابحث عن "الموقع" وقم بتغييره إلى "أثناء استخدام التطبيق" أو "دائمًا"
5. أو يمكنك النقر على "فتح الإعدادات" أدناه للوصول المباشر

* إذا لم يظهر خيار الموقع:
1. اذهب إلى الإعدادات > الخصوصية > خدمات الموقع
2. قم بتفعيل خدمات الموقع بشكل عام
3. ثم ابحث عن ADCDA Inspector وفعّل إذن الموقع
''';
    } else {
      instructions = '''
1. افتح إعدادات جهازك
2. ابحث عن إعدادات التطبيقات أو الخصوصية
3. ابحث عن تطبيق ADCDA Inspector
4. قم بتفعيل إذن الوصول إلى الموقع
''';
    }
      
    message = '''
يتطلب تطبيق ADCDA Inspector الوصول إلى موقعك الحالي لإتمام الاستبيان.

لا يمكن إكمال الاستبيان بدون السماح بالوصول إلى موقعك.

كيفية تفعيل إذن الموقع:
$instructions
''';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openAppSettings();
            },
            child: Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
