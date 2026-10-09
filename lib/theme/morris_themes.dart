/// Theme catalog for Nine Men's Morris: 14 carved-stone themes, 10 piece
/// styles, 7 board accents, and a custom theme creator. All persist via
/// [SettingsStore]. All art direction stays inside the game's Lapidary
/// Archaeological identity — ancient stone, bronze, bone, parchment.
library;

import 'package:flutter/material.dart';

/// Full palette for one carved-stone theme.
class MorrisTheme {
  final String id;
  final String name;
  final String blurb;
  final bool proOnly;
  final Color sandstone; // board slab base
  final Color sandstoneLight; // lit bevels, grain
  final Color grooveDark; // chisel trench core
  final Color socketDeep; // point socket recess
  final Color bronze; // player one token
  final Color bronzeDark; // bronze shading
  final Color bronzeLight; // bronze highlight
  final Color bone; // player two token
  final Color boneDark; // bone shading
  final Color verdigris; // patina / status accent
  final Color basalt; // vault canvas
  final Color basaltDeep; // darkest canvas
  final Color parchment; // panels
  final Color sepiaInk; // letterpress text

  const MorrisTheme({
    required this.id,
    required this.name,
    required this.blurb,
    required this.proOnly,
    required this.sandstone,
    required this.sandstoneLight,
    required this.grooveDark,
    required this.socketDeep,
    required this.bronze,
    required this.bronzeDark,
    required this.bronzeLight,
    required this.bone,
    required this.boneDark,
    required this.verdigris,
    required this.basalt,
    required this.basaltDeep,
    required this.parchment,
    required this.sepiaInk,
  });

  /// Build from a custom creator's raw colors (derived tones computed).
  factory MorrisTheme.custom({
    required Color sandstone,
    required Color bronze,
    required Color bone,
    required Color accent,
  }) {
    final hsl = HSLColor.fromColor(sandstone);
    return MorrisTheme(
      id: 'custom',
      name: 'Your Carving',
      blurb: 'Chiselled by you.',
      proOnly: true,
      sandstone: sandstone,
      sandstoneLight: hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0)).toColor(),
      grooveDark: hsl.withLightness((hsl.lightness - 0.34).clamp(0.0, 1.0)).toColor(),
      socketDeep: hsl.withLightness((hsl.lightness - 0.42).clamp(0.0, 1.0)).toColor(),
      bronze: bronze,
      bronzeDark: HSLColor.fromColor(bronze).withLightness(0.22).toColor(),
      bronzeLight: HSLColor.fromColor(bronze).withLightness(0.68).toColor(),
      bone: bone,
      boneDark: HSLColor.fromColor(bone).withLightness(0.45).toColor(),
      verdigris: accent,
      basalt: const Color(0xFF3C2F21),
      basaltDeep: const Color(0xFF1C1106),
      parchment: const Color(0xFFF4EBD0),
      sepiaInk: const Color(0xFF3A2514),
    );
  }
}

