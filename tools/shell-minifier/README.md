# Shell minifier

This tool performs conservative identifier shortening for the POSIX shell
scripts. It parses the input with `mvdan.cc/sh/v3`; for variables, it only
renames locals declared in the unconditional leading `local` commands of a
function and top-level `readonly` constants. Other global variables and locals
declared later are left unchanged. Function names are renamed only when all
uses are statically identifiable in the source; names found in opaque strings
are left unchanged. Runtime-computed function calls cannot be proven safe
statically and should be added to the protected-name handling if introduced.
Documentation comments and blank lines inside the top-level `RESERVED_IPV4` and
`RESERVED_IPV6` string constants are removed from generated output; other quoted
text is left unchanged. The tool does not alter the readable source files.

The build compiles the English and Russian scripts from the single `skeen.sh`
template and the root `translations.json` catalog, then formats and minifies
each artifact. Run it from the repository root with `shfmt` on `PATH`:

```sh
sh .github/build-shell-scripts.sh [output-directory]
```

The default output directory is `dist/`; the generated files are `skeen` and
`skeen_ru`. The build checks each artifact with `sh -n`. To run the minifier
tests:

```sh
cd tools/shell-minifier
go test ./...
```

The minifier itself reads formatted shell source from standard input and writes
the transformed source to standard output. Transformation statistics go to
standard error. The tool requires Go 1.26 or newer.
