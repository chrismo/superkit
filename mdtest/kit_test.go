//go:build kit

// for this to work, it needs to be in the mdtest dir of the super source code
//
// then run with

package mdtest

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestMarkdownExamples(t *testing.T) {
	require.NoError(t, os.Chdir("/Users/chrismo/modev/superkit/doc"))
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
