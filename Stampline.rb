class Stampline

  def initialize(word, stamps)
    @word = word
    @stamps = stamps
  end

  attr_accessor :word, :stamps

  #to view as an object
  def to_s
    str = '[ ' + @word + ' : '
    @stamps.each { |stamp| str += stamp + ' , '}
    str << "\b\b]\n"
    str
  end

  def to_l
    @word + ' : ' + @stamps[-1] + "\n"
  end

  def to_v
    str = @word + ' ; '
    @stamps.each { |stamp| str += stamp + ' , '}
    str.delete_suffix!(' , ') << "\n"
  end

  def add_stamp
    str = Date.today.to_s
    @stamps << str unless @stamps[-1].eql? str
    self
  end

  def show_last
    @word + ' : ' + stamps[-1]
  end

  def show_first
    @word + ' : ' + stamps[1]
  end

  def eql?(other)
    word.eql? other.word && stamps.eql?(other.translation)
  end

  def hash
    [word, stamps].hash
  end
end