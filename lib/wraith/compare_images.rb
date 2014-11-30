require 'wraith'
require 'image_size'
require 'open3'
require 'parallel'

class Wraith::CompareImages
  attr_reader :wraith

  def initialize(config)
    @wraith = Wraith::Wraith.new(config)
    File.unlink @wraith.fail_log if File.exists? @wraith.fail_log
  end


  def compare_images
    files = Dir.glob("#{wraith.directory}/*/*.png").sort
    Parallel.each(files.each_slice(2), in_processes: Parallel.processor_count) do |base, compare|
      diff = base.gsub(/([a-z0-9]+).png$/, 'diff.png')
      info = base.gsub(/([a-z0-9]+).png$/, 'data.txt')
      compare_task(base, compare, diff, info)
    end
    !File.exist? @wraith.fail_log
  end 

  def percentage(img_size, px_value, info)
    pixel_count = (px_value / img_size) * 100
    rounded = pixel_count.round(2)
    File.open(info, 'w') { |file| file.write(rounded) }
    if rounded != 0.0
      STDERR.puts "ERROR: #{info} - #{rounded}"
      `echo #{info} >> #{@wraith.fail_log}`
    end
  end

  def compare_task(base, compare, output, info)
    cmdline = "compare -dissimilarity-threshold 1 -fuzz #{wraith.fuzz} -metric AE -highlight-color blue #{base} #{compare} #{output}"
    px_value = Open3.popen3(cmdline) { |_stdin, _stdout, stderr, _wait_thr| stderr.read }.to_f
    begin
      img_size = ImageSize.path(output).size.inject(:*)
      p = percentage(img_size, px_value, info)
    rescue
      File.open(info, 'w') { |file| file.write('invalid') } unless File.exist?(output)
    end
  end
end
