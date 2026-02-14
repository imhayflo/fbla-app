import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';

class SocialService {
 

  static const String nationalInstagramUrl =
      'https://www.instagram.com/fbla_national/';

  static const String defaultStateInstagramUrl =
      'https://www.instagram.com/fbla_national/';

  static const Map<String, String> stateInstagramUrls = {
    'CA': 'https://www.instagram.com/californiafbla/',
    'TX': 'https://www.instagram.com/texasfbla/',
    'GA': 'https://www.instagram.com/gafbla/',
    // add more...
  };

 

  void openNationalInstagram() {
    _openUrl(nationalInstagramUrl);
  }

  void openStateInstagram(String? state) {
    final key = (state ?? '').trim().toUpperCase();
    final url = stateInstagramUrls[key] ?? defaultStateInstagramUrl;
    _openUrl(url);
  }

  void openChapterInstagramUrl(String? chapterUrl) {
    final url = (chapterUrl ?? '').trim();
    if (url.isEmpty) return;
    _openUrl(url);
  }

  void openInstagramPostUrl(String url) {
    _openUrl(url);
  }

  void _openUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;

    
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }



  void shareAchievement(Achievement achievement, {String? memberName}) {
    final prefix = memberName != null && memberName.isNotEmpty
        ? '$memberName just earned: '
        : 'I just earned: ';

    final text =
        "$prefix${achievement.title} — ${achievement.subtitle} 🏆 #FBLA #FutureBusinessLeaders";

    Share.share(
      text,
      subject: 'FBLA Achievement: ${achievement.title}',
    );
  }

  void shareProfile(Member member) {
    final buffer = StringBuffer(
      "I'm a member of FBLA — ${member.chapter.isNotEmpty ? member.chapter : 'Future Business Leaders of America'}!",
    );

    if (member.points > 0) buffer.write(' ${member.points} points.');
    if (member.rank > 0) buffer.write(' Rank #${member.rank}.');

    buffer.write(' #FBLA #FutureBusinessLeaders');

    // ignore: discarded_futures
    Share.share(buffer.toString(), subject: 'FBLA Member');
  }
}
