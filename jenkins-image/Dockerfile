FROM jenkins/jenkins:2.550-jdk25

USER root
RUN apt-get update && apt-get install -y curl ca-certificates && rm -rf /var/lib/apt/lists/*
USER jenkins

# Install the necessary plugins from the plugins.txt file
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt