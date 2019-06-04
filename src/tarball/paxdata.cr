# :nodoc:
module Tarball::Paxdata
  def self.parse(io : IO)
    data = Hash(String, String).new
    io.each_line do |line|
      key, value = parse_line(line)
      data[key] = value
    end
    data
  end

  private def self.parse_line(line)
    parts = line.split(' ')
    length = parts.shift.to_i
    raise PaxdataError.new("Invalid line length") unless length == line.bytesize + 1
    parts = parts.join(' ').split('=')
    key = parts.shift
    value = parts.join('=')
    {key, value}
  end
end
