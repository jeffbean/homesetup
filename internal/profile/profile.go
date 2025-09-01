package profile

import (
    "bufio"
    "os"
    "path/filepath"
    "strings"
)

// ActiveProfile returns HS_PROFILE from ~/.config/homesetup/profile.env or "base".
func ActiveProfile() string {
    home, _ := os.UserHomeDir()
    envPath := filepath.Join(home, ".config", "homesetup", "profile.env")
    if f, err := os.Open(envPath); err == nil {
        defer f.Close()
        s := bufio.NewScanner(f)
        for s.Scan() {
            line := strings.TrimSpace(s.Text())
            if strings.HasPrefix(line, "#") || len(line) == 0 {
                continue
            }
            if strings.HasPrefix(line, "HS_PROFILE=") {
                v := strings.TrimPrefix(line, "HS_PROFILE=")
                v = strings.Trim(v, "\"'")
                if v != "" {
                    return v
                }
            }
        }
    }
    return "base"
}

