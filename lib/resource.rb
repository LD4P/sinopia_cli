# frozen_string_literal: true

require 'thor'
require 'client'

# Methods for resource endpoint
class Resource < Thor
  class_option :api_url, type: :string, default: 'https://api.stage.sinopia.io'

  option :uri_only, type: :boolean, desc: 'Print resource URIs only.'
  option :templates_only, type: :boolean, desc: 'Resource templates only.'
  option :group, type: :string, desc: 'Group name filter.'
  option :updated_before, type: :string,
                          desc: 'Resource last updated before filter, e.g., 2019-11-08T17:40:23.363Z'
  option :updated_after, type: :string, desc: 'Resource last updated after filter, e.g., 2019-11-08T17:40:23.363Z'
  option :type, type: :string, desc: 'Class filter, e.g., http://id.loc.gov/ontologies/bibframe/AbbreviatedTitle'
  desc 'list', 'list resources'
  def list
    url = "#{options[:api_url]}/resource"
    while url
      params = {
        'group' => options[:group],
        'updatedBefore' => options[:updated_before],
        'updatedAfter' => options[:updated_after],
        'type' => options[:templates_only] ? 'http://sinopia.io/vocabulary/ResourceTemplate' : options[:type]
      }.compact
      url = list_page(url, options[:uri_only], params)
    end
  end

  option :uri, type: :array, desc: 'Space separated list of URIs.'
  option :file, type: :string, desc: 'File containing list of URIs.'
  option :token, type: :string, desc: 'JWT token. Otherwise, read from .cognitoToken'
  desc 'delete', 'delete resources'
  def delete
    raise 'Must provide a URI or file' unless options.key?(:uri) || options.key?(:file)

    uris = options.key?(:uri) ? options[:uri] : File.readlines(options[:file], chomp: true)
    uris.each_with_index { |uri, index| delete_resource(uri, index, uris.size) }
  end

  private

  def connection(token: nil)
    @connection ||= Client.connection(token: token)
  end

  def list_page(url, uri_only, params = {})
    resp = connection.get url, params
    raise "Error getting #{url}." unless resp.success?

    resp_json = JSON.parse(resp.body)
    put_page(resp_json, uri_only)
    resp_json.dig('links', 'next')
  end

  def put_page(resp_json, uri_only)
    resp_json['data'].each do |resource|
      if uri_only
        puts "#{resource['uri']}: (#{index +1} of #{count})"
      else
        puts JSON.pretty_generate(resource)
      end
    end
  end

  def delete_resource(uri, index, count)
    token = options[:token] || File.read('.cognitoToken')
    resp = connection(token: token).delete uri
    if resp.success?
      puts "Deleted #{uri} (#{index+1} of #{count})"
    elsif resp.status == 404
      puts "Skipped #{uri} (#{index+1} of #{count})"
    else
      raise "Error deleting #{uri}: #{resp.status}"
    end
  end
end
