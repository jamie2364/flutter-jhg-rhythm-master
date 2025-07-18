import 'dart:js' as js;

void playWebMetronomeSound(String url, double volume) {
  js.context.callMethod('playMetronomeSound', [url, volume]);
} 