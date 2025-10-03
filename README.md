# Developer Environment Automated Setup

This repository contains scripts for quick and easy setup of your local machine as a development environment. 

## Configurations
- [Windows](./windows/README.md)
- OSX - TODO

## SSH Configuration

You can find more information on generating ssh keys [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Generate an ssh key (if you do not have one already)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# legacy ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Add key to ssh agent

```bash
ssh-add ~/.ssh/id_ed25519
```