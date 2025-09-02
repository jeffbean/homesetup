package actions

import (
    "os"
    "os/exec"
    "path/filepath"
    "log/slog"
)

func ApplyDotfiles() error {
    if _, err := exec.LookPath("stow"); err != nil {
        return err
    }
    if _, err := os.Stat("dotfiles"); err != nil {
        return err
    }
    entries, rerr := os.ReadDir("dotfiles")
    if rerr != nil {
        return rerr
    }
    for _, e := range entries {
        if e.IsDir() {
            pkg := e.Name()
            slog.Info("stowing", slog.String("package", pkg))
            if err := run("stow", "--no-folding", "-d", "dotfiles", "-vt", os.Getenv("HOME"), pkg); err != nil {
                slog.Error("stow failed", slog.String("package", pkg), slog.Any("err", err))
                return err
            }
        }
    }
    return nil
}

func Apply() error {
    if err := ApplyDotfiles(); err != nil {
        return err
    }
    if _, err := exec.LookPath("tmux"); err == nil {
        if err := run("tmux", "source-file", filepath.Join(os.Getenv("HOME"), ".tmux.conf")); err != nil {
            slog.Warn("tmux reload failed", slog.Any("err", err))
        } else {
            slog.Info("tmux reloaded")
        }
    } else {
        slog.Info("tmux not found; skip reload")
    }
    // Try to reload Oh My Zsh in a fresh zsh instance
    if _, err := exec.LookPath("zsh"); err == nil {
        if err := exec.Command("zsh", "-ic", "omz reload").Run(); err != nil {
            slog.Warn("omz reload failed", slog.Any("err", err))
        } else {
            slog.Info("omz reloaded")
        }
    } else {
        slog.Info("zsh not found; skip omz reload")
    }
    slog.Info("dotfiles stowed")
    return nil
}
