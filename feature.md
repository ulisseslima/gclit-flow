# push options for automatically creating a merge request
# https://docs.gitlab.com/ee/user/project/push_options.html

# use gitlab api to assign a merge request to someone
# https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/merge_requests.md#create-mr

# use codes in the commit message to close issues:
# closes #123
# https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue

# https://www.reddit.com/r/git/comments/3rrzf6/should_i_ever_have_longterm_feature_branches_in/
# merge develop branch back into your feature often to avoid conflicts

# start
#git checkout develop
#git checkout -b $1

# finish
# work locally, commit but don't push unless more than one people need to work on the feature
# if you need other people to work on the feature:
# git push -u origin $1
#git checkout develop

##
# to get changes from specifica files from other branches:
# git checkout otherbranch file1 [file2 file3 ...]

##
# to keep your branch up to date with a target final branch for merging (NOTA: ainda tem que testar):
# git merge --no-ff develop

# The --no-ff flag causes the merge to always create a new commit object,
# even if the merge could be performed with a fast-forward.
# This avoids losing information about the historical existence of a feature branch
# and groups together all commits that together added the feature
#git merge --no-ff feature_branch

#git push origin develop
#git branch -d feature_branch


##
# keep local branch in synch with master https://stackoverflow.com/questions/16329776/how-to-keep-a-git-branch-in-sync-with-master
#
# git checkout master && git pull && git checkout $branch && git merge master
# se der conflitos:
# git mergetool
# salva os arquivos
# git commit -a -m 'resolvendo conflitos'
# git merge master
# git push

# to finish ant put the changes back in master:
# git checkout master
# git merge mobiledevicesupport
# git push origin master
##
