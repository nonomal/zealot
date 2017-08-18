class DsymFileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/apps/a#{model.app.id}/dsym"
  end

  def size
    @size = file.size
  end

  def extension_white_list
    ['dsym']
  end

  def md5
    chunk = model.send(mounted_as)
    @md5 ||= Digest::MD5.hexdigest(chunk.read.to_s)
  end

  def filename
    @name ||= "#{md5}#{File.extname(super)}" if super
  end
end
