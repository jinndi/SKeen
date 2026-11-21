package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"regexp"
	"sort"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

type edit struct {
	start int
	end   int
	value string
}

type symbol struct {
	name      string
	positions []edit
	protected bool
}

var shellName = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`)

var protectedNames = map[string]bool{
	"ACTION": true, "AUTO": true, "CALLER": true, "HOME": true, "IFS": true,
	"MIRROR": true,
	"OPTARG": true, "OPTIND": true, "PATH": true, "PWD": true, "RANDOM": true,
	"SHELL": true, "SECONDS": true, "UID": true, "EUID": true, "PPID": true,
	"FORCE_COLOR": true,
}

func main() {
	if err := run(os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(input io.Reader, output, diagnostics io.Writer) error {
	source, err := io.ReadAll(input)
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	minified, stats, err := minify(source)
	if err != nil {
		return err
	}
	if _, err := output.Write(minified); err != nil {
		return fmt.Errorf("write output: %w", err)
	}
	fmt.Fprintf(diagnostics, "symbols shortened: %d; bytes saved: %d (%d -> %d)\n",
		stats.symbols, stats.bytesSaved, len(source), len(minified))
	return nil
}

type minifyStats struct {
	symbols    int
	bytesSaved int
}

func minify(source []byte) ([]byte, minifyStats, error) {
	file, err := syntax.NewParser(syntax.Variant(syntax.LangPOSIX)).
		Parse(bytes.NewReader(source), "skeen")
	if err != nil {
		return nil, minifyStats{}, fmt.Errorf("parse POSIX shell: %w", err)
	}

	functions := make(map[string]*symbol)
	variables := make(map[string]*symbol)
	var literals []*syntax.Lit
	var functionDecls []*syntax.FuncDecl
	commandWords := make(map[int]bool)
	protectedAssignments := make(map[string]bool)
	var opaqueStrings []string
	indirectExpansion := false

	addPosition := func(target map[string]*symbol, name string, start, end uint) {
		if !shellName.MatchString(name) || protectedNames[name] {
			return
		}
		entry := target[name]
		if entry == nil {
			entry = &symbol{name: name}
			target[name] = entry
		}
		entry.positions = append(entry.positions, edit{
			start: int(start),
			end:   int(end),
		})
	}
	syntax.Walk(file, func(node syntax.Node) bool {
		switch n := node.(type) {
		case *syntax.Lit:
			literals = append(literals, n)
		case *syntax.SglQuoted:
			opaqueStrings = append(opaqueStrings, n.Value)
		case *syntax.FuncDecl:
			functionDecls = append(functionDecls, n)
			if n.Name != nil {
				addPosition(functions, n.Name.Value, n.Name.ValuePos.Offset(), n.Name.ValueEnd.Offset())
			}
		case *syntax.CallExpr:
			if len(n.Args) > 0 {
				if lit, ok := simpleLiteral(n.Args[0]); ok {
					commandWords[int(lit.ValuePos.Offset())] = true
				}
			}
			if len(n.Args) > 0 {
				for _, assignment := range n.Assigns {
					if assignment.Name != nil {
						protectedAssignments[assignment.Name.Value] = true
					}
				}
			}
		case *syntax.ParamExp:
			if n.Excl {
				indirectExpansion = true
			}
		}
		return true
	})

	// Global assignments remain unchanged. Top-level readonly declarations are
	// immutable constants, so their declarations and static references can be
	// renamed as a unit unless another guard detects dynamic use.
	readonlyNames := make(map[string]bool)
	for _, stmt := range file.Stmts {
		if stmt.Negated || stmt.Background || len(stmt.Redirs) != 0 {
			continue
		}
		call, ok := stmt.Cmd.(*syntax.CallExpr)
		if !ok || len(call.Args) == 0 || len(call.Assigns) != 0 ||
			call.Args[0].Lit() != "readonly" {
			continue
		}
		addDeclaredWords(variables, call.Args[1:], func(target map[string]*symbol, name string, start, end uint) {
			readonlyNames[name] = true
			addPosition(target, name, start, end)
		})
	}
	if len(readonlyNames) > 0 {
		syntax.Walk(file, func(node syntax.Node) bool {
			switch n := node.(type) {
			case *syntax.ParamExp:
				if n.Param != nil && readonlyNames[n.Param.Value] {
					addPosition(variables, n.Param.Value, n.Param.ValuePos.Offset(), n.Param.ValueEnd.Offset())
				}
			case *syntax.ArithmExp:
				addArithmeticNames(n.X, func(target map[string]*symbol, name string, start, end uint) {
					if readonlyNames[name] {
						addPosition(target, name, start, end)
					}
				}, variables)
			}
			return true
		})
	}

	// Only rename locals declared at the start of a function body. Globals and
	// locals introduced conditionally are outside the transform's safe scope.
	for _, function := range functionDecls {
		block, ok := function.Body.Cmd.(*syntax.Block)
		if !ok {
			continue
		}
		localNames := make(map[string]bool)
		for _, stmt := range block.Stmts {
			if stmt.Negated || stmt.Background || len(stmt.Redirs) != 0 {
				break
			}
			call, ok := stmt.Cmd.(*syntax.CallExpr)
			if !ok || len(call.Args) == 0 || len(call.Assigns) != 0 ||
				call.Args[0].Lit() != "local" {
				break
			}
			addDeclaredWords(variables, call.Args[1:], func(target map[string]*symbol, name string, start, end uint) {
				localNames[name] = true
				addPosition(target, name, start, end)
			})
			for _, word := range call.Args[1:] {
				literal, ok := firstLiteral(word)
				if !ok {
					continue
				}
				match := localAssignment.FindStringSubmatchIndex(literal.Value)
				if match == nil {
					continue
				}
				name := literal.Value[match[2]:match[3]]
				if hasIdentifier(literal.Value[match[1]:], name) {
					if entry := variables[name]; entry != nil {
						entry.protected = true
					}
				}
			}
		}
		if len(localNames) == 0 {
			continue
		}

		hasEval := false
		syntax.Walk(function.Body, func(node syntax.Node) bool {
			if _, nested := node.(*syntax.FuncDecl); nested {
				return false
			}
			switch n := node.(type) {
			case *syntax.CallExpr:
				if len(n.Args) > 0 && n.Args[0].Lit() == "eval" {
					hasEval = true
				}
			case *syntax.Assign:
				if n.Name != nil && localNames[n.Name.Value] {
					addPosition(variables, n.Name.Value, n.Name.ValuePos.Offset(), n.Name.ValueEnd.Offset())
				}
			case *syntax.ParamExp:
				if n.Param != nil && localNames[n.Param.Value] {
					addPosition(variables, n.Param.Value, n.Param.ValuePos.Offset(), n.Param.ValueEnd.Offset())
				}
			case *syntax.ArithmExp:
				addArithmeticNames(n.X, func(target map[string]*symbol, name string, start, end uint) {
					if localNames[name] {
						addPosition(target, name, start, end)
					}
				}, variables)
			case *syntax.ForClause:
				if loop, ok := n.Loop.(*syntax.WordIter); ok && loop.Name != nil &&
					localNames[loop.Name.Value] {
					addPosition(variables, loop.Name.Value, loop.Name.ValuePos.Offset(), loop.Name.ValueEnd.Offset())
				}
			}
			return true
		})

		for name := range localNames {
			if entry := variables[name]; entry != nil &&
				(hasEval || indirectExpansion || protectedAssignments[name]) {
				entry.protected = true
			}
		}
	}

	// A function name is only changed when every textual occurrence is a
	// declaration or a statically identifiable call. This keeps generated
	// hooks, string-based dispatch, and other indirect references untouched.
	functionCallPositions := make(map[string][]edit)
	syntax.Walk(file, func(node syntax.Node) bool {
		call, ok := node.(*syntax.CallExpr)
		if !ok || len(call.Args) == 0 {
			return true
		}
		lit, ok := simpleLiteral(call.Args[0])
		if !ok {
			return true
		}
		if _, declared := functions[lit.Value]; declared {
			functionCallPositions[lit.Value] = append(functionCallPositions[lit.Value], edit{
				start: int(lit.ValuePos.Offset()),
				end:   int(lit.ValueEnd.Offset()),
			})
		}
		return true
	})

	for name, entry := range functions {
		calls := functionCallPositions[name]
		if len(calls) == 0 {
			entry.protected = true
			continue
		}
		entry.positions = append(entry.positions, calls...)
	}

	allowedVariablePositions := make(map[string]map[int]bool)
	for name, entry := range variables {
		allowedVariablePositions[name] = make(map[int]bool, len(entry.positions))
		for _, position := range entry.positions {
			allowedVariablePositions[name][position.start] = true
		}
		if protectedAssignments[name] || indirectExpansion {
			entry.protected = true
		}
	}

	allowedFunctionPositions := make(map[string]map[int]bool)
	for name, entry := range functions {
		allowedFunctionPositions[name] = make(map[int]bool, len(entry.positions))
		for _, position := range entry.positions {
			allowedFunctionPositions[name][position.start] = true
		}
	}

	// Names inside single-quoted strings are opaque shell text, not expansions.
	for _, value := range opaqueStrings {
		for name, entry := range variables {
			if !entry.protected && hasIdentifier(value, name) {
				entry.protected = true
			}
		}
		for name, entry := range functions {
			if !entry.protected && hasIdentifier(value, name) {
				entry.protected = true
			}
		}
	}

	for _, literal := range literals {
		start := int(literal.ValuePos.Offset())
		for name, entry := range variables {
			if entry.protected {
				continue
			}
			if commandWords[start] {
				continue
			}
			if hasOpaqueOccurrence(literal, name, allowedVariablePositions[name]) {
				entry.protected = true
			}
		}
		for name, entry := range functions {
			if entry.protected {
				continue
			}
			if hasOpaqueOccurrence(literal, name, allowedFunctionPositions[name]) {
				entry.protected = true
			}
		}
	}

	used := make(map[string]bool)
	for _, literal := range literals {
		for _, name := range identifier.FindAllString(literal.Value, -1) {
			used[name] = true
		}
	}

	edits := make([]edit, 0)
	stats := minifyStats{}
	for _, group := range []struct {
		symbols  map[string]*symbol
		alphabet string
	}{
		{symbols: variables, alphabet: "abcdefghijklmnopqrstuvwxyz"},
		{symbols: functions, alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"},
	} {
		var candidates []*symbol
		for _, entry := range group.symbols {
			if !entry.protected && len(entry.positions) > 0 {
				candidates = append(candidates, entry)
			}
		}
		sort.Slice(candidates, func(i, j int) bool {
			savingI := (len(candidates[i].name) - 1) * len(candidates[i].positions)
			savingJ := (len(candidates[j].name) - 1) * len(candidates[j].positions)
			if savingI == savingJ {
				return candidates[i].name < candidates[j].name
			}
			return savingI > savingJ
		})

		usedAliases := make(map[string]bool, len(used))
		for name := range used {
			usedAliases[name] = true
		}
		aliasIndex := 0
		for _, entry := range candidates {
			alias, next := nextAlias(aliasIndex, usedAliases, group.alphabet)
			if alias == "" {
				break
			}
			aliasIndex = next
			if len(alias) >= len(entry.name) {
				continue
			}
			for _, position := range entry.positions {
				position.value = alias
				edits = append(edits, position)
			}
			stats.symbols++
			stats.bytesSaved += (len(entry.name) - len(alias)) * len(entry.positions)
			usedAliases[alias] = true
		}
	}

	if len(edits) == 0 {
		return append([]byte(nil), source...), stats, nil
	}

	sort.Slice(edits, func(i, j int) bool {
		return edits[i].start > edits[j].start
	})
	result := append([]byte(nil), source...)
	lastStart := len(source) + 1
	for _, position := range edits {
		if position.start < 0 || position.end > len(result) || position.start >= position.end {
			return nil, minifyStats{}, fmt.Errorf("invalid source range for symbol replacement")
		}
		if position.end > lastStart {
			return nil, minifyStats{}, fmt.Errorf("overlapping symbol replacements")
		}
		result = append(result[:position.start],
			append([]byte(position.value), result[position.end:]...)...)
		lastStart = position.start
	}

	if _, err := syntax.NewParser(syntax.Variant(syntax.LangPOSIX)).
		Parse(bytes.NewReader(result), "skeen.min"); err != nil {
		return nil, minifyStats{}, fmt.Errorf("minified output did not parse: %w", err)
	}
	return result, stats, nil
}

func addArithmeticNames(
	expr syntax.ArithmExpr,
	add func(map[string]*symbol, string, uint, uint),
	target map[string]*symbol,
) {
	switch expr := expr.(type) {
	case *syntax.Word:
		if len(expr.Parts) == 1 {
			if literal, ok := expr.Parts[0].(*syntax.Lit); ok {
				add(target, literal.Value, literal.ValuePos.Offset(), literal.ValueEnd.Offset())
			}
		}
	case *syntax.BinaryArithm:
		addArithmeticNames(expr.X, add, target)
		addArithmeticNames(expr.Y, add, target)
	case *syntax.UnaryArithm:
		addArithmeticNames(expr.X, add, target)
	case *syntax.ParenArithm:
		addArithmeticNames(expr.X, add, target)
	}
}

func simpleLiteral(word *syntax.Word) (*syntax.Lit, bool) {
	if word == nil || len(word.Parts) != 1 {
		return nil, false
	}
	literal, ok := word.Parts[0].(*syntax.Lit)
	return literal, ok
}

func addDeclaredWords(
	target map[string]*symbol,
	words []*syntax.Word,
	add func(map[string]*symbol, string, uint, uint),
) {
	for _, word := range words {
		literal, ok := firstLiteral(word)
		if !ok || strings.HasPrefix(literal.Value, "-") {
			continue
		}
		match := localAssignment.FindStringSubmatchIndex(literal.Value)
		if match == nil {
			continue
		}
		name := literal.Value[match[2]:match[3]]
		start := literal.ValuePos.Offset() + uint(match[2])
		add(target, name, start, start+uint(len(name)))
	}
}

func firstLiteral(word *syntax.Word) (*syntax.Lit, bool) {
	if word == nil || len(word.Parts) == 0 {
		return nil, false
	}
	literal, ok := word.Parts[0].(*syntax.Lit)
	return literal, ok
}

func hasOpaqueOccurrence(literal *syntax.Lit, name string, allowed map[int]bool) bool {
	for start := 0; start < len(literal.Value); {
		index := strings.Index(literal.Value[start:], name)
		if index < 0 {
			return false
		}
		index += start
		end := index + len(name)
		if isIdentifierBoundary(literal.Value, index, end) {
			position := int(literal.ValuePos.Offset()) + index
			if !allowed[position] {
				return true
			}
		}
		start = end
	}
	return false
}

func hasIdentifier(value, name string) bool {
	for start := 0; start < len(value); {
		index := strings.Index(value[start:], name)
		if index < 0 {
			return false
		}
		index += start
		end := index + len(name)
		if isIdentifierBoundary(value, index, end) {
			return true
		}
		start = end
	}
	return false
}

func isIdentifierBoundary(value string, start, end int) bool {
	isIdentifierByte := func(b byte) bool {
		return b == '_' || b >= 'a' && b <= 'z' || b >= 'A' && b <= 'Z' || b >= '0' && b <= '9'
	}
	return (start == 0 || !isIdentifierByte(value[start-1])) &&
		(end == len(value) || !isIdentifierByte(value[end]))
}

func nextAlias(index int, used map[string]bool, alphabet string) (string, int) {
	base := len(alphabet)
	for i := index; i < base*base*base*base; i++ {
		alias, ok := encodeAlias(i, alphabet)
		if ok && !used[alias] && !shellKeyword[alias] {
			return alias, i + 1
		}
	}
	return "", index
}

func encodeAlias(index int, alphabet string) (string, bool) {
	base := len(alphabet)
	for length := 1; length <= 4; length++ {
		capacity := 1
		for i := 0; i < length; i++ {
			capacity *= base
		}
		if index >= capacity {
			index -= capacity
			continue
		}
		result := make([]byte, length)
		for i := length - 1; i >= 0; i-- {
			result[i] = alphabet[index%base]
			index /= base
		}
		return string(result), true
	}
	return "", false
}

var localAssignment = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_]*)(?:\+?=|$)`)

var identifier = regexp.MustCompile(`[A-Za-z_][A-Za-z0-9_]*`)

var shellKeyword = map[string]bool{
	"case": true, "do": true, "done": true, "elif": true, "else": true,
	"esac": true, "fi": true, "for": true, "function": true, "if": true,
	"in": true, "then": true, "time": true, "until": true, "while": true,
}
