require "file_utils"

# File system objects(regular files, directries or links) in the tar archive.
#
# Tarball::Entity object must contain an entity body entry with one of following entry types:
#
# - Tarball::Entry::Type::FILE (Regular file)
# - Tarball::Entry::Type::HARDLINK (Hardlink)
# - Tarball::Entry::Type::SYMLINK (Symlink)
# - Tarball::Entry::Type::DIRECTORY (Directory)
#
# It can contain one each of Tarball::Entry::Type::LONGNAME (GNUTAR long name) entry and a Tarball::Entry::Type::LONGNAME (GNUTAR long linkname) entry.
class Tarball::Entity
  include Comparable(self)

  @entries = [] of Entry
  @body : Entry?
  @long_name : String?
  @long_linkname : String?

  # :nodoc:
  def type
    body.type
  end

  def <=>(other : self)
    if self.type == other.type
      self.name <=> other.name
    else
      self.type <=> other.type
    end
  end

  # Adds tar file entry to this entity.
  def add_entry(entry : Entry)
    case entry.type
    when .longname?
      set_long_name(entry)
    when .longlinkname?
      set_long_linkname(entry)
    else
      set_entity_body(entry)
    end
    self
  end

  # Returns `true` when entity body has been set.
  def has_body?
    @body ? true : false
  end

  # Returns `true` when entity body has been set.
  def has_long_name?
    @long_name ? true : false
  end

  # Returns `true` when entity body has been set.
  def has_long_linkname?
    @long_name ? true : false
  end

  # Returns `true` when self is a regular file.
  def file?
    type.file?
  end

  # Returns `true` when self is a directory.
  def directory?
    type.directory?
  end

  # Returns `true` when self is a hardlink.
  def hardlink?
    type.hardlink?
  end

  # Returns `true` when self is a symlink.
  def symlink?
    type.symlink?
  end

  private def set_entity_body(entry : Entry)
    raise EntityError.new("Entity already exist.") if has_body?
    @body = entry
  end

  private def set_long_name(entry : Entry)
    raise EntityError.new("Long name already exist.") if has_long_name?
    @long_name = String.build { |io| entry.write_content(io) }.sub(/\0.*/, "")
  end

  private def set_long_linkname(entry : Entry)
    raise EntityError.new("Long link name already exist.") if has_long_linkname?
    @long_linkname = String.build { |io| entry.write_content(io) }.sub(/\0.*/, "")
  end

  private def body
    if body = @body
      body
    else
      raise EntityError.new("No entity exists yet.")
    end
  end

  # Returns file or directory name of this entity.
  def name
    if body.header.gnutar?
      @long_name || body.header.name
    else
      String.build do |str|
        if body.header.posix?
          unless body.header.prefix.empty?
            str << body.header.prefix << '/'
          end
        end
        str << body.header.name
      end
    end
  end

  # Returns file or directory name that this entity links to.
  #
  # `linkname` is only used when the entity body is Entry::Type::HARDLINK or Entry::Type::SYMLINK.
  def linkname
    if body.header.gnutar?
      @long_linkname || body.header.linkname
    else
      body.header.linkname
    end
  end

  # :nodoc:
  def to_s(io : IO)
    io << name
    nil
  end

  # Writes content data of the entity to IO.
  def content(io : IO)
    body.content(io)
    nil
  end

  # :nodoc:
  def extract(dir = ".")
    full_path = File.expand_path(name, dir)
    case type
    when .hardlink?
      link_path = File.expand_path(linkname, dir)
      extract_hardlink(full_path, link_path)
    when .symlink?
      extract_symlink(full_path, linkname)
    when .directory?
      extract_dir(full_path)
    else
      extract_file(full_path)
    end
  end

  # Writes content data to IO.
  def write_content(io : IO)
    body.write_content(io)
  end

  # :nodoc:
  def extract_as(filename : String)
    raise EntityError.new("Only regular file can extract as a specific filename.") unless type.file?
    full_path = File.expand_path(filename)
    extract_file(full_path)
  end

  private def extract_dir(full_path : String)
    FileUtils.mkdir_p(full_path, mode: body.header.mode.to_i32)
  end

  private def extract_file(full_path : String)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.open(full_path, "w", perm: body.header.mode.to_i32) do |file|
      body.write_content(file)
    end
  end

  private def extract_symlink(full_path : String, link_path : String)
    FileUtils.ln_s(link_path, full_path)
  end

  private def extract_hardlink(full_path : String, link_path : String)
    FileUtils.ln(link_path, full_path)
  end
end
