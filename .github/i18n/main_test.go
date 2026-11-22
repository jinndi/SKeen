package main

import (
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestCompileSourceReplacesWholeMessagesAndTemplates(t *testing.T) {
	source := []byte(`#!/bin/sh
echo "--HELLO--"
`)
	messages := catalog{
		"HELLO": {
			"en": "Hello {name}!",
			"ru": "Привет, {name}!",
		},
	}
	got, err := compileSource(source, messages, "ru")
	if err != nil {
		t.Fatal(err)
	}
	want := `#!/bin/sh
echo "Привет, ${name}!"
`
	if string(got) != want {
		t.Fatalf("compiled source mismatch:\nwant: %q\ngot:  %q", want, got)
	}
}

func TestCompileSourceRequiresEveryLocaleValue(t *testing.T) {
	_, err := compileSource([]byte("echo \"--HELLO--\"\n"), catalog{
		"HELLO": {"en": "Hello"},
	}, "ru")
	if err == nil || !strings.Contains(err.Error(), `translation "HELLO" is missing for locale "ru"`) {
		t.Fatalf("expected missing locale error, got %v", err)
	}
}

func TestCompileSourceRejectsMissingCatalogKey(t *testing.T) {
	_, err := compileSource([]byte("echo \"--UNKNOWN--\"\n"), catalog{}, "en")
	if err == nil || !strings.Contains(err.Error(), "UNKNOWN") {
		t.Fatalf("expected missing key error, got %v", err)
	}
}

func TestCompileSourceRejectsUnusedCatalogKey(t *testing.T) {
	_, err := compileSource([]byte("echo ok\n"), catalog{
		"UNUSED": {"en": "unused"},
	}, "en")
	if err == nil || !strings.Contains(err.Error(), "unused translation keys") {
		t.Fatalf("expected unused key error, got %v", err)
	}
}

func TestShellExpressionEscapesMetacharacters(t *testing.T) {
	expression, err := shellExpression(`price $5; "quoted" \ path`)
	if err != nil {
		t.Fatal(err)
	}
	if expression != `"price \$5; \"quoted\" \\ path"` {
		t.Fatalf("unexpected shell expression: %s", expression)
	}
}

func TestShellExpressionRejectsMalformedPlaceholder(t *testing.T) {
	if _, err := shellExpression("Broken {name"); err == nil {
		t.Fatal("expected malformed placeholder error")
	}
}

func TestAwkExpressionQuotesLiteralText(t *testing.T) {
	got, err := awkExpression(`Peer said "hello"\today`)
	if err != nil {
		t.Fatal(err)
	}
	if want := `"Peer said \"hello\"\\today"`; got != want {
		t.Fatalf("unexpected awk expression:\nwant %s\ngot  %s", want, got)
	}
}

func TestCompileSourcePreservesQuotedAwkMessages(t *testing.T) {
	source := []byte(`awk 'BEGIN { m="--AWK_HELLO--"; print m }'`)
	got, err := compileSource(source, catalog{
		"AWK_HELLO": {
			"en": `Peer said "hello"\today`,
			"ru": `Сказали "привет"\сегодня`,
		},
	}, "ru")
	if err != nil {
		t.Fatal(err)
	}
	want := `awk 'BEGIN { m="Сказали \"привет\"\\сегодня"; print m }'`
	if string(got) != want {
		t.Fatalf("compiled source mismatch:\nwant: %q\ngot:  %q", want, got)
	}
}

func TestCompileSourceEmitsHookCommandWithoutEscapingItsOutput(t *testing.T) {
	source := []byte(`SKEEN_NAME=SKeen
echo "--LOGGER_UPDATE--"
`)
	messages := catalog{
		"LOGGER_UPDATE": {
			"en": `logger -p notice -t "{SKEEN_NAME}" "Updating $type rules for $table table"`,
			"ru": `logger -p notice -t "{SKEEN_NAME}" "Обновление $type правил $table таблицы"`,
		},
	}
	compiled, err := compileSource(source, messages, "ru")
	if err != nil {
		t.Fatal(err)
	}

	cmd := exec.Command("/bin/sh", "-c", string(compiled))
	cmd.Env = []string{"PATH=" + os.Getenv("PATH")}
	output, err := cmd.Output()
	if err != nil {
		t.Fatalf("run compiled shell snippet: %v", err)
	}
	want := "logger -p notice -t \"SKeen\" \"Обновление $type правил $table таблицы\"\n"
	if string(output) != want {
		t.Fatalf("hook output mismatch:\nwant: %q\ngot:  %q", want, output)
	}
}

func TestCompileSourceEmitsQuotedPlaceholderWithoutBackslashes(t *testing.T) {
	source := []byte(`opkgtun_desc=wan0
echo "--INTERFACE_EXISTS--"
`)
	compiled, err := compileSource(source, catalog{
		"INTERFACE_EXISTS": {
			"en": `Interface named '{opkgtun_desc}' already exists`,
			"ru": `Интерфейс с именем '{opkgtun_desc}' уже существует`,
		},
	}, "ru")
	if err != nil {
		t.Fatal(err)
	}

	cmd := exec.Command("/bin/sh", "-c", string(compiled))
	cmd.Env = []string{"PATH=" + os.Getenv("PATH")}
	output, err := cmd.Output()
	if err != nil {
		t.Fatalf("run compiled shell snippet: %v", err)
	}
	want := "Интерфейс с именем 'wan0' уже существует\n"
	if string(output) != want {
		t.Fatalf("message output mismatch:\nwant: %q\ngot:  %q", want, output)
	}
}
