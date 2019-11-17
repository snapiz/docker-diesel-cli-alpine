ARG TOOLCHAIN=stable

FROM alpine:3.9 as provider

# The original libmysqlclient.a has a lot of missing symbols
# This is to make a super fat libmysqlclient.a for mysql linking later
RUN apk add --no-cache binutils mariadb-dev musl-dev && \
    ar x /usr/lib/libmysqlclient.a && \
    ar x /usr/lib/libssl.a && \
    ar x /usr/lib/libcrypto.a && \
    ar x /lib/libz.a && \
    ar x /usr/lib/libc.a && \
    ar rcs /root/libmysqlclient.a *.o *.lo && \
    rm -rf *.o *.lo && \
    :

FROM clux/muslrust:${TOOLCHAIN} as builder
COPY --from=provider /root/libmysqlclient.a /musl/lib/

ARG DIESEL_VER=1.4.0
ENV DIESEL_VER=${DIESEL_VER}

RUN cargo install diesel_cli \
    --version "=${DIESEL_VER}" \
    --no-default-features \
    --features "postgres mysql sqlite"

FROM alpine:3.9

RUN apk add --no-cache libpq ca-certificates

COPY --from=builder /root/.cargo/bin/diesel /usr/local/bin/