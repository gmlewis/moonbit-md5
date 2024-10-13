# gmlewis/md5
[![check](https://github.com/gmlewis/moonbit-md5/actions/workflows/check.yml/badge.svg)](https://github.com/gmlewis/moonbit-md5/actions/workflows/check.yml)

This is a simple md5 hash algorithm based on Go's implementation:
https://cs.opensource.google/go/go/+/refs/tags/go1.23.0:src/crypto/md5/md5.go
which has the copyright notice:

```
// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
```

## Status

The code has been updated to support compiler:

```bash
$ moon version --all
moon 0.1.20241011 (ca50f51 2024-10-11) ~/.moon/bin/moon
moonc v0.1.20241011+9ea637707 ~/.moon/bin/moonc
moonrun 0.1.20241011 (ca50f51 2024-10-11) ~/.moon/bin/moonrun
```

Use `moonup` to manage `moon` compiler versions:
https://github.com/chawyehsu/moonup
