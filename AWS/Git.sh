#!/bin/bash

# Set variables
REPO_NAME="my-repository"
MAIN_BRANCH="main"
STAGING_BRANCH="staging"
DEV_BRANCH="development"
UAT_BRANCH="uat"
GITHUB_USER="satish-219"

# 1. Create repo
curl -u "$GITHUB_USER" https://api.github.com/satish-219/my-repository -d "{\"name\":\"$REPO_NAME\"}"

# Navigate to repo directory
git clone https://github.com/$GITHUB_USER/$REPO_NAME.git
cd $REPO_NAME

# 2. Create files and push to repo
echo "f1 file" > f1.txt
echo "f2 file" > f2.txt
git add f1.txt f2.txt
git commit -m "Add files"
git push

# 3. Create another branch
git checkout -b $STAGING_BRANCH

# 4. Add files to new branch(staging) and push back to git
echo "f3 file" > f4.txt
git add .
git commit -m "Add files to staging"
git push

# 5. Create PR and merge with main branch
# Requires GitHub CLI
gh pr create --title "Merge staging into main" --body "Merging changes" --base $MAIN_BRANCH --head $STAGING_BRANCH
gh pr merge --merge

# 6. Create development branch and create 3 files -> add 3 files -> do commit -> revert 1 file out of 3
git checkout -b $DEVELOPMENT_BRANCH
echo "f4 file" > f4.txt
echo "f5 file" > f5.txt
echo "f6 file" > f6.txt
git add .
git commit -m "Add development files"
git reflog
git revert 3a632a3
git push 

# 7. Create UAT branch and create 3 files -> add 3 files -> do commit -> do push -> revert 1 file out of 3
git checkout -b $UAT_BRANCH
echo "f7 file" > f7.txt
echo "f8 file" > f8.txt
echo "f9 file" > f9.txt
git add .
git commit -m "UAT files"
git reflog
git revert 7bbe32c
git push

echo "Completed all tasks."
