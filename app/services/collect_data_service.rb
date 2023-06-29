require "faraday"

class CollectDataService
  attr_accessor :host, :basic_auth

  def initialize
    @host = ENV["CONFLUENCE_HOST"]
    @basic_auth = {
      username: ENV["CONFLUENCE_USER_NAME"],
      password: ENV["CONFLUENCE_API_KEY"]
    }
  end

  def perform
    send_notification
  end

  def get_pages_approving
    path = Settings.confluence.path.get_children % {page_id: Settings.confluence.parent_page_id}
    response = call_api(path)
    content = ActiveSupport::JSON.decode(response.body)&.dig("body", "view", "value")
    parsed_content = content.split("</a></li>").map do |t|
      hash = {}
      t.rpartition('<li><a ').last.split(" ").each do |child|
        key, value = child.split("=", 2)
        hash[key] = value&.gsub(/"/, '')
      end
      hash
    end
  end

  def get_page_comments
    page_informations = get_pages_approving.reject {|t| t["data-linked-resource-id"].blank? }
    page_informations.each do |page|
      page_id = page["data-linked-resource-id"]
      next unless page_id && get_state(page_id).downcase == "confirmed"

      page["approval_users"] = []
      path = Settings.confluence.path.get_comments % {page_id: page_id}
      response = call_api(path)
      comments = ActiveSupport::JSON.decode(response.body)&.dig("results")
      comments.each do |comment|
        content = comment.dig("body", "view", "value")
        created_by = comment.dig("history", "createdBy", "accountId")
        next unless content.downcase.include?("thống nhất")
        page["approval_users"] << created_by
      end
      page["approval_users"].uniq!
    end
    page_informations
  end

  def get_state page_id
    path = Settings.confluence.path.get_state % {page_id: page_id}
    response = call_api(path)
    ActiveSupport::JSON.decode(response.body).dig("contentState", "name")
  end

  def extract_datas
    get_page_comments
  end

  def send_notification
    extract_datas.each do ||

    end
  end

  def call_api full_path
    request_helper = Faraday.new(url: host) do |builder|
      builder.request :authorization, :basic, basic_auth[:username], basic_auth[:password]
    end
   request_helper.get(full_path)
  end
end
