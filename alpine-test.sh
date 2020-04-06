#!/bin/bash

# script to build image from alpine base image_tag

# following environment variables are required to be available:
# image_registry_docker_group >> the url for the docker group repository in the registry server
# image_registry_docker_private >> the url for the docker private repository in the registry server


image_base="alpine"
image_name="myalpine"
image_version="1.0"
image_format="docker"
image_author="uwe.geercken@web.de"
image_registry_user="admin"
image_tag="${image_registry_docker_private}/${image_name}:${image_version}"

container_user="uwe"
container_user_group="uwe"

echo "[script] start of build: ${image_name}:${image_version}"
container=$(buildah from ${image_registry_docker_group}/${image_base})

echo "[script] working container: ${container}"

buildah run $container adduser -S "${container_user}" -G "${container_user_group}"
buildah run $container chown root:${container_user} /opt
buildah run $container chmod g+w /opt

buildah config --created-by "${image_author}" $container
buildah config --author "${image_author}" $container
buildah config --label name="${image_name}" $container
buildah config --user "${container_user}" $container

echo "[script] committing to image: ${image_name}"
buildah commit --format "${image_format}" $container "${image_name}"

echo "[script] removing container: ${container}"
buildah rm $container

echo "[script] tagging ${image_name}: ${image_tag}"
buildah tag  "${image_name}" "${image_tag}"

echo "[script] login to registry ${image_registry_docker_private}, using user: ${image_registry_user}"
buildah login -u "${image_registry_user}" -p fasthans "${image_registry_docker_private}"

echo "[script] pushing image ${image_name}:latest to: ${image_registry_docker_private}"
buildah push --tls-verify=false "${image_name}" "docker://${image_registry_docker_private}/${image_name}"
echo "[script] pushing image ${image_name}:${image_version} to: ${image_registry_docker_private}"
buildah push --tls-verify=false "${image_name}:${image_version}" "docker://${image_tag}"
