---
title: "The Most Exciting Feature of Go 1.8"
date: 2016-10-31T19:43:42+01:00
url: "default-gopath"
keywords: [technical, go]
---

You might think that the [built-in support for gracefully shutting down http servers](https://github.com/golang/go/issues/4674) is reason enough to be excited for the upcoming Go 1.8. It could also be the proposed [sub-millisecond GC pauses](https://groups.google.com/forum/m/#!topic/golang-dev/Ab1sFeoZg_8). Heck, if you’re having refactoring issues on a Google scale then it could be the [controversial](https://groups.google.com/d/msg/golang-dev/OmjsXkyOQpQ/EkERNkTeAgAJ) addition of [alias declarations](https://github.com/golang/proposal/blob/master/design/16339-alias-decls.md).

Based on my experience, working with small teams and people new to Go, [Go 1.8 shipping with a default `GOPATH`](https://github.com/golang/go/issues/17262) is going to be the most groundbreaking of all new features.

One of the things I still miss from publishing command-line packages on NPM is the end-user experience.

```sh
brew install node
npm install -g myapp
myapp
```

This is assuming you’re using macOS with [Homebrew](http://brew.sh/), but the experience is not that different on other operating systems. There’s no mucking around with `PATH` variables at all. You don’t even have to know where the package installed to… it’s just there, ready to use.

The addition of a default `GOPATH` in Go 1.8 will bring the experience much closer to that of Node & NPM. The only remaining friction is that the the default `$GOPATH/bin` directory won’t be added to a user’s `$PATH`. Hopefully this can be addressed at some stage, either by the community or the Go team.

Installing and using Go commands as of 1.8 could now be as simple as this:

```sh
brew install go
go get github.com/foo/bar
~/go/bin/bar
```

Go 1.8 is going to be a great release which will continue to push the language, runtime and toolchain forward. If you’re as excited as me then you can keep an eye on progress using the [Go 1.8 GitHub milestone](https://github.com/golang/go/milestone/38).

{{< tweet user="francesc" id="791079293447057408" >}}

Special thanks to [Francesc Campoy](https://twitter.com/francesc) for [implementing this feature](https://twitter.com/francesc/status/791079293447057408) 💖
