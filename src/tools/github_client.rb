#!/usr/bin/env ruby

require 'uri'
require 'json'
require 'net/http'
require 'tools/log'
require 'tools/file_manager'

class Github_client

    LOG_COMP = 'GH'

    GH_URL_BASE = 'https://api.github.com/repos/'
    repo_name = ENV['GITHUB_REPOSITORY']
    GH_URL = "#{GH_URL_BASE}#{repo_name}"

    # Obtain Issue details
    def self.get_issue(issue_number)
        Log.info(LOG_COMP, 'Configuring github client')
        
        uri = URI("#{GH_URL}/issues/#{issue_number}")
        req = Net::HTTP::Get.new(uri)
        req['Accept'] = 'application/vnd.github.v3+json'
        req['Authorization'] = "token #{ENV['GH_TOKEN']}"
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
        end

        unless res.is_a?(Net::HTTPSuccess)
            Log.error(LOG_COMP, "Error fetching the issue from github: #{res}")
            raise "Error fetching issue details: #{res.message}"
        end

        JSON.parse(res.body)
    end

    def self.commit_files(files, commit_message, issue_number)
        Log.info(LOG_COMP, 'Committing files to GitHub repository')
      
        uri = URI("#{GH_URL}/deployments/#{issue_number}/")
      
        files.each do |file|
          file_path = FileManager::DIR_DEPLOYMENT + "/#{issue_number}/" + file
          puts file_path  
          unless File.exist?(file_path)
            Log.error(LOG_COMP, "File #{file} does not exist.")
            next
          end
          puts "Client"
          system('ls','-l')
          file_content = File.read(file_path)
          encoded_content = Base64.strict_encode64(file_content)
      
          commit_data = {
            message: commit_message,
            content: encoded_content,
            path: file
          }
      
          req = Net::HTTP::Put.new(uri)
          req['Accept'] = 'application/vnd.github.v3+json'
          req['Authorization'] = "token #{ENV['GH_TOKEN']}"
          req.body = JSON.generate(commit_data)
      
          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
          end
      
          unless res.is_a?(Net::HTTPSuccess)
            Log.error(LOG_COMP, "Error committing file #{file} to GitHub: #{res.code} - #{res.message} - #{res.body}")
            raise "Error committing file #{file} to GitHub: #{res.code} - #{res.message}"
          end
        end
      
        Log.info(LOG_COMP, "Files committed successfully to GitHub repository")
      end      
end
