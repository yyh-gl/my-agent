# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.14-slim-bookworm
ARG NODE_IMAGE=node:25-bookworm-slim
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian12:nonroot

FROM ${PYTHON_IMAGE} AS python
RUN arch="$(dpkg --print-architecture | sed 's/amd64/x86_64/;s/arm64/aarch64/')"; \
    cp -a "/lib/${arch}-linux-gnu" /python-libs

FROM ${NODE_IMAGE} AS node
RUN mkdir /node-libs && \
    find /lib /usr/lib -name "libatomic.so*" -exec cp -Pd {} /node-libs/ \;

FROM ${RUNTIME_IMAGE}

COPY --from=python /usr/local/bin/python3.14 /usr/local/bin/python3.14
COPY --from=python /usr/local/lib/libpython3.14.so.1.0 /usr/local/lib/
COPY --from=python /usr/local/lib/python3.14 /usr/local/lib/python3.14

COPY --from=python /python-libs /python-libs

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /node-libs /python-libs/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LD_LIBRARY_PATH=/usr/local/lib:/python-libs

WORKDIR /app

USER nonroot
