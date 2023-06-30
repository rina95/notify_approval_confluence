# encoding: utf-8
require "faraday"

class CollectDataService
  attr_accessor :host, :basic_auth, :accout_ids_list

  def initialize
    @host = ENV["CONFLUENCE_HOST"]
    @basic_auth = {
      username: ENV["CONFLUENCE_USER_NAME"],
      password: ENV["CONFLUENCE_API_KEY"]
    }
    @accout_ids_list = ActiveSupport::JSON.decode(ENV["ACCOUNT_ID_LIST"]) rescue []
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
      page_status = get_state(page_id).downcase rescue ""
      page["status"] = page_status
      next unless page_status == "confirmed"

      page["approval_users"] = []
      path = Settings.confluence.path.get_comments % {page_id: page_id}
      response = call_api(path)
      comments = ActiveSupport::JSON.decode(response.body)&.dig("results")
      comments.each do |comment|
        content = comment.dig("body", "view", "value")
        created_by = comment.dig("history", "createdBy", "accountId")
        # binding.pry if created_by == "62f4ba4bb5b801a9aff191c8"
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
    hash = {}
    keys = accout_ids_list.keys
    get_page_comments.each do |data|
      next unless data["status"] == "confirmed"
      ids = keys - data["approval_users"]
      ids.each do |id|
        # hash[id] = hash[id] ? hash[id] : {"email": accout_ids_list[id], href: []}
        hash[id] = hash[id] ? hash[id] : {"email": "phanbt95@gmail.com", href: []}
        hash[id][:href] << host + data["href"].gsub("_", "+")
      end
    end
    hash
  end

  def send_notification
    pp extract_datas
    extract_datas.each do |accountID, data|
      email = data[:email]
      links = data[:href]
      NotifyApproveMailer.notify(email, links).deliver_now
    end
  end

  def call_api full_path
    request_helper = Faraday.new(url: host) do |builder|
      builder.request :authorization, :basic, basic_auth[:username], basic_auth[:password]
    end
   request_helper.get(full_path)
  end
end
