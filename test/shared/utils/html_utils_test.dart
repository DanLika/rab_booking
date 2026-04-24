import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/utils/html_utils.dart';

void main() {
  group('HtmlUtils', () {
    group('escapeHtml', () {
      test('escapes & to &amp;', () {
        expect(HtmlUtils.escapeHtml('fish & chips'), 'fish &amp; chips');
      });

      test('escapes < to &lt;', () {
        expect(HtmlUtils.escapeHtml('1 < 2'), '1 &lt; 2');
      });

      test('escapes > to &gt;', () {
        expect(HtmlUtils.escapeHtml('2 > 1'), '2 &gt; 1');
      });

      test('escapes " to &quot;', () {
        expect(
          HtmlUtils.escapeHtml('He said "Hello"'),
          'He said &quot;Hello&quot;',
        );
      });

      test('escapes \' to &#39;', () {
        expect(HtmlUtils.escapeHtml("It's a trap"), 'It&#39;s a trap');
      });

      test('escapes all special characters in a single string', () {
        const input = '<a href="test?a=1&b=2">It\'s test</a>';
        const expected =
            '&lt;a href=&quot;test?a=1&amp;b=2&quot;&gt;It&#39;s test&lt;/a&gt;';
        expect(HtmlUtils.escapeHtml(input), expected);
      });

      test('returns empty string for null input', () {
        expect(HtmlUtils.escapeHtml(null), '');
      });

      test('returns empty string for empty input', () {
        expect(HtmlUtils.escapeHtml(''), '');
      });

      test('returns same string when no special characters are present', () {
        const safeString = 'Hello World 123';
        expect(HtmlUtils.escapeHtml(safeString), safeString);
      });

      test('avoids double-escaping by escaping & first', () {
        // If < was escaped to &lt; first, and then & was escaped,
        // it would become &amp;lt;
        expect(HtmlUtils.escapeHtml('<'), '&lt;');
      });

      test('handles malicious script tags correctly', () {
        const malicious = '<script>alert("XSS")</script>';
        const expected = '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;';
        expect(HtmlUtils.escapeHtml(malicious), expected);
      });
    });
  });
}
