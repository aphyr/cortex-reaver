class Array
  # Extend Array with #all, so that I can just call All on sequel datasets
  # without worrying if they're arrays or not.
  def all
    self
  end
end
