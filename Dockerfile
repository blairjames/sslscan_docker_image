# Starting with Alpine latest image 
FROM alpine:latest

# Compile
RUN \
 apk update && apk upgrade && \
 apk add --no-cache make git perl gcc linux-headers musl-dev zlib-dev zlib zlib-static && \
 git clone https://github.com/rbsec/sslscan.git && \
  cd sslscan && \
   make static && \
   make install || exit 1

# Copy binary, dependant libraries to scratch image.
FROM scratch
COPY --from=0 /usr/bin/sslscan .
COPY --from=0 /etc/passwd /etc/passwd
COPY --from=0 /etc/gshadow /etc/gshadow
COPY --from=0 /etc/group /etc/group
COPY --from=0 /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=0 /lib/libz.so.1 /lib/libz.so.1
ENTRYPOINT ["./sslscan"]
