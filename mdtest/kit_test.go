//go:build kit

// for this to work, this source file needs to be copied into the mdtest dir of
// the super source code repo, then run with .test-doc.sh in this repo's root
// directory.

// this presumes the root dirs of both repos share a parent dir.

package mdtest

import (
	"flag"
	"os"
	"strings"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

var mdFilter *string
var mdPath *string

func init() {
    mdFilter = flag.String("mdfilter", "", "Filter markdown files by pattern (e.g., '*auth*')")
    mdPath = flag.String("mdpath", "../../superkit/doc", "Path to markdown files")
}

func TestMarkdownExamples(t *testing.T) {
    require.NoError(t, os.Chdir(*mdPath))
    files, err := Load()
    require.NoError(t, err)
    require.NotZero(t, len(files))

    for _, f := range files {
        f := f
        // Skip files that don't match the filter
        if *mdFilter != "" && !strings.Contains(f.Path, *mdFilter) {
            continue
        }
        t.Run(filepath.ToSlash(f.Path), func(t *testing.T) {
            t.Parallel()
            f.Run(t)
        })
    }
}
