ARG BASE_IMAGE=""
ARG COMMAND=""

############ DEPENDENCIES ###############
FROM ${BASE_IMAGE} as dependencies

ENV WORKSPACE $DOCKER_HOME/ws
WORKDIR $WORKSPACE

COPY . src/

RUN if [[ -f "src/package.xml" ]]; then \
        export PACKAGE_NAME=$(sed -n 's/.*<name>\(.*\)<\/name>.*/\1/p' src/package.xml) && \
        mkdir -p src/${PACKAGE_NAME} && \
        cd src && shopt -s dotglob && find * -maxdepth 0 -not -name ${PACKAGE_NAME} -exec mv {} ${PACKAGE_NAME} \; ; \
    fi

# get non apt dependencies
RUN find . -name "*.repos" -exec bash -c 'vcs import src < {}' \;

# get apt dependencies via rosdep
RUN apt-get update && \
    rosdep update && \
    if [ -x "$(command -v colcon)" ]; then export OS="ubuntu:jammy"; else export OS="ubuntu:focal"; fi && \
    ROS_PACKAGE_PATH=$(pwd):$ROS_PACKAGE_PATH rosdep install --os $OS -y --simulate --from-paths src --ignore-src \
        | tee $WORKSPACE/.install-dependencies.sh && \
    chmod +x $WORKSPACE/.install-dependencies.sh

# add additional apt dependencies
RUN if [[ -f "src/${PACKAGE_NAME}/docker/additional.apt-dependencies" ]]; then \
        echo "apt-get install -y \\" >> $WORKSPACE/.install-dependencies.sh && \
        cat src/${PACKAGE_NAME}/docker/additional.apt-dependencies | awk '{print "  " $0 " \\"}' >> $WORKSPACE/.install-dependencies.sh && \
        echo ";" >> $WORKSPACE/.install-dependencies.sh ; \
    fi

# add custom installations
RUN if [[ -f "src/${PACKAGE_NAME}/docker/custom.sh" ]]; then \
        cat src/${PACKAGE_NAME}/docker/custom.sh >> $WORKSPACE/.install-dependencies.sh ; \
    fi

############ DEPENDENCIES-INSTALL ########
FROM ${BASE_IMAGE} AS dependencies-install

ENV WORKSPACE $DOCKER_HOME/ws
WORKDIR $WORKSPACE

COPY --from=dependencies $WORKSPACE/.install-dependencies.sh $WORKSPACE/.install-dependencies.sh

RUN apt-get update && \
    $WORKSPACE/.install-dependencies.sh && \
    rm -rf /var/lib/apt/lists/*

############ DEVELOPMENT ################
FROM dependencies-install as development

# copy ROS packages
COPY . src/

RUN if [[ -f "src/package.xml" ]]; then \
        export PACKAGE_NAME=$(sed -n 's/.*<name>\(.*\)<\/name>.*/\1/p' src/package.xml) && \
        mkdir -p src/${PACKAGE_NAME} && \
        cd src && find * -maxdepth 0 -not -name ${PACKAGE_NAME} -exec mv {} asd \; ; \
    fi

# clone .repos
RUN find . -name "*.repos" -exec bash -c 'vcs import src < {}' \;

############ BUILD ######################
FROM development as build

# build ROS workspace
RUN if [ -x "$(command -v colcon)" ]; then \
        colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release ; \
    elif [ -x "$(command -v catkin)" ]; then \
        catkin config --install --extend /opt/ros/$ROS_DISTRO && \
        catkin build -DCMAKE_BUILD_TYPE=Release --force-color --no-status --summarize ; \
    fi

############ RUN ######################
FROM dependencies-install as run
ARG COMMAND

# copy ROS packages
COPY --from=build $WORKSPACE/install install

RUN echo ${COMMAND} > cmd.sh && \
    chmod a+x cmd.sh

# run launchfile
COPY docker/docker-ros/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["./cmd.sh"]
