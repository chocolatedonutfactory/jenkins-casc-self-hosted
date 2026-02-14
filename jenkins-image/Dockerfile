FROM jenkins/jenkins:2.550-jdk25

# Install the necessary plugins from the plugins.txt file
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt