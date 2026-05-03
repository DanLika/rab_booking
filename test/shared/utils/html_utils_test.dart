import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/utils/html_utils.dart';

void main() {
  group('HtmlUtils.escapeHtml', () {
    test('returns empty string for null input', () {
      expect(HtmlUtils.escapeHtml(null), '');
    });

    test('returns empty string for empty input', () {
      expect(HtmlUtils.escapeHtml(''), '');
    });

    test('returns original string if no special characters are present', () {
      const input = 'Hello World 123!';
      expect(HtmlUtils.escapeHtml(input), input);
    });

    test('escapes ampersand (&)', () {
      expect(HtmlUtils.escapeHtml('Jack & Jill'), 'Jack &amp; Jill');
    });

    test('escapes less than (<)', () {
      expect(HtmlUtils.escapeHtml('5 < 10'), '5 &lt; 10');
    });

    test('escapes greater than (>)', () {
      expect(HtmlUtils.escapeHtml('10 > 5'), '10 &gt; 5');
    });

    test('escapes double quotes (")', () {
      expect(
        HtmlUtils.escapeHtml('He said "Hello"'),
        'He said &quot;Hello&quot;',
      );
    });

    test("escapes single quotes (')", () {
      expect(HtmlUtils.escapeHtml("It's fine"), 'It&#39;s fine');
    });

    test(
      'handles double-escaping prevention scenarios correctly (by escaping the & first)',
      () {
        // The `escapeHtml` function replaces '&' with '&amp;' first.
        // If we input '&amp;', it will become '&amp;amp;' which is expected behavior for a dumb string replacement,
        // but let's test a realistic input like: '&lt;' -> '&amp;lt;'
        expect(HtmlUtils.escapeHtml('&lt;'), '&amp;lt;');
      },
    );

    test('escapes multiple special characters together (XSS vector)', () {
      const input = '<script>alert("XSS & Hack\'s")</script>';
      const expected =
          '&lt;script&gt;alert(&quot;XSS &amp; Hack&#39;s&quot;)&lt;/script&gt;';
      expect(HtmlUtils.escapeHtml(input), expected);
    });

    test('handles special characters at the start, middle, and end', () {
      const input = '& start < middle > end "';
      const expected = '&amp; start &lt; middle &gt; end &quot;';
      expect(HtmlUtils.escapeHtml(input), expected);
    });
  });
}
