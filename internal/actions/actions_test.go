package actions

import (
    "os"
    "path/filepath"
    "runtime"
    "testing"
)

func TestPlan_NoTools_ReturnsNil(t *testing.T) {
    t.Setenv("PATH", "")
    if err := Plan(); err != nil {
        t.Fatalf("Plan() returned error without tools: %v", err)
    }
}

func TestBrewInstall_NoBrew_ReturnsError(t *testing.T) {
    t.Setenv("PATH", "")
    t.Setenv("HS_BREWFILE", filepath.Join(t.TempDir(), "NoSuch"))
    if err := BrewInstall(); err == nil {
        t.Fatalf("BrewInstall() expected error when brew not present")
    }
}

func TestBrewInstall_WithDummyBrew_Succeeds(t *testing.T) {
    tmp := t.TempDir()
    // create dummy brew file
    brew := filepath.Join(tmp, "brew")
    contents := "#!/bin/sh\n# dummy brew for tests\nexit 0\n"
    if err := os.WriteFile(brew, []byte(contents), 0o755); err != nil {
        t.Fatal(err)
    }
    t.Setenv("PATH", tmp)
    bf := filepath.Join(tmp, "Brewfile")
    if err := os.WriteFile(bf, []byte(""), 0o644); err != nil {
        t.Fatal(err)
    }
    t.Setenv("HS_BREWFILE", bf)
    if err := BrewInstall(); err != nil {
        t.Fatalf("BrewInstall() with dummy brew failed: %v", err)
    }
}

func TestApplyDotfiles_NoStow_ReturnsError(t *testing.T) {
    t.Setenv("PATH", "")
    if err := ApplyDotfiles(); err == nil {
        t.Fatalf("ApplyDotfiles() expected error when stow not present")
    }
}

func TestApplyDotfiles_WithDummyStow_Succeeds(t *testing.T) {
    // Skip on Windows
    if runtime.GOOS == "windows" {
        t.Skip("stow not available on Windows")
    }
    // Ensure we run from repo root (so ./dotfiles exists)
    root := findRepoRoot(t)
    if err := os.Chdir(root); err != nil {
        t.Fatalf("chdir repo root: %v", err)
    }
    tmp := t.TempDir()
    stow := filepath.Join(tmp, "stow")
    contents := "#!/bin/sh\n# dummy stow for tests\nexit 0\n"
    if err := os.WriteFile(stow, []byte(contents), 0o755); err != nil {
        t.Fatal(err)
    }
    t.Setenv("PATH", tmp)
    if err := ApplyDotfiles(); err != nil {
        t.Fatalf("ApplyDotfiles() with dummy stow failed: %v", err)
    }
}

// findRepoRoot walks up until it finds a go.mod and dotfiles directory
func findRepoRoot(t *testing.T) string {
    t.Helper()
    dir, _ := os.Getwd()
    for i := 0; i < 5; i++ {
        if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
            if _, derr := os.Stat(filepath.Join(dir, "dotfiles")); derr == nil {
                return dir
            }
        }
        parent := filepath.Dir(dir)
        if parent == dir { // reached FS root
            break
        }
        dir = parent
    }
    t.Skip("repo root with go.mod and dotfiles not found")
    return ""
}
