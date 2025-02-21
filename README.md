# Ubuntu Focal Snapshot Repositories

## Overview

This script enables snapshot repositories on Ubuntu Focal by parameterizing the snapshot date via the `UBUNTU_SNAPSHOT` environment variable. It supports both amd64 and arm64, addressing a specific arm64 issue with apt cache clearing.

See [Ubuntu Snapshot Service](https://snapshot.ubuntu.com/)

## Why this Exists

We often create multi-architecture docker images that use the Ubuntu Snapshot Service
to lock versions installed from apt repositories to a specific date. We noticed an
issue with Ubuntu Focal which has minimal support for the Ubuntu Snapshot Service.

Specifically, with Ubuntu Focal on `arm64`, there is a specific order-of-operations
that must occur in order to enable snapshots. The instructions on Canonical's website
did not address this, and the error messages produced did not yield any search results.

This script configures Ubuntu Focal with Ubuntu Snapshot Service and locks all repositories
to a specific archive date. It works on amd64 and arm64.

## How to Use

### Set the Snapshot Date

Set the snapshot date environment variable. The date format is `YYYYMMDDTHHMMSSZ`. For example, the date 3:04:00 am UTC on 1 March 2024 is represented as `20240301T030400Z`

```bash
export UBUNTU_SNAPSHOT="20240301T030400Z"
```

### Execute the Script

```bash
./apt-snapshot.sh
```

## How it Works

1. Temporarily disables snapshot configuration.
1. Restores standard apt sources.
1. Runs an initial `apt-get update` to enable snapshot support. We found this step was required on arm64, otherwise apt update fails with the error "Snapshots are not supported."
1. Installs updated certificates as required.
1. Configures snapshot-specific sources based on system architecture.
1. Re-enables snapshot support via `/etc/apt/apt.conf.d/50snapshot`.
1. Disables standard apt sources and updates the snapshot package lists.

*Note:* Clearing `/var/lib/apt/lists/*` (as is commonly done in Dockerfiles) will result
in arm64 unable to perform an apt update. Running this script again will resolve the issue.
