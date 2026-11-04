# Specification intake

Checked: 2026-11-02 (America/New_York)

## Required source

Version 3.0 master specification, referred to by the user as attached.

- Source received: no.
- Source read in full: no.
- Original filename, file hash, page count, and Phase 0/Phase A definitions: unavailable.
- Source-of-truth status: unresolved; application implementation is gated by the user's explicit instruction to read the full document first.

## Evidence

1. The visible user message contains the requested scope, but not the specification body or an attachment path.
2. The chat's `list_artifacts` tool returned `{"artifacts":[]}`.
3. The Downloads directory contains route PDFs, a product label PDF, a training presentation, and a data directory; no filename matched the requested specification.
4. Bounded filename searches under Documents, Desktop, and this chat's visualization workspace found no match for `master.*spec`, `specification`, `version.?3`, `v3[._ -]?0`, or `BUILD_STATE`. Some unrelated historical dependency directories returned access-denied errors, so this is not proof that no copy exists anywhere on the computer.
5. No Page was selected in the supplied open-Page context.
6. The user has been asked for an existing file path or accessible link. No source content is to be inferred from unrelated Lawn Ace documents or prior chats.

## Intake procedure when the source arrives

1. Preserve the original source and record its path or URL, title, stated version, and SHA-256 hash where applicable.
2. Read every page/section, including appendices, tables, diagrams, and acceptance criteria. If extraction is incomplete, resolve the missing content before implementation.
3. Extend `REQUIREMENTS.csv` with stable specification IDs and exact source references. Preserve both warm-season and cool-season turf, ornamentals, and every requirement explicitly named by the user.
4. Capture Phase 0 and Phase A scope verbatim or with traceable references. Record conflicts and unresolved decisions instead of silently narrowing scope.
5. Select the architecture against the specification and environment evidence; identify owner setup only when the actual integration requires it.
6. Implement and verify Phase A, retaining unimplemented later requirements in the register.
