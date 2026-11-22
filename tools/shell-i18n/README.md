# Shell translation compiler

This module compiles quoted `--...--` markers in a POSIX shell template
using the single root `translations.json` catalog. The markers stay inside
string literals in the source, including AWK strings, so the template remains
readable and valid for syntax-aware editors. Each key stores complete
messages for all locales next to each other:

```json
{
  "UPDATE_FAILED": {
    "en": "Failed to update {name}",
    "ru": "Ошибка обновления {name}"
  }
}
```

Use a marker as a complete shell string, for example:

```sh
echo "--UPDATE_FAILED--"
```

Keys are complete message units, not fragments. `{name}` is a runtime shell
variable placeholder; all other text is escaped as a literal. Placeholder
names are validated independently per locale so legacy messages can preserve
their existing variable behavior. Compilation fails for missing keys, missing
locale values, malformed placeholders, or unused catalog entries.

Compile a template with:

```sh
go run . -input skeen.sh -catalog translations.json -locale en
```

The repository build runs the compiler for `en` and `ru`, formats and minifies
each result, then validates both artifacts with `sh -n`:

```sh
sh .github/build-shell-scripts.sh [output-directory]
```

Add new messages to `translations.json` and use each key exactly once or more in
`skeen.sh`. Every supported locale must be present for every key; compilation
fails rather than falling back to English.
