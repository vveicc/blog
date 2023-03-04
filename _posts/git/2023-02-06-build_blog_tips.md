---
layout: post
title: "GitHub Pages搭建个人博客Tips"
date: 2023-02-06
tags: [GitHub Pages]
toc: true
comments: true
author: vveicc
---

详细步骤可以参考[完整教程](https://lemonchann.github.io/create_blog_with_github_pages)，此处只记录一些小问题以及后续操作可能会遇到的点。

<!-- more -->

## 本地调试预览

首先安装[Jekyll](https://jekyllcn.com)，然后在仓库根目录下运行`jekyll serve`，使用浏览器打开[localhost:4000](http://localhost:4000)即可预览。

## Google Analytics

[Google Analytics](https://analytics.google.com/analytics)已经升级为Google Analytics 4，不过使用起来难度也不大，可以参考[官方文档](https://skillshop.exceedlms.com/student/path/66749-google-analytics)学习了解。

## 支持LaTeX数学公式

在`<head></head>`标签中引入[MathJax@3](https://www.mathjax.org/#gettingstarted)：

```html
<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
```

[Polyfill](https://polyfill.io/v3/)的作用是对老浏览器做支持，如果不需要可以不引入。

行内公式配置：

```html
<script>
  MathJax = {
    tex: {
      inlineMath: [['$', '$']],
      processEscapes: true
    }
  };
</script>
```

效果展示：

行内公式：$ax^2 + bx + c = 0$

行级公式：

$$
ax^2 + bx + c = 0
$$

## 混合代码段CodeTabs

### 效果展示

```cpp C++
cout << "Hello, World!" << endl;
```

```java Java
System.out.println("Hello, World!");
```

```python Python3
print("Hello, World!")
```

```md Markdown示例
    ```cpp C++
    cout << "Hello, World!" << endl;
    ```
    
    ```java Java
    System.out.println("Hello, World!");
    ```
    
    ```python Python3
    print("Hello, World!")
    ```
```

### 安装插件

通过[jekyll-commonmark-codetabs](https://rubygems.org/gems/jekyll-commonmark-codetabs)插件实现：

在 `Gemfile` 文件中添加 `jekyll-commonmark-codetabs` gem：

```ruby
group :jekyll_plugins do
  gem 'jekyll-commonmark-codetabs'
end
```

在 `_config.yml` 文件中配置 Markdown 解析器：

```yaml
markdown: CommonMarkCodeTabs
```

jekyll-commonmark-codetabs插件基于[jekyll-commonmark-ghpages](https://rubygems.org/gems/jekyll-commonmark-ghpages)，可以直接进行配置，示例：

```yaml
commonmark:
  options: ["SMART", "FOOTNOTES"]
  extensions: ["strikethrough", "autolink", "table", "tagfilter"]
```

执行命令安装插件：

```bash
bundle install --path vendor/bundle
```

### 本地调试

在仓库根目录下运行`bundle exec jekyll serve`。

### 通过GitHub Pages发布

GitHub Pages仅默认支持一小部分Jekyll插件，需要通过GitHub Actions根据 `Gemfile` 文件安装插件并构建推送至`gh-pages`分支，再通过GitHub Pages从`gh-pages`分支部署。

在GitHub仓库中添加`.github/workflows/jekyll-gh-pages.yml`文件：

{% raw %}
```yaml
# Building and publishing a Jekyll site to branch gh-pages
name: jekyll-gh-pages

on:
  # Runs on pushes targeting the default branch
  push:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# Allow one concurrent deployment
concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  jekyll:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      # Build & Publish
      # Use GitHub Actions' cache to shorten build times and decrease load on servers
      - uses: actions/cache@v2
        with:
          path: vendor/bundle
          key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile') }}
          restore-keys: |
            ${{ runner.os }}-gems-

      - uses: helaili/jekyll-action@v2
        with:
          token: ${{ secrets.PUBLISH_TOKEN }} # 需要申请GitHub Access Token并添加至GitHub仓库Secrets中
          target_branch: 'gh-pages'
```
{% endraw %}
