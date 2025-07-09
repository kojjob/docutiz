# GitHub Setup Instructions

## 1. Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `docutiz` (or your preferred name)
3. Description: "AI-powered document extraction SaaS platform"
4. Set as **Private** (recommended) or Public
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## 2. Add GitHub Remote

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin git@github.com:YOUR_USERNAME/docutiz.git

# Or if using HTTPS:
git remote add origin https://github.com/YOUR_USERNAME/docutiz.git
```

## 3. Push Both Branches

```bash
# Push main branch
git checkout main
git push -u origin main

# Push develop branch
git checkout develop
git push -u origin develop

# Set main as default branch on GitHub (in repository settings)
```

## 4. Configure Branch Protection

On GitHub, go to Settings > Branches and add protection rules for:

### Main Branch Protection:
- Require pull request reviews (2 approvals)
- Dismiss stale pull request approvals
- Require status checks to pass
- Require branches to be up to date
- Include administrators
- Restrict who can push to matching branches

### Develop Branch Protection:
- Require pull request reviews (1 approval)
- Require status checks to pass
- Require branches to be up to date

## 5. Verify Setup

```bash
# Check remotes
git remote -v

# Check branch tracking
git branch -vv

# Fetch all branches
git fetch --all
```

## Common Issues

### SSH Key Not Set Up
If you get permission denied:
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub
# Add this key to GitHub: Settings > SSH and GPG keys
```

### HTTPS Credentials
If using HTTPS and prompted for credentials:
```bash
# Cache credentials
git config --global credential.helper osxkeychain
```