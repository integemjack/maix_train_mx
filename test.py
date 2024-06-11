import subprocess
import requests
import json
import re
import os

# 定义一些常量
DOCKERFILE_PATH = "./Dockerfile"
API_KEY = os.getenv("OPENAI_API_KEY")
API_URL = "https://api.openai.com/v1/chat/completions"

def run_command(command):
    print(f"Running command: {command}")
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            print(output.strip())

    stderr = process.stderr.read()
    if stderr:
        print(f"Command error: {stderr.strip()}")
    return process.poll(), stderr

def build_docker_image():
    print("Building Docker image...")
    process = subprocess.Popen("docker build -t integem/notebook:maix_train_mx_v3 .", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            print(output.strip())

    stderr = process.stderr.read()
    if stderr:
        print(f"Docker build error: {stderr.strip()}")
    return process.poll(), stderr

def run_docker_container():
    print("Running Docker container...")
    process = subprocess.Popen('docker run --rm -it -p 8888:8888 integem/notebook:maix_train_mx_v3 bash -c "cd maix_train_mx && python train.py"', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            print(output.strip())

    stderr = process.stderr.read()
    if stderr:
        print(f"Docker run error: {stderr.strip()}")
    return process.poll(), stderr

def get_modified_dockerfile(error_message, dockerfile_content):
    print("Getting modified Dockerfile...")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    }
    data = {
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant that can fix Dockerfiles."},
            {"role": "user", "content": f"Here's a Dockerfile:\n\n{dockerfile_content}\n\nAnd here's the error message:\n\n{error_message}\n\nPlease provide a corrected version of the Dockerfile."}
        ],
        "max_tokens": 4096,
    }
    response = requests.post(API_URL, headers=headers, data=json.dumps(data))
    if response.status_code != 200:
        print(f"Error calling OpenAI API: {response.status_code}")
        print(f"Response: {response.text}")
        return ""

    response_json = response.json()
    if "choices" not in response_json or not response_json["choices"]:
        print("Invalid response from OpenAI API")
        print(f"Response JSON: {response_json}")
        return ""

    modified_dockerfile = response_json["choices"][0]["message"]["content"]
    print(f"Modified Dockerfile received: {modified_dockerfile}")
    return modified_dockerfile

def extract_dockerfile_content(modified_dockerfile):
    print("Extracting Dockerfile content...")
    match = re.search(r'```(dockerfile)?(.*?)```', modified_dockerfile, re.DOTALL | re.IGNORECASE)
    if match:
        extracted_content = match.group(2).strip()
        print(f"Extracted Dockerfile content: {extracted_content}")
        return extracted_content
    return modified_dockerfile

def main():
    while True:
        return_code, stderr = build_docker_image()
        if return_code != 0:
            print("Error building Docker image:")
            print(stderr)
            print("Reading current Dockerfile...")
            with open(DOCKERFILE_PATH, "r") as f:
                dockerfile_content = f.read()
                print(f"Current Dockerfile content:\n{dockerfile_content}")
            modified_dockerfile = get_modified_dockerfile(stderr, dockerfile_content)
            if not modified_dockerfile:
                print("Failed to get modified Dockerfile. Exiting...")
                break
            extracted_content = extract_dockerfile_content(modified_dockerfile)
            print("Writing modified Dockerfile...")
            with open(DOCKERFILE_PATH, "w") as f:
                f.write(extracted_content)
                print(f"Modified Dockerfile content:\n{extracted_content}")
            continue

        return_code, stderr = run_docker_container()
        if return_code != 0:
            print("Error running Docker container:")
            print(stderr)
            print("Reading current Dockerfile...")
            with open(DOCKERFILE_PATH, "r") as f:
                dockerfile_content = f.read()
                print(f"Current Dockerfile content:\n{dockerfile_content}")
            modified_dockerfile = get_modified_dockerfile(stderr, dockerfile_content)
            if not modified_dockerfile:
                print("Failed to get modified Dockerfile. Exiting...")
                break
            extracted_content = extract_dockerfile_content(modified_dockerfile)
            print("Writing modified Dockerfile...")
            with open(DOCKERFILE_PATH, "w") as f:
                f.write(extracted_content)
                print(f"Modified Dockerfile content:\n{extracted_content}")
            continue

        print("Docker container ran successfully with output:")
        break

if __name__ == "__main__":
    main()
