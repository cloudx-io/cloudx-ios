---
name: docs-sync-agent
description: Syncs CloudX iOS SDK README to docs repo MDX incrementally
tools: Read, Write, Edit, Bash, Grep, Glob
model: sonnet
---

# CloudX iOS Docs Sync

Incrementally syncs iOS SDK documentation to the public docs site, preserving MDX structure.

## Usage

```
Use @docs-sync-agent to sync iOS SDK docs to docs repo
```

## Sources & Targets

| Source (this repo) | Target (`../../../docs/{lang}/ios/`) |
|---|---|
| `core/README.md` | `integration.mdx` |
| `CHANGELOG.md` | `changelog.mdx` |
| `adapter-meta/README.md` | `adapters/meta.mdx` |
| `adapter-vungle/README.md` | `adapters/vungle.mdx` |
| `adapter-inmobi/README.md` | `adapters/inmobi.mdx` |
| `renderer-cloudx/README.md` | `adapters/renderer.mdx` |

Where `{lang}` is each language folder found in `../../../docs/` (e.g., `en`, `zh`).

**Note:** Other adapters (mintegral, moloco) exist in this repo but don't have corresponding docs yet. Skip any source file if its target doesn't exist.

## Workflow

### Step 1: Discover Languages
Find all language folders in the docs repo:
```bash
ls -d ../../../docs/*/ios/ 2>/dev/null | xargs -n1 dirname | xargs -n1 basename
```

This returns language codes like `en`, `zh`, etc.

### Step 2: Read
Read source files (once):
- `core/README.md`, `CHANGELOG.md`, and adapter READMEs from this repo
- Get SDK version from `CHANGELOG.md` (first release heading, e.g., `## [2.0.0]` → version `2.0.0`)

For each discovered `{lang}`, read target files:
- `../../../docs/{lang}/ios/integration.mdx`
- `../../../docs/{lang}/ios/changelog.mdx`
- `../../../docs/{lang}/ios/adapters/meta.mdx` (if exists)
- `../../../docs/{lang}/ios/adapters/vungle.mdx` (if exists)
- `../../../docs/{lang}/ios/adapters/inmobi.mdx` (if exists)
- `../../../docs/{lang}/ios/adapters/renderer.mdx` (if exists)

### Step 3: Compare
Compare source files with any `{lang}/ios/` targets (code/versions are identical across languages).
Ignore `<CodeGroup>` wrappers and frontmatter.

Look for differences in:
- Version strings
- Code examples
- Section text
- New/removed sections

Compare CHANGELOG.md with changelog.mdx for new release entries.

**If no changes found (all languages already in sync), report "Already in sync" and stop.**

### Step 4: Edit
Apply changes to MDX files in **all language folders** using Edit tool (not Write).

**For integration.mdx and adapter docs:**
- Update changed text/code in place
- For new sections with Objective-C + Swift blocks, wrap in:
  ```
  <CodeGroup>
  ```objc Objective-C
  ...
  ```

  ```swift Swift
  ...
  ```
  </CodeGroup>
  ```
- For Ruby/Bash blocks (CocoaPods), use "Ruby" and "Bash" labels
- Never modify frontmatter or existing `<CodeGroup>` structure

**For changelog.mdx:**
- Add new release entries below frontmatter
- Don't modify existing entries

### Step 5: PR
```bash
cd ../../../docs
git checkout -b sync/ios-docs-{version}
# Add changes for all discovered {lang}/ios/ folders
git add */ios/
git commit -m "Sync iOS SDK docs to {version}"
gh pr create --title "Sync iOS SDK docs to {version}" --body "{summary of changes}"
```

Note: `*/ios/` is shell glob that matches all `{lang}/ios/` folders.

Return the PR link.

## Important

- **Edit, don't regenerate** - Preserve MDX structure
- **No changes = no PR** - Don't create empty PRs
- **Sync all languages** - Apply same changes to all `{lang}/ios/` folders
- **Skip missing targets** - If a target file doesn't exist, skip that source
