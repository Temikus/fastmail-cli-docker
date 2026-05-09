image_version := `grep -o 'ARG FASTMAIL_CLI_VERSION=[0-9.]*' Dockerfile | cut -d= -f2`
build_date := `date -u +%Y-%m-%d`
build_date_full := `date -u +%Y-%m-%dT%H:%M:%SZ`
build_timestamp := `date -u +%Y%m%dT%H%M%SZ`
vcs_ref := `git rev-parse --short HEAD`
image := "ghcr.io/temikus/fastmail-cli-mcp"

# Build the Docker image
build:
    docker build \
        --platform=linux/amd64 \
        --build-arg="BUILD_DATE={{ build_date_full }}" \
        --build-arg="VCS_REF={{ vcs_ref }}" \
        -t {{ image }} \
        -t {{ image }}:{{ image_version }} \
        -t {{ image }}:{{ image_version }}-{{ build_date }} \
        -t {{ image }}:{{ image_version }}-{{ build_timestamp }} \
        -t {{ image }}:latest \
        .
    @echo "{{ build_timestamp }}" > .build-timestamp

# Push the Docker image
push:
    docker push {{ image }}:{{ image_version }}
    docker push {{ image }}:{{ image_version }}-{{ build_date }}
    docker push {{ image }}:{{ image_version }}-$(cat .build-timestamp)
    docker push {{ image }}:latest
