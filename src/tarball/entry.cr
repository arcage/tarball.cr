# Tar entry object.
class Tarball::Entry
  enum Type
    DIRECTORY
    FILE
    HARDLINK
    SYMLINK
    LONGNAME
    LONGLINKNAME
    PAXDATA
    UNSUPPORTED  = Int32::MAX
  end

  # Returns `Tarball::Header` object of this entiry
  getter header

  @pos : (Int32 | Int64)

  def initialize(@io : IO)
    @pos = @io.pos
    @header = Header.new(Tarball.read_block(io))
    @io.pos = next_entry_pos
  end

  # Returns offset of content data.
  def content_pos
    @pos + BLOCK_SIZE
  end

  # Returns offset of next entry
  def next_entry_pos
    content_pos + header.content_blocks * BLOCK_SIZE
  end

  # Returns entry type.
  def type
    header.type
  end

  # Returns entry format.
  def format
    header.format
  end

  # Writes content data to IO.
  def write_content(io : IO)
    remains = @header.size
    @io.pos = content_pos
    loop do
      bytes = Tarball.read_block(@io)
      if remains >= BLOCK_SIZE
        io.write bytes
      else
        io.write bytes[0, remains]
        break
      end
      remains -= BLOCK_SIZE
    end
    nil
  end

  # Returns PAX data.
  #
  # When self is not a `Tarball::Entry::Type::PAXDATA`
  def pax_data
    raise EntryError.new("Not a PAXHEADER entry") unless type.paxdata?
    pos = @io.pos
    buffer = IO::Memory.new(@header.size)
    write_content(buffer)
    buffer.rewind
    Paxdata.parse(buffer)
  end
end
