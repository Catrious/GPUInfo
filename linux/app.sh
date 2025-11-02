#!/bin/bash

# -------------------------------
# GPUInfo Linux - OpenGL + Vulkan
# -------------------------------

# Detect Linux base distro
DISTRO="unknown"
if [ -f /etc/debian_version ]; then
    DISTRO="debian"
elif [ -f /etc/redhat-release ]; then
    DISTRO="redhat"
elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
fi

# Function to install zenity
install_zenity() {
    case "$DISTRO" in
        debian)
            if ! command -v zenity >/dev/null 2>&1; then
                sudo apt-get install -y zenity
            fi
            ;;
        redhat)
            if ! command -v zenity >/dev/null 2>&1; then
                if command -v dnf >/dev/null 2>&1; then
                    sudo dnf install -y zenity
                else
                    sudo yum install -y zenity
                fi
            fi
            ;;
        arch)
            if ! command -v zenity >/dev/null 2>&1; then
                sudo pacman -Sy --noconfirm zenity
            fi
            ;;
        *)
            echo "Unknown distro. Please install zenity manually."
            exit 1
            ;;
    esac
}

# Install zenity if missing
install_zenity

# -------------------------------
# Detect OpenGL
# -------------------------------
if command -v glxinfo >/dev/null 2>&1; then
    OPENGL_VERSION=$(glxinfo | grep "OpenGL version" | head -n1 | awk -F': ' '{print $2}' | awk '{print $1"."$2}' )
    if [ -z "$OPENGL_VERSION" ]; then
        OPENGL_VERSION="OpenGL not supported"
    else
        OPENGL_VERSION="OpenGL $OPENGL_VERSION"
    fi
else
    OPENGL_VERSION="OpenGL not supported"
fi

# -------------------------------
# Detect Vulkan
# -------------------------------
if command -v vulkaninfo >/dev/null 2>&1; then
    VULKAN_VERSION=$(vulkaninfo 2>/dev/null | grep "Vulkan Instance Version" | awk '{print $4}' | head -n1)
    if [ -z "$VULKAN_VERSION" ]; then
        VULKAN_VERSION="Vulkan not supported"
    else
        VULKAN_VERSION="Vulkan $VULKAN_VERSION"
    fi
elif ldconfig -p | grep -q libvulkan.so; then
    VULKAN_VERSION="Vulkan 1.0"
else
    VULKAN_VERSION="Vulkan not supported"
fi

# -------------------------------
# Show Zenity dialog
# -------------------------------
zenity --info --title="GPU Info" --text="$OPENGL_VERSION\n$VULKAN_VERSION"
