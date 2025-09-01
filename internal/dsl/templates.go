package dsl

import (
    "bytes"
    "embed"
    "io/fs"
    "text/template"
)

//go:embed templates/**
var tmplFS embed.FS

// RenderTemplate renders a named template from the embedded templates dir.
func RenderTemplate(name string, data any) (string, error) {
    // Allow paths without directory
    var content []byte
    var err error
    // First try direct name under templates/
    content, err = fs.ReadFile(tmplFS, "templates/"+name)
    if err != nil {
        // Then try as provided (in case caller passes templates/...)
        content, err = fs.ReadFile(tmplFS, name)
        if err != nil {
            return "", err
        }
    }
    t, err := template.New(name).Parse(string(content))
    if err != nil {
        return "", err
    }
    var buf bytes.Buffer
    if err := t.Execute(&buf, data); err != nil {
        return "", err
    }
    return buf.String(), nil
}

