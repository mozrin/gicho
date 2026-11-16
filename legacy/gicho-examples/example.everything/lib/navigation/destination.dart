import 'package:flutter/material.dart';

final class Destination {
  const Destination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const destinations = <Destination>[
  Destination('/fnav1', 'FNav1', Icons.looks_one_outlined, Icons.looks_one),
  Destination('/fnav2', 'FNav2', Icons.looks_two_outlined, Icons.looks_two),
  Destination('/fnav3', 'FNav3', Icons.looks_3_outlined, Icons.looks_3),
  Destination('/fnav4', 'FNav4', Icons.looks_4_outlined, Icons.looks_4),
  Destination('/config', 'Config', Icons.tune_outlined, Icons.tune),
];
