# Visual Studio Code Server

```bash
docker run -it --rm --name code-server --security-opt=seccomp:unconfined -p 127.0.0.1:8443:8443 -v $(pwd)/project:/home/coder/project monostream/code-server:latest --allow-http --no-auth
```