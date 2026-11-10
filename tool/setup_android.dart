// Configura a pasta android/ gerada pelo `flutter create` para o Respira SP:
// - permissões de INTERNET (necessária no APK de release) e de notificações
// - core library desugaring (exigido pelo flutter_local_notifications)
// - nome do app exibido no aparelho
//
// Uso (na raiz do projeto):  dart run tool/setup_android.dart
// É seguro rodar mais de uma vez.
import 'dart:io';

void main() {
  _patchManifest();
  _patchGradle();
  stdout.writeln('\nPronto! Rode: flutter pub get && flutter run');
}

void _patchManifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    _fail('AndroidManifest.xml não encontrado. Rode antes: '
        'flutter create --platforms=android,ios .');
  }
  var xml = file.readAsStringSync();
  const permissions = [
    'android.permission.INTERNET',
    'android.permission.POST_NOTIFICATIONS',
  ];
  final missing = permissions.where((p) => !xml.contains(p)).toList();
  if (missing.isNotEmpty) {
    final start = xml.indexOf('<manifest');
    final end = xml.indexOf('>', start) + 1;
    final lines = missing
        .map((p) => '\n    <uses-permission android:name="$p"/>')
        .join();
    xml = xml.substring(0, end) + lines + xml.substring(end);
  }
  xml = xml.replaceFirst(
    RegExp(r'android:label="[^"]*"'),
    'android:label="Respira SP"',
  );
  file.writeAsStringSync(xml);
  stdout.writeln('✔ AndroidManifest.xml: permissões e nome do app');
}

void _patchGradle() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final isKts = kts.existsSync();
  final file = isKts ? kts : groovy;
  if (!file.existsSync()) _fail('build.gradle do app não encontrado.');

  var gradle = file.readAsStringSync();
  if (gradle.contains('oreLibraryDesugaringEnabled')) {
    stdout.writeln('✔ ${file.path}: desugaring já configurado');
    return;
  }

  final flag = isKts
      ? 'isCoreLibraryDesugaringEnabled = true'
      : 'coreLibraryDesugaringEnabled true';
  final dep = isKts
      ? 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
      : "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'";

  if (gradle.contains('compileOptions {')) {
    gradle = gradle.replaceFirst(
      'compileOptions {',
      'compileOptions {\n        $flag',
    );
  } else {
    gradle = gradle.replaceFirst(
      RegExp(r'android\s*\{'),
      'android {\n    compileOptions {\n        $flag\n    }',
    );
  }

  final depsBlock = RegExp(r'^dependencies\s*\{', multiLine: true);
  if (depsBlock.hasMatch(gradle)) {
    gradle = gradle.replaceFirst(depsBlock, 'dependencies {\n    $dep');
  } else {
    gradle += '\ndependencies {\n    $dep\n}\n';
  }

  file.writeAsStringSync(gradle);
  stdout.writeln('✔ ${file.path}: core library desugaring ativado');
}

Never _fail(String message) {
  stderr.writeln('✘ $message');
  exit(1);
}
