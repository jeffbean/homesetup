package actions

import (
    "os"
    "os/exec"
    "log/slog"
)

func BrewInstall() error {
    if _, err := exec.LookPath("brew"); err != nil {
        return err
    }
    bf := brewfile()
    if _, err := os.Stat(bf); err != nil {
        return err
    }
    if err := run("brew", "bundle", "--file="+bf); err != nil {
        slog.Error("brew bundle failed", slog.String("file", bf), slog.Any("err", err))
        return err
    }
    slog.Info("brew bundle applied", slog.String("file", bf))
    return nil
}
