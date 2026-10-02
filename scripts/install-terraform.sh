#!/usr/bin/env bash
set -euo pipefail
version=1.12.2
install_dir="${1:-$PWD/.tools}"
mkdir -p "$install_dir"
install_dir="$(cd "$install_dir" && pwd)"
task_tmp="$(mktemp -d)"
trap 'rm -rf "$task_tmp"' EXIT
base="https://releases.hashicorp.com/terraform/$version"
archive="terraform_${version}_linux_amd64.zip"
curl --fail --silent --show-error --location "$base/$archive" -o "$task_tmp/$archive"
curl --fail --silent --show-error --location "$base/terraform_${version}_SHA256SUMS" -o "$task_tmp/SHA256SUMS"
(cd "$task_tmp" && grep "  $archive\$" SHA256SUMS | sha256sum --check -)
unzip -qo "$task_tmp/$archive" -d "$install_dir"
"$install_dir/terraform" version