const List<MorrisTheme> morrisThemes = [
  // --- Free -----------------------------------------------------------------
  MorrisTheme(
    id: 'lapidary',
    name: 'Lapidary Classic',
    blurb: 'The museum-gallery original.',
    proOnly: false,
    sandstone: Color(0xFFC2A87D),
    sandstoneLight: Color(0xFFE4D3AE),
    grooveDark: Color(0xFF3A2C1C),
    socketDeep: Color(0xFF2E2115),
    bronze: Color(0xFF8C6239),
    bronzeDark: Color(0xFF5E3F22),
    bronzeLight: Color(0xFFD9A860),
    bone: Color(0xFFD0C5B7),
    boneDark: Color(0xFF7E7263),
    verdigris: Color(0xFF4A7C6D),
    basalt: Color(0xFF3C2F21),
    basaltDeep: Color(0xFF1C1106),
    parchment: Color(0xFFF4EBD0),
    sepiaInk: Color(0xFF3A2514),
  ),
  MorrisTheme(
    id: 'desert',
    name: 'Desert Sunstone',
    blurb: 'Sun-baked dunes, honey bronze.',
    proOnly: false,
    sandstone: Color(0xFFD9B77C),
    sandstoneLight: Color(0xFFF2DCAC),
    grooveDark: Color(0xFF4A3520),
    socketDeep: Color(0xFF3A2A18),
    bronze: Color(0xFF9A6B2E),
    bronzeDark: Color(0xFF66431C),
    bronzeLight: Color(0xFFE8B96A),
    bone: Color(0xFFE8DCC4),
    boneDark: Color(0xFF8A7C64),
    verdigris: Color(0xFF5E8A6A),
    basalt: Color(0xFF453522),
    basaltDeep: Color(0xFF241708),
    parchment: Color(0xFFF8EFD6),
    sepiaInk: Color(0xFF42290F),
  ),
  MorrisTheme(
    id: 'nile',
    name: 'Nile Delta',
    blurb: 'River silt and lotus green.',
    proOnly: false,
    sandstone: Color(0xFFB49B6E),
    sandstoneLight: Color(0xFFD8C49A),
    grooveDark: Color(0xFF33301E),
    socketDeep: Color(0xFF28241A),
    bronze: Color(0xFF7C5A30),
    bronzeDark: Color(0xFF523A1E),
    bronzeLight: Color(0xFFC89858),
    bone: Color(0xFFD8CCB4),
    boneDark: Color(0xFF7A6E58),
    verdigris: Color(0xFF3F7A5E),
    basalt: Color(0xFF33301F),
    basaltDeep: Color(0xFF181510),
    parchment: Color(0xFFF2E8CC),
    sepiaInk: Color(0xFF33270F),
  ),
  MorrisTheme(
    id: 'volcanic',
    name: 'Volcanic Basalt',
    blurb: 'Black lava rock, ember bronze.',
    proOnly: false,
    sandstone: Color(0xFF6E6258),
    sandstoneLight: Color(0xFF9A8C7C),
    grooveDark: Color(0xFF1E1A16),
    socketDeep: Color(0xFF171310),
    bronze: Color(0xFFA05A2A),
    bronzeDark: Color(0xFF683614),
    bronzeLight: Color(0xFFE89A54),
    bone: Color(0xFFCFC4B2),
    boneDark: Color(0xFF6E6258),
    verdigris: Color(0xFFC46A3A),
    basalt: Color(0xFF26211C),
    basaltDeep: Color(0xFF100D0A),
    parchment: Color(0xFFEDE0C2),
    sepiaInk: Color(0xFF2E1E0E),
  ),
  // --- Pro ------------------------------------------------------------------
  MorrisTheme(
    id: 'marble',
    name: 'Roman Marble',
    blurb: 'Pale Carrara, imperial bronze.',
    proOnly: true,
    sandstone: Color(0xFFD8D2C4),
    sandstoneLight: Color(0xFFF4F0E4),
    grooveDark: Color(0xFF4A463C),
    socketDeep: Color(0xFF3A372E),
    bronze: Color(0xFF8C6239),
    bronzeDark: Color(0xFF5E3F22),
    bronzeLight: Color(0xFFD9A860),
    bone: Color(0xFFEFE9DA),
    boneDark: Color(0xFF8E8878),
    verdigris: Color(0xFF4A7C6D),
    basalt: Color(0xFF3E3A30),
    basaltDeep: Color(0xFF1E1C16),
    parchment: Color(0xFFF8F4E8),
    sepiaInk: Color(0xFF3A3226),
  ),
  MorrisTheme(
    id: 'oakiron',
    name: 'Aged Oak & Iron',
    blurb: 'Timber boards, iron men.',
    proOnly: true,
    sandstone: Color(0xFF9A7A52),
    sandstoneLight: Color(0xFFC4A87C),
    grooveDark: Color(0xFF33241A),
    socketDeep: Color(0xFF2A1E14),
    bronze: Color(0xFF5A5E64),
    bronzeDark: Color(0xFF383B40),
    bronzeLight: Color(0xFF9AA0A8),
    bone: Color(0xFFD8C8A8),
    boneDark: Color(0xFF8A785C),
    verdigris: Color(0xFF7A6A3A),
    basalt: Color(0xFF35281C),
    basaltDeep: Color(0xFF1C130C),
    parchment: Color(0xFFF0E4C8),
    sepiaInk: Color(0xFF38240F),
  ),
  MorrisTheme(
    id: 'oasis',
    name: 'Turquoise Oasis',
    blurb: 'Desert stone, oasis inlay.',
    proOnly: true,
    sandstone: Color(0xFFC8A878),
    sandstoneLight: Color(0xFFE8D0A4),
    grooveDark: Color(0xFF3A2E1E),
    socketDeep: Color(0xFF2E2418),
    bronze: Color(0xFF8C6239),
    bronzeDark: Color(0xFF5E3F22),
    bronzeLight: Color(0xFFD9A860),
    bone: Color(0xFFD8CCB8),
    boneDark: Color(0xFF7E7263),
    verdigris: Color(0xFF2E8A8A),
    basalt: Color(0xFF2E3A34),
    basaltDeep: Color(0xFF141E1A),
    parchment: Color(0xFFF4EBCF),
    sepiaInk: Color(0xFF332712),
  ),
  MorrisTheme(
    id: 'sandstorm',
    name: 'Sandstorm Dune',
    blurb: 'Wind-worn rose sandstone.',
    proOnly: true,
    sandstone: Color(0xFFC89A72),
    sandstoneLight: Color(0xFFE8C49C),
    grooveDark: Color(0xFF4A2E20),
    socketDeep: Color(0xFF3A2418),
    bronze: Color(0xFF7A4E2A),
    bronzeDark: Color(0xFF523018),
    bronzeLight: Color(0xFFC48854),
    bone: Color(0xFFE4D4BC),
    boneDark: Color(0xFF8A7460),
    verdigris: Color(0xFF8A5A3A),
    basalt: Color(0xFF402E22),
    basaltDeep: Color(0xFF201410),
    parchment: Color(0xFFF6E8CC),
    sepiaInk: Color(0xFF3E2412),
  ),
  MorrisTheme(
    id: 'obsidian',
    name: 'Obsidian Night',
    blurb: 'Midnight glass, moon-bone men.',
    proOnly: true,
    sandstone: Color(0xFF4A4450),
    sandstoneLight: Color(0xFF6E6878),
    grooveDark: Color(0xFF121014),
    socketDeep: Color(0xFF0E0C10),
    bronze: Color(0xFF9A6B3A),
    bronzeDark: Color(0xFF64421E),
    bronzeLight: Color(0xFFE0AC62),
    bone: Color(0xFFE8E4D8),
    boneDark: Color(0xFF8A867A),
    verdigris: Color(0xFF5A8A9A),
    basalt: Color(0xFF1E1C24),
    basaltDeep: Color(0xFF0C0A10),
    parchment: Color(0xFFE8E0CC),
    sepiaInk: Color(0xFF2A2418),
  ),
  MorrisTheme(
    id: 'terracotta',
    name: 'Terracotta Kiln',
    blurb: 'Fired clay, kiln-bronze.',
    proOnly: true,
    sandstone: Color(0xFFB8724E),
    sandstoneLight: Color(0xFFDE9E72),
    grooveDark: Color(0xFF422418),
    socketDeep: Color(0xFF361D12),
    bronze: Color(0xFF6E4A24),
    bronzeDark: Color(0xFF482E14),
    bronzeLight: Color(0xFFB8824A),
    bone: Color(0xFFE8D8BE),
    boneDark: Color(0xFF8A7460),
    verdigris: Color(0xFF5E7A4A),
    basalt: Color(0xFF3E2A1E),
    basaltDeep: Color(0xFF201310),
    parchment: Color(0xFFF4E4C6),
    sepiaInk: Color(0xFF3A2210),
  ),
  MorrisTheme(
    id: 'jade',
    name: 'Jade Carving',
    blurb: 'Deep green stone, gold men.',
    proOnly: true,
    sandstone: Color(0xFF6E8A72),
    sandstoneLight: Color(0xFF9AB89E),
    grooveDark: Color(0xFF1E2E22),
    socketDeep: Color(0xFF18241C),
    bronze: Color(0xFFA8823A),
    bronzeDark: Color(0xFF6E5422),
    bronzeLight: Color(0xFFE8C26A),
    bone: Color(0xFFE4E0D0),
    boneDark: Color(0xFF8A8672),
    verdigris: Color(0xFF3A7A5E),
    basalt: Color(0xFF26332A),
    basaltDeep: Color(0xFF121A14),
    parchment: Color(0xFFEEE8CC),
    sepiaInk: Color(0xFF2A3020),
  ),
  MorrisTheme(
    id: 'granite',
    name: 'Granite Quarry',
    blurb: 'Grey megaliths, rust inlay.',
    proOnly: true,
    sandstone: Color(0xFF8E8A82),
    sandstoneLight: Color(0xFFBEBAB0),
    grooveDark: Color(0xFF2E2C28),
    socketDeep: Color(0xFF242220),
    bronze: Color(0xFF8A5A3A),
    bronzeDark: Color(0xFF5E3A22),
    bronzeLight: Color(0xFFC88A5A),
    bone: Color(0xFFD8D4C8),
    boneDark: Color(0xFF7E7A70),
    verdigris: Color(0xFF9A5A3A),
    basalt: Color(0xFF343230),
    basaltDeep: Color(0xFF161514),
    parchment: Color(0xFFF0EACF),
    sepiaInk: Color(0xFF322E24),
  ),
  MorrisTheme(
    id: 'papyrus',
    name: 'Papyrus Dawn',
    blurb: 'First light on river stone.',
    proOnly: true,
    sandstone: Color(0xFFD4B98E),
    sandstoneLight: Color(0xFFEFE0B8),
    grooveDark: Color(0xFF4E3E26),
    socketDeep: Color(0xFF3E301E),
    bronze: Color(0xFF8C6239),
    bronzeDark: Color(0xFF5E3F22),
    bronzeLight: Color(0xFFD9A860),
    bone: Color(0xFFF0E6D2),
    boneDark: Color(0xFF96866C),
    verdigris: Color(0xFF6E8A5E),
    basalt: Color(0xFF463824),
    basaltDeep: Color(0xFF251B0E),
    parchment: Color(0xFFFAF0D6),
    sepiaInk: Color(0xFF402D12),
  ),
  MorrisTheme(
    id: 'amber',
    name: 'Amber Fossil',
    blurb: 'Resin-gold, ancient insects optional.',
    proOnly: true,
    sandstone: Color(0xFFB89A5E),
    sandstoneLight: Color(0xFFDEC48C),
    grooveDark: Color(0xFF40301A),
    socketDeep: Color(0xFF332614),
    bronze: Color(0xFF7A4E22),
    bronzeDark: Color(0xFF523014),
    bronzeLight: Color(0xFFC48A44),
    bone: Color(0xFFEBDCB4),
    boneDark: Color(0xFF9A8660),
    verdigris: Color(0xFF8A6E3A),
    basalt: Color(0xFF3E2F1A),
    basaltDeep: Color(0xFF221708),
    parchment: Color(0xFFF6EAC8),
    sepiaInk: Color(0xFF3A2810),
  ),
];

