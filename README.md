> [!IMPORTANT]
> - This script is under active development. Use at your own risk.
> - Intended for fresh Ubuntu/Debian installations only.
> - Review the code before running on production systems.
> - This script must be executed with root privileges.

# Midhun's Server Setup Script

> [!NOTE]
> This script provides automated server configuration and software installation for Ubuntu/Debian.

## Prerequisites

- `bash`
- `curl`

## How to Use

1.  Download the script:
    ```bash
    curl -O https://raw.githubusercontent.com/midhunmonachan/dotfiles/main/setup.sh
    ```

2.  Ensure the script `setup.sh` has execute permissions:
    ```bash
    chmod +x setup.sh
    ```
3.  Run the script:
    ```bash
    ./setup.sh
    ```
    The script will prompt for `sudo` access when necessary.

4.  After successful installation, you can remove the setup script:
    ```bash
    rm setup.sh
    ```

## Script Details

- **Author**: Midhun Monachan
- **GitHub**: [github.com/midhunmonachan](https://github.com/midhunmonachan)
- **License**: MIT
