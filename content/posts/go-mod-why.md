---
title: "CVE-2021-32760 & Go Modules"
date: 2021-09-27T16:57:17+01:00
url: "go-mod-why"
---

![Screenshot of Dependabot alerts](/blog/img/dependabot-alerts.png "Dependabot alerts")

---

I wanted to share a quick story of [CVE-2021-32760](https://github.com/advisories/GHSA-c72p-9xmj-rx3w) and how it relates to some of the lesser-known intricacies of [Go Modules](https://go.dev/blog/using-go-modules).

I was working on a project when I noticed the dreaded Security tab had found something! The Security overview listed a single Dependabot alert, how odd — I'm normally very good at keeping my dependencies up to date. The GitHub Advisory Database has a [page describing the vulnerability](https://github.com/advisories/GHSA-c72p-9xmj-rx3w). Just to be clear, this is not an issue with Go itself — but rather a specific version of an open source module. It's not even a serious issue, but considering it was the only blemish on my otherwise clean record I wanted to fix it!

The affected versions of the library are `< 1.4.8` and `>= 1.5.0, < 1.5.4`, and it was patched in `1.4.8` and `1.5.4` so the first step is to find which version I'm using.

```sh
$ cat go.mod | grep containerd

```

Nothing. The dependency is not listed in my `go.mod` file at all, but there was a clue in the dependabot alert — it's pointing to my `go.sum` file.

```sh
$ cat go.sum | grep containerd
github.com/containerd/containerd v1.4.3 h1:ijQT13JedHSHrQGWFcGEwzcNKrAGIiZ+jSD5QQG07SY=
github.com/containerd/containerd v1.4.3/go.mod h1:bC6axHOhabU15QhwfG7w5PipXdVtMXFTttgp+kVtyUA=
```

Found it, the module is indeed being listed in my `go.sum` file and it's a version with the vulnerability in it. The implications here, and I may be incorrect, are that my project does not import the `containerd` module directly — but it was downloaded, as we have a checksum for it. This could mean that it's a transitive dependency that is not included in my project due to build tags, test dependencies or some other reason. Let's try and see why it's being referenced.

```sh
$ go mod why github.com/containerd/containerd
# github.com/containerd/containerd
(main module does not need package github.com/containerd/containerd)
```

Bizarre! This doesn't feel like the expected behaviour at all, a quick Google and we can see there are open issues on the Go project related to this.

> _"Currently, if you run `go mod why -m` on the output of every module in `go list -m all`, some modules may come back with the answer (main module does not need module […]), even after a `go mod tidy`."_ — https://github.com/golang/go/issues/27900

I noticed the `-m` flag referenced in the above issue, which I wasn't too familiar with. Here is the documentation on the flag:

> _"The `-m` flag causes go mod why to treat its arguments as a list of modules. go mod why will print a path to any package in each of the modules. Note that even when `-m` is used, `go mod why` queries the package graph, not the module graph printed by `go mod graph`."_ — https://golang.org/ref/mod#go-mod-why

Let's try `go mod why -m` and see what happens.

```sh
$ go mod why -m github.com/containerd/containerd
# github.com/containerd/containerd
github.com/wayneashleyberry/demo-api/pkg/migrator
github.com/golang-migrate/migrate/v4/database/mysql
github.com/golang-migrate/migrate/v4/database/mysql.test
github.com/dhui/dktest
github.com/docker/docker/api/types/network
github.com/docker/docker/errdefs
github.com/containerd/containerd/errdefs
```

Success, we can see where this module is coming from... and that it's a transitive test dependency. One could stop here, because this is code isn't actually being included in our build — but we can do better. Unfortunately, at the time of this post, there were no updates to the `golang-migrate/migrate` module — the module I was actually importing. There is a way to override transitive dependencies though!

Here's the single line I needed in my `go.mod` file to remove this finding:

```sh
replace github.com/containerd/containerd => github.com/containerd/containerd v1.4.8
```

We can use the `replace` directive to force the module to be loaded at a specific version, which overrides all other versions required in the module graph. This directive can be used for many other purposes and I would encourage you to read more about it. This does pin this dependency to a specific version, which is good for now but may harm us in the future. It's important to check back in on these kinds of situations as the intermediate modules get updated and we can remove our replacement.

https://golang.org/ref/mod#go-mod-file-replace

_Follow up — 19 October 2021_

For the sake of posterity I thought it worth mentioning [CVE-2021-41103](https://github.com/advisories/GHSA-c2h3-6mxw-7mvq), which was published after this initial post was written. The version of `containerd` that you want is now `1.4.11`.

```sh
replace github.com/containerd/containerd => github.com/containerd/containerd v1.4.11
```
