package desired

import (
    "bufio"
    "os"
    "path/filepath"
    "regexp"
    "sort"
    "strings"
    "time"
)

type MasApp struct{
    ID string
    Name string
}

type Desired struct{
    Formulae []string
    Casks []string
    Mas []MasApp
}

var (
    reBrew = regexp.MustCompile(`^\s*brew\s+"([^"]+)"`)
    reCask = regexp.MustCompile(`^\s*cask\s+"([^"]+)"`)
    reMas  = regexp.MustCompile(`^\s*mas\s+"([^"]+)".*,\s*id:\s*([0-9]+)`) // name then id
)

// ParseBrewfile extracts desired sets from a Brewfile path.
func ParseBrewfile(path string) (Desired, error) {
    f, err := os.Open(path)
    if err != nil { return Desired{}, err }
    defer f.Close()
    var d Desired
    s := bufio.NewScanner(f)
    for s.Scan() {
        line := s.Text()
        if m := reBrew.FindStringSubmatch(line); m != nil { d.Formulae = append(d.Formulae, m[1]); continue }
        if m := reCask.FindStringSubmatch(line); m != nil { d.Casks = append(d.Casks, m[1]); continue }
        if m := reMas.FindStringSubmatch(line); m != nil { d.Mas = append(d.Mas, MasApp{ID: m[2], Name: m[1]}); continue }
    }
    // sort/uniq
    d.Formulae = uniqSorted(d.Formulae)
    d.Casks = uniqSorted(d.Casks)
    sort.Slice(d.Mas, func(i,j int) bool { return d.Mas[i].ID < d.Mas[j].ID })
    d.Mas = uniqMas(d.Mas)
    return d, nil
}

func uniqSorted(xs []string) []string {
    sort.Strings(xs)
    out := xs[:0]
    var prev string
    for i, v := range xs {
        if i == 0 || v != prev {
            out = append(out, v)
            prev = v
        }
    }
    return out
}

func uniqMas(xs []MasApp) []MasApp {
    out := xs[:0]
    var prevID string
    for i, v := range xs {
        if i == 0 || v.ID != prevID {
            out = append(out, v)
            prevID = v.ID
        }
    }
    return out
}

// WriteDesiredSnapshot writes desired sets to snapshots/desired/<timestamp>/
func WriteDesiredSnapshot(repoRoot string, ts time.Time, d Desired) (string, error) {
    dir := filepath.Join(repoRoot, "snapshots", "desired", ts.Format("20060102-150405"))
    if err := os.MkdirAll(dir, 0o755); err != nil { return "", err }
    // formulae
    if err := os.WriteFile(filepath.Join(dir, "desired_brew_formulae.txt"), []byte(strings.Join(d.Formulae, "\n")+"\n"), 0o644); err != nil { return "", err }
    // casks
    if err := os.WriteFile(filepath.Join(dir, "desired_brew_casks.txt"), []byte(strings.Join(d.Casks, "\n")+"\n"), 0o644); err != nil { return "", err }
    // mas apps id \t name
    var b strings.Builder
    for _, m := range d.Mas { b.WriteString(m.ID); b.WriteString("\t"); b.WriteString(m.Name); b.WriteString("\n") }
    if err := os.WriteFile(filepath.Join(dir, "desired_mas_apps.tsv"), []byte(b.String()), 0o644); err != nil { return "", err }
    // create symlink latest -> dir (best-effort)
    latest := filepath.Join(repoRoot, "snapshots", "desired", "latest")
    _ = os.Remove(latest)
    _ = os.Symlink(dir, latest)
    return dir, nil
}

