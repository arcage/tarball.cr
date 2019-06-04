# Header object of entries included in tar file.
class Tarball::Header
  # :nodoc:
  TYPES = {
    '\0' => Entry::Type::FILE,
    '0'  => Entry::Type::FILE,
    '1'  => Entry::Type::HARDLINK,
    '2'  => Entry::Type::SYMLINK,
    '5'  => Entry::Type::DIRECTORY,
    'L'  => Entry::Type::LONGNAME,
    'K'  => Entry::Type::LONGLINKNAME,
  }

  # :nodoc:
  COMMON = {
    name:     0..99,
    mode:     100..107,
    uid:      108..115,
    gid:      116..123,
    size:     124..135,
    mtime:    136..147,
    checksum: 148..155,
    linkname: 157..256,
    magic:    257..262,
  }

  # :nodoc:
  USTAR = {
    version:  263..264,
    uname:    265..296,
    gname:    297..328,
    devmajor: 329..336,
    devminor: 337..344,
  }

  # :nodoc:
  POSIX = {
    prefix: 345..499,
  }

  # :nodoc:
  GNUTAR = {
    atime:     345..356,
    ctime:     357..368,
    offset:    369..380,
    longnames: 381..384,
    sparse:    386..481,
    realsize:  483..494,
  }

  # Creates Header object from byte data.
  #
  # `data` must be 512 bytes.
  def initialize(@data : Bytes)
    raise HeaderError.new("header data must be 512 byte.") unless @data.size == BLOCK_SIZE
    verify_checksum if checksum
  end

  macro string_field(field_name, header_format)
    @{{field_name.id}} : String?
    
    {{ "# Returns **#{field_name.id}** field in this header.".id }}
    {% if header_format.id != :common %}{{ "# (#{header_format.upcase.id} format)".id }}{% end %}
    def {{field_name.id}} : String
      @{{field_name.id}} ||= as_string({{header_format.id}}_data(:{{field_name.id}}))
    end
  end

  macro number_field(field_name, header_format)
    @{{field_name.id}} : UInt64?
    
    {{ "# Returns **#{field_name.id}** field in this header.".id }}
    {% if header_format.id != :common %}{{ "# (#{header_format.upcase.id} format)".id }}{% end %}
    def {{field_name.id}} : UInt64
      @{{field_name.id}} ||= as_number({{header_format.id}}_data(:{{field_name.id}}))
    end
  end

  macro time_field(field_name, header_format)
    @{{field_name.id}} : Time?
    
    {{ "# Returns **#{field_name.id}** field in this header.".id }}
    {% if header_format.id != :common %}{{ "# (#{header_format.upcase.id} format)".id }}{% end %}
    def {{field_name.id}} : Time
      @{{field_name.id}} ||= as_time({{header_format.id}}_data(:{{field_name.id}}))
    end
  end

  string_field(:name, :common)
  number_field(:mode, :common)
  number_field(:uid, :common)
  number_field(:gid, :common)
  number_field(:size, :common)
  time_field(:mtime, :common)
  number_field(:checksum, :common)
  string_field(:linkname, :common)
  string_field(:magic, :common)

  string_field(:version, :ustar)
  string_field(:uname, :ustar)
  string_field(:gname, :ustar)
  number_field(:devmajor, :ustar)
  number_field(:devminor, :ustar)

  string_field(:prefix, :posix)

  time_field(:atime, :gnutar)
  time_field(:ctime, :gnutar)
  number_field(:offset, :gnutar)
  number_field(:realsize, :gnutar)

  @typeflag : Char?

  # Returns **typeflag** field in this header.
  def typeflag : Char
    @typeflag ||= as_char(@data[156])
  end

  # Returns entiry type.
  def type
    TYPES[typeflag]? || Entry::Type::UNSUPPORTED
  end

  @isextended : Bool?

  # Returns **isextended** field in this header. (GNUTAR format)
  def isextended : Bool
    HeaderError.new("isextended field can be used only in GNU tar format") unless gnutar?
    @isextended ||= as_bool(@data[482])
  end

  # :nodoc:
  def to_s(io)
    inspect(io)
  end

  # :nodoc:
  def inspect(io : IO)
    io << '<' << self.class.name << ":0x" << object_id.to_s.rjust(16, '0') << ' '
    io << "@name="; name.inspect(io)
    io << ", @mode="; mode.inspect(io)
    io << ", @uid="; uid.inspect(io)
    io << ", @gid="; gid.inspect(io)
    io << ", @size="; size.inspect(io)
    io << ", @mtime="; Time::Format::ISO_8601_DATE_TIME.format(mtime, io)
    io << ", @checksum="; checksum.inspect(io)
    io << ", @typeflag="; typeflag.inspect(io)
    io << ", @linkname="; linkname.inspect(io)
    io << ", @magic="; magic.inspect(io)
    io << '>'
    nil
  end

  private def verify_checksum
    calc = 0u64
    0.upto(147) do |i|
      calc += @data[i]
    end
    148.upto(155) do
      calc += 32
    end
    156.upto(BLOCK_SIZE - 1) do |i|
      calc += @data[i]
    end
    raise HeaderError.new("Invalid checksum value.") unless checksum == calc
    nil
  end

  # Returns how many blocks exist for content data.
  def content_blocks : Int32
    ((size.to_f / BLOCK_SIZE).ceil).to_i
  end

  private def as_string(bytes : Bytes) : String
    String.new(bytes).sub(/\0.*/, "")
  end

  private def as_number(bytes : Bytes) : UInt64
    str = as_string(bytes)
    if str.empty?
      0u64
    else
      str.to_u64(8)
    end
  end

  private def as_char(byte : UInt8) : Char
    byte.unsafe_chr
  end

  private def as_bool(byte : UInt8) : Bool
    !byte == 0
  end

  private def as_time(bytes : Bytes) : Time
    Time.unix(as_number(bytes)).to_local
  end

  # Returns `true` when self is POSIX format.
  def posix? : Bool
    magic == "ustar"
  end

  # Returns `true` when self is GNUTAR format.
  def gnutar? : Bool
    magic == "ustar "
  end

  # Returns `true` when self is POSIX or GNUTAR format.
  def ustar? : Bool
    posix? || gnutar?
  end

  private def common_data(field : Symbol) : Bytes
    @data[COMMON[field]]
  rescue KeyError
    raise HeaderError.new("#{field} field not found")
  end

  private def ustar_data(field : Symbol) : Bytes
    raise HeaderError.new("#{field} field can be used only in POSIX or GNU tar format") unless ustar?
    @data[USTAR[field]]
  rescue KeyError
    raise HeaderError.new("#{field} field not found")
  end

  private def posix_data(field : Symbol) : Bytes
    raise HeaderError.new("#{field} field can be used only in POSIX format") unless posix?
    @data[POSIX[field]]
  rescue KeyError
    raise HeaderError.new("#{field} field not found")
  end

  private def gnutar_data(field : Symbol) : Bytes
    raise HeaderError.new("#{field} field can be used only in GNU tar format") unless gnutar?
    @data[GNUTAR[field]]
  rescue KeyError
    raise HeaderError.new("#{field} field not found")
  end
end
