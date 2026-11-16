import 'package:flutter/material.dart';

final class SecondaryDestination {
  const SecondaryDestination(this.path, this.label, this.icon, this.message);

  final String path;
  final String label;
  final IconData icon;
  final String message;
}

const secondaryDestinations = <SecondaryDestination>[
  SecondaryDestination(
    '/dnav1',
    'DNav1',
    Icons.filter_1_outlined,
    'Drawer destination one.',
  ),
  SecondaryDestination(
    '/dnav2',
    'DNav2',
    Icons.filter_2_outlined,
    'Drawer destination two.',
  ),
  SecondaryDestination(
    '/dnav3',
    'DNav3',
    Icons.filter_3_outlined,
    'Drawer destination three.',
  ),
  SecondaryDestination(
    '/dnav4',
    'DNav4',
    Icons.filter_4_outlined,
    'Drawer destination four.',
  ),
  SecondaryDestination(
    '/dnav5',
    'Logging',
    Icons.filter_5_outlined,
    'Drawer destination five.',
  ),
];
