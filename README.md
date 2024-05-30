# docker-MoE-LLaVA

This is the docker image for [gesen2egee/MoE-LLaVA-hf](https://github.com/gesen2egee/MoE-LLaVA-hf), a script that uses [MoE-LLaVA](https://github.com/PKU-YuanGroup/MoE-LLaVA) to describe images. It is designed to prepare the training set caption for stable diffusion model training.

Get the Dockerfile at [GitHub](https://github.com/jim60105/docker-MoE-LLaVA), or pull the image from [ghcr.io](https://ghcr.io/jim60105/moe-llava).

## 🚀 Get your Docker ready for GPU support

### Windows

Once you have installed [**Docker Desktop**](https://www.docker.com/products/docker-desktop/), [**CUDA Toolkit**](https://developer.nvidia.com/cuda-downloads), [**NVIDIA Windows Driver**](https://www.nvidia.com.tw/Download/index.aspx), and ensured that your Docker is running with [**WSL2**](https://docs.docker.com/desktop/wsl/#turn-on-docker-desktop-wsl-2), you are ready to go.

Here is the official documentation for further reference.  
<https://docs.nvidia.com/cuda/wsl-user-guide/index.html#nvidia-compute-software-support-on-wsl-2>
<https://docs.docker.com/desktop/wsl/use-wsl/#gpu-support>

### Linux, OSX

Install an NVIDIA GPU Driver if you do not already have one installed.  
<https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html>

Install the NVIDIA Container Toolkit with this guide.  
<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html>

## 📦 Available Pre-built Image

You can pull the pre-build image which **does not include the models** from the GitHub Container Registry.  
These images will download the models at runtime.

Mount the current directory as `/dataset` and run the script with additional input arguments.

> [!IMPORTANT]  
> Remember to prepend `--` before the arguments.

```bash
docker run --gpus all -it -v ".:/dataset" ghcr.io/jim60105/moe-llava:no_model -- [arguments]
# Example
docker run --gpus all -it -v ".:/dataset" ghcr.io/jim60105/moe-llava:no_model -- --moe --force --caption_style='mixed' --folder_name --modify_prompt --low_vram
```

The `[arguments]` placeholder should be replaced with the [arguments for the script](https://github.com/gesen2egee/MoE-LLaVA-hf/blob/main/predict.py#L352-L360). Check the [original colab notebook](https://github.com/gesen2egee/MoE-LLaVA-hf/blob/main/MoE_LLaVA_jupyter.ipynb) for more information.

## ⚡️ Preserve the download cache for the models

You can mount the `/.cache` to share model caches between containers.  
In this way, they will not be repeatedly downloaded every time when image start.

```bash
docker run --gpus all -it -v ".:/dataset" -v "moe_cache:/.cache" ghcr.io/jim60105/moe-llava:no_model -- --moe --force --caption_style='mixed' --folder_name --modify_prompt --low_vram
```

## 🛠️ Building the Image *include models*

> [!CAUTION]  
> These models are really large! They blows up the image size to ***40GB*** 😕  
> It is recommended to use the no-model image and mount the cache volume.  
> ![image](https://github.com/jim60105/docker-MoE-LLaVA/assets/16995691/17a58c24-8e2f-4d73-aa77-9495f9a1ccfb)

> [!IMPORTANT]  
> Clone the Git repository recursively to include submodules:  
> `git clone --recursive https://github.com/jim60105/docker-MoE-LLaVA.git`

You can build the image which includes the models by targeting to the final stage.  
Use the `LOW_VRAM` build argument and to choose the model to preload.

- (No build-arg): Preload the `LanguageBind/MoE-LLaVA-Phi2-2.7B-4e` model.
- `LOW_VRAM=1`: Preload the `LanguageBind/MoE-LLaVA-StableLM-1.6B-4e-384` model.

```bash
docker build -t moe-llava --target final --build-arg LOW_VRAM=1 .
```

## 📝 LICENSE

> [!NOTE]  
> The main program, [PKU-YuanGroup/MoE-LLaVA](https://github.com/PKU-YuanGroup/MoE-LLaVA) and [the predict script](https://github.com/gesen2egee/MoE-LLaVA-hf/blob/main/LICENSE), is distributed under [Apache License 2.0](https://github.com/PKU-YuanGroup/MoE-LLaVA/blob/main/LICENSE).  
> Please consult their repository for access to the source code and licenses.  
> The following is the license for the Dockerfiles and CI workflows in this repository.

<img src="https://github.com/jim60105/docker-MoE-LLaVA/assets/16995691/65f76d01-a00b-4a93-86b6-a06bc3667869" alt="gplv3" width="300" />

[GNU GENERAL PUBLIC LICENSE Version 3](LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

> [!CAUTION]
> A GPLv3 licensed Dockerfile means that you _**MUST**_ **distribute the source code with the same license**, if you
>
> - Re-distribute the image. (You can simply point to this GitHub repository if you doesn't made any code changes.)
> - Distribute a image that uses code from this repository.
> - Or **distribute a image based on this image**. (`FROM ghcr.io/jim60105/moe-llava` in your Dockerfile)
>
> "Distribute" means to make the image available for other people to download, usually by pushing it to a public registry. If you are solely using it for your personal purposes, this has no impact on you.
>
> Please consult the [LICENSE](LICENSE) for more details.
