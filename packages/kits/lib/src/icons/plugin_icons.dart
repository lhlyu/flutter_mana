import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PluginIcon {
  ruler('#E6F7F1', '#2DB493', '''
    <path d="M16 13h14v22h21v15H16z" fill="currentColor"/>
    <path d="M23 20h7m-7 8h7m-7 8h7m-7 7h7m7-8v7m7-7v7"/>
  '''),
  colorPicker('#FFF0F4', '#ED7599', '''
    <circle cx="21" cy="44" r="9" fill="currentColor" stroke="none"/>
    <path d="m35 22 8 8-19 19-9 2 2-9z" fill="#FFFFFF"/>
    <path d="m38 15 11 11-6 6-11-11z" fill="currentColor"/>
    <path d="m31 22 12 12M23 40l7-7"/>
  '''),
  device('#EAF2FF', '#638FE8', '''
    <rect x="20" y="11" width="26" height="42" rx="6" fill="#FFFFFF"/>
    <rect x="24" y="19" width="18" height="23" rx="3" fill="currentColor" stroke="none"/>
    <path d="M29 15h8"/>
    <circle cx="33" cy="47" r="1.7" fill="#26384D" stroke="none"/>
  '''),
  network('#E4F7FC', '#35B5D1', '''
    <path d="M26 32h7V19h6M33 32v13h6"/>
    <rect x="10" y="24" width="17" height="16" rx="4" fill="#FFFFFF"/>
    <rect x="38" y="11" width="16" height="16" rx="4" fill="currentColor"/>
    <rect x="38" y="37" width="16" height="16" rx="4" fill="#FFFFFF"/>
    <circle cx="18.5" cy="32" r="3" fill="currentColor" stroke="none"/>
    <path d="M43 19h6m-6 26h6"/>
  '''),
  performance('#EDF8E8', '#76B75B', '''
    <rect x="12" y="15" width="40" height="30" rx="5" fill="#FFFFFF"/>
    <path d="M18 33h7l5-11 7 17 5-10h4" stroke="currentColor" stroke-width="3"/>
    <path d="M32 45v7m-8 0h16"/>
  '''),
  grid('#E8F7F6', '#42B6AF', '''
    <rect x="14" y="14" width="36" height="36" rx="5" fill="#FFFFFF"/>
    <path d="M26 26h12v12H26z" fill="currentColor" stroke="none"/>
    <path d="M26 14v36m12-36v36M14 26h36M14 38h36"/>
  '''),
  license('#FFF6E4', '#EEB64E', '''
    <rect x="16" y="11" width="30" height="40" rx="5" fill="#FFFFFF"/>
    <path d="M23 20h16M23 27h12M23 34h7"/>
    <path d="m36 43-2 11 8-4 8 4-2-11" fill="currentColor"/>
    <circle cx="42" cy="38" r="10" fill="currentColor"/>
    <path d="m37 38 3 3 6-6" stroke="#FFFFFF" stroke-width="2.6"/>
  '''),
  logs('#F0EDFF', '#9A82E3', '''
    <rect x="12" y="12" width="40" height="40" rx="6" fill="#FFFFFF"/>
    <path d="M13 23h38"/>
    <path d="M19 18h1m5 0h1m5 0h1" stroke="currentColor" stroke-width="3"/>
    <circle cx="20" cy="31" r="2" fill="currentColor" stroke="none"/>
    <circle cx="20" cy="39" r="2" fill="#EEB64E" stroke="none"/>
    <circle cx="20" cy="47" r="2" fill="#ED7599" stroke="none"/>
    <path d="M27 31h17M27 39h13M27 47h16"/>
  '''),
  memory('#FFF0EB', '#ED9576', '''
    <path d="M24 12v8m8-8v8m8-8v8M24 44v8m8-8v8m8-8v8M12 24h8m-8 8h8m-8 8h8M44 24h8m-8 8h8m-8 8h8"/>
    <rect x="20" y="20" width="24" height="24" rx="4" fill="currentColor"/>
    <rect x="26" y="26" width="12" height="12" rx="2" fill="#FFFFFF"/>
  '''),
  package('#FFF3E6', '#EFA35C', '''
    <path d="m32 11 20 11v21L32 54 12 43V22z" fill="#FFFFFF"/>
    <path d="m12 22 20 11 20-11-20-11z" fill="currentColor"/>
    <path d="m24 15 20 11-7 4-20-11" fill="#FFFFFF" stroke="none"/>
    <path d="M32 33v21M18 37l7 4"/>
  '''),
  screen('#E8F4FF', '#55A5DF', '''
    <rect x="11" y="14" width="42" height="31" rx="5" fill="#FFFFFF"/>
    <rect x="16" y="19" width="32" height="21" rx="2" fill="currentColor" stroke="none"/>
    <path d="M32 45v7m-9 0h18"/>
    <path d="M22 28v-4h6m14 7v4h-6M23 34l18-9" stroke="#FFFFFF" stroke-width="2.2"/>
  '''),
  preferences('#FCEEF7', '#CE7EB0', '''
    <rect x="12" y="12" width="40" height="40" rx="7" fill="#FFFFFF"/>
    <path d="M18 22h28M18 32h28M18 42h28"/>
    <circle cx="25" cy="22" r="5" fill="currentColor"/>
    <circle cx="39" cy="32" r="5" fill="#FFFFFF"/>
    <circle cx="28" cy="42" r="5" fill="currentColor"/>
  '''),
  code('#EEEDFF', '#8C87E2', '''
    <rect x="11" y="13" width="42" height="38" rx="6" fill="#FFFFFF"/>
    <path d="M12 24h40"/>
    <path d="M18 19h1m5 0h1m5 0h1" stroke="currentColor" stroke-width="3"/>
    <path d="m24 31-6 6 6 6m16-12 6 6-6 6m-5-14-6 16" stroke="currentColor" stroke-width="2.8"/>
  '''),
  touch('#FFF0F5', '#E983AF', '''
    <circle cx="29" cy="23" r="13" stroke="currentColor" stroke-width="2"/>
    <circle cx="29" cy="23" r="7" fill="currentColor" stroke="none"/>
    <path d="M25 37V23a4 4 0 0 1 8 0v11l3-3a4 4 0 0 1 6 0l5 5v5c0 7-4 11-10 11h-5c-4 0-6-2-8-5l-6-9a4 4 0 0 1 6-5z" fill="#FFFFFF"/>
    <rect x="29" y="47" width="15" height="7" rx="2.5" fill="currentColor"/>
  '''),
  visual('#FFF7E6', '#EFB64E', '''
    <path d="M10 33c10-17 34-17 44 0-10 17-34 17-44 0z" fill="#FFFFFF"/>
    <circle cx="32" cy="33" r="9" fill="currentColor"/>
    <circle cx="32" cy="33" r="3" fill="#26384D" stroke="none"/>
    <circle cx="35" cy="30" r="2" fill="#FFFFFF" stroke="none"/>
    <path d="M48 11v8m-4-4h8" stroke="currentColor"/>
  '''),
  inspector('#EDF0FD', '#8396DB', '''
    <path d="M28 21h9M21 28v9"/>
    <rect x="12" y="12" width="17" height="16" rx="4" fill="currentColor"/>
    <rect x="37" y="13" width="15" height="14" rx="4" fill="#FFFFFF"/>
    <rect x="13" y="37" width="15" height="15" rx="4" fill="#FFFFFF"/>
    <path d="m47 47 7 7" stroke-width="4"/>
    <circle cx="39" cy="39" r="11" fill="#FFFFFF"/>
    <rect x="35" y="35" width="8" height="8" rx="2" fill="currentColor"/>
  '''),
  demo('#F6ECFC', '#BD87D6', '''
    <path d="m31 12 6 14 14 6-14 6-6 14-6-14-14-6 14-6z" fill="currentColor"/>
    <path d="m31 26 6 6-6 6-6-6z" fill="#FFFFFF" stroke="none"/>
    <circle cx="50" cy="14" r="4" fill="#EEB64E"/>
  ''');

  const PluginIcon(this.background, this.accent, this._paths);
  final String background;
  final String accent;
  final String _paths;

  String get svg =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="1" y="1" width="62" height="62" rx="15" fill="$background"/>
  <g fill="none" stroke="#26384D" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">${_paths.replaceAll('currentColor', accent)}</g>
</svg>''';
}

typedef PluginIconKey = ({PluginIcon icon, double size, double scale});

/// Rasterizes the SVG at its display resolution and uses Flutter's image cache.
class PluginIconImage extends ImageProvider<PluginIconKey> {
  const PluginIconImage(this.icon);
  final PluginIcon icon;

  @override
  Future<PluginIconKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture((
        icon: icon,
        size: configuration.size?.longestSide ?? 64,
        scale: configuration.devicePixelRatio ?? 1,
      ));

  @override
  ImageStreamCompleter loadImage(
    PluginIconKey key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_load(key));

  Future<ImageInfo> _load(PluginIconKey key) async {
    final source = await vg.loadPicture(SvgStringLoader(key.icon.svg), null);
    try {
      final pixels = (key.size * key.scale).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(pixels / 64);
      canvas.drawPicture(source.picture);
      final picture = recorder.endRecording();
      try {
        return ImageInfo(
          image: await picture.toImage(pixels, pixels),
          scale: key.scale,
        );
      } finally {
        picture.dispose();
      }
    } finally {
      source.picture.dispose();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PluginIconImage && other.icon == icon;

  @override
  int get hashCode => icon.hashCode;
}
