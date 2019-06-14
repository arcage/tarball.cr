# ```crystal
# require "tarball"
#
# # Extracts all files in "archive.tar" to under the "data" directory.
# Tarball.extract_all("archive.tar", "data")
# ```
module Tarball
  VERSION = "0.1.3"

  # :nodoc:
  class Error < Exception; end

  # :nodoc:
  class ArchiveError < Error; end

  # :nodoc:
  class EntryError < Error; end

  # :nodoc:
  class HeaderError < Error; end

  # :nodoc:
  class EntityError < Error; end

  # :nodoc:
  class PaxdataError < Error; end

  BLOCK_SIZE = 512

  # :nodoc:
  END_OF_ARCHIVE = Bytes.new(BLOCK_SIZE, 0)

  # Extracts all file system objects in the tar archive file.
  def self.extract_all(archive_file : String, dir = ".")
    Archive.open(archive_file) do |archive|
      archive.extract_all(dir)
    end
  end

  # Opens tar archive file.
  def self.open(archive_file : String)
    Archive.open(archive_file)
  end

  # Opens tar archive file and yields given block.
  def self.open(archive_file : String, &block)
    archive = Archive.open(archive_file)
    yield archive
    archive.close
  end

  # Opens gzipped tar archive file.
  def self.open_gz(archive_file : String)
    GzArchive.open(archive_file)
  end

  # Opens gzipped tar archive file and yields given block.
  def self.open_gz(archive_file : String, &block)
    archive = GzArchive.open(archive_file)
    yield archive
    archive.close
  end

  # :nodoc:
  def self.read_block(io : IO)
    block = Bytes.new(BLOCK_SIZE, 0)
    read_size = io.read(block)
    raise Error.new("Invalid file size") unless read_size == BLOCK_SIZE
    block
  end
end

require "./tarball/*"