MorrisTheme themeById(String id, {MorrisTheme? custom}) {
  if (id == 'custom' && custom != null) return custom;
  for (final t in morrisThemes) {
    if (t.id == id) return t;
  }
  return morrisThemes.first;
}

/// How a token is drawn: shape + engraving + surface treatment.
class PieceStyle {
  final String id;
  final String name;
  final String blurb;
  final bool proOnly;
  final int ringCount; // concentric engraved rings (0-3)
  final double bossScale; // center boss size factor
  final double patina; // verdigris bloom density 0..1
  final bool hex; // hexagon-cut stone instead of disc
  final bool square; // square tablet instead of disc
  final bool spiral; // spiral engraving instead of rings

  const PieceStyle({
    required this.id,
    required this.name,
    required this.blurb,
    required this.proOnly,
    this.ringCount = 2,
    this.bossScale = 1.0,
    this.patina = 0.5,
    this.hex = false,
    this.square = false,
    this.spiral = false,
  });
}

const List<PieceStyle> pieceStyles = [
  PieceStyle(id: 'classic', name: 'Classic Disc', blurb: 'The museum original.', proOnly: false),
  PieceStyle(id: 'ringed', name: 'Ringed Coin', blurb: 'Triple-ring engraving.', proOnly: false, ringCount: 3),
  PieceStyle(id: 'domed', name: 'Domed Boss', blurb: 'A proud raised crown.', proOnly: false, ringCount: 1, bossScale: 1.5),
  PieceStyle(id: 'flat', name: 'Flat Tablet', blurb: 'Slim, no boss.', proOnly: true, ringCount: 1, bossScale: 0.0),
  PieceStyle(id: 'hex', name: 'Hex Stone', blurb: 'Six-cut edges.', proOnly: true, hex: true, ringCount: 1),
  PieceStyle(id: 'stele', name: 'Square Stele', blurb: 'A tiny stone monument.', proOnly: true, square: true, ringCount: 1),
  PieceStyle(id: 'patina', name: 'Patina Bloom', blurb: 'Heavy verdigris age.', proOnly: true, patina: 1.0, ringCount: 2),
  PieceStyle(id: 'gem', name: 'Inlaid Gem', blurb: 'Boss like a jewel.', proOnly: true, bossScale: 1.3, ringCount: 3, patina: 0.2),
  PieceStyle(id: 'spiral', name: 'Carved Spiral', blurb: 'Celtic whorl engraving.', proOnly: true, spiral: true, ringCount: 0),
  PieceStyle(id: 'pebble', name: 'River Pebble', blurb: 'Smooth, ringless.', proOnly: true, ringCount: 0, bossScale: 0.6, patina: 0.1),
];

