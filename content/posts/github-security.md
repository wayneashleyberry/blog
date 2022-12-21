---
title: "Upgrade Your GitHub Security"
date: 2021-05-14T16:57:25+01:00
url: "github-security"
summary: "I wanted to point out a few GitHub settings that were new to me. Two-factor authentication, security and analysis features, email privacy and GPG keys are fairly new and not required by default."
---

I wanted to point out a few GitHub settings that were new to me.

### Account Security

**Two-factor authentication**

GitHub has many options for a second authentication factor, and just as many recovery options. I'm not going to explain why two-factor authentication is important here. Instead I wanted to point out that you should remove any SMS numbers from your Two-factor methods and Recovery options. It's been well publicised over the past few years how easy it is to SIM swap and you don't want someone else getting your GitHub 2fa tokens. I would recommend using physical security keys as your primary second factor, and falling back to an authenticator app if necessary.

https://github.com/settings/security#two-factor-summary

### Security & analysis

**Configure security and analysis features**

GitHub has a host of new security and analysis features that scan your code for vulnerabilities.
You can enable them by default on any new repositories, which is recommended.

https://github.com/settings/security_analysis

### Emails

> **Keep my email addresses private**
>
> We’ll remove your public profile email and use 727262+wayneashleyberry@users.noreply.github.com when performing web-based Git operations (e.g. edits and merges) and sending email on your behalf. If you want command line Git operations to use your private email you must set your email in Git.
>
> Commits pushed to GitHub using this email will still be associated with your account.

This one was new to me, and required a little extra effort. Turns out, by default your email address can easily be grabbed from any public commit on GitHub. Go and have a look... grab the URL of a commit and add the `.patch` suffix. GitHub has a setting to prevent this, and if you want to keep your account email address private you should enable it. This requires extra work because you do need to update your local git config, and it may affect your SSH and GPG keys as well.

https://github.com/settings/emails

> **Block command line pushes that expose my email**
>
> When you push to GitHub, we’ll check the most recent commit. If the author email on that commit is a private email on your GitHub account, we will block the push and warn you about exposing your private email.

If the above setting sounds appealing to you, then you'll want to go a step further and block all pushes that would expose your real email address. If you're going to use private noreply email addresses then I would suggest enabling this option to prevent any accidental pushes using an incorrect config.

https://github.com/settings/emails

**Email preferences**

> **Only receive account related emails, and those I subscribe to.**
>
> We’ll only send you legal or administrative emails, and any emails you’re specifically subscribed to.

This is a personal one, but I have subscribed to the Vulnerability newsletter, because those are the only kinds of updates that interest me.

https://github.com/settings/emails#preferences

### SSH and GPG keys

Remember setting up a new machine and pushing your first commit? You might have forgotten to update your `git` configuration but pushed to GitHub regardless. Turns out, you can write whatever you want in your `.gitconfig` and it'll display on GitHub. SSH keys verify a secure connection to a GitHub account, but not the details associated with each commit or tag. I would encourage everyone to take a look at GPG keys and the extra level of verification they add.

**Vigilant mode**

> **Flag unsigned commits as unverified**
>
> This will include any commit attributed to your account but not signed with your GPG or S/MIME key. Note that this will include your existing unsigned commits.

[Learn about vigilant mode](https://docs.github.com/en/authentication/managing-commit-signature-verification/displaying-verification-statuses-for-all-of-your-commits)

You've seen those "verified" badges next to some commits and tags, hopefully you're signing your work with a GPG key and seeing it on your work work. Vigilant mode, which is in beta at the time of writing this post, pushes this to the next level by adding a warning to unsigned commits and tags. I would enable this setting to give a stronger signal to your collaborators but also remind you to always automatically sign your commits with a GPG key.

https://github.com/settings/keys
