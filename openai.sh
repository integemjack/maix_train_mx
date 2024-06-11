#!/bin/bash

DOCKERFILE_PATH="./Dockerfile"
API_KEY=$OPENAI_API_KEY
API_URL="https://api.openai.com/v1/chat/completions"

run_command() {
    echo "Running command: $1"
    eval "$1" 2>&1 | tee -a output.log
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "Command error: $1 failed"
        exit 1
    fi
}

build_docker_image() {
    echo "Building Docker image..."
    docker build -t integem/notebook:maix_train_mx_v3 . 2>&1 | tee -a output.log
    return ${PIPESTATUS[0]}
}

run_docker_container() {
    echo "Running Docker container..."
    docker run --rm -it -p 8888:8888 integem/notebook:maix_train_mx_v3 bash -c "cd maix_train_mx && python train.py" 2>&1 | tee -a output.log
    return ${PIPESTATUS[0]}
}

get_modified_dockerfile() {
    echo "Getting modified Dockerfile..."
    response=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
          "model": "gpt-4o",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant that can fix Dockerfiles."},
            {"role": "user", "content": "Here is a Dockerfile:\n\n'"$1"'\n\nAnd here is the error message:\n\n'"$2"'\n\nPlease provide a corrected version of the Dockerfile."}
          ],
          "max_tokens": 4096
        }')

    echo "$response" | jq -r '.choices[0].message.content'
}

extract_dockerfile_content() {
    echo "Extracting Dockerfile content..."
    echo "$1" | sed -n '/```/,/```/p' | sed '1d;$d'
}

main() {
    while true; do
        build_docker_image
        if [ $? -ne 0 ]; then
            echo "Error building Docker image"
            dockerfile_content=$(cat "$DOCKERFILE_PATH")
            echo "Current Dockerfile content: $dockerfile_content"
            error_message=$(docker build -t integem/notebook:maix_train_mx_v3 . 2>&1)
            modified_dockerfile=$(get_modified_dockerfile "$dockerfile_content" "$error_message")
            if [ -z "$modified_dockerfile" ]; then
                echo "Failed to get modified Dockerfile. Exiting..."
                break
            fi
            extracted_content=$(extract_dockerfile_content "$modified_dockerfile")
            echo "Writing modified Dockerfile..."
            echo "$extracted_content" > "$DOCKERFILE_PATH"
            continue
        fi

        run_docker_container
        if [ $? -ne 0 ]; then
            echo "Error running Docker container"
            dockerfile_content=$(cat "$DOCKERFILE_PATH")
            echo "Current Dockerfile content: $dockerfile_content"
            error_message=$(docker run --rm -it -p 8888:8888 integem/notebook:maix_train_mx_v3 bash -c "cd maix_train_mx && python train.py" 2>&1)
            modified_dockerfile=$(get_modified_dockerfile "$dockerfile_content" "$error_message")
            if [ -z "$modified_dockerfile" ]; then
                echo "Failed to get modified Dockerfile. Exiting..."
                break
            fi
            extracted_content=$(extract_dockerfile_content "$modified_dockerfile")
            echo "Writing modified Dockerfile..."
            echo "$extracted_content" > "$DOCKERFILE_PATH"
            continue
        fi

        echo "Docker container ran successfully with output:"
        break
    done
}

main
