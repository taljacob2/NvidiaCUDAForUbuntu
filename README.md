# NVIDIA CUDA For Ubuntu

A script which installs for Ubuntu:
- NVIDIA Drivers
- NVIDIA CUDA Drivers
- Optionally additional NVIDIA CUDA tools

See [NVIDIA Drivers Installation Guide](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html#ubuntu-installation)

## Usage - Download And Execute Immediately

Example Usage Via `curl`:

```bash
curl -s https://raw.githubusercontent.com/taljacob2/nvidia-cuda-for-ubuntu/refs/heads/master/install-nvidia-drivers-and-cuda-for-ubuntu.sh | sudo bash -s -- -s -r -o -d -c=docker
```

Or Example Usage Via `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/taljacob2/nvidia-cuda-for-ubuntu/refs/heads/master/install-nvidia-drivers-and-cuda-for-ubuntu.sh | sudo bash -s -- -s -r -o -d -c=docker
```
