# Build Graph Inspection

This package contains tooling for hashing and diff-ing the Bazel build graph. This allows one to identify which packages or targets are affected by a given set of changes. This is useful for transparency, and can be used for selective testing.

The implementation is based on the strategy used by Dropbox and described in a [talk at BazelCon](https://www.youtube.com/watch?v=9Dk7mtIm7_A), which uses a [Merkle Trees](https://en.wikipedia.org/wiki/Merkle_tree) to directly compare the build graph.

There are two commands:

- `hash.py` generates a hash file, which is the "top-layer" of the Merkle tree
- `diff.py` generates hash files for two commits and compares them, outputting a list of affected targets
