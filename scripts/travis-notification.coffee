# Description
#   hubot scripts for notifying travis test result.
#   This requires integration of travis and slack described at:
#   http://docs.travis-ci.com/user/notifications/#Slack-notifications

author = "Kentaro Wada"

# TODO: get github username from api
# GitHub = require("github")
#
# github = new GitHub({
#   version: "3.0.0"
#   protocol: "https",
#   host: "api.github.com",
#   timeout: 5000,
# })
# github.authenticate({
#     type: "oauth",
#     token: process.env.GITHUB_TOKEN
# })
#
# org = "jsk-ros-pkg"
# github.orgs.getTeams {org: org}, (err, res) ->
#   for team in res
#     github.orgs.getTeamMembers {id: team.id}, (err, res) ->
#       for user in res
#         github.user.getFrom {"user": user.login}, (err, res) ->
#           console.log(res.name)
#           console.log(res.login)

module.exports = (robot) ->

  jsk_maintainers = [
    # "Kei Okada",
    "Ryohei Ueda",
    # "Shunichi Nozawa",
  ]

  slack_username_map = {
    "Eisoku Kuroiwa": "eisoku9618",
    "Kei Okada": "k-okada",
    "Kentaro Wada": "wkentaro",
    "Ryohei Ueda": "garaemon",
    "Shunichi Nozawa": "nozawa",
    "Yuki Furuta": "furushchev",
  }

  robot.catchAll(
    (response) ->
      message = response.message

      match = /by\s(.*)\s(passed|failed|errored)/.exec(message.text)
      if not match
        return
      author_name = match[1]
      test_result = match[2]

      if not slack_username_map[author_name]?
        return
      slack_username = slack_username_map[author_name]

      match = /Build\s\#\d*\s\((.*)\)\s\(.*\s\((.*)\)\).*of\s(.*?)\s(in\sPR)\s\#(\d)?/.exec(message.text)
      if not match
        return
      build_url = match[1]
      pr_url = match[2]
      repo_slug = match[3]
      is_pr_build = match[4]?
      pr_number = match[5]

      if test_result != "passed" and not is_pr_build
        return  # no notification for passed push build

      # compose message text
      title = "#{repo_slug}\##{pr_number}: Build #{test_result}"
      text = message.rawText
      if /(failed|errored)/.exec(test_result)
        # test failed and notify to the commiter
        fallback = "Need some fixes!:cry: - #{repo_slug}\##{pr_number}"
        pretext =  "@#{slack_username}: Need some fixes!:cry:"
        color = "danger"
      else
        # test passed and notify to the commiter and maintainers
        maintainers = ("@" + slack_username_map[name] for name in jsk_maintainers when name != author_name).join(" ")
        fallback = "Review and merge!:+1: - ${repo_slug}\##{pr_number}"
        pretext =  "@#{slack_username} #{maintainers}: Review and merge!:+1:"
        color = "good"

      response.attachments =
        fallback: fallback
        pretext: pretext
        title: title
        text: text
        color: color

      robot.adapter.customMessage response
  )
