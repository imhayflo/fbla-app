import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';

/// Handles sharing achievements and opening Instagram profiles/posts.
class SocialService {
  /// Opens an Instagram profile in the Instagram app or browser.
  Future<bool> openInstagramProfile(String username) async {
    final handle = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (handle.isEmpty) return false;
    // Try app deep link first, then web.
    final appUrl = Uri.parse('instagram://user?username=$handle');
    final webUrl = Uri.parse('https://instagram.com/$handle');
    if (await canLaunchUrl(appUrl)) {
      return launchUrl(appUrl, mode: LaunchMode.externalApplication);
    }
    return launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  /// Opens an Instagram post URL (e.g. https://instagram.com/p/xxx).
  Future<bool> openInstagramPostUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.toString().startsWith('http'))) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Share an achievement as text (user can then paste into Instagram or other apps).
  Future<void> shareAchievement(Achievement achievement, {String? memberName}) {
    final prefix = memberName != null && memberName.isNotEmpty
        ? '$memberName just earned: '
        : 'I just earned: ';
    final text =
        "$prefix${achievement.title} — ${achievement.subtitle} 🏆 #FBLA #FutureBusinessLeaders";
    return Share.share(
      text,
      subject: 'FBLA Achievement: ${achievement.title}',
    );
  }

  /// Share a generic "I'm in FBLA" or points/rank message.
  Future<void> shareProfile(Member member) {
    final buffer = StringBuffer(
        "I'm a member of FBLA — ${member.chapter.isNotEmpty ? member.chapter : 'Future Business Leaders of America'}!");
    if (member.points > 0) buffer.write(' ${member.points} points.');
    if (member.rank > 0) buffer.write(' Rank #${member.rank}.');
    buffer.write(' #FBLA #FutureBusinessLeaders');
    return Share.share(buffer.toString(), subject: 'FBLA Member');
  }
}
