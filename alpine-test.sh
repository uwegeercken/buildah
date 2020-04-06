#!/bin/bash

image_base="alpine"
image_name="myalpine"
image_version="1.0"
image_format="docker"
image_author="uwe.geercken@web.de"
image_registry="silent1:8083"
image_registry_group="${image_registry_docker_group}"
image_registry_user="admin"
image_tag="${image_registry}/${image_name}:${image_version}"

container_user="uwe"
container_user_group="uwe"

echo "start of build: ${image_name}:${image_version}"
container=$(buildah from ${image_registry_group}/${image_base})

echo "working container: ${container}"

buildah run $container adduser -S "${container_user}" -G "${container_user_group}"
buildah run $container chown root:${container_user} /opt
buildah run $container chmod g+w /opt

buildah config --created-by "${image_author}" $container
buildah config --author "${image_author}" $container
buildah config --label name="${image_name}" $container
buildah config --user "${container_user}" $container

echo "committing to image: ${image_name}"
buildah commit --format "${image_format}" $container "${image_name}"

echo "removing container: ${container}"
buildah rm $container

echo "tagging ${image_name}: ${image_tag}"
buildah tag  "${image_name}" "${image_tag}"

echo "login to registry ${image_registry}, using user: ${image_registry_user}"
buildah login -u "${image_registry_user}" -p fasthans "${image_registry}"

echo "pushing image to: ${image_registry}"
buildah push --tls-verify=false "${image_name}" "docker://${image_registry}/${image_name}"
buildah push --tls-verify=false "${image_name}:${image_version}" "docker://${image_tag}"
