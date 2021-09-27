require "Dictionary"

def starter(mode, platform)
  platform = (
    if platform.eql? "x64-mingw32"
      :win
    elsif platform.eql? "x86_64-linux-gnu"
      :linux
    else
      :mac
    end
  )
  puts "Running on " + platform.to_s
  if platform.eql? :mac or platform.eql? :linux
    Dictionary.new(platform, mode)
  elsif platform.eql? :win
    status = File.open('data/instance.lock').read
    if status.eql? 'free'
      set_availability false
      Dictionary.new(platform, mode)
      set_availability true
    else
      puts "Script is locked. Do you wish to unlock it?"
      gets.chomp
      set_availability true
      system %{taskkill /IM ruby.exe}
    end
  end
end

def set_availability(bool)
  File.open(File.dirname(__FILE__) + "/data/instance.lock", 'w') do |f|
    f << (bool ? 'free' : 'taken')
    f.close
  end
end

