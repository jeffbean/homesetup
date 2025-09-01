package dsl

import (
    "encoding/json"
    "io/fs"
    "os"
    "path/filepath"
)

type FileSpec struct {
    Path     string            `json:"path"`
    Content  string            `json:"content,omitempty"`
    Template string            `json:"template,omitempty"`
    Data     map[string]string `json:"data,omitempty"`
}

// LoadFilesSpec loads all JSON specs under a directory. Each file may contain
// either an object {"files":[...] } or a top-level array of FileSpec.
func LoadFilesSpec(dir string) ([]FileSpec, error) {
    var specs []FileSpec
    _ = filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
        if err != nil {
            return nil
        }
        if d.IsDir() {
            return nil
        }
        if filepath.Ext(path) != ".json" {
            return nil
        }
        b, err := os.ReadFile(path)
        if err != nil {
            return nil
        }
        // Try array form first
        var arr []FileSpec
        if err := json.Unmarshal(b, &arr); err == nil && arr != nil {
            specs = append(specs, arr...)
            return nil
        }
        // Try object with "files"
        var obj struct{ Files []FileSpec `json:"files"` }
        if err := json.Unmarshal(b, &obj); err == nil && obj.Files != nil {
            specs = append(specs, obj.Files...)
            return nil
        }
        return nil
    })
    return specs, nil
}

type FilePlan struct {
    Path    string
    Content string
    Action  string // create|update|ok
}

func PlanFiles(repoRoot string, specs []FileSpec, profile string) []FilePlan {
    var out []FilePlan
    for _, s := range specs {
        // If a template is provided, render content
        content := s.Content
        if s.Template != "" {
            if s.Data == nil {
                s.Data = map[string]string{}
            }
            // Inject standard keys
            s.Data["Profile"] = profile
            if rendered, err := RenderTemplate(s.Template, s.Data); err == nil {
                content = rendered
            } else {
                // On render error, keep content empty to force create/update with empty content
                content = s.Content
            }
        }
        abs := filepath.Join(repoRoot, s.Path)
        cur, err := os.ReadFile(abs)
        if err != nil {
            out = append(out, FilePlan{Path: s.Path, Content: content, Action: "create"})
            continue
        }
        if string(cur) == content {
            out = append(out, FilePlan{Path: s.Path, Content: content, Action: "ok"})
        } else {
            out = append(out, FilePlan{Path: s.Path, Content: content, Action: "update"})
        }
    }
    return out
}

func ApplyFiles(repoRoot string, plans []FilePlan) error {
    for _, p := range plans {
        if p.Action == "ok" {
            continue
        }
        abs := filepath.Join(repoRoot, p.Path)
        if err := os.MkdirAll(filepath.Dir(abs), 0o755); err != nil {
            return err
        }
        if err := os.WriteFile(abs, []byte(p.Content), 0o644); err != nil {
            return err
        }
    }
    return nil
}
