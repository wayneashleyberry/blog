---
title: "The Most Exciting Feature of Go 1.18"
date: 2021-11-06T07:20:03+01:00
url: "buildvcs"
keywords: [technical, go]
---

_This post was written before Go 1.18 was released, I have tried to keep the example code up to date since the beta's and final release were released._

It's been 5 years since I wrote about [the most exciting feature of Go 1.8](/default-gopath) and there have been significant improvements in the language, toolchain and ecosystem since then. I'm not going to cover any of that... Go 1.18 is around the corner, being set to release in February of 2022, and [the release notes](https://tip.golang.org/doc/go1.18) already describe a very exciting, albeit small, feature.

Go 1.18 brings [generics](https://groups.google.com/g/golang-dev/c/iuB22_G9Kbo/m/7B1jd1I3BQAJ?pli=1), [fuzz testing](https://twitter.com/katie_hockman/status/1440082486692773897), [improved support for IP address types](https://tip.golang.org/doc/go1.18#netip) and [faster image drawing operations](https://tip.golang.org/doc/go1.18#image/draw) amongst other things. This is an impressive release, with the hype train definitely focusing on generics. However, the most exciting feature, for me at least, is that the version control information is going to automatically be embedded in compiled binaries.

{{< tweet user="katie_hockman" id="1440082486692773897" >}}

**_What is this useful for?_**

Injecting build parameters into your application provides critical data for observability. I have been adding commit hashes into logger contexts for years now. Google Cloud will read the `serviceContext` object in any log message and make use of the data in error reporting. This can provide great insight into when errors were introduced and what the error rates are for different versions of your service. I'm sure other cloud providers offer similar functionality as well.

**_How have we done this in the past?_**

There have been a variety of methods for doing this before Go 1.18, there is the very handy [`govvv`](https://github.com/ahmetb/govvv) library, you could use the more recent [`embed`](https://pkg.go.dev/embed) directive. Don't forget the swiss army knife that is [`-ldflags`](https://www.digitalocean.com/community/tutorials/using-ldflags-to-set-version-information-for-go-applications), which is powerful but has brittle and complex syntax. These are perfectly fine solutions, but they all require an extra step, dependency or something else to learn. As of Go 1.18 we can do this with pure Go code and the standard toolchain.

**_How do we do this now?_**

You'll need to install [beta 1](https://go.dev/dl/#go1.18beta1) because at the time of this post Go 1.18 is not released.

```sh
$ go install golang.org/dl/go1.18beta1@latest
$ go1.18beta1 download
```

You can now use `go1.18beta1` in place of the `go` command.

```sh
$ go1.18beta1 version
go version go1.18beta1 darwin/amd64
```

If you're using [Visual Studio Code](https://code.visualstudio.com/) and the [vscode-go](https://github.com/golang/vscode-go) extension, then there is a command provided to easily choose the Go environment that you want to use. Simply search for "go environment" in the command palette, or click on the Go version in the bottom left of the editor.

Let's write a sample application to inspect the new build information, and save the files in a new git repository.

```go
package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		panic("could not read build info")
	}

	for _, setting := range info.Settings {
		fmt.Printf("%s: %s\n", setting.Key, setting.Value)
	}
}
```

Running the above code will print the following output:

```sh
-compiler: gc
CGO_ENABLED: 1
CGO_CFLAGS:
CGO_CPPFLAGS:
CGO_CXXFLAGS:
CGO_LDFLAGS:
GOARCH: amd64
GOOS: darwin
GOAMD64: v1
vcs: git
vcs.revision: df3191846668b599d17ec1cb79ca212127a421ee
vcs.time: 2021-12-16T08:03:56Z
vcs.modified: false
```

If you don't see the git keys, make sure that you are building or running the entire package and not a single file. I'm so used to `go run main.go` that it took me a while to figure this part out. If you read the documentation you'll see mention of the main package and main module... this implies the requirement to build a package for build information to be included.

**_Build packages, not files_**

> Version control information is embedded if the go command is invoked in a directory within a Git, Mercurial, Fossil, or Bazaar repository, and the `main` package and its containing main module are in the same repository. This information may be omitted using the flag `-buildvcs=false`. — https://tip.golang.org/doc/go1.18

```sh
# These will work
go1.18beta1 run .
go1.18beta1 run ./...
# This will not
go1.18beta1 run main.go
```

**_Using build info with the zap logger_**

Here's another example of how one would include this information in a logger context.

```go
package main

import (
	"runtime/debug"

	"go.uber.org/zap"
)

func main() {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		panic("could not read build info")
	}

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	for _, setting := range info.Settings {
		if setting.Key == "vcs.revision" {
			logger = logger.With(zap.String("version", setting.Value))
		}
	}

	logger.Info("Hello, World!")
}
```

Running the above application will print the following:

```json
{
  "level": "info",
  "ts": 1636189230.721092,
  "caller": "buildinfo/main.go:24",
  "msg": "Hello, World!",
  "version": "0b1cb25494ccc504337fb5fe916291fb7d680823"
}
```

**_Reproducible builds_**

> "Please consider omitting build time from your artifacts. It makes build reproducibility a nightmare; people are coming up with frameworks to lie to build systems about the current time. https://reproducible-builds.org" — [rollcat on hacker news](https://news.ycombinator.com/item?id=29008811)

This new build info is very exciting, but be careful which data you decide to include in your build artifacts regardless of how you are doing so. We should be striving for reproducible builds, and some of these variables, like the date, will be different for each build. These variable factors should be excluded from your binary.

_Further reading_

- [Upcoming Features in Go 1.18 By Sebastian Holstein](https://sebastian-holstein.de/post/2021-11-08-go-1.18-features/)
- [Twitter thread by Daniel Martí](https://twitter.com/mvdan_/status/1456947756925399040)
