FROM alpine

RUN apk --no-cache add \
    openssh \
    tmux \
    irssi

RUN echo "set -g default-terminal screen-256color" >> /root/.tmux.conf && \
    echo "set -g status off" >> /root/.tmux.conf

RUN /usr/bin/ssh-keygen -A && \
    touch /root/.hushlogin

ADD profile /root/.profile

ADD docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
