# *docker-ros* – Automated Containerization of ROS Apps

<p align="center">
  <img src="https://img.shields.io/github/v/release/ika-rwth-aachen/docker-ros"/></a>
  <img src="https://img.shields.io/github/license/ika-rwth-aachen/docker-ros"/>
  <a href="https://github.com/ika-rwth-aachen/docker-ros/actions/workflows/github.yml"><img src="https://github.com/ika-rwth-aachen/docker-ros/actions/workflows/github.yml/badge.svg"/></a>
  <a href="https://github.com/ika-rwth-aachen/docker-ros/actions/workflows/gitlab.yml"><img src="https://github.com/ika-rwth-aachen/docker-ros/actions/workflows/gitlab.yml/badge.svg"/></a>
</p>

*docker-ros* automatically builds minimal container images of ROS applications.

<img src="assets/logo.png" height=130 align="right">

- [About](#about)
  - [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Build a minimal image for deployment](#build-a-minimal-image-for-deployment)
  - [Build development and deployment images](#build-development-and-deployment-images)
  - [Build multi-arch images](#build-multi-arch-images)
  - [Build deployment image with additional industrial\_ci check](#build-deployment-image-with-additional-industrial_ci-check)
  - [Build multi-arch images on arch-specific self-hosted runners in parallel](#build-multi-arch-images-on-arch-specific-self-hosted-runners-in-parallel)
  - [Build images locally](#build-images-locally)
- [Advanced Dependencies](#advanced-dependencies)
  - [Extra System Dependencies (apt)](#extra-system-dependencies-apt)
  - [Custom Installation Script](#custom-installation-script)
  - [Extra Image Files](#extra-image-files)
- [Configuration Variables](#configuration-variables)

We recommend to use *docker-ros* in combination with our other tools for Docker and ROS.
- [*docker-ros-ml-images*](https://github.com/ika-rwth-aachen/docker-ros-ml-images) provides machine learning-enabled ROS Docker images <a href="https://github.com/ika-rwth-aachen/docker-ros-ml-images"><img src="https://img.shields.io/github/stars/ika-rwth-aachen/docker-ros-ml-images?style=social"/></a>
- [*docker-run*](https://github.com/ika-rwth-aachen/docker-run) is a CLI tool for simplified interaction with Docker images <a href="https://github.com/ika-rwth-aachen/docker-run"><img src="https://img.shields.io/github/stars/ika-rwth-aachen/docker-run?style=social"/></a>


## About

*docker-ros* provides a generic [Dockerfile](docker/Dockerfile) that can be used to build development and deployment Docker images for arbitrary ROS packages or package stacks. Building such images can easily be automated by integrating *docker-ros* into CI through the provided [GitHub action](action.yml) or [GitLab CI template](.gitlab-ci/docker-ros.yml). The development image built by *docker-ros* contains all required dependencies and the source code of your ROS-based repository. The deployment image only contains dependencies and the compiled binaries created by building the ROS packages in the repository. *docker-ros* is also able to build multi-arch Docker images for *amd64* and *arm64* architectures.

The Dockerfile performs the following steps to build these images:
1. All dependency repositories that are defined in a `.repos` file anywhere in the repository are cloned using [*vcstool*](https://github.com/dirk-thomas/vcstool).
2. The ROS dependencies listed in each package's `package.xml` are installed by [*rosdep*](https://docs.ros.org/en/independent/api/rosdep/html/).
3. *(optional)* Additional dependencies from a special file `additional.apt-dependencies` are installed, if needed (see [*Advanced Dependencies*](#extra-system-dependencies-apt)).
4. *(optional)* A special folder `files/` is copied into the images, if needed (see [*Advanced Dependencies*](#extra-image-files)).
5. *(optional)* A special script `custom.sh` is executed to perform further arbitrary installation commands, if needed (see [*Advanced Dependencies*](#custom-installation-script)).
6. *(deployment)* All ROS packages are built using `catkin` (ROS) or `colcon` (ROS2).
7. *(deployment)* A custom launch command is configured to run on container start.

### Prerequisites

*docker-ros* is made for automated execution in GitHub or GitLab CI pipelines. For local execution, see [*Build images locally*](#build-images-locally).

<details><summary>GitHub</summary>

GitHub offers free minutes on GitHub-hosted runners executing GitHub Actions, [see here](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions). No further setup is required other than integrating *docker-ros* into your repository, see [*Usage*](#usage).

Note that GitHub is currently only offering Linux runners based on the *amd64* architecture. *docker-ros* can also build multi-arch Docker images solely on the *amd64* platform through emulation, but performance can be improved greatly by deploying [self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners) for the *arm64* platform.

</details>

<details><summary>GitLab</summary>

> **Note**  
> - GitLab runners must be based on the Docker executor, [see here](https://docs.gitlab.com/runner/executors/docker.html)
> - GitLab runners must run in privileged mode for Docker-in-Docker, [see here](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode)
> - GitLab runners must be tagged with tags `privileged` and either `amd64` or `arm64` depending on their architecture

GitLab offers free minutes on GitLab-hosted runners executing GitLab CI pipelines on [gitlab.com](https://gitlab.com), [see here](https://docs.gitlab.com/runner/#use-gitlabcom-saas-runners). On self-hosted GitLab instances, you can set up self-hosted runners, [see here](https://docs.gitlab.com/runner/#use-self-managed-runners).

Note that GitLab is currently only offering Linux runners based on the *amd64* architecture. *docker-ros* can also build multi-arch Docker images solely on the *amd64* platform through emulation, but performance can be improved greatly by deploying [self-hosted runners](https://docs.gitlab.com/runner/#use-self-managed-runners) for the *arm64* platform.

</details>


## Usage

*docker-ros* can easily be integrated into any GitHub or GitLab repository containing ROS packages. Example integrations can be found in the following sections. Configuration options can be found [here](#configuration-variables). For local execution, see [*Build images locally*](#build-images-locally).

<details open><summary>GitHub</summary>

*docker-ros* provides a [GitHub action](action.yml) that can simply be added to a job via the [`jobs.<job_id>.steps[*].uses` keyword](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepsuses). A quick start for GitHub Actions is found [here](https://docs.github.com/en/actions/quickstart).

</details>

<details open><summary>GitLab</summary>

*docker-ros* provides a [GitLab CI template](.gitlab-ci/docker-ros.yml) that can simply be included in a [`.gitlab-ci.yml`](https://docs.gitlab.com/ee/ci/yaml/gitlab_ci_yaml.html) file. A quick start for GitLab CI is found [here](https://docs.gitlab.com/ee/ci/quick_start/).

</details>

### Build a minimal image for deployment

<details open><summary>GitHub</summary>

```yml
jobs:
  docker-ros:
    runs-on: ubuntu-latest
    steps:
      - uses: ika-rwth-aachen/docker-ros@main
        with:
          base-image: rwthika/ros2:humble
          command: ros2 run my_pkg my_node
```

</details>

<details open><summary>GitLab</summary>

```yml
include:
  - remote: https://raw.githubusercontent.com/ika-rwth-aachen/docker-ros/main/.gitlab-ci/docker-ros.yml

variables:
  BASE_IMAGE: rwthika/ros2:humble
  COMMAND: ros2 run my_pkg my_node
```

</details>

### Build development and deployment images

<details><summary>GitHub</summary>

```yml
jobs:
  docker-ros:
    runs-on: ubuntu-latest
    steps:
      - uses: ika-rwth-aachen/docker-ros@main
        with:
          base-image: rwthika/ros2:humble
          command: ros2 run my_pkg my_node
          target: dev,run
```

</details>

<details><summary>GitLab</summary>

```yml
include:
  - remote: https://raw.githubusercontent.com/ika-rwth-aachen/docker-ros/main/.gitlab-ci/docker-ros.yml

variables:
  BASE_IMAGE: rwthika/ros2:humble
  COMMAND: ros2 run my_pkg my_node
  TARGET: dev,run
```

</details>

### Build multi-arch images

<details><summary>GitHub</summary>

```yml
jobs:
  docker-ros:
    runs-on: ubuntu-latest
    steps:
      - uses: ika-rwth-aachen/docker-ros@main
        with:
          base-image: rwthika/ros2:humble
          command: ros2 run my_pkg my_node
          target: dev,run
          platform: amd64,arm64
```

</details>

<details><summary>GitLab</summary>

```yml
include:
  - remote: https://raw.githubusercontent.com/ika-rwth-aachen/docker-ros/main/.gitlab-ci/docker-ros.yml

variables:
  BASE_IMAGE: rwthika/ros2:humble
  COMMAND: ros2 run my_pkg my_node
  TARGET: dev,run
  PLATFORM: amd64,arm64
```

</details>

### Build deployment image with additional industrial_ci check

<details><summary>GitHub</summary>

```yml
jobs:
  docker-ros:
    runs-on: ubuntu-latest
    steps:
      - uses: ika-rwth-aachen/docker-ros@main
        with:
          base-image: rwthika/ros2:humble
          command: ros2 run my_pkg my_node
          enable-industrial-ci: 'true'
```

</details>

<details><summary>GitLab</summary>

```yml
include:
  - remote: https://raw.githubusercontent.com/ika-rwth-aachen/docker-ros/main/.gitlab-ci/docker-ros.yml

variables:
  BASE_IMAGE: rwthika/ros2:humble
  COMMAND: ros2 run my_pkg my_node
  ENABLE_INDUSTRIAL_CI: 'true'
```

</details>

### Build multi-arch images on arch-specific self-hosted runners in parallel

<details><summary>GitHub</summary>

```yml
jobs:
  docker-ros:
    strategy:
      matrix:
        target: [dev, run]
        platform: [amd64, arm64]  
    runs-on: [self-hosted, "${{ matrix.platform }}"]
    steps:
      - uses: ika-rwth-aachen/docker-ros@main
        with:
          base-image: rwthika/ros2:humble
          command: ros2 run my_pkg my_node
          target: ${{ matrix.target }}
          platform: ${{ matrix.platform }}
          enable-singlearch-push: true
      # TODO: manifest
```

</details>

<details><summary>GitLab</summary>

```yml
# TODO
```

</details>

### Build images locally

*docker-ros* can build Docker images locally by executing the [`build.sh`](scripts/build.sh) script.

1. Clone *docker-ros* as a Git submodule to `docker/docker-ros` in your repository.
    ```bash
    # ros-repository/
    mkdir -p docker
    git submodule add https://github.com/ika-rwth-aachen/docker-ros.git docker/docker-ros
    ```
2. Configure the build using the same [environment variables](#configuration-variables) as used for GitLab CI and run [`build.sh`](scripts/build.sh), e.g.:
    ```bash
    # ros-repository/
    cd docker
      BASE_IMAGE="rwthika/ros2:humble" \
      COMMAND="ros2 run my_pkg my_node" \
      IMAGE="my-image:latest" \
    ./docker-ros/scripts/build.sh
    ```
    > **Note**  
    > You can save your environment variable configuration in a `.env` file and source it before running the build script.


## Advanced Dependencies

In order to keep things organized, we recommend to place all *docker-ros* related files in a `docker` folder on top repository level.

### Extra System Dependencies (apt)

If your ROS-based repository requires system dependencies that cannot be installed by specifying their [rosdep](https://docs.ros.org/en/independent/api/rosdep/html/) keys in a `package.xml`, you can use the special `additional.apt-dependencies` file.

Create a file `additional.apt-dependencies` in your `docker` folder and list any other dependencies that need to be installed via apt.

### Custom Installation Script

If your ROS-based repository requires to execute any other installation or pre-/post-installation steps, you can use the special `custom.sh` script.

Create a script `custom.sh` in your `docker` folder that executes arbitrary commands as part of the image building process.

### Extra Image Files

If you need to have additional files present in the deployment image, you can use the special `files` folder. These will be copied into the container before the custom installation script `custom.sh` is executed.

Create a folder `files` in your `docker` folder and place any files or directories in it. The contents will be copied to `/docker-ros/files` in the image.


## Configuration Variables

> **Note**  
> *GitHub Action input* | *GitLab CI environment variable*

- **`base-image` | `BASE_IMAGE`**  
  Base image `name:tag`  
  *required*  
- **`build-context` | `BUILD_CONTEXT`**  
  Build context of Docker build process  
  *default:* `${{ github.workspace }}` | `.`  
- **`command` | `COMMAND`**  
  Launch command of run image  
  *required if `target=run`*  
- **`dev-image-name` | `DEV_IMAGE_NAME`**  
  Image name of dev image  
  *default:* `<IMAGE_NAME>`  
- **`dev-image-tag` | `DEV_IMAGE_TAG`**  
  Image tag of dev image  
  *default:* `<IMAGE_TAG>-dev`  
- **`-` | `DOCKER_ROS_GIT_REF`**  
  Git reference of *docker-ros* to run in CI  
  *default:* `main` 
- **`enable-industrial-ci` | `ENABLE_INDUSTRIAL_CI`**  
  Enable [*industrial_ci*](https://github.com/ros-industrial/industrial_ci)  
  *default:* `false` 
- **`enable-push-as-latest` | `ENABLE_PUSH_AS_LATEST`**  
  Push images with tag `latest`/`latest-dev` in addition to the configured image names  
  *default:* `false`  
- **`enable-singlearch-push` | `ENABLE_SINGLEARCH_PUSH`**  
  Enable push of single arch images with `-amd64`/`-arm64` postfix  
  *default:* `false` 
- **`git-https-password` | `GIT_HTTPS_PASSWORD`**  
  Password for cloning private Git repositories via HTTPS  
  *default:* `${{ github.token }}` | `$CI_JOB_TOKEN` 
- **`git-https-server` | `GIT_HTTPS_SERVER`**  
  Server URL (without protocol) for cloning private Git repositories via HTTPS  
  *default:* `github.com` | `$CI_SERVER_HOST:$CI_SERVER_PORT` 
- **`git-https-user` | `GIT_HTTPS_USER`**  
  Username for cloning private Git repositories via HTTPS  
  *default:* `${{ github.actor }}` | `gitlab-ci-token`  
- **`git-ssh-known-host-keys` | `GIT_SSH_KNOWN_HOST_KEYS`**  
  Known SSH host keys for cloning private Git repositories via SSH (may be obtained using `ssh-keyscan`)  
- **`git-ssh-private-key` | `GIT_SSH_PRIVATE_KEY`**  
  SSH private key for cloning private Git repositories via SSH  
- **`image-name` | `IMAGE_NAME`**  
  Image name of run image  
  *default:* `ghcr.io/${{ github.repository }}` | `$CI_REGISTRY_IMAGE`  
- **`image-tag` | `IMAGE_TAG`**  
  Image tag of run image
  *default:* `latest`  
- **`platform` | `PLATFORM`**  
  Target platform architecture (comma-separated list)  
  *default:* runner architecture
  *supported values:* `amd64`, `arm64`
- **`registry-password` | `REGISTRY_PASSWORD`**  
  Docker registry password  
  *default:* `${{ github.token }}` | `$CI_REGISTRY_PASSWORD`  
- **`registry-username` | `REGISTRY_USERNAME`**  
  Docker registry username  
  *default:* `${{ github.actor }}` | `$CI_REGISTRY_USER`  
- **`registry` | `REGISTRY`**  
  Docker registry to push images to  
  *default:* `ghcr.io` | `$CI_REGISTRY`  
- **`target` | `TARGET`**  
  Target stage of Dockerfile (comma-separated list)  
  *default:* `run`
  *supported values:* `dev`, `run`
