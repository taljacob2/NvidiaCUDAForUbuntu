#!/bin/bash

: '
This script installs:
- **NVIDIA Drivers**
  Verify the installation with:
  ```
  lsmod | grep nvidia
  sudo dmesg | grep -i nvidia
  dkms status
  ls -l /dev/nvidia*
  nvidia-smi
  ```

- **NVIDIA CUDA Drivers**
  Verify the installation with:
  ```
  nvcc -V
  ```

- **Optionally, additional NVIDIA CUDA Drivers**
  - **CuDNN**
    Verify the installation with:
    ```
    ls /usr/src/cudnn_samples_*
    ```
    or even further with https://docs.nvidia.com/deeplearning/cudnn/archives/cudnn-890/install-guide/index.html#verify

Requirements:
- Ubuntu Linux.
- Secure boot is disabled (you can check it with 'mokutil --sb-state').
- There is an NVIDIA GPU attached (you can check it with 'lspci -nnk | grep -i nvidia').
- Run this script with `sudo` privilleges.
- A reboot is required to complete the installation.

See all the documentation here:

```
bash install-nvidia-drivers-and-cuda-for-ubuntu.sh --help
```
'


IS_HEADLESS_SERVER=false
IS_REBOOT_AFTER_INSTALLATION=false
IS_OVERWRITE_OTHER_INSTALLATIONS=false
IS_INSTALL_CUDNN=false

export DEBIAN_FRONTEND=noninteractive

displayHelp() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "This script installs:"
    echo "- NVIDIA Drivers"
    echo "- NVIDIA CUDA Drivers"
    echo "- Optionally, additional NVIDIA CUDA Drivers"
    echo
    echo "Requirements:"
    echo "- Ubuntu Linux."
    echo "- Secure boot is disabled."
    echo "- There is an NVIDIA GPU attached (you can check it with 'lspci -nnk | grep -i nvidia | grep -i vga')"
    echo "- Run this script with 'sudo' privilleges."
    echo
    echo "Options:"
    echo "  -h, --help               Show this help message and exit."
    echo "  -s, --headless-server    Boolean. "false" by default."
    echo "                           Install in headless mode (no attached display)."
    echo "                           Set this to "true" only if you run Ubuntu Server without a display attached."
    echo "  -r, --reboot             Boolean. "false" by default."
    echo "                           A reboot is required to complete the installation."
    echo "                           This option reboots the system after installation."
    echo "                           Set this to "true" if you wish for the script to do so for you."
    echo "                           Set this to "false" if you wish to do so manually later."
    echo "  -o, --overwrite          Boolean. "false" by default."
    echo "                           Overwrite existing NVIDIA/CUDA installations."
    echo "  -d, --cudnn              Boolean. "false" by default."
    echo "                           Install cuDNN."
    echo
    exit 0
}


removeNvidiaDrivers() {
  sudo apt-get remove -y --purge '^nvidia-.*'
  sudo apt-get remove -y --purge '^libnvidia-.*'
  sudo apt-get autoremove -y
  sudo apt-get autoclean -y
}

installNvidiaDrivers() {
  local recommendedDrivers=$(nvidia-detector)
  
  if [ $IS_HEADLESS_SERVER == "false" ]; then
    sudo ubuntu-drivers install
    sudo apt install $recommendedDrivers
  else
    sudo ubuntu-drivers install --gpgpu
    sudo apt install $recommendedDrivers-server
  fi
}

installNvidiaCudaDrivers() {
  sudo apt install -y g++ freeglut3-dev build-essential libx11-dev libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev

  # Documentation here: https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network

  # Install Nvidia Cuda Toolkit
  wget "https://developer.download.nvidia.com/compute/cuda/repos/$(uname -n)04/x86_64/cuda-keyring_1.1-1_all.deb"
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  sudo apt-get update
  sudo apt-get -y install cuda-toolkit-12-9

  # Install the proprietary kernel module flavor:
  sudo apt-get install -y cuda-drivers

  cat << EOF | sudo tee -a /etc/bash.bashrc
# Add nvidia cuda installation path
export PATH=$PATH:/usr/local/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
EOF

  # Import it to the shell:
  source /etc/bash.bashrc

  # Run ldconfig to update the shared library cache:
  sudo ldconfig
}

installCuDNN() {
  # Requires invocation of `installNvidiaCudaDrivers`
  # Documentation here: https://developer.nvidia.com/cudnn-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network
  sudo apt-get install -y cudnn-cuda-12
}


# Check if parameters options are given on the command line:
while :
do
    case "$1" in
      -s | --headless-server)
          IS_HEADLESS_SERVER=true
          shift 1
          ;;
      -r | --reboot)
          IS_REBOOT_AFTER_INSTALLATION=true
          shift 1
          ;;
      -o | --overwrite)
          IS_OVERWRITE_OTHER_INSTALLATIONS=true
          shift 1
          ;;
      -d | --cudnn)
          IS_INSTALL_CUDNN=true
          shift 1
          ;;
      -h | --help)
          displayHelp
          exit 0
          ;;
      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          # Or call function `displayHelp`
          exit 1
          ;;
      *)  # No more options
          break
          ;;
    esac
done


sudo apt update -y

sudo apt install gcc-12 g++-12 linux-headers-$(uname -r) build-essential

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 10
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 20
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 20

[ $IS_OVERWRITE_OTHER_INSTALLATIONS == "true" ] && removeNvidiaDrivers

installNvidiaDrivers
installNvidiaCudaDrivers

[ $IS_INSTALL_CUDNN == "true" ] && installCuDNN

# NOTE: `sudo reboot` is required to complete the installation.
[ $IS_REBOOT_AFTER_INSTALLATION == "true" ] && sudo reboot
