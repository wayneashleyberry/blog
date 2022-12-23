---
title: "Beware Firebase Project Limits"
date: 2017-05-23T18:29:46+01:00
url: "firebase-projects"
keywords: [technical, cloud, firebase]
---

Firebase is an incredible platform, some of their recent additions like [Cloud Functions for static hosting](https://firebase.google.com/docs/hosting/functions) are pretty amazing. However, I’d like to share a serious blindspot that I came across while preparing for a product launch.

The intent of this post is in no way to discourage anyone from using Firebase. I love Firebase and I recommend you give it a go! This is just an important learning that I wanted to share — hopefully it can prevent you from getting stuck in the same position as me.

There’s a limit to how many Firebase projects you can create, and it isn’t communicated in the console at all. This is one of the messages I received from Firebase support:

> The number of projects you can create at [console.firebase.google.com](https://console.firebase.google.com/) is based on some factors that we cannot disclose. Somewhere in the range of 5–10 seems to be the norm. Cloud usually handles quota request within 2 business days.

So now you’re thinking, sure, that’s reasonable — what’s the big deal? I agree, doesn’t seem like a big deal. When you hit the limit, you could just delete some unnecessary test projects.

Something else that isn’t communicated in the console, is that when you delete a project it hangs around for 30 days in case you need to restore it.

> After a 30-day waiting period, the project and associated data are permanently deleted from the console. — https://support.google.com/cloud/answer/6251787?hl=en

These two factors together could put you in the tricky situation I found myself in. I was stuck in limbo, unable to create new projects and unable to force delete projects waiting to be deleted.

So you fill out the form to request an increase in your project limit — and hope it’s accepted before you need to launch. Thankfully I did receive an increase to my project limit after filling out the request form and waiting two business days — but it was a very close call.
