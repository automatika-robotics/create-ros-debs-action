# create-ros-debs-action

The `create-ros-debs-action` GitHub Action automates the process of creating installable Debian (deb) packages from a source repository containing a ROS2 package. It supports multiple versions of ROS2, allowing you to generate deb files for different distributions like Humble, Iron, Jazzy, etc. This action can be used for your internal CI pipelines and to create installable debs for self-hosted PPAs.

## Features

  - **Multi-version Support**: Generate deb files for specified or all non-EOL (End-of-Life) ROS 2 distributions.
  - **Docker-based Workflow**: Utilizes Docker to ensure consistent build environments across different platforms.

## Usage

To use `create-ros-debs-action` in your GitHub repository, add the following step to your workflow file (e.g., `.github/workflows/create_debs.yml`):

```yaml
name: Create ROS2 Debs

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  create_debs:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: automatika-robotics/create-ros-debs-action@v2
        with:
          source-dir-name: '.' # Optional, default is '.'
          target-dir-name: 'debs'  # Optional, default is 'debs'
          ros-versions-matrix: 'humble iron jazzy'  # Optional, this parameter is a space separated list of strings. Defaults to non-EOL ROS2 versions

      - uses: actions/upload-artifact@v3
        with:
          name: ros2-debs
          path: debs # Assuming 'debs' is your target-dir-name
```

## Inputs

| Input                 | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Required | Default Value                                    |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------ |
| `source-dir-name`     | Name of the directory with `package.xml`. Defaults to root directory.                                                                                                                                                                                                                                                                                                                                                                                                                           | No       | `.`                                              |
| `target-dir-name`     | Name of the directory for storing generated deb files. Defaults to `debs`.                                                                                                                                                                                                                                                                                                                                                                                                                      | No       | `'debs'`                                         |
| `ros-versions-matrix` | Space separated strings of ROS2 version names. e.g. `'humble iron jazzy'`. Defaults to versions which have not reached End-of-Life, check [https://endoflife.date/api/ros-2.json](https://endoflife.date/api/ros-2.json). | No       | Non-EOL ROS2 versions (as per API) |

## Contributions

All contributions are welcome\! If you find any bugs or have suggestions for improvements, please open an issue in the [repository](https://github.com/automatika-robotics/push-to-release-repo-action/issues).

Happy building\! 🚀
