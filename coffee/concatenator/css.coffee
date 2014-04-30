Concatenator = require '../concatenator'


class CssConcatenator extends Concatenator
  concat: (callback) =>
    delete @error
    delete @src

    try
      concatenated = ''
      for path, source of @source.sources
        concatenated += ((source.compiler or source).src or '') + '\n\n'
      @src = concatenated
    catch err
      @error = err
#       console.error '\nCSS CONCAT ERROR', @source.path, err

    callback? @error, @src

module.exports = CssConcatenator
