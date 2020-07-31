# sslscan_docker_image
###### Please send any questions, queries or concerns to: `sslscan@blairjames.com`

- Full featured SSLScan implementation. 
- Lean and up-to-date.
- CI/CD built, monitored and maintained.
- Compiled fresh from latest stable source.
- Clean, scratch-built image.
- Single concern container.

#### Run as you would native SSLScan, just add the `docker run` prefix.
``` 
docker run --rm blairy/sslscan
```
###### An alias can be added for the SSLScan command: `alias sslscan="docker run --rm blairy/sslscan"`
###### Add to "$HOME/.bashrc" to make alias permanent.

#### Example Commands:
 - docker run --rm blairy/sslscan -version
 --docker run --rm blairy/sslscan --show-times google.com


