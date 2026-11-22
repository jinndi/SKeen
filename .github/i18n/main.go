package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"regexp"
	"sort"
	"strings"
)

var (
	markerPattern     = regexp.MustCompile(`--([A-Z][A-Z0-9_]*)--`)
	templatePattern   = regexp.MustCompile(`\{([A-Za-z_][A-Za-z0-9_]*|[0-9]+)\}`)
	invalidTemplate   = regexp.MustCompile(`\{[^{}]*(?:\}|$)|\}`)
	shellVariableName = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_]*|[0-9]+)$`)
	validKey          = regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)
)

type catalog map[string]map[string]string

func main() {
	inputPath := flag.String("input", "", "shell template to compile")
	catalogPath := flag.String("catalog", "", "translation catalog JSON")
	locale := flag.String("locale", "", "locale to compile")
	flag.Parse()

	if *inputPath == "" || *catalogPath == "" || *locale == "" {
		fmt.Fprintln(os.Stderr, "usage: go run . -input TEMPLATE -catalog CATALOG -locale LOCALE")
		os.Exit(2)
	}
	if err := compile(*inputPath, *catalogPath, *locale, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func compile(inputPath, catalogPath, locale string, output io.Writer) error {
	source, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("read shell template: %w", err)
	}
	catalogBytes, err := os.ReadFile(catalogPath)
	if err != nil {
		return fmt.Errorf("read translation catalog: %w", err)
	}
	var messages catalog
	decoder := json.NewDecoder(bytes.NewReader(catalogBytes))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&messages); err != nil {
		return fmt.Errorf("parse translation catalog: %w", err)
	}
	if err := ensureJSONEOF(decoder); err != nil {
		return err
	}
	if err := validateCatalog(messages); err != nil {
		return err
	}

	compiled, err := compileSource(source, messages, locale)
	if err != nil {
		return err
	}
	if _, err := output.Write(compiled); err != nil {
		return fmt.Errorf("write compiled shell script: %w", err)
	}
	return nil
}

func validateCatalog(messages catalog) error {
	for key, locales := range messages {
		if !validKey.MatchString(key) {
			return fmt.Errorf("invalid translation key %q: keys must match UPPER_SNAKE_CASE", key)
		}
		if len(locales) == 0 {
			return fmt.Errorf("translation %q has no locale values", key)
		}
		for locale, text := range locales {
			if strings.TrimSpace(locale) == "" {
				return fmt.Errorf("translation %q has an empty locale name", key)
			}
			if text == "" {
				return fmt.Errorf("translation %q is empty for locale %q", key, locale)
			}
			if _, err := shellExpression(text); err != nil {
				return fmt.Errorf("translation %q (%s): %w", key, locale, err)
			}
		}
	}
	return nil
}

func ensureJSONEOF(decoder *json.Decoder) error {
	var extra any
	if err := decoder.Decode(&extra); !errors.Is(err, io.EOF) {
		if err == nil {
			return fmt.Errorf("parse translation catalog: multiple JSON values")
		}
		return fmt.Errorf("parse translation catalog: %w", err)
	}
	return nil
}

func compileSource(source []byte, messages catalog, locale string) ([]byte, error) {
	used := make(map[string]bool)
	var firstErr error
	compiled := markerPattern.ReplaceAllFunc(source, func(token []byte) []byte {
		match := markerPattern.FindSubmatch(token)
		key := string(match[1])
		used[key] = true
		byLocale, exists := messages[key]
		if !exists {
			if firstErr == nil {
				firstErr = fmt.Errorf("translation key %s is missing from catalog", key)
			}
			return token
		}
		text, exists := byLocale[locale]
		if !exists {
			if firstErr == nil {
				firstErr = fmt.Errorf("translation %q is missing for locale %q", key, locale)
			}
			return token
		}
		contents, err := shellDoubleQuotedContents(text)
		if strings.HasPrefix(key, "AWK_") {
			contents, err = awkDoubleQuotedContents(text)
		}
		if err != nil {
			if firstErr == nil {
				firstErr = fmt.Errorf("translation %q: %w", key, err)
			}
			return token
		}
		return []byte(contents)
	})
	if firstErr != nil {
		return nil, firstErr
	}

	var unused []string
	for key := range messages {
		if !used[key] {
			unused = append(unused, key)
		}
	}
	if len(unused) > 0 {
		sort.Strings(unused)
		return nil, fmt.Errorf("catalog contains unused translation keys: %s", strings.Join(unused, ", "))
	}
	return compiled, nil
}

func awkExpression(text string) (string, error) {
	contents, err := awkDoubleQuotedContents(text)
	if err != nil {
		return "", err
	}
	return `"` + contents + `"`, nil
}

func awkDoubleQuotedContents(text string) (string, error) {
	if templatePattern.MatchString(text) || invalidTemplate.MatchString(text) {
		return "", fmt.Errorf("awk messages cannot contain shell placeholders")
	}
	text = strings.ReplaceAll(text, `\`, `\\`)
	text = strings.ReplaceAll(text, `"`, `\"`)
	text = strings.ReplaceAll(text, "\n", `\n`)
	return text, nil
}

func shellDoubleQuotedContents(text string) (string, error) {
	var result strings.Builder
	matches := templatePattern.FindAllStringSubmatchIndex(text, -1)
	last := 0
	for _, match := range matches {
		literal := text[last:match[0]]
		if invalidTemplate.MatchString(literal) {
			return "", fmt.Errorf("malformed template placeholder in %q", text)
		}
		writeShellLiteral(&result, literal)

		name := text[match[2]:match[3]]
		if !shellVariableName.MatchString(name) {
			return "", fmt.Errorf("invalid placeholder {%s}", name)
		}
		result.WriteString("${")
		result.WriteString(name)
		result.WriteByte('}')
		last = match[1]
	}
	literal := text[last:]
	if invalidTemplate.MatchString(literal) {
		return "", fmt.Errorf("malformed template placeholder in %q", text)
	}
	writeShellLiteral(&result, literal)
	return result.String(), nil
}

func writeShellLiteral(result *strings.Builder, text string) {
	for _, r := range text {
		switch r {
		case '\\', '"', '$', '`':
			result.WriteByte('\\')
		}
		result.WriteRune(r)
	}
}

// shellExpression emits a safely quoted POSIX-shell expression. Named
// placeholders are runtime shell-variable expansions; all other input remains
// literal text.
func shellExpression(text string) (string, error) {
	var result strings.Builder
	var literal strings.Builder
	flushLiteral := func() {
		if literal.Len() == 0 {
			return
		}
		result.WriteByte('"')
		for _, r := range literal.String() {
			switch r {
			case '\\', '"', '$', '`':
				result.WriteByte('\\')
			}
			result.WriteRune(r)
		}
		result.WriteByte('"')
		literal.Reset()
	}

	matches := templatePattern.FindAllStringSubmatchIndex(text, -1)
	last := 0
	for _, match := range matches {
		literal.WriteString(text[last:match[0]])
		name := text[match[2]:match[3]]
		if !shellVariableName.MatchString(name) {
			return "", fmt.Errorf("invalid placeholder {%s}", name)
		}
		flushLiteral()
		result.WriteString("${")
		result.WriteString(name)
		result.WriteByte('}')
		last = match[1]
	}
	literal.WriteString(text[last:])
	if invalidTemplate.MatchString(literal.String()) {
		return "", fmt.Errorf("malformed template placeholder in %q", text)
	}
	flushLiteral()
	if result.Len() == 0 {
		return `""`, nil
	}
	return result.String(), nil
}
