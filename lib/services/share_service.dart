import 'package:share_plus/share_plus.dart';

/// Interface for sharing content via the platform share sheet.
abstract class ShareService {
  Future<void> share({required String title, required String url});
}

/// Default implementation delegating to [SharePlus.instance.share] from `share_plus`.
class ShareServiceImpl implements ShareService {
  const ShareServiceImpl();

  @override
  Future<void> share({required String title, required String url}) async {
    final cleanUrl = url.trim();
    final cleanTitle = title.trim();

    final String text;
    if (cleanTitle.isNotEmpty && cleanUrl.isNotEmpty) {
      text = '$cleanTitle\n$cleanUrl';
    } else if (cleanUrl.isNotEmpty) {
      text = cleanUrl;
    } else {
      text = cleanTitle;
    }

    if (text.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: cleanTitle.isNotEmpty ? cleanTitle : null,
        ),
      );
    }
  }
}
