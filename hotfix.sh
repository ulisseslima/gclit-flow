#!/bin/bash
# @installable

# quando não houver chamado no mantis, criar um issue no gitlab

# start
git checkout master
git checkout -b "hotfix_$branch"

# work locally, commit but don't push unless more than one people need to work on the feature

# finish
git checkout master
# The --no-ff flag causes the merge to always create a new commit object,
# even if the merge could be performed with a fast-forward.
# This avoids losing information about the historical existence of a feature branch
# and groups together all commits that together added the feature
git merge --no-ff "hotfix_$branch"
git tag -a $version

# propagate back
git checkout develop
git merge --no-ff "hotfix_$branch"

git branch -d "hotfix_$branch"