PieceStyle pieceStyleById(String id) {
  for (final s in pieceStyles) {
    if (s.id == id) return s;
  }
  return pieceStyles.first;
}

/// Board accent: socket inlay + mill-flash + move-target highlight colors.
class BoardAccent {
  final String id;
  final String name;
  final bool proOnly;
  final Color inlay;
  final Color millFlash;
  final Color moveTarget;

  const BoardAccent({
    required this.id,
    required this.name,
    required this.proOnly,
    required this.inlay,
    required this.millFlash,
    required this.moveTarget,
  });
}

const List<BoardAccent> boardAccents = [
  BoardAccent(id: 'verdigris', name: 'Verdigris', proOnly: false,
      inlay: Color(0xFF4A7C6D), millFlash: Color(0xFF4A7C6D), moveTarget: Color(0xFF4A7C6D)),
  BoardAccent(id: 'lapis', name: 'Lapis Lazuli', proOnly: false,
      inlay: Color(0xFF2E4A8A), millFlash: Color(0xFF3A5AA8), moveTarget: Color(0xFF3A5AA8)),
  BoardAccent(id: 'carnelian', name: 'Carnelian', proOnly: true,
      inlay: Color(0xFF9A3A2A), millFlash: Color(0xFFB84A34), moveTarget: Color(0xFFB84A34)),
  BoardAccent(id: 'goldleaf', name: 'Gold Leaf', proOnly: true,
      inlay: Color(0xFFB8862A), millFlash: Color(0xFFD8A83A), moveTarget: Color(0xFFD8A83A)),
  BoardAccent(id: 'obsidian', name: 'Obsidian', proOnly: true,
      inlay: Color(0xFF2E2A34), millFlash: Color(0xFF4A4450), moveTarget: Color(0xFF5A5462)),
  BoardAccent(id: 'turquoise', name: 'Turquoise', proOnly: true,
      inlay: Color(0xFF2E8A8A), millFlash: Color(0xFF3AA8A8), moveTarget: Color(0xFF3AA8A8)),
  BoardAccent(id: 'copper', name: 'Copper', proOnly: true,
      inlay: Color(0xFF8A5A3A), millFlash: Color(0xFFA8724A), moveTarget: Color(0xFFA8724A)),
];

BoardAccent boardAccentById(String id) {
  for (final a in boardAccents) {
    if (a.id == id) return a;
  }
  return boardAccents.first;
}
