package actions

import (
    "os"
    "os/exec"
    "path/filepath"
    "log/slog"
)

func brewfile() string {
	if bf := os.Getenv("HS_BREWFILE"); bf != "" {
		return bf
	}
	return filepath.Join("config", "Brewfile")
}

func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func Plan() error {
    bf := brewfile()
    if _, err := os.Stat(bf); err == nil {
        if err := run("brew", "bundle", "check", "--file="+bf); err != nil {
            slog.Warn("brew bundle check failed", slog.String("file", bf), slog.Any("err", err))
        } else {
            slog.Info("brew bundle check", slog.String("file", bf))
        }
    } else {
        slog.Warn("Brewfile not found", slog.String("file", bf))
    }

    if _, err := exec.LookPath("stow"); err == nil {
        if _, err := os.Stat("dotfiles"); err == nil {
            entries, rerr := os.ReadDir("dotfiles")
            if rerr != nil {
                slog.Error("read dotfiles dir", slog.Any("err", rerr))
                return rerr
            }
            for _, e := range entries {
                if e.IsDir() {
                    pkg := e.Name()
                    slog.Info("stow preview", slog.String("package", pkg))
                    if err := run("stow", "-nvt", os.Getenv("HOME"), "-d", "dotfiles", pkg); err != nil {
                        slog.Warn("stow preview failed", slog.String("package", pkg), slog.Any("err", err))
                    }
                }
            }
        } else {
            slog.Warn("dotfiles directory not found")
        }
    } else {
        slog.Warn("stow not installed (brew install stow)")
    }
    return nil
}
