# Description
#   hubot scripts for notifying travis test result.
#   This requires integration of travis and slack described at:
#   http://docs.travis-ci.com/user/notifications/#Slack-notifications
#
# author: Kentaro Wada <www.kentaro.wada@gmail.com>

GitHub = require("github")

module.exports = (robot) ->

  github = new GitHub({
    version: "3.0.0"
    protocol: "https"
    host: "api.github.com"
    timeout: 5000
  })
  github.authenticate({
      type: "oauth"
      token: process.env.HUBOT_GITHUB_TOKEN
  })

  jsk_maintainers = [
    # "Kei Okada",
    "Ryohei Ueda",
    # "Shunichi Nozawa",
  ]

  robot.catchAll(
    (response) ->
      message = response.message

      match = /by\s(.*)\s(passed|failed|errored)/.exec(message.text)
      if not match
        return
      author_name = match[1]
      test_result = match[2]

      # Get map of real_name and username from GitHub API
      org = "jsk-ros-pkg"
      github.orgs.getMembers {org: org, per_page: 100}, (err, members) ->
        namemap = {}
        count = 0
        for member in members
          github.user.getFrom {"user": member.login}, (err, user) ->
            if user.name and user.login
              namemap[user.name] = user.login
            count += 1
            if count isnt members.length
              return
            console.log('Collection of username from GitHub API is done.')

            if not namemap[author_name]?
              console.log("#{author_name} is not found in GitHub username map.")
              return
            slack_username = namemap[author_name]

            match = /Build\s\#\d*\s\((.*)\)\s\(.*\s\((.*)\)\).*of\s(.*?)\s(in\sPR)\s\#(\d*)/.exec(message.text)
            if not match
              return
            build_url = match[1]
            pr_url = match[2]
            repo_slug = match[3]
            is_pr_build = match[4]?
            pr_number = match[5]

            if test_result != "passed" and not is_pr_build
              console.log('Skip notification which is not PR build.')
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
              maintainers = ("@" + namemap[name] for name in jsk_maintainers when name != author_name).join(" ")
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
