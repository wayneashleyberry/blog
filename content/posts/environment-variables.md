---
title: "Environment Variables & Go"
date: 2022-04-26T16:57:31+01:00
url: "environment-variables"
---

I wanted to share a few tips on working with environment variables. I will be mentioning a few libraries specific to Go but the principles should apply to most languages. Keep in mind these are my opinions and come from learnings in a very specific context, feel free to disagree.

**Don’t auto-load .env files in application code**

I love `.env` files — they make my configuration portable and easy to change. However, loading `.env` files from your application code does introduce a slight risk and an unnecessary dependency. Let's look at [joho/godotenv](https://github.com/joho/godotenv) for example, it provides a modules for automatically reading an `.env` file at runtime as well as a CLI for loading them yourself. The risk of autoloading environment variables from an `.env` file is small, but something I have run into and was difficult to debug. Here's the scenario, you're doing local development and submit a build container using [Google Cloud Build](https://cloud.google.com/build). You don't realise that your local `.env` file is actually being included in the build files and now it's not only bundled with your container, potentially leaking secrets, but it's also overriding other variables defined in your runtime. There's a small amount of waste including a library like this in an application as well, because it's essentially a developer tool and should never be used in place of _actual_ environment variables in production. Thankfully [joho/godotenv](https://github.com/joho/godotenv) includes a command-line utility which makes this workflow explicit.

```sh
godotenv -f .env go run main.go
```

**Define variables in one place**

This speaks to the legibility of a code base, where the Go convention is to reading code over writing it. Keeping all of your environment variables in a single file or package might be a little more work up front... but it significantly reduces the energy required to comprehend an unfamiliar application. Having to search a repo for calls to `os.Getenv` or `envconfig.Parse` is very unpleasant and can get messy very quickly. Your team will be grateful for this, and your future self will probably also appreciate the work.

**Validate soon and in a single place**

I usually follow the command/package structure for my Go apps. Here's a quick overview of what an application might look like:

```sh
.
├── cmd
│  └── serve
│     └── serve.go # This command reads environment variables.
├── pkg
│  └── server
│     └── server.go # This command doesn't know environment variables exist.
└── main.go
```

You have a single entry point for building the application, `main.go`, and everything else is either a package or command. Each command should read and validate the required environment variables as early on in the execution as possible, failing if there are any incorrect or missing values. Packages should never read environment variables.

**Defaults _can be_ dangerous**

You'll see a trend here, define variables in one place, validate in one place etc. The same applies to defaults, from my experience it is often best to omit default values entirely. Let's give an example, you deploy an application to a new environment and mistakenly set environment variables in the wrong place, or have a type. There are no errors and the application is running, but the behavior is not as expected. You now need to debug the code and figure out which values are actually being used. Defaults allow this kind of error tolerance where behaviours can subtlety change.

Default values are obviously still very useful for humans though, I would suggest keeping them as far away from application code as possible. Start with documentation, that's a good place for example or default values, beyond that, perhaps an `.env.example` file?

**Add descriptions, not examples**

This is a very niche annoyance. Providing examples for environment variables has the potential to trigger security alerts, usually due to high entropy strings. These would _hopefully_ be false positives, but something you might have to deal with either way. It's probably best to just avoid providing example values, especially in source code... but instead rely on descriptions, documentation and validation.

```diff
type EnvironmentVariables struct {
-    Token  string  `required:"true" envconfig:"TOKEN" example:"012312312312312a"`
+    Token  string  `required:"true" envconfig:"TOKEN" description:"16 character alpha-numerical string"`
}
```

**Libraries shouldn’t read anything from the environment**

Libraries should to be predictable, they ideally shouldn't `panic`, read anything from the environment or write anything to `stdout` (you should provide a logger for that). Configuration is the responsibility of the caller, if you maintain a library that may need to read environment variables then I would suggest making reading them optional and explicit.

**Sort them alphabetically**

Last and definitely least, this is a personal preference but also speaks to consistency and improved comprehension. Code formatters have taught us to stop worrying about code style, but sometimes I find myself trying to order environment variables into logical groups that make sense. It's not worth your time, sort them alphabetically and have done with it. Using consistent prefixes would result in logical groups of environment variables always being together, which is a nice side effect.
