# Tar archive file object.
class Tarball::Archive
  enum Format
    OLD
    POSIX
    GNUTAR
  end

  @closed = false
  @entities = {} of String => Entity
  @format : Format?

  # Open tar archive from filename.
  def self.open(archive_file : String)
    new(archive_file)
  end

  private def initialize(archive_file : String)
    @io = File.open(archive_file)
    read_archive
  end

  # Returns entity from filename.
  def [](filename : String)
    @entities[filename]
  rescue KeyError
    raise ArchiveError.new("File not found in archive. '#{filename}'")
  end

  # Returns entity from filename.
  def []?(filename : String)
    @entities[filename]?
  end

  # Returns list of entities in archive.
  def entities
    @entities.values
  end

  # Returns file format(`Tarball::Archive::Format`) of this archive
  def format
    @format.not_nil!
  end

  # Returns list of included filenames.
  def filenames
    @entities.keys
  end

  def each_entity
    entities.sort.each
  end

  def each_entity(&block)
    entities.sort.each do |entity|
      yield entity
    end
  end

  def closed?
    @closed
  end

  def close
    return if closed?
    @io.close unless @io.closed?
    @closed = true
  end

  private def read_archive
    entity = nil
    loop do
      pos = @io.pos
      block = Tarball.read_block(@io)
      break if block == END_OF_ARCHIVE && Tarball.read_block(@io) == END_OF_ARCHIVE
      entity ||= Entity.new
      @io.pos = pos
      entry = Entry.new(@io)
      if format = @format
        raise ArchiveError.new("Multiple entry formats are intermingled.") unless format == entry.format
      else
        @format = entry.format
      end
      entity.add_entry(entry)
      if entity.has_body?
        raise ArchiveError.new("Duplicated file name '#{entity.name}' exists.") if @entities.has_key?(entity.name)
        @entities[entity.name] = entity
        entity = nil
      end
    end
    nil
  end

  # Extract all files to under the `dir`
  def extract_all(dir = ".")
    each_entity do |entity|
      entity.extract(dir)
    end
  end

  # Extracts a file to specific path.
  #
  # If `path` isn't given, default name is used.
  def extract_file(filename : String, path : String? = nil)
    entity = self[filename]
    path ||= entity.name
    entity.extract_as(path)
  end

  # Write content of a file to IO.
  def write_content(filename : String, io : IO)
    self[filename].write_content(io)
    nil
  end
end
