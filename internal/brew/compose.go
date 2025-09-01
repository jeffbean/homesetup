package brew

import (
    "fmt"
    "io"
    "os"
    "path/filepath"
    "time"
)

// ComposeBrewfile creates a composed Brewfile with profile extras if present.
// Returns the composed path (or empty string if only base Brewfile is used).
func ComposeBrewfile(repoRoot, profile string, ts time.Time) (string, error) {
    base := filepath.Join(repoRoot, "Brewfile")
    extras := filepath.Join(repoRoot, "config", "profiles", profile, "Brewfile.extra")
    if _, err := os.Stat(extras); err != nil {
        // extras not present; nothing to compose
        return "", nil
    }
    outDir := filepath.Join(repoRoot, "snapshots", "logs")
    _ = os.MkdirAll(outDir, 0o755)
    out := filepath.Join(outDir, fmt.Sprintf("Brewfile.composed.%s", ts.Format("20060102-150405")))
    bf, err := os.Open(base)
    if err != nil {
        return "", err
    }
    defer bf.Close()
    ef, err := os.Open(extras)
    if err != nil {
        return "", err
    }
    defer ef.Close()

    of, err := os.Create(out)
    if err != nil {
        return "", err
    }
    defer of.Close()

    if _, err := io.Copy(of, bf); err != nil {
        return "", err
    }
    if _, err := of.WriteString("\n# --- Profile: " + profile + " extras ---\n"); err != nil {
        return "", err
    }
    if _, err := io.Copy(of, ef); err != nil {
        return "", err
    }
    return out, nil
}

