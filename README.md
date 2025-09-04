# ICIP Sandbox

<p align="center"><img src="logo.svg" alt="ICIP Sandbox Logo" width="480"></p>

⚡ A scalable sandbox for better accommodation of code-RL training | 🛡️ Secure | 🌐 Multi-language | 🔥 Fast

## 📋 Table of Contents
- [✨ Updates](#updates)
- [🎯 Features](#features)
- [🚀 Usage](#usage)
- [📝 Citation](#citation)
- [🙏 Acknowledgement](#acknowledgement)
- [📄 License](#license)

## ✨ Updates
- Adapted to RL training frameworks including [verl](https://github.com/volcengine/verl?tab=readme-ov-file), and Ascend NPU environment with [verl](https://github.com/volcengine/verl?tab=readme-ov-file) and [MindSpeed-RL](https://github.com/Ascend/MindSpeed-RL)
- Added support for unified evaluation interface for code generation tasks
- Improved sandbox setup parameters for better controllability
- Added support for automatic distributed deployment
- Added support for sandbox exception logging

## 🎯 Features

**Code Runner**: Run and return the result of a code snippet

Supported languages:

- Python (python, pytest)
- C++
- C#
- Go (go, go test)
- Java (javac, junit)
- NodeJS
- Typescript (tsx, jest)
- Scala
- Kotlin
- PHP
- Rust
- Bash
- Lua
- R
- Perl
- D
- Ruby
- Julia
- Verilog
- CUDA (GPU)
- Python (GPU)

Jupyter mode kernels:

- python3

**Online Judge**: Implementation of Evaluation & RL datasets that requires code running

- [HumanEval](https://github.com/openai/human-eval)
- [MultiPL-E HumanEval](https://github.com/nuprl/MultiPL-E)
- [Shadow Humaneval](https://huggingface.co/datasets/Miaosen/openai-humaneval-sky-shadow)
- [CodeContests](https://github.com/google-deepmind/code_contests)
- [MBPP](https://github.com/google-research/google-research/tree/master/mbpp)
- [MBXP](https://github.com/amazon-science/mxeval)
- [MHPP](https://github.com/SparksofAGI/MHPP)
- [CRUXEval](https://github.com/facebookresearch/cruxeval)
- [NaturalCodeBench](https://github.com/THUDM/NaturalCodeBench)
- [PAL-Math](https://github.com/deepseek-ai/DeepSeek-Coder/tree/main/Evaluation/PAL-Math)
- [verilog-eval](https://github.com/NVlabs/verilog-eval)

**Unified Evaluation**: A unified evaluation interface for code generation tasks, including stdio and function call evaluation modes on various languages

- [common_evaluate_batch](#calling-the-sandbox)

## 🚀 Usage

### 📦 Installation

**Docker**

Use the provided docker `zhengxin1999/icip-sandbox:v1` 

Or, build the image locally:

```bash
docker build --rm -f ./scripts/Dockerfile.v2 -t code_sandbox:server .
```

For **ARM64** environment, you can use the image `crpi-x4j7ugz3dc0rfat9.cn-beijing.personal.cr.aliyuncs.com/zhuqiming/ascend910b:code_sandbox`

Or, build the image locally:

```bash
docker build --rm -f ./scripts/Dockerfile.arm64 -t code_sandbox:server .
```

### 🌐 Deployment

#### 🔧 Environment Variables
Before deployment, configure the following environment variables:
```bash
# Server configuration
export HOST=0.0.0.0           # Server host address
export PORT=8080              # Server port
export WORKERS=4              # Number of parallel workers for uvicorn (set 1 for single CPU)
export MAX_MEM=500000        # Maximum memory limit per process in KB (500MB), or 'unlimited'
export SAVE_BAD_CASES=false  # Set 'true' to save bad cases for debugging in 'output/{datetime}/'
```

#### 💻 Single-Node Deployment
For running the sandbox on a single machine:

```bash
# Start the server with basic configuration
make run-online

# OR use supervisor for automatic restart on failure
bash deploy/start_sandbox_with_supervisor.sh
```

#### 🌍 Distributed Deployment
For running the sandbox across multiple machines:

1. **Main Node Setup** (Load Balancer)
   ```bash
   # On the main node (acts as load balancer)
   export PORT=8081              # nginx will run on this port
   bash deploy/start_distributed_nginx.sh
   ```

2. **Worker Node Setup**
   ```bash
   # On each worker node
   export HOST=0.0.0.0
   export PORT=8080              # Worker nodes run on port 8080
   export WORKERS=4              # Adjust based on CPU cores
   export MAX_MEM=500000        # Adjust based on available memory
   export SAVE_BAD_CASES=false

   make run-distributed
   ```

#### 📈 Scaling the Distributed Setup
- To add or remove worker nodes:
  1. Start/stop the worker nodes using the worker node setup instructions above
  2. Re-run `bash deploy/start_distributed_nginx.sh` on the main node
  - The nginx configuration will automatically update to include all available worker nodes

#### 🐳 Docker Deployment
To run the sandbox server using Docker with health check and automatic restart on failure:

```bash
docker run \
    --privileged \
    -p 8080:8080 \
    -p 8081:8081 \
    --volume ~/icip-sandbox:/icip-sandbox \
    -w /icip-sandbox \
    --health-cmd='python /icip-sandbox/deploy/a_plus_b.py || exit 1' \
    --health-interval=2s \
    -itd \
    --restart unless-stopped \
    zhengxin1999/icip-sandbox:v1 \
    make run-online
```

### 🔌 Calling the sandbox
In additioon to the originally provided dataset-specific evaluation APIs, we also provide a unified evaluation API, which includes both stdio and function call evaluation modes on various languages.
Here is an example of how to use the `common_evaluate_batch` API for testing a+b problem with standard input/output format.
```python
# stdio evaluate
payload = {
    "completion": """```python\na, b = map(int, input().split())\nprint(a + b)\n```""",
    "config": {
        "language": "python",
        "run_timeout": 10,
        "provided_data": { 
            "test_cases": 
                {"type": "stdin_stdout", "input": ["1 2", "3 4"], "output": ["3", "7"], "fn_name": None},            
        },
        "extra": {
            "run_all_cases": True
        }
    }
}

response = requests.post('http://0.0.0.0:8080/common_evaluate_batch', json=payload)
result = response.json()
```

<details>
<summary>Response</summary>

```json
{
    "id": 0,
    "accepted": true,
    "extracted_code": "a, b = map(int, input().split())\nprint(a + b)",
    "full_code": null,
    "test_code": null,
    "tests": [
        {
            "passed": true,
            "exec_info": {
                "status": "Success",
                "message": "",
                "compile_result": null,
                "run_result": {
                    "status": "Finished",
                    "execution_time": 0.0040967464447021484,
                    "return_code": 0,
                    "stdout": "3\n",
                    "stderr": ""
                },
                "executor_pod_name": null,
                "files": {}
            },
            "test_info": {
                "input": {
                    "stdin": "1 2"
                },
                "output": {
                    "stdout": "3"
                }
            }
        },
        {
            "passed": true,
            "exec_info": {
                "status": "Success",
                "message": "",
                "compile_result": null,
                "run_result": {
                    "status": "Finished",
                    "execution_time": 0.017037630081176758,
                    "return_code": 0,
                    "stdout": "7\n",
                    "stderr": ""
                },
                "executor_pod_name": null,
                "files": {}
            },
            "test_info": {
                "input": {
                    "stdin": "3 4"
                },
                "output": {
                    "stdout": "7"
                }
            }
        }
    ],
    "extracted_type": null,
    "extra": null
}
```

</details>

Also an example of function call evaluation for the same problem:
```python
# function evaluate batch
payload = {
    "completion": """```python\ndef add(a, b):\n    return a + b\n```""",
    "config": {
        "language": "python",
        "provided_data": { 
            "test_cases": 
                {"type": "function_call", "input": [[1, 2], [3, 4]], "output": [3, 7], "fn_name": "add"},            
        },
        "extra": {
            "run_all_cases": True
        }
    }
}

response = requests.post('http://0.0.0.0:8080/common_evaluate_batch', json=payload)
result = response.json()
```

<details>
<summary>Response</summary>

```json
{
    "id": 0,
    "accepted": true,
    "extracted_code": "def add(a, b):\n    return a + b",
    "full_code": null,
    "test_code": null,
    "tests": [
        {
            "passed": true,
            "exec_info": {
                "status": "Success",
                "message": "",
                "compile_result": null,
                "run_result": {
                    "status": "Finished",
                    "execution_time": 0.00021147727966308594,
                    "return_code": 0,
                    "stdout": "",
                    "stderr": ""
                },
                "executor_pod_name": null,
                "files": {}
            },
            "test_info": {
                "type": "function_call",
                "fn_name": "add",
                "input": [1, 2],
                "output": [3]
            }
        },
        {
            "passed": true,
            "exec_info": {
                "status": "Success",
                "message": "",
                "compile_result": null,
                "run_result": {
                    "status": "Finished",
                    "execution_time": 0.01851511001586914,
                    "return_code": 0,
                    "stdout": "",
                    "stderr": ""
                },
                "executor_pod_name": null,
                "files": {}
            },
            "test_info": {
                "type": "function_call",
                "fn_name": "add",
                "input": [3, 4],
                "output": [7]
            }
        }
    ],
    "extracted_type": null,
    "extra": null
}
```

</details>

### 🛠️ Dev & Test

Refer to installation section for the setup of development environment.

Run all unit tests:

```bash
make test
```

Run a specific unit test (allows you to see stdout):

```bash
make test-case CASE=test_java_assert
```

Run a specific unit test with pdb:

```bash
make test-case-pdb CASE=test_java_assert
```

Format the code:

```bash
make format
```

### 🤖 Model Context Protocol
Install [fastmcp](https://gofastmcp.com/getting-started/installation), then start the mcp server, which connects to the sandbox `run_code` API:

```bash
cd mcp_server

export SANDBOX_URL="http://0.0.0.0:8080/run_code"
fastmcp run server.py --transport="http" --host 0.0.0.0 --port="8765"
```

Then, add the following to your MCP client:

```json
{
    "mcpServers": {
        "sandbox": {
            "httpUrl": "http://124.16.138.150:8765/mcp"
        }
    }
}
```

## 📝 Citation
```bibtex
@software{icip_cas_sandbox_2025,
  author = {},
  title = {{icip-sandbox}},
  url = {https://github.com/icip-cas/icip-sandbox},
  year = {2025}
}
```

## 🙏 Acknowledgement

This project is modified from [SandboxFusion](https://github.com/bytedance/SandboxFusion), an open-source secure sandbox for running and judging code generated by LLMs. We extend our gratitude to the original authors and contributors of SandboxFusion for their excellent work in creating a robust foundation for code execution and evaluation.

The original SandboxFusion project is licensed under the Apache License 2.0 and is maintained by ByteDance. For more information about the original project, please visit their [GitHub repository](https://github.com/bytedance/SandboxFusion).

## 📄 License

```
Copyright 2025 Chinese Information Processing Laboratory, Institute of Software, Chinese Academy of Sciences.
Copyright 2024 Bytedance Ltd. and/or its affiliates

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
