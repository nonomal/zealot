# frozen_string_literal: true

module ReleaseUrl
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  def download_url
    download_release_url(id)
  end

  def install_url
    if platform.casecmp?('unknown') || platform.casecmp?('android') || platform.casecmp?('macos')
      return download_url
    end

    ios_url = channel_release_install_url(channel.slug, id)
    "itms-services://?action=download-manifest&url=#{ios_url}"
  end

  def release_url
    friendly_channel_release_url(channel, self)
  end

  def qrcode_url(size = :thumb)
    channel_release_qrcode_url(channel, self, size: size)
  end
end