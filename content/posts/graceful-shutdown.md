---
title: "Zero downtime deployments with Go and Kubernetes"
date: 2018-08-06T19:40:55+01:00
url: "graceful-shutdown"
keywords: [technical, kubernetes, go, cloud]
---

If you’re writing Go then you’re probably aware that graceful shutdown was added to the http package in 1.8.

> The HTTP server also adds support for [graceful shutdown](https://golang.org/doc/go1.8#http_shutdown), allowing servers to minimize downtime by shutting down only after serving all requests that are in flight. — [Go 1.8 is released](https://blog.golang.org/go1.8)

Similarly, If you’re using Kubernetes then I’m sure you’re aware of, and hopefully using rolling updates for your deployments.

> Rolling updates incrementally replace your resource’s Pods with new ones, which are then scheduled on nodes with available resources. Rolling updates are designed to update your workloads without downtime. — [Performing Rolling Updates](https://cloud.google.com/kubernetes-engine/docs/how-to/updating-apps)

However, you might not be sure how the two work together to ensure truly zero downtime deployments — I wasn’t! This is a quick guide to writing readiness and liveness probes in Go and how to configure them with a Kubernetes rolling update deployment.

**_Getting started_**

Let’s get started with a basic health check, to begin we’ll use it for both the readiness and liveness probes in Kubernetes. This was how I started writing services, and until you hit a significant amount of traffic, it’s probably fine.

Here’s a sample Go app, using a [Chi router and middleware](https://github.com/go-chi/chi) as well as the deployment probe configuration.

```go
package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	r := chi.NewRouter()

	r.Use(middleware.Heartbeat("/health"))

	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello, World!"))
	})

	http.ListenAndServe(":3000", r)
}
```

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
readinessProbe:
  httpGet:
    path: /health
    port: 80
```

This will work fine, but when performing a rolling update Kubernetes will send a `SIGTERM` signal to the process and the server will die. Any open connections will fail resulting in a bad experience for users

**_Graceful shutdown_**

There is fantastic documentation and example code for the `server.Shutdown` method on [godoc.org](https://golang.org/pkg/net/http/#Server.Shutdown). One thing to note here is that the example uses `os.Interrupt` as the shutdown signal. That’ll work when you run a server locally and hit `ctrl-C` to close it, but not on Kubernetes. Kubernetes sends a `SIGTERM` signal which is different.

```go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	var srv http.Server

	idleConnsClosed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)

		// interrupt signal sent from terminal
		signal.Notify(sigint, os.Interrupt)

		// sigterm signal sent from kubernetes
		signal.Notify(sigint, syscall.SIGTERM)

		<-sigint

		// We received an interrupt signal, shut down.
		if err := srv.Shutdown(context.Background()); err != nil {
			// Error from closing listeners, or context timeout:
			log.Printf("HTTP server Shutdown: %v", err)
		}

		close(idleConnsClosed)
	}()

	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		// Error starting or closing listener:
		log.Printf("HTTP server ListenAndServe: %v", err)
	}

	<-idleConnsClosed
}
```

Now, let’s look at how we integrate graceful shutdown with the two different Kubernetes probes.

_A quick primer on probes in Kubernetes:_

- _Liveness_ indicates that the pod is running, if the liveness probe fails the pod will be restarted.
- _Readiness_ indicates that the pod is ready to receive traffic, when a pod is ready the load balancer will start sending traffic to it.

Let’s go through the steps we want to happen during a rolling update.

1. Running pods are told to shut down via a SIGTERM signal
2. The readiness probes on those running pods should start failing as they are not accepting new traffic, but only closing any open connections
3. During this time new pods have started up and will be ready to receive traffic
4. Once all connections to old pods have been closed, the liveness probes should fail
5. The old pods are now completely shut down and assuming the rollout went well, all traffic should be going to new pods

We’ll need to use two different types of probes to achieve this, an `httpGet` probe for readiness and a `command` for liveness. Think about it, once a Go application receives the `SIGTERM` signal it will no longer serve new traffic so any http health checks will fail, this is why the liveness check needs to be independent of the http server.

The most common way to do this is by creating a file on disk when the process starts, and remove it when ending. The liveness check is then a simple `cat` command to check that the file exists.

Here’s an example of how we would create the probe file before running the application, and remove it once it has completed.

```go
package probe

