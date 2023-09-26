FROM debian:11

ENV DEPLOY_USER das
ENV DEPLOY_USER_DIR /home/${DEPLOY_USER}

RUN useradd ${DEPLOY_USER} --create-home --shell /bin/bash

# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        bash locales \
	libssl1.1 \
        && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

RUN echo "${DEPLOY_USER} ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LANG C.UTF-8

ADD https://github.com/florisbreggeman/das/releases/download/1.0.0/das-1.0.0.tar.gz ${DEPLOY_USER_DIR}/das.tar.gz

RUN chown ${DEPLOY_USER}:${DEPLOY_USER} -R ${DEPLOY_USER_DIR}

USER ${DEPLOY_USER}

WORKDIR ${DEPLOY_USER_DIR}

RUN tar -vxf ${DEPLOY_USER_DIR}/das.tar.gz -C ${DEPLOY_USER_DIR}

RUN cp /home/das/das/releases/1.0/runtime.exs.docker /home/das/das/releases/1.0/runtime.exs

CMD ["/home/das/das/bin/das", "start"]]
