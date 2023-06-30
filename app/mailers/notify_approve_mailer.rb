class NotifyApproveMailer < ApplicationMailer
  default from: "notifications@gmail.com"

  def notify mail, links
    @link_page_list = links
    @contact_name = ENV["CONTACT_USER_NAME"]
    @contact_phone = ENV["CONTACT_PHONE_NUMBER"]
    @contact_email = ENV["CONTACT_EMAIL"]
    mail(to: mail, subject: Settings.mail.subject)
  end
end
