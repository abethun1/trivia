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
  };

  var output = input;
  namedEntities.forEach((entity, value) {
    output = output.replaceAll(entity, value);
  });

  // Decode decimal numeric entities like: &#123;
  output = output.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final codePoint = int.tryParse(match.group(1)!);
    if (codePoint == null) return match.group(0)!;
    return String.fromCharCode(codePoint);
  });

  // Decode hex numeric entities like: &#x1F600;
  output = output.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    final codePoint = int.tryParse(match.group(1)!, radix: 16);
    if (codePoint == null) return match.group(0)!;
    return String.fromCharCode(codePoint);
  });

  return output;
}
