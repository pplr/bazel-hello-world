set -eu

DOCKER="%{docker_tool_path}"

if [[ -z "${DOCKER}" ]]; then
    echo >&2 "error: docker not found; do you need to manually configure the docker toolchain?"
    exit 1
fi

export IMAGE=$("${DOCKER}" import "%{docker_image}")
echo ${IMAGE}

docker-compose -f "%{compose_file}" up --renew-anon-volumes