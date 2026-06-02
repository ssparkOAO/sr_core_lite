---
name: github-repo-publish-flow
description: Use this skill when a user wants help managing a local project with Git and GitHub, including choosing a repository root, writing .gitignore, committing only stable checkpoints, pushing to GitHub, adding README links, and explaining or configuring GitHub Pages for static HTML.
---

# GitHub Repository Publish Flow

Use this skill for any project where the user wants to back up, publish, or update files through GitHub.

The goal is not to push every tiny edit. The goal is to help the user create meaningful checkpoints, keep the repository clean, and understand how GitHub Pages maps files to URLs.

## Core Concepts

Explain these ideas in plain language when the user is learning:

```text
add    = choose files for the next version
commit = create a local checkpoint
push   = upload commits to GitHub
Pages  = publish static HTML/CSS/images as a website
```

## Before Changing Anything

1. Inspect the current directory:

```powershell
git status --short
git rev-parse --show-toplevel
git remote -v
```

2. If the directory is not a Git repository, choose the smallest meaningful project root.

Good repository roots usually contain:

- source code
- docs or README
- scripts/tools
- static site or report HTML
- config files needed to rebuild the project

Avoid choosing a parent folder that contains many unrelated projects or duplicate backup folders.

## Repository Root Rule

The directory where `git init` was run is the repository root.

GitHub shows this repository root as the top level of the repo.

For GitHub Pages, if Pages is set to:

```text
Branch: main
Folder: / root
```

then the website root also starts from the repository root.

Example:

```text
repo root/html/index.html
```

becomes:

```text
https://<account>.github.io/<repo>/html/
```

## GitHub Pages URL Rule

For project pages:

```text
https://<account>.github.io/<repo>/<path-inside-repo>
```

If a URL ends at a folder, the web server looks for:

```text
index.html
```

So these are equivalent:

```text
https://<account>.github.io/<repo>/html/
https://<account>.github.io/<repo>/html/index.html
```

Other HTML files need their filenames:

```text
https://<account>.github.io/<repo>/html/report.html
```

## .gitignore Guidance

Add a `.gitignore` before the first large commit.

Ignore generated or local-only files such as:

- build output
- simulation output
- cache directories
- temporary logs
- virtual environments
- large intermediate data
- local manual backup folders

Keep files that are needed to understand, rebuild, verify, or present the project.

## Commit Timing

Do not push after every small change unless the user asks.

Suggest commit + push when:

- a stable feature is complete
- a test or verification flow passes
- documentation is readable enough to share
- a day or work session ends
- the user is about to try a risky refactor
- the user wants an online backup before switching computers

## Standard Update Flow

Use this flow for normal updates:

```powershell
git status
git add .
git commit -m "Clear short description"
git push
```

Before `git add .`, check that unwanted files are not about to be included.

For safer staging, add specific paths:

```powershell
git add README.md html/index.html docs/
```

## Remote Setup Flow

For a new GitHub repository:

```powershell
git remote add origin https://github.com/<account>/<repo>.git
git branch -M main
git push -u origin main
```

If a remote already exists, inspect before changing it:

```powershell
git remote -v
```

## README Guidance

A useful README should include:

- project purpose
- live site link, if GitHub Pages is enabled
- important screenshots or diagrams
- key folders
- quick update commands
- notes about generated files or ignored files

Use relative image paths for repository images:

```markdown
![Model](model.png)
```

Use full URLs for GitHub Pages links:

```markdown
[Live HTML site](https://<account>.github.io/<repo>/html/)
```

## Safety Rules

- Never overwrite user changes.
- Never run destructive Git commands unless explicitly requested.
- Do not `git reset --hard` as a routine fix.
- If push fails due to network or authentication, explain the specific blocker.
- If GitHub Pages appears stale, remind the user that deployment can take tens of seconds to a few minutes.

## Final Response Checklist

When finished, report:

- commit hash and message
- whether push succeeded
- live Pages URL, if applicable
- any files intentionally not pushed
