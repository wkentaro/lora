# Description
#   hubot scripts for notifying travis test result.
#   This requires integration of travis and slack described at:
#   http://docs.travis-ci.com/user/notifications/#Slack-notifications


module.exports = (robot) ->

  jsk_maintainers = [
    "Kei Okada",
    "Ryohei Ueda",
    "Shunichi Nozawa",
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
      slack_username = slack_username_map[author_name]
      if /(failed|errored)/.exec(test_result)
        # test failed and notify to the commiter
        response.reply "OMG!! @#{slack_username} , travis test #{test_result} :cry: Please check it ->\n #{response.message}"
      else
        # test passed and notify to the commiter and maintainers
        maintainers = ("@" + slack_username_map[name] for name in jsk_maintainers when name != author_name).join(" ")
        response.reply "Good Job!! @#{slack_username} , travis test #{test_result} :+1: ->\n #{response.message}\nHey, #{maintainers}. Please review it and merge."
  )
