require "gzip"

# Gzipped tar archive file object.
class Tarball::GzArchive < Tarball::Archive
  private def initialize(archive_file : String)
    @io = File.tempfile("tarball.cr", ".tar")
    bytes = Bytes.new(1024)
    Gzip::Reader.open(archive_file) do |gz|
      loop do
        read_size = gz.read(bytes)
        break if read_size == 0
        @io.write bytes[0, read_size]
      end
    end
    @io.rewind
    read_archive
  end

  def finalize
    @io.delete
  end
end
