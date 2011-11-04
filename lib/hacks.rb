class Array
  def sample ; self[rand(size)] ; end
end

class File
  # reverse_readline
  def reverse_readline
    buffer = 1024
    lines = []
    done = false
    seek(0,SEEK_END)
    while !done
      if pos > buffer
         to_read = buffer
         seek(-to_read,SEEK_CUR)
      else
         to_read = pos
         seek(0,SEEK_SET)
         done=true
      end
      chunk = read(to_read)
      chunk += lines.first unless lines.empty?
      lines = chunk.split("\n")
      lines[(done ? 0 : 1)..-1].reverse.each do |line| 
        result = yield line
        break unless result 
      end
      seek(-to_read,SEEK_CUR)
    end
  end
end


