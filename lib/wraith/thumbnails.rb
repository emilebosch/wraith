require 'wraith'
require 'parallel'
require 'fileutils'

class Wraith::Thumbnails
  attr_reader :wraith

  def initialize(config)
    @wraith = Wraith::Wraith.new(config)
  end

  def generate_thumbnails
    puts 'Generating thumbnails'

    files = Dir.glob("#{wraith.directory}/*/*.png")

    Parallel.each(files, in_processes: Parallel.processor_count) do |filename|
      new_name = filename.gsub(/^#{wraith.directory}/, "#{wraith.directory}/thumbnails")
      thumbnail_image(filename, new_name)
    end
  end

  def thumbnail_image(png_path, output_path)
    unless File.directory?(File.dirname(output_path))
      FileUtils.mkdir_p(File.dirname(output_path))
    end

    `convert #{png_path} -thumbnail 200 -crop 200x200+0+0 #{output_path}`
  end
end
