import 'package:intl/intl.dart';

/// Date / heure courtes en français pour affichage UI.
String formatDateFr(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
  } catch (_) {
    return iso;
  }
}

String formatDateTimeFr(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy · HH:mm', 'fr_FR').format(d);
  } catch (_) {
    return iso;
  }
}

/// "Il y a 5 minutes / 2 heures / 3 jours"
String formatRelativeFr(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return formatDateFr(iso);
  } catch (_) {
    return iso;
  }
}
