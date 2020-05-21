module NodeToSource
  def to_source
    node = RubyVM::AbstractSyntaxTree.of(self)
    return nil if node.nil?

    path, _lineno = source_location
    lines_for_file = File.readlines(path)
    extract_source(node: node, lines_for_file: lines_for_file)
  end

  private

  def extract_source(node:, lines_for_file:)
    first_lineno = node.first_lineno - 1
    first_column = node.first_column
    last_lineno = node.last_lineno - 1
    last_column = node.last_column - 1

    if first_lineno == last_lineno
      lines_for_file[first_lineno][first_column..last_column]
    else
      src = ' ' * first_column + lines_for_file[first_lineno][first_column..]
      ((first_lineno + 1)...last_lineno).each do |lineno|
        src << lines_for_file[lineno]
      end
      src << lines_for_file[last_lineno][0..last_column]
    end
  end
end

class Method
  include NodeToSource
end

class Proc
  include NodeToSource
end
