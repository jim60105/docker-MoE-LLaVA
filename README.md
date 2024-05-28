# docker-MoE-LLaVA

This is the docker image for [gesen2egee/MoE-LLaVA-hf](https://github.com/gesen2egee/MoE-LLaVA-hf), a script that uses [MoE-LLaVA](https://github.com/PKU-YuanGroup/MoE-LLaVA) technology to predict descriptions for images. It is designed to prepare the training set caption for stable diffusion model training.

Get the Dockerfile at [GitHub](https://github.com/jim60105/docker-MoE-LLaVA), or pull the image from [ghcr.io](https://ghcr.io/jim60105/moe-llava).

## Usage Command

Mount the current directory as `/dataset` and run the script with additional input arguments.

> [!NOTE]  
> Remember to prepend `--` before the arguments.

```bash
docker run --gpus all -it -v ".:/dataset" ghcr.io/jim60105/moe-llava -- [arguments]

# Example
docker run --gpus all -it -v ".:/dataset" ghcr.io/jim60105/moe-llava -- --moe --force --caption_style='mixed' --folder_name --modify_prompt
```

The `[arguments]` placeholder should be replaced with the [arguments for the script](https://github.com/gesen2egee/MoE-LLaVA-hf/blob/main/predict.py#L354-L362). Check the [original colab notebook](https://github.com/gesen2egee/MoE-LLaVA-hf/blob/main/MoE_LLaVA_jupyter.ipynb) for more information.

### Build Command

> [!IMPORTANT]  
> Clone the Git repository recursively to include submodules:  
> `git clone --recursive https://github.com/jim60105/docker-MoE-LLaVA.git`

```bash
docker build -t moe-llava .
```

> [!NOTE]  
> If you are using an earlier version of the docker client, it is necessary to [enable the BuildKit mode](https://docs.docker.com/build/buildkit/#getting-started) when building the image. This is because I used the `COPY --link` feature which enhances the build performance and was introduced in Buildx v0.8.  
> With the Docker Engine 23.0 and Docker Desktop 4.19, Buildx has become the default build client. So you won't have to worry about this when using the latest version.

## LICENSE

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
