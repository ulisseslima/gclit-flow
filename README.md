# Git Flow CLI Tools
Another Git Flow solution, this time integrating with the RunRun API and with timesheet functionality.

## Inspired by
* https://nvie.com/posts/a-successful-git-branching-model/
* https://about.gitlab.com/blog/2016/09/06/resolving-merge-conflicts-from-the-gitlab-ui/
* https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow
* https://danielkummer.github.io/git-flow-cheatsheet/
* https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-flow

## RunRun rest API integration
* https://runrun.it/api/documentation

## Installation
```
./setup.sh
```
* Follow the prompts...

## Usage example:
* Start a feature (creates a branch with "feature/" prefix, creates a runrun task on the current project, pushes the feature to the target branch, creates a comment on the runrun task with additional info):
```
gclit-feature "the name"
```

* Make changes...

* Keep up to date with remote branch changes:
```
gclit-sync
```

* Make more changes...

* Deliver the feature (commits pending changes, creates merge request if project url is from gitlab, syncs with target branch [e.g.: master], pushes changes, merges changes back to target branch if project url is from github, delivers runrun task):
```
gclit-deliver
```

* At any time you can pause/play the current runrun task:
```
gclit-play
gclit-pause
```

## Debug
* Open debug logs with:
```
./logs.sh
```

# Recommended workflow for issues
For each issue you'll work on:
```
gclit-fix ${issue_id}
# a runrun task will be created.
# do your work...
# then only commit. do not push. otherwise merge request won't be auto created.
# use commit message 'closes #${issue_id}' so an auto changelog can be created.
# when you're done:
gclit-deliver
# that's it!
# a merge request will be automatically created, the branch deleted, the task ended, and you'll switch to a synced master branch
```