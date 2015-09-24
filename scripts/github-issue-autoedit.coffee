# Description
#   hubot scripts for auto editing opened issue.
#
# Features:
#   * auto labeling (ex. if title is "[bug] Hogehoge", add label "bug")

GitHub = require("github")
github = new GitHub({
  version: "3.0.0"
  protocol: "https",
  host: "api.github.com",
  timeout: 5000,
})
github.authenticate({
  type: "oauth",
  token: process.env.HUBOT_GITHUB_TOKEN,
})

url = require 'url'

module.exports = (robot) ->

    githubot = require('githubot')(robot)

    channel_name = '#github'

    # Auto labeling by issue title
    robot.router.post '/github/github-issue-autoedit', (req, res) ->
        data = req.body

        if data.action not in ['opened', 'reopened']
            return res.end ''

        issue = data.issue
        repo = data.repository

        match = /^\[(.*)\]/.exec(issue.title)
        label_new = match[1]

        if not label_new
          return res.end ''

        github.issues.getLabels {user: repo.owner.login, repo: repo.name}, (error, labels) ->
          # Check if the specified label exists
          for label in labels
            if label_new is label.name
              issue.labels.push(label_new)
              url = "repos/#{repo.owner.login}/#{repo.name}/issues/#{issue.number}"
              githubot.patch url, {labels: issue.labels}, (issue) ->
                if not issue?
                  robot.messageRoom channel_name, "Error occured on issue *#{repo.full_name}\##{issue.number}* auto labeling."
                  return
                body = "Added label *#{label_new}* to *#{repo.full_name}\##{issue.number}*."
                robot.messageRoom channel_name, body
                res.end ''
