module Stifado
  # Responsible for splitting a file into multiple parts
  # of a set size.
  class Splitter
    getter parts : Array(Path) = [] of Path

    def initialize(file : Path, output : Path, limit : Int32 = 5_000_000)
      # Exit if for some reason the file doesn't exist.
      abort "File doesnt exist" unless File.exists?(file)
      # Create the output path if it doesn't exist.
      Dir.mkdir_p(output)

      @file = file
      @output = output
      @limit = limit

      split
    end

    # The split function.
    private def split
      dest = @output / @file.basename

      # Open the file.
      File.open(@file) do |file|
        part = 0
        offset = 0
        file_size = file.size

        # While the offset is smaller than
        # the file size.
        while offset < file_size
          # If we are requesting a range outside
          # the file limits, change it so it's
          # right at the end.
          safe_limit = offset + @limit > file_size ? file_size - offset : @limit

          # The part path is {path}.XXX where XXX
          # is the part no padded with 0s so it's
          # 3 digits.
          part_path = Path["#{dest}.#{part.to_s.rjust(3, '0')}"]

          # Get the range of bytes between offset
          # and safe_limit and write them back at
          # part_path.
          file.read_at(offset, safe_limit) do |io|
            File.write(part_path, io)
          end
          # Add the new part to the list.
          @parts << part_path

          # Increase part no by 1.
          part = part.succ
          # Increase offset to the next range.
          offset = offset + @limit
        end
      end
    end
  end
end
