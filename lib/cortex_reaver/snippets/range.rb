class Range
  # Constructs the smallest range which covers this and other.
  def |(other)
    my_end, other_end = self.end, other.end
    my_end -= 1 if self.exclude_end?
    other_end -= 1 if other.exclude_end?
    [self.begin, other.begin].min .. [my_end, other_end].max
  end
end
