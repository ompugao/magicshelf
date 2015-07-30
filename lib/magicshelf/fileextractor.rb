require 'filemagic'
require 'zip'
require 'open3'
require 'shellwords'
require 'magicshelf/exception'

module MagicShelf
  class FileExtractorError < Error; end

  class FileExtractor
    attr_accessor :inputfile, :destdir

    def enter()
      raise MagicShelf::FileExtractorError.new("inputfile is not set") if @inputfile == nil
      mimetype = FileMagic.new(FileMagic::MAGIC_MIME_TYPE).file(@inputfile)
      raise MagicShelf::FileExtractorError.new("unsupported filetype: #{mimetype}") if not %w{application/x-rar application/zip}.include?(mimetype)
      @mimetype = mimetype
      
      yield
    end

    def process()
      case @mimetype
      when "application/zip"
        Zip::File.open(@inputfile) do |zip_file|
          zip_file.each do |entry|
            MagicShelf.logger.info("Extracting #{entry.name} ...")
            entry.extract(File.join(@destdir,entry.name))
          end
        end
      when "application/x-rar"
        out, err, status = Open3.capture3("which unrar")
        if status.exitstatus != 0
          raise MagicShelf::FileExtractorError.new("cannot execute unrar, is it on your PATH?")
        end
        
        out, err, status = Open3.capture3("unrar x #{Shellwords.escape(@inputfile)} #{Shellwords.escape(@destdir)}")
        if status.exitstatus != 0
          raise MagicShelf::FileExtractorError.new("unrar exits with status #{status.exitstatus}: \n #{out} \n #{err}")
        end
      else
        raise MagicShelf::FileExtractorError.new("no way to extract file for the file with filetype: #{@mimetype}")
      end

    end

  end
end
