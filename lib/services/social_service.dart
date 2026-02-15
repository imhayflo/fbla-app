import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';

class SocialService {
  void openUrl(String? url) {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void openInstagramProfile({String? url, String? handle}) {
    final u = (url ?? '').trim();
    if (u.isNotEmpty) {
      openUrl(u);
      return;
    }

    final h = (handle ?? '').trim().replaceFirst(RegExp(r'^@'), '');
    if (h.isEmpty) return;
    openUrl('https://www.instagram.com/$h/');
  }

  void openLinkedInProfile({String? url, String? handle}) {
    final u = (url ?? '').trim();
    if (u.isNotEmpty) {
      openUrl(u);
      return;
    }

    final h = (handle ?? '').trim().replaceFirst(RegExp(r'^@'), '');
    if (h.isEmpty) return;
    openUrl('https://www.linkedin.com/company/$h/');
  }

  void openInstagramPostUrl(String url) {
    openUrl(url);
  }

  void shareAchievement(Achievement achievement, {String? memberName}) {
    final prefix = memberName != null && memberName.isNotEmpty
        ? '$memberName just earned: '
        : 'I just earned: ';

    final text =
        "$prefix${achievement.title} — ${achievement.subtitle} 🏆 #FBLA #FutureBusinessLeaders";

    Share.share(text, subject: 'FBLA Achievement: ${achievement.title}');
  }

  void shareProfile(Member member) {
    final buffer = StringBuffer(
        "I'm a member of FBLA — ${member.chapter.isNotEmpty ? member.chapter : 'Future Business Leaders of America'}!");

    if (member.points > 0) buffer.write(' ${member.points} points.');
    if (member.rank > 0) buffer.write(' Rank #${member.rank}.');

    buffer.write(' #FBLA #FutureBusinessLeaders');

    Share.share(buffer.toString(), subject: 'FBLA Member');
  }
}
