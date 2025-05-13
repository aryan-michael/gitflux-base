# GitFlux

Manage multiple git accounts with ease. GitFlux helps developers switch between different Git accounts seamlessly, perfect for those who maintain separate accounts for personal and professional use.

## Installation

```bash
npm install -g gitflux
```

## Features

- Switch between multiple Git accounts
- Easy account management (add/remove accounts)
- Automatic SSH key switching
- Simple CLI interface
- Configuration persistence

## Prerequisites

- Git installed on your system
- SSH keys set up for your different Git accounts
- Node.js and npm installed

## Usage

Simply run:

```bash
gitflux
```

Follow the interactive prompts to:
1. Switch between accounts
2. Add new accounts
3. Delete existing accounts
4. List all available accounts

## SSH Key Setup

Your SSH keys should be named according to your Git username and stored in `~/.ssh/` or else the `Switch Account` won't work. For example:
- For username "work-user": `~/.ssh/work-user`
- For username "personal-user": `~/.ssh/personal-user`

## License

MIT © Aryan Michael