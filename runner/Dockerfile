FROM ghcr.io/actions/actions-runner:latest

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#Install other dependencies
# RUN apt-get update && \
#     curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
#     echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" | tee /etc/apt/sources.list.d/hashicorp.list && \
#     apt-get update && \
#     apt-get install -y packer

USER runner
ENTRYPOINT ["/entrypoint.sh"]