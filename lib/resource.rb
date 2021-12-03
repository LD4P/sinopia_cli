# frozen_string_literal: true

require 'client'
require 'json'
require 'thor'

# Methods for resource endpoint
class Resource < Thor
  class_option :api_url, type: :string, default: 'https://api.stage.sinopia.io'

  option :uri_only, type: :boolean, desc: 'Print resource URIs only.'
  option :files, type: :boolean, desc: 'Write to files.'
  option :templates_only, type: :boolean, desc: 'Resource templates only.'
  option :group, type: :string, desc: 'Group name filter.'
  option :updated_before, type: :string,
                          desc: 'Resource last updated before filter, e.g., 2019-11-08T17:40:23.363Z'
  option :updated_after, type: :string, desc: 'Resource last updated after filter, e.g., 2019-11-08T17:40:23.363Z'
  option :type, type: :string, desc: 'Class filter, e.g., http://id.loc.gov/ontologies/bibframe/AbbreviatedTitle'
  desc 'list', 'list resources'
  # rubocop:disable Metrics/AbcSize
  def list
    url = "#{options[:api_url]}/resource"
    while url
      params = {
        'group' => options[:group],
        'updatedBefore' => options[:updated_before],
        'updatedAfter' => options[:updated_after],
        'type' => options[:templates_only] ? 'http://sinopia.io/vocabulary/ResourceTemplate' : options[:type]
      }.compact
      url = list_page(url, options[:uri_only], options[:files], params)
    end
  end
  # rubocop:enable Metrics/AbcSize

  option :uri, type: :array, desc: 'Space separated list of URIs.'
  option :file, type: :string, desc: 'File containing list of URIs.'
  option :token, type: :string, desc: 'JWT token. Otherwise, read from .cognitoToken'
  desc 'delete', 'delete resources'
  def delete
    raise 'Must provide a URI or file' unless options.key?(:uri) || options.key?(:file)

    uris = options.key?(:uri) ? options[:uri] : File.readlines(options[:file], chomp: true)
    uris.each_with_index { |uri, index| delete_resource(uri, index, uris.size) }
  end

  option :uri, type: :array, desc: 'Space separated list of source URIs.'
  option :file, type: :string, desc: 'File containing list of source URIs.'
  option :token, type: :string, desc: 'JWT token. Otherwise, read from .cognitoToken'
  option :overwrite, type: :boolean, default: false, desc: 'Overwrite resource if it already exists'
  desc 'copy', 'copy resources from one Sinopia environment to another'
  def copy
    source_uris = source_uris_from_options(options)
    source_uris.each.with_index(1) do |source_uri, index|
      dest_uri = copy_resource(source_uri, overwrite: options[:overwrite])
      puts "Copied #{source_uri} to #{dest_uri} (#{index} of #{source_uris.count})"
    rescue RuntimeError => e
      puts "Error copying #{source_uri}: #{e}"
    end
  end

  private

  def connection
    @connection ||= Client.connection
  end

  def connection_with_token
    @connection_with_token ||= Client.connection(token: token)
  end

  def list_page(url, uri_only, files, params = {})
    resp = connection.get url, params
    raise "Error getting #{url}." unless resp.success?

    resp_json = JSON.parse(resp.body)
    put_page(resp_json, uri_only, files)
    resp_json.dig('links', 'next')
  end

  def put_page(resp_json, uri_only, files)
    resp_json['data'].each do |resource|
      if uri_only
        puts resource['uri']
      else
        puts JSON.pretty_generate(resource)
      end
      put_file(resource) if files
    end
  end

  def put_file(resource)
    Dir.mkdir('output') unless File.exist?('output')
    File.write("output/#{resource['id']}.json", JSON.pretty_generate(resource))
  end

  def delete_resource(uri, index, count)
    resp = connection_with_token.delete uri
    if resp.success?
      puts "Deleted #{uri} (#{index + 1} of #{count})"
    elsif resp.status == 404
      puts "Skipped #{uri} (#{index + 1} of #{count})"
    else
      raise "Error deleting #{uri}: #{resp.status}"
    end
  end

  def copy_resource(source_uri, overwrite: false)
    source_resource_body = get_resource(source_uri)
    source_id = JSON.parse(source_resource_body)['id']
    dest_uri = "#{options[:api_url]}/resource/#{source_id}"

    dest_resource = source_resource_body.gsub(source_uri, dest_uri)

    http_method = resource_exists?(dest_uri) && overwrite ? :put : :post
    resp = connection_with_token.public_send(http_method, dest_uri, dest_resource)

    raise "Error copying #{source_uri} to #{dest_uri}: (#{resp.status}) #{resp.body}" unless resp.success?

    dest_uri
  end

  def source_uris_from_options(options)
    raise 'Must provide a URI or file' unless options.key?(:uri) || options.key?(:file)

    options.key?(:uri) ? options[:uri] : File.readlines(options[:file], chomp: true)
  end

  def get_resource(uri)
    resp = connection.get(uri)
    raise "Error getting #{uri}: #{resp.status}" unless resp.success?

    resp.body
  end

  def resource_exists?(uri)
    connection.get(uri).success?
  end

  def token
    @token ||= options[:token] || File.read('.cognitoToken')
  end
end
