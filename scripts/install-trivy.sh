#!/usr/bin/env bash
set -euo pipefail
version=0.74.0
install_dir="${1:-$PWD/.tools}"
mkdir -p "$install_dir"
install_dir="$(cd "$install_dir" && pwd)"
task_tmp="$(mktemp -d)"
trap 'rm -rf "$task_tmp"' EXIT
archive="trivy_${version}_Linux-64bit.tar.gz"
base="https://github.com/aquasecurity/trivy/releases/download/v$version"
curl -fsSL "$base/$archive" -o "$task_tmp/$archive"
curl -fsSL "$base/trivy_${version}_checksums.txt" -o "$task_tmp/checksums.txt"
(cd "$task_tmp" && grep "  $archive\$" checksums.txt | sha256sum --check -)
tar -xzf "$task_tmp/$archive" -C "$install_dir" trivy
"$install_dir/trivy" --version
