# push options for automatically creating a merge request
https://docs.gitlab.com/ee/user/project/push_options.html

# use gitlab api to assign a merge request to someone
https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/merge_requests.md#create-mr

# use codes in the commit message to close issues:
## closes #123
https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue

# long term branches
https://www.reddit.com/r/git/comments/3rrzf6/should_i_ever_have_longterm_feature_branches_in/

# common commands
merge develop branch back into your feature often to avoid conflicts

## start
```
git checkout $remote_branch
git checkout -b $branch
```

## finish
work locally, commit but don't push unless more than one people need to work on the feature
```
git push -u origin $branch
git checkout $remote_branch
```

## to pick changes from specific files from other branches:
```
git checkout otherbranch file1 [file2 file3 ...]
```

## to keep your branch up to date with a target final branch for merging:
```
git merge --no-ff $remote_branch
```

## The --no-ff flag causes the merge to always create a new commit object, even if the merge could be performed with a fast-forward. This avoids losing information about the historical existence of a feature branch and groups together all commits that together added the feature
```
git merge --no-ff $branch

git push origin $remote_branch
git branch -d $branch
```

## keep local branch in synch with $remote_branch https://stackoverflow.com/questions/16329776/how-to-keep-a-git-branch-in-sync-with-master
```
git checkout $remote_branch
git pull
git checkout $branch
git merge $remote_branch
```

## in case of conflicts:
```
git mergetool
```

## then just commit normally:
```
git commit -a -m 'resolving conflicts'
git merge $remote_branch
git push
```

## to finish ant put the changes back in $remote_branch:
```
git checkout $remote_branch
git merge $branch
git push origin $remote_branch
```