FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl git jq unzip sudo ca-certificates && \
    update-ca-certificates && \
    useradd -m runner

WORKDIR /runner

# Install GitHub Actions runner
ENV RUNNER_VERSION=2.324.0
RUN curl -L -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz && \
    ./bin/installdependencies.sh

COPY start.sh /runner/start.sh
RUN chmod +x /runner/start.sh
RUN chown -R runner /runner

USER runner
ENTRYPOINT ["/runner/start.sh"]