import "os"

const liveFile = "/tmp/live"

// Create will create a file for the liveness check.
func Create() error {
	_, err := os.Create(liveFile)

	return err
}

// Remove will remove the file create for the liveness probe.
func Remove() error {
	return os.Remove(liveFile)
}

// Exists checks if the file created for the liveness probe exists.
func Exists() bool {
	if _, err := os.Stat(liveFile); err == nil {
		return true
	}

	return false
}
```

```go
// Command defines the command-line interface for starting our aplication HTTP server.
var Command = &cobra.Command{
	Use:   "app",
	Short: "Run the application",
	RunE: func(cmd *cobra.Command, args []string) error {
		var s app.Specification
		envconfig.MustProcess("", &s)

		if err := probe.Create(); err != nil {
			return fmt.Errorf("create probe: %w", err)
		}

		app.Run(s)

		if err := probe.Remove(); err != nil {
			return fmt.Errorf("remove probe: %w", err)
		}

		return nil
	},
}
```

I’ve hardcoded the location of the probe file here to simplify the example code, but don’t overlook this. You’ll need to make sure that you mount a [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) to write to. I’d also suggest using the [`ioutil.TempFile`](https://golang.org/pkg/io/ioutil/#TempFile) method available in the Go standard library.

Now… we need to update the deployment configuration to check for the existence of `/tmp/live`.

```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /tmp/live
readinessProbe:
  httpGet:
    path: /health
    port: 80
```

That _should_ be all you need, but I did run into an interesting problem.

**_Debugging_**

You might run into issues, like I did, where the pod got stuck in a restart loop. Once you’ve found the pod name, you can use the describe command to see what’s going on:

```sh
kubectl describe pod my-application-789757d855-ptccl
```

In my case, I ran into a rather interesting error:

```sh
Warning  Unhealthy              16s (x7 over 1m)  kubelet, gke-dev-cluster-2-dev-pool-2-b6567556-l83v  Liveness probe failed: rpc error: code = 2 desc = oci runtime error: exec failed: container_linux.go:247: starting container process caused "exec: \"cat\": executable file not found in $PATH"
```

_That’s right, the container I was using didn’t have `cat` installed._

I’ve been using the [distroless container from Google](https://github.com/GoogleContainerTools/distroless) as a base image for my application containers. It has everything I need to run a Go binary and nothing else. This is fantastic because the containers I ship are tiny… build times are faster, deployments are faster and it reduces security risk.

It’s great that I can ship 15mb containers, but… not so great when I can’t use basic utilities like `cat`. Rather than poking around in the container to see what else I could use, or use a different base image, I wrote a small sub-command in my Go application to handle this. You’ll notice a `probe.Exists` method in the `probe` package above, here’s what the liveness sub-command looks like:

```go
package live

import (
	"os"

	"github.com/overhq/over-stories-api/pkg/probe"
	"github.com/spf13/cobra"
)

// Command defines the command-line interface for our liveness probe.
var Command = &cobra.Command{
	Use:   "live",
	Short: "Check if application is live",
	RunE: func(cmd *cobra.Command, args []string) error {
		if probe.Exists() {
			return nil
		}

		return fmt.Errof("probe does not exist")
	},
}
```

Calling the liveness check as a sub-command instead of using `cat` directly sorted out my problems, hopefully that helps if you run into a similar issue.

I hope this post has provided some insight into how the graceful shutdown and rolling updates can work together to achieve truly zero downtime deployments. If you have any questions, thoughts or suggestions then I’d love to hear from you!

If you'd like to read more about this topic, I'd recommend the documentation on [Kubernetes Container probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes), the [`server.Shutdown` method](https://golang.org/pkg/net/http/#Server.Shutdown) in the Go standard library or Google Cloud specific documentation on [performing rolling updates](https://cloud.google.com/kubernetes-engine/docs/how-to/updating-apps).
