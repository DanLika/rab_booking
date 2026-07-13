/// Croatian noun agreement for a count: one / paucal (2–4) / many (5+), with
/// the teens (11–14 take "many") and higher-decade rules (21 takes "one",
/// 22–24 take "paucal", …). Used so booking cards read "1 gost", "2 gosta",
/// "5 gostiju" — not the old hardcoded "1 gosta".
String hrPlural(int n, String one, String few, String many) {
  final int m10 = n % 10;
  final int m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

/// "gost" (1) / "gosta" (2–4) / "gostiju" (5+).
String guestWord(int n) => hrPlural(n, 'gost', 'gosta', 'gostiju');

/// "noć" (1) / "noći" (2+). Croatian uses "noći" for both paucal and many.
String nightWord(int n) => hrPlural(n, 'noć', 'noći', 'noći');
