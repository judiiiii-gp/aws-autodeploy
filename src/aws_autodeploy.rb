#!/usr/bin/env ruby
$LOAD_PATH << '../src'

require 'logger'
require 'tools/log'
require 'json'
require 'octokit'
require 'git'
require_relative 'actions/action'
require_relative 'tools/github_client'
require_relative 'tools/issue_params'
require_relative 'templates/validate_template'

# Logger
LOG_COMP = 'MAIN'

logger = Logger.new(STDOUT)
Log.logger = logger
Log.info(LOG_COMP, 'Starting AWS-Autodeploy')

# Client for issue comments & labels
client = Octokit::Client.new(access_token: ENV['GH_TOKEN'])

# Action tag
action_tag = ARGV[0].to_s
Log.debug(LOG_COMP, "Action tag: #{action_tag}")

# Issue from GitHub Client
repo = ENV['GITHUB_REPOSITORY']
issue_number = ARGV[1]
issue = Github_client.get_issue(issue_number)
Log.debug(LOG_COMP, "Issue num: #{issue_number}")

# Get Params from Issue
parameterizer = IssueParams.new(issue['body'])
issue_params = parameterizer.get_params()
accepted_services = ARGV[2].split(',')
services = parameterizer.get_services(issue_params,accepted_services)
ordered_params = parameterizer.get_order_params(issue_params,services)


# Code:

# Generate action from issue tag
action = Action.for(action_tag)

# Execute action
Log.debug(LOG_COMP, "Executing action '#{action_tag}'")
action_state=action.execute(issue_number,ordered_params,services)

# Report results
Log.debug(LOG_COMP, "Reporting action '#{action_tag}'")
comment_body = action.report()
client.add_comment(repo, issue_number, comment_body)


# Update Issue States
Log.debug(LOG_COMP, "Updating labels for Issue")
current_labels = client.labels_for_issue(repo, issue_number).map(&:name)
current_labels.each do |label|
    client.remove_label(repo, issue_number, label)
end
action_state.each do |label|
    client.add_labels_to_an_issue(repo, issue_number, [label])
end

# Commit Files
if action_tag == "action-deploy" && !action_state.include?('state-failed-deploying')
    files = Terraform.get_files
    files_directory = File.expand_path("../deployments/#{issue_number}/", __dir__)
    repo = Git.open(File.expand_path('..', __dir__))
    files.each do |file|
        file_path = File.join(files_directory, file)
        `git add #{file_path}`
    end
    commit_message = "commit configuration files of issue #{issue_number}"
    client.create_commit(repo, commit_message, files.map { |file| { path: file } }, branch: 'main')
end