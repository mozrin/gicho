# Gicho

## Scope and ownership

Gicho is a public MIT-licensed Flutter package in one source repository.
The only owning Project is https://github.com/users/mozrin/projects/11.
Keep package code, catalogs, tools, assets, examples and tests here. Do not
create companion repositories or separately distributed first-party packages.
Historical sources under legacy/ are unmaintained references, not dependencies.
Do not modify Orchard or any original Flackage repository or consumer.

## Wiki exception approved by the owner

The owner explicitly authorizes wiki work for mozrin/gicho while this repository
is public, despite the shared Codex Harness restriction for GitHub Free owners.
This Gicho-only exception was approved on 16 November 2026 because Gicho is public.
It does not apply to private repositories or change the shared policy.
Continue to verify owner/visibility and use the separate ignored wiki/ Git clone.

## Version and release

VERSION and the root pubspec.yaml package version must agree. The public Dart
entry is package:gicho/gicho.dart. Never publish to pub.dev without separate
owner authorization. Issue branches integrate through PRs into develop;
numeric tags identify exact reviewed integration commits. Do not merge main.

## Localization and source organization

Preserve the copied package's existing lib/src organization during the rename.
The package registers 20 locales; consumers choose their enabled subset and
must retain English fallback. Preserve existing catalogs and RTL support.
New application examples initially enable English, Thai and Arabic where
usable catalogs are provided; existing example choices remain explicit.

## Validation

Run flutter pub get, flutter analyze and flutter test at the package root and
in every maintained examples/* app. Test meaningful behavior, then build and
launch on appropriate available supported platforms. Record external-service
and physical-device limitations honestly. Never commit credentials or caches.

by-dolly
