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
    "Ryohei Ueda": "ryoheiueda",
    "Shunichi Nozawa": "nozawa",
    "Yuki Furuta": "furushchev",
  }

  robot.catchAll(
    (message) ->
      message.user.name in ["Shell", "wkentaro", "Travis CI"]
    (response) ->
      match = /by\s(.*)\s(passed|failed|errored)/.exec(response.message.text)
      author_name = match[1]
      test_result = match[2]
      message = response.message
      slack_username = slack_username_map[author_name]

      # FIXME: formatted text with hyperlink does not work
      # see: https://github.com/slackhq/hubot-slack/issues/114
      # reference = message.rawText
      contents = message.text.split(" ")
      repo = contents[6]
      build_link = contents[2].replace("(", "").replace(")", "")
      pr_link = contents[4].replace("(", "").replace(")", "")
      reference = "Repo: #{repo}\nBuild: #{build_link}\nPR: #{pr_link}"

      # compose message text
      if /(failed|errored)/.exec(test_result)
        # test failed and notify to the commiter
        text = "OMG!! @#{slack_username} , travis test #{test_result} :cry: Please check it.\n #{reference}"
      else
        # test passed and notify to the commiter and maintainers
        maintainers = ("@" + slack_username_map[name] for name in jsk_maintainers when name != author_name).join(" ")
        text = "Good Job!! @#{slack_username} , travis test #{test_result} :+1:\n #{reference}\nHey, #{maintainers}. Please review it and merge."

      response.send text
  )
