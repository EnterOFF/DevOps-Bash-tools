#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-11 03:28:53 +0800 (Tue, 11 Mar 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds duplicate Terraform providers, often caused by using the default mode in Terragrunt without using Plugin Cache

This will show you why if you're using Terragrunt to split the code base you need to configure a unified Terraform Plugin Cache

    https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache

For example, in a repo checkout for a single project, I had 30 x 600MB AWS provider

    30  597M  hashicorp/aws/5.80.0/darwin_arm64/terraform-provider-aws_v5.80.0_x5
    7   631M  ashicorp/aws/5.90.1/darwin_arm64/terraform-provider-aws_v5.90.1_x5
    4   637M  hashicorp/aws/5.90.0/darwin_arm64/terraform-provider-aws_v5.90.0_x5
    3   599M  hashicorp/aws/5.81.0/darwin_arm64/terraform-provider-aws_v5.81.0_x5

Output format:

    <count>    <size_provider_MB>    <provider>
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

#min_args 1 "$@"

dir="${1:-.}"

timestamp "Finding Terraform providers and hashing them"
# slow way of finding duplicates
providers="$(find "$dir" -type f -name 'terraform-provider-*' -exec md5sum {} \;)"
#providers="$(find "$dir" -type f -name 'terraform-provider-*' -exec du -m {} \;)"

timestamp "Finding duplicate providers by hash"
echo
awk '{print $1}' <<< "$providers" |
sort |
uniq -c |
sort -k1nr |
while read -r count hash; do
    echo -n "$count "
    # head -n 1 is more reliable than grep -m 1 on some platforms (macOS BSD)
    filename="$(grep "$hash" <<< "$providers" | head -n1 | awk '{print $2}')"
    du -h "$filename" |
    awk '{printf $1" "}'
    filename_short="${filename##*.terraform/providers/}"
    filename_short="${filename_short#registry.terraform.io/}"
    echo "$filename_short"
done |
column -t
