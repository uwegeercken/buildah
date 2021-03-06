#!/bin/bash

# script to build image from alpine base image_tag

# following environment variables are required to be available:
# image_registry_docker_group >> the url for the docker group repository in the registry server (for pulling images)
# image_registry_docker_private >> the url for the docker private repository in the registry server (for pushing images)
# image_registry_user >> the userid to login to the private registry (for pushing images)
# image_registry_password >> the password to login to the private registry (for pushing images)

image_base="alpine"
image_base_version="latest"

image_name="myalpine"
image_version="1.0"
image_format="docker"
image_author="uwe.geercken@web.de"

image_name_registry="${image_registry_docker_private}/${image_name}"
image_tag="${image_registry_docker_private}/${image_name}:${image_version}"

container_user="uwe"
container_user_group="uwe"

echo "[script] start of build: ${image_name_registry}:${image_version}"
container=$(buildah from ${image_registry_docker_group}/${image_base}:${image_base_version})

echo "[script] working container: ${container}"
buildah run $container addgroup -S "${container_user_group}"
buildah run $container adduser -S "${container_user}" -G "${container_user_group}"
buildah run $container chown root:${container_user} /opt
buildah run $container chmod g+w /opt

buildah config --created-by "${image_author}" $container
buildah config --author "${image_author}" $container
buildah config --label name="${image_name}" $container
buildah config --user "${container_user}" $container

echo "[script] committing to image: ${image_name_registry}"
buildah commit --format "${image_format}" $container "${image_name_registry}"

echo "[script] removing container: ${container}"
buildah rm $container

echo "[script] tagging ${image_name_registry}: ${image_tag}"
buildah tag  "${image_name_registry}" "${image_tag}"

echo "[script] login to registry ${image_registry_docker_private}, using user: ${image_registry_user}"
buildah login -u "${image_registry_user}" -p "${image_registry_password}" "${image_registry_docker_private}"

echo "[script] pushing image ${image_name_registry}:latest to: ${image_registry_docker_private}"
buildah push --tls-verify=false "${image_name_registry}" "docker://${image_name_registry}"
echo "[script] pushing image ${image_tag} to: ${image_registry_docker_private}"
buildah push --tls-verify=false "${image_tag}" "docker://${image_tag}"
