package main

import (
	"bytes"
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestMinifyPreservesBehavior(t *testing.T) {
	source := []byte(`#!/bin/sh
readonly LONG_CONSTANT="hello"
LONG_VALUE="${LONG_CONSTANT}-world"
say_long() {
  printf '%s\n' "$LONG_VALUE"
}
say_long
`)

	minified, stats, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if stats.symbols == 0 {
		t.Fatal("expected at least one symbol to be shortened")
	}
	if strings.Contains(string(minified), "LONG_CONSTANT") {
		t.Fatalf("readonly constant was not shortened: %s", minified)
	}

	want := runShell(t, source)
	got := runShell(t, minified)
	if !bytes.Equal(got, want) {
		t.Fatalf("minified output differs:\nwant %q\ngot  %q", want, got)
	}
}

func TestMinifyPreservesArithmeticVariableReferences(t *testing.T) {
	source := []byte(`#!/bin/sh
increment_long() {
  local LONG_COUNTER=0
  LONG_COUNTER=$((LONG_COUNTER + 1))
  printf '%s\n' "$LONG_COUNTER"
}
increment_long
`)

	minified, stats, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if stats.symbols == 0 {
		t.Fatal("expected arithmetic variable to be shortened")
	}
	if strings.Contains(string(minified), "LONG_COUNTER") {
		t.Fatalf("local arithmetic variable was not shortened: %s", minified)
	}
	if got, want := runBash(t, minified), runBash(t, source); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyDoesNotRenameGlobalsOrLateLocals(t *testing.T) {
	source := []byte(`#!/bin/sh
GLOBAL_VALUE="global"
show_values() {
  printf '%s\n' "$GLOBAL_VALUE"
  local LATE_VALUE="late"
  printf '%s\n' "$LATE_VALUE"
}
show_values
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"GLOBAL_VALUE", "LATE_VALUE"} {
		if !strings.Contains(string(minified), name) {
			t.Fatalf("non-local variable %s was renamed: %s", name, minified)
		}
	}
	if got, want := runBash(t, minified), runBash(t, source); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyRenamesStaticallyCalledFunctionsWithEvalPresent(t *testing.T) {
	source := []byte(`#!/bin/sh
long_function_name() { printf '%s\n' "ok"; }
long_function_name
eval 'OTHER_VALUE=1'
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(minified), "long_function_name") {
		t.Fatalf("statically called function was not renamed: %s", minified)
	}
	if got, want := runBash(t, minified), runBash(t, source); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyProtectsFunctionNamesUsedInEvalText(t *testing.T) {
	source := []byte(`#!/bin/sh
long_function_name() { printf '%s\n' "ok"; }
long_function_name
eval 'long_function_name'
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(minified), "long_function_name") {
		t.Fatalf("function referenced by eval text was renamed: %s", minified)
	}
	if got, want := runBash(t, minified), runBash(t, source); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyProtectsReadonlyConstantsUsedInEvalText(t *testing.T) {
	source := []byte(`#!/bin/sh
readonly LONG_CONSTANT="ok"
eval 'printf "%s\n" "$LONG_CONSTANT"'
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(minified), "LONG_CONSTANT") {
		t.Fatalf("readonly constant used by eval was renamed: %s", minified)
	}
	if got, want := runBash(t, minified), runBash(t, source); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyProtectsSelfReferentialLocalInitializer(t *testing.T) {
	source := []byte(`#!/bin/sh
VALUE="outer"
read_value() {
  local VALUE="$VALUE"
  printf '%s\n' "$VALUE"
}
read_value
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(minified), `local VALUE="$VALUE"`) {
		t.Fatalf("self-referential local initializer was renamed: %s", minified)
	}
	if got, want := runBash(t, minified), runBash(t, source); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyPreservesEnvironmentVariables(t *testing.T) {
	source := []byte(`#!/bin/sh
LOCAL_VALUE="enabled"
if [ "${FORCE_COLOR:-0}" = "1" ] && [ "${EXTERNAL_VALUE:-0}" = "1" ]; then
  printf '%s\n' "$LOCAL_VALUE"
fi
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"FORCE_COLOR", "EXTERNAL_VALUE"} {
		if !strings.Contains(string(minified), name) {
			t.Fatalf("environment variable %s was renamed: %s", name, minified)
		}
	}

	env := []string{"FORCE_COLOR=1", "EXTERNAL_VALUE=1"}
	if got, want := runShellWithEnv(t, minified, env...), runShellWithEnv(t, source, env...); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyPreservesInstallerEnvironmentVariables(t *testing.T) {
	source := []byte(`#!/bin/sh
AUTO="${AUTO:-}"
MIRROR="${MIRROR:-}"
printf '%s|%s\n' "$AUTO" "$MIRROR"
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"AUTO", "MIRROR"} {
		if !strings.Contains(string(minified), name) {
			t.Fatalf("installer environment variable %s was renamed: %s", name, minified)
		}
	}

	env := []string{"AUTO=2", "MIRROR=https://mirror.example/"}
	if got, want := runShellWithEnv(t, minified, env...), runShellWithEnv(t, source, env...); !bytes.Equal(got, want) {
		t.Fatalf("output changed: got %q, want %q", got, want)
	}
}

func TestMinifyProtectsOpaqueStringReferences(t *testing.T) {
	source := []byte(`#!/bin/sh
readonly LONG_VALUE="hello"
printf '%s\n' "$LONG_VALUE"
printf '%s\n' 'LONG_VALUE'
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(minified), "LONG_VALUE") {
		t.Fatalf("opaque string reference was renamed: %s", minified)
	}
	if got := runShell(t, minified); !bytes.Equal(got, runShell(t, source)) {
		t.Fatalf("output changed: got %q, want %q", got, runShell(t, source))
	}
}

func TestMinifyProtectsCommandEnvironmentAssignments(t *testing.T) {
	source := []byte(`#!/bin/sh
LONG_VALUE=hello env | grep '^LONG_VALUE='
`)

	minified, _, err := minify(source)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(minified), "LONG_VALUE") {
		t.Fatalf("command environment variable was renamed: %s", minified)
	}
}

func runShell(t *testing.T, source []byte) []byte {
	return runShellWithEnv(t, source)
}

func runBash(t *testing.T, source []byte) []byte {
	t.Helper()
	command := exec.Command("bash")
	command.Stdin = bytes.NewReader(source)
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("run bash: %v\n%s", err, output)
	}
	return output
}

func runShellWithEnv(t *testing.T, source []byte, env ...string) []byte {
	t.Helper()
	command := exec.Command("sh")
	command.Stdin = bytes.NewReader(source)
	command.Env = append(os.Environ(), env...)
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("run shell: %v\n%s", err, output)
	}
	return output
}
