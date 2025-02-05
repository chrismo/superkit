//go:build kit

// for this to work, this source file needs to be copied into the mdtest dir of
// the super source code repo, then run with .test-doc.sh in this repo's root
// directory.

// this presumes the root dirs of both repos share a parent dir.

package mdtest

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestMarkdownExamples(t *testing.T) {
	require.NoError(t, os.Chdir("../../superkit/doc"))
	files, err := Load()
	require.NoError(t, err)
	require.NotZero(t, len(files))
	for _, f := range files {
		f := f
		t.Run(filepath.ToSlash(f.Path), func(t *testing.T) {
			t.Parallel()
			f.Run(t)
		})
	}
}
