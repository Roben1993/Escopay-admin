import 'dart:io';

void main() async {
  final dir = Directory('build/web');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8081);
  print('Serving admin at http://localhost:8081');
  await for (final req in server) {
    var path = req.uri.path == '/' ? '/index.html' : req.uri.path;
    final file = File('${dir.path}$path');
    if (await file.exists()) {
      final ext = path.split('.').last;
      final mime = {
        'html': 'text/html',
        'js': 'application/javascript',
        'css': 'text/css',
        'png': 'image/png',
        'json': 'application/json',
        'wasm': 'application/wasm',
        'ico': 'image/x-icon',
      }[ext] ?? 'application/octet-stream';
      req.response.headers.set('Content-Type', mime);
      await req.response.addStream(file.openRead());
    } else {
      // SPA fallback
      final index = File('${dir.path}/index.html');
      req.response.headers.set('Content-Type', 'text/html');
      await req.response.addStream(index.openRead());
    }
    await req.response.close();
  }
}
