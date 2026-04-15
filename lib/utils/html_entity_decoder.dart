String decodeHtmlEntities(String input) {
  if (input.isEmpty) return input;

  final namedEntities = <String, String>{
    '&quot;': '"',
    '&apos;': "'",
    '&#039;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&nbsp;': ' ',
    '&ldquo;': '"',
    '&rdquo;': '"',
    '&lsquo;': "'",
    '&rsquo;': "'",
    '&hellip;': '...',
    '&ndash;': '-',
    '&mdash;': '--',
    '&deg;': '°',
  };

  var output = input;

  // Decode in multiple passes to handle double-encoded values like "&amp;quot;".
  for (var pass = 0; pass < 3; pass++) {
    final before = output;

    namedEntities.forEach((entity, value) {
      output = output.replaceAll(entity, value);
    });

    // Decode decimal numeric entities like "&#123" or "&#123;".
    output = output.replaceAllMapped(RegExp(r'&#(\d+);?'), (match) {
      final codePoint = int.tryParse(match.group(1)!);
      if (codePoint == null || codePoint < 0 || codePoint > 0x10FFFF) {
        return match.group(0)!;
      }
      return String.fromCharCode(codePoint);
    });

    // Decode hex numeric entities like "&#x1F600" or "&#x1F600;" (case-insensitive x).
    output = output.replaceAllMapped(RegExp(r'&#[xX]([0-9a-fA-F]+);?'), (match) {
      final codePoint = int.tryParse(match.group(1)!, radix: 16);
      if (codePoint == null || codePoint < 0 || codePoint > 0x10FFFF) {
        return match.group(0)!;
      }
      return String.fromCharCode(codePoint);
    });

    if (before == output) {
      break;
    }
  }

  // Normalize common mojibake leftovers.
  output = output
      .replaceAll('â€™', "'")
      .replaceAll('â€œ', '"')
      .replaceAll('â€\u009d', '"')
      .replaceAll('â€“', '-')
      .replaceAll('â€”', '--')
      .replaceAll('Â ', ' ')
      .replaceAll('Â', '');

  return output;
}
