#--
#
# Kyle Kingsbury: This plugin is adapted from Ryan's Thoth. His license follows:
#
# Copyright (c) 2009 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

#require 'cgi'
require 'json'
require 'open-uri'
require 'timeout'
require 'uri'

module CortexReaver; module Plugins

  # Twitter plugin for Cortex Reaver.
  module Twitter
    Config = CortexReaver.config.plugins.twitter ||= Construct.new

    # The twitter username to look for
    Config.define :username, :default => 'aphyr_'

    # Whether or not to include replies. If this is false, the most recent
    # non-reply tweets will be displayed.
    Config.define :include_replies, :default => false

    # Time in seconds to cache results. It's a good idea to keep this nice
    # and high both to improve the performance of your site and to avoid
    # pounding on Twitter's servers. Default is 600 seconds (10 minutes).
    Config.define :cache_ttl, :default => 600

    # Request timeout in seconds.
    Config.define :request_timeout, :default => 3

    # If Twitter fails to respond at least this many times in a row, no new
    # requests will be sent until the failure_timeout expires in order to
    # avoid hindering your blog's performance.
    Config.define :failure_threshold, :default => 3

    # After the failure_threshold is reached, the plugin will wait this many
    # seconds before trying again. Default is 600 seconds (10 minutes).
    Config.define :failure_timeout, :default => 600

    class << self

      # Parses tweet text and converts it into HTML. Explicit URLs and @username
      # or #hashtag references will be turned into links.
      def parse_tweet(tweet)
        index     = 0
        html      = tweet.dup
        protocols = ['ftp', 'ftps', 'git', 'http', 'https', 'mailto', 'scp',
                     'sftp', 'ssh', 'telnet']
        urls      = []

        # Extract URLs and replace them with placeholders for later.
        URI.extract(html.dup, protocols) do |url|
          html.sub!(url, "__URL#{index}__")
          urls << url
          index += 1
        end

        # Replace URL placeholders with links.
        urls.each_with_index do |url, index|
          html.sub!("__URL#{index}__", "<a href=\"#{url}\">" <<
              "#{url.length > 26 ? url[0..26] + '...' : url}</a>")
        end

        # Turn @username into a link to the specified user's Twitter profile.
        html.gsub!(/@([a-zA-Z0-9_]{1,16})([^a-zA-Z0-9_])?/,
            '@<a href="http://twitter.com/\1">\1</a>\2')

        # Turn #hashtags into links.
        html.gsub!(/#([a-zA-Z0-9_]{1,32})([^a-zA-Z0-9_])?/,
            '<a href="http://search.twitter.com/search?q=%23\1">#\1</a>\2')

        return html
      end

      # Gets a Hash containing recent tweets for the specified _user_. The only
      # valid option currently is <code>:count</code>, which specifies the
      # maximum number of tweets that should be returned.
      def recent_tweets(user = Config.username, options = {:count => 1})
        if @skip_until
          return [] if @skip_until > Time.now
          @skip_until = nil
        end

        cache   = Ramaze::Cache.plugin
        options = {:count => 5}.merge(options)
        count   = options[:count].to_i

        count += 10 unless Config.include_replies
        count = 200 if count > 200

        url = "http://twitter.com/statuses/user_timeline/#{user}.json?count=" <<
            count.to_s

        if value = cache[url]
          return value
        end

        tweets = []

        Timeout.timeout(Config.request_timeout, StandardError) do
          failed = 0
          begin
            tweets = JSON.parse(open(url).read)
          rescue JSON::ParseError => e
            # Twitter likes to hand out weird HTML responses sometimes. :/
            failed += 1
            retry unless failed > 3

            # Admit defeat
            raise RuntimeError.new("Failed to parse Twitter response 4 times: #{e}")
          end
        end

        # Weed out replies if necessary.
        unless Config.include_replies
          tweets.delete_if do |tweet|
            !tweet['in_reply_to_status_id'].nil? ||
                !tweet['in_reply_to_user_id'].nil?
          end

          tweets = tweets.slice(0, options[:count].to_i)
        end

        # Parse the tweets into an easier-to-use format.
        tweets.map! do |tweet|
          {
            :created_at => Time.parse(tweet['created_at']),
            :html       => parse_tweet(tweet['text']),
            :id         => tweet['id'],
            :source     => tweet['source'],
            :text       => tweet['text'],
            :truncated  => tweet['truncated'],
            :url        => "http://twitter.com/#{user}/statuses/#{tweet['id']}"
          }
        end

        @failures = 0

        return cache.store(url, tweets, :ttl => Config.cache_ttl)

      rescue => e
        Ramaze::Log.error "CortexReaver::Plugins::Twitter: #{e.message}"

        @failures ||= 0
        @failures += 1

        if @failures >= Config.failure_threshold
          @skip_until = Time.now + Config.failure_timeout
          Ramaze::Log.error "CortexReaver::Plugins::Twitter: Twitter failed to respond #{@failures} times. Will retry after #{@skip_until}."
        end

        return []
      end

    end

  end
end; end
