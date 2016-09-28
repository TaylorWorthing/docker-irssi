# SSH + TMUX + IRSSI
Combine ssh, tmux, and irssi to create a remotely hosted IRC client.

This container hosts an ssh server that will automatically create/connect to a tmux session running irssi whenever you log in. This means you can leave irssi connected and remotely access it anywhere using ssh.

## Deployment
Here is an example on how to run this container using all supported features.
```sh-session
$ docker run --name irssi --hostname irssi -d \
    -p 2222:22 \
    -p 60000-61000:60000-61000/udp \
    -e ENABLE_MOSH="true" \
    -e SSH_PASSWORD="P455w0rd" \
    -e SSH_AUTHORIZED_KEY="$(< ~/.ssh/id_rsa.pub)" \
    -e IRSSI_REPO="git@bitbucket.org:BrowncoatShadow/irssi.git" \
    -e IRSSI_REPO_KEY="$(< ~/.ssh/id_rsa)" \
    -e ENABLE_SCRIPTS="true" \
    browncoatshadow/irssi
```

### Configuration
#### ssh
`-p 2222:22` maps a port on the host to the ssh port in the container.

`-e SSH_PASSWORD="P455w0rd"` sets the password on the root account in the container, and enables password login for the root account. This can be a convenient fallback, but ssh keys are recommended.

`-e SSH_AUTHORIZED_KEY="$(< ~/.ssh/id_rsa.pub)"` reads your public ssh key from file from your client, then writes it to root's `~/.ssh/authorized_keys` file.  This allows secure password-less login.

#### irssi
`-e IRSSI_REPO="git@bitbucket.org:BrowncoatShadow/irssi.git"` takes a git repo containing your irssi configuration. This allows you to easily deploy your irssi configuration remotely in an easy way. *If your irssi configuration contains passwords, it is **highly** recommended that you store them in a private and/or self hosted repo.*

`-e IRSSI_REPO_KEY="$(< ~/.ssh/id_rsa)"` is useful if your irssi configuration repo is private. It will store your private ssh key into a temp file used to clone the irssi repo. It is then removed.

`-e ENABLE_SCRIPTS="true"` will install the perl scripting dependencies for irssi plugins and make sure `load perl` is in the `~/.irssi/startup` file.

#### mosh
`-e ENABLE_MOSH="true"` will install [mosh](https://mosh.org/).

`-p 60000-61000:60000-61000/udp` publishes the default port range for mosh to establish connections. If you prefer, you can instead publish specific ports and have your mosh client instruct the server to establish connections using those ports.


## Connecting
You can connect to the container using ssh, which will automatically open irssi inside of a tmux session. If you need help determining the IP you need to connect to your container, docker's `port` subcommand is very helpful.
```sh-session
$ docker port irssi 22
192.168.99.100:2222
$ ssh root@192.168.99.100 -p 2222
```

You can quit by using the `/quit` command in irssi, or detach tmux using the key binding `ctrl-b d`, which will leave irssi connected in the background. Both will disconnect you from the ssh connection.

> **TIP:** [tmux_away.pl](https://github.com/irssi/scripts.irssi.org/blob/master/scripts/tmux_away.pl) is an amazingly useful script in this situation. It can automatically mark you as away whenever you are detached from the tmux session and mark you as no longer away when you reconnect.

### SSH Config
Simplify connection by adding an entry to your `~/.ssh/config` file.
```
# ~/.ssh/config
Host irssi
  User root
  HostName 192.168.99.100
  Port 2222
```

Now you can connect using a host alias.
```sh-session
$ ssh irssi
```


## Advanced Deployments
This container was designed to be simple for remote deployments. However, it can easily be used to make something more complex. Here are a couple of examples.

### Example: Log Storage
If you want to store your logs you can create a persistent volume for log storage and mount it in your irssi container.
```sh-session
$ docker volume create --name irssi-logs
irssi-logs
$ docker run --name irssi -d \
    -p 2222:22 \
    -e SSH_PASSWORD="P455w0rd" \
    -e IRSSI_REPO="git@bitbucket.org:BrowncoatShadow/irssi.git" \
    -v irssi-logs:/root/irclogs \
    browncoatshadow/irssi
```

### Example: Custom Container
You can also use this container as a base for building a custom deployment. Maybe you want to build with your configuration or add additional features or plugin dependencies.

```dockerfile
# Dockerfile
FROM browncoatshadow/irssi

ADD /home/browncoatshadow/.irssi /root/.irssi/
ADD /home/browncoatshadow/.ssh/authorized_keys /root/.ssh/authorized_keys

RUN apk --no-cache add irssi-proxy && \
    echo "load proxy" >> /root/.irssi/startup

EXPOSE 6667
```

Now build and deploy the custom container.
```sh-session
$ docker build . -t browncoatshadow/irssi-proxy
Sending build context to Docker daemon 100.4 kB
...
Successfully built 8d95468e90fb
$ docker run --name irssi-proxy -d \
    -p 2200:22 \
    -p 6667:6667 \
    browncoatshadow/irssi-proxy
```
