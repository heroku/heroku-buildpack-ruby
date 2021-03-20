#!/usr/bin/env bash
set -euo pipefail

# This script is an integral part of the release workflow: .github/workflows/release.yml
# It requires the following environment variables to function correctly:
#
# REQUESTED_BUILDPACK_ID - The ID of the buildpack to package and push to the container registry.

while IFS="" read -r -d "" buildpack_toml_path; do
	buildpack_id="$(yj -t <"${buildpack_toml_path}" | jq -r .buildpack.id)"
	buildpack_version="$(yj -t <"${buildpack_toml_path}" | jq -r .buildpack.version)"
	buildpack_docker_repository="$(yj -t <"${buildpack_toml_path}" | jq -r .metadata.release.docker.repository)"
	buildpack_path=$(dirname "${buildpack_toml_path}")
	buildpack_build_path="${buildpack_path}"

	if [[ $buildpack_id == "${REQUESTED_BUILDPACK_ID}" ]]; then
		# Some buildpacks require a build step before packaging. If we detect a build.sh script, we execute it and
		# modify the buildpack_build_path variable to point to the directory with the built buildpack instead.
		if [[ -f "${buildpack_path}/build.sh" ]]; then
			echo "Buildpack has build script, executing..."
			"${buildpack_path}/build.sh"
			echo "Build finished!"

			buildpack_build_path="${buildpack_path}/target"
		fi

		image_name="${buildpack_docker_repository}:${buildpack_version}"
		pack package-buildpack --config "${buildpack_build_path}/package.toml" --publish "${image_name}"

		# We might have local changes after building and/or shimming the buildpack. To ensure scripts down the pipeline
		# work with a clean state, we reset all local changes here.
		git reset --hard
		git clean -fdx

		echo "::set-output name=id::${buildpack_id}"
		echo "::set-output name=version::${buildpack_version}"
		echo "::set-output name=path::${buildpack_path}"
		echo "::set-output name=address::${buildpack_docker_repository}@$(crane digest "${image_name}")"
		exit 0
	fi
done < <(find . -name buildpack.toml -print0)

echo "Could not find requested buildpack with id ${REQUESTED_BUILDPACK_ID}!"
exit 1
