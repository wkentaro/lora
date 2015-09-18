# Description
#   hubot scripts for notifying travis test result.
#   This requires integration of travis and slack described at:
#   http://docs.travis-ci.com/user/notifications/#Slack-notifications


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
    (message) ->
      message.user.name in ["Shell", "wkentaro", "Travis CI"]
    (response) ->
      message = response.message

      match = /by\s(.*)\s(passed|failed|errored)/.exec(message.text)
      author_name = match[1]
      test_result = match[2]

      if not slack_username_map[author_name]?
        return
      slack_username = slack_username_map[author_name]

      # FIXME: formatted text with hyperlink does not work
      # see: https://github.com/slackhq/hubot-slack/issues/114
      # reference = message.rawText
      match = /Build\s\#\d*\s\((.*)\)\s\(.*\s\((.*)\)\).*of\s(.*?)\s(in\sPR)?/.exec(message.text)
      build_url = match[1]
      pr_url = match[2]
      repo_slug = match[3]
      is_pr_build = match[4]?

      if test_result != "passed" and not is_pr_build
        return  # no notification for passed push build

      # compose message text
      reference = "#{repo_slug}\n     build: #{build_url}\n     pr: #{pr_url}"
      if /(failed|errored)/.exec(test_result)
        # test failed and notify to the commiter
        text = "@#{slack_username}: Need some fixes!:cry:\nFwd: #{reference}"
      else
        # test passed and notify to the commiter and maintainers
        maintainers = ("@" + slack_username_map[name] for name in jsk_maintainers when name != author_name).join(" ")
        text = "@#{slack_username} #{maintainers}: Review and merge!:+1:\nFwd: #{reference}"

      response.send text
  )
