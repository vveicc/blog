---
layout: post
title: "通过GitHub Actions备份GitHub仓库"
date: 2023-02-06
tags: [GitHub Actions, git-mirror-action]
toc: true
comments: true
author: vveicc
---

通过GitHub Actions可以方便的将托管在GitHub平台的仓库同步到其他代码托管平台，实现仓库备份。

本文以GitHub仓库同步至Gitee为例，介绍使用[git-mirror-action](https://github.com/wearerequired/git-mirror-action)备份GitHub仓库的具体步骤。

<!-- more -->

## 1.生成新的SSH密钥

参考[生成新SSH密钥](https://docs.github.com/zh/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#%E7%94%9F%E6%88%90%E6%96%B0-ssh-%E5%AF%86%E9%92%A5)。
建议使用单独的密钥文件，例如：`id_ssh_github_actions`。

## 2.将公钥添加至GitHub和Gitee

GitHub:`Settings`->`Access`->`SSH and GPG keys`->`New SSH key`

Gitee:`设置`->`安全设置`->`SSH公钥`

## 3.将私钥添加至GitHub仓库

`GitHub仓库`->`Settings`->`Security`->`Secrets and variables`->`Actions`->`New repository secret`

## 4.配置GitHub Actions

在GitHub仓库中添加`.github/workflows/sync.yml`文件：

{% raw %}
```yaml
name: Sync

on:
  # Triggers the workflow on push event
  push:

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  Sync-to-Gitee:
    runs-on: ubuntu-latest
    steps:
      - uses: wearerequired/git-mirror-action@v1.2.0
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }} # SSH_PRIVATE_KEY是将私钥添加至GitHub仓库时设置的名称
        with:
          source-repo: "git@github.com:***/***.git"     # 源仓库SSH URL
          destination-repo: "git@gitee.com:***/***.git" # 目标仓库SSH URL
```
{% endraw %}
