---
title: "Introducing: Entropy Scanner"
date: 2021-09-18T16:57:31+01:00
url: "entropy-scanner"
---

![Screenshot of the Visual Studio Code extension in action](/img/entropy-scanner.png "Entropy Scanner")

I have released my first extension for Visual Studio Code!

[Entropy Scanner](https://marketplace.visualstudio.com/items?itemName=wayneashleyberry.entropy-scanner) is based on the algorithm that underpins [`tartufo`](https://github.com/godaddy/tartufo) and [`truffleHog`](https://github.com/dxa4481/truffleHog), but provides real-time feedback on your source code while you are writing it. The extension is open source and can be found on [GitHub](https://github.com/wayneashleyberry/vscode-entropy-scanner).

Entropy scanners are useful because they can detect certain types of strings without any predefined lists to pattern match against. High entropy strings may contain private keys, auth tokens or other sensitive information that should not be tracked in your version control. This shouldn't be the only tool you use to scan your source code for secrets, but it definitely helps.

Entropy Scanner provides real-time feedback on these high entropy strings, but it also adds a quick action to exclude certain findings in a `tartufo.toml` file. The extension also reads the
`exclude-signatures` and `exclude-path-patterns` tartufo config, providing a seamless experience between the two tools.

Visual Studio Code has been my primary editor for a while now, and it was quite fun writing a language server using TypeScript. I must admit, after almost exclusively writing Go and Rust for years the JavaScript ecosystem is still a mess. That said, Microsoft have done a fantastic job of [providing examples](https://github.com/microsoft/vscode-extension-samples) to get you started.
