# Description
#   hubot scripts for auto editing opened issue.
#
# Features:
#   * auto labeling (ex. if title is "[bug] Hogehoge", add label "bug")


url = require 'url'

module.exports = (robot) ->

    github = require('githubot')(robot)

    channel_name = '#github'

    # Auto labeling by issue title
    robot.router.post '/github/github-issue-autoedit', (req, res) ->
        data = req.body

        if data.action not in ['opened', 'reopened']
            return res.end ''

        issue = data.issue
        repo = data.repository

        match = /^\[(.*)\]/.exec(issue.title)
        label = match[1]

        if label
          issue.labels.push(label)
          url = "repos/#{repo.owner.login}/#{repo.name}/issues/#{issue.number}"
          github.patch url, {labels: issue.labels}, (issue) ->
            if ! issue?
              robot.messageRoom channel_name, "Error occured on issue *#{repo.full_name}\##{issue.number}* auto labeling."
              return
            body = "Added label *#{label}* to *#{repo.full_name}\##{issue.number}*."
            robot.messageRoom channel_name, body
            res.end ''
