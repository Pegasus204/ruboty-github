module Ruboty
  module Github
    module Actions
      class GetPRDiff < Base
        def call
          if has_access_token?
            get
          else
            require_access_token
          end
        end

        private

        def get
          message.reply("#{text}")
        rescue Octokit::Unauthorized
          message.reply("Failed in authentication (401)")
        rescue Octokit::NotFound
          message.reply("Could not find that repository")
        rescue => exception
          message.reply("Failed by #{exception.class} #{exception}")
        end

        def text
          [
            '```',
            changelog,
            '```',
          ].join("\n")
        end

        def changelog
          return "No diffs found" if commit_diffs.commits.length.zero?

          commit_diffs.commits.map do |elm|
            if elm.commit.committer.name == "GitHub"
              num = elm.commit.message[/Merge pull request #(\d+) from/, 1]

              next unless num

              "[##{num}](#{pull_request_link(num)}) #{pull_request_title(num)}"
            else
              nil
            end
          end.compact.reverse.join("\n")
        end

        def pull_request_title(number)
          pull_request(number).title
        end

        def pull_request(number)
          client.pull_request(repository, number)
        end

        def pull_request_link(number)
          "https://github.com/#{repository}/pull/#{number}"
        end

        def commit_diffs
          client.compare(repository, message[:base], message[:head])
        end
      end
    end
  end
end

