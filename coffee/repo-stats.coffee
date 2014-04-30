
class RepoStats
  stats: =>
    inf = source: file: 0

    for x, source of @sources
      inf.source.file += 1

      if source.src?
        inf.source.load ?= 0
        inf.source.load += 1
        inf.source.size ?= 0
        inf.source.size += source.src.length
      if source.error?
        inf.source.error ?= 0
        inf.source.error += 1

      if source.compiler?
        inf.compile ?= {}
        inf.compile.file ?= 0
        inf.compile.file += 1

        if source.compiler.src?
          inf.compile.done ?= 0
          inf.compile.done += 1
          inf.compile.size ?= 0
          inf.compile.size += source.compiler.src.length
        if source.compiler.error?
          inf.compile.error ?= 0
          inf.compile.error += 1

      if source.minifier?
        inf.minify ?= {}

        if source.minifier.src?
          inf.minify.done ?= 0
          inf.minify.done += 1
          inf.minify.size ?= 0
          inf.minify.size += source.minifier.src.length
        if source.minifier.error?
          inf.minify.error ?= 0
          inf.minify.error += 1

      if source.deployer?
        inf.deploy ?= {}

        if source.minifier.src?
          inf.deploy.done ?= 0
          inf.deploy.done += 1
        if source.minifier.error?
          inf.deploy.error ?= 0
          inf.deploy.error += 1

    inf.source.inProgress = !@watchingAll or inf.source.load < inf.source.file

    if inf.compile?
      inf.compile.inProgress = 0 < (inf.compile.done or 0) +
                                   (inf.compile.error or 0) < inf.compile.file

    if inf.minify?
      inf.minify.inProgress = 0 < (inf.minify.done or 0) +
                                  (inf.minify.error or 0) < inf.source.file

    if inf.deploy?
      inf.deploy.inProgress = 0 < (inf.deploy.done or 0) +
                                  (inf.deploy.error or 0) < inf.source.file

    if @concatenator?
      inf.concat ?= {}

      if @concatenator.src?
        inf.concat.size ?= 0
        inf.concat.size += @concatenator.src.length
      if @concatenator.error?
        inf.concat.error ?= 0
        inf.concat.error += 1

      inf.concat.inProgress = not (inf.concat.size or inf.concat.error or
                                   inf.compile?.inProgress or inf.source.inProgress)

    if @minifier?
      inf.minify ?= {}

      if @minifier.src?
        inf.minify.done = 1
        inf.minify.size = @minifier.src.length
      if @minifier.error?
        inf.minify.done = 0
        inf.minify.error = 1

      inf.minify.inProgress = not (inf.minify.size or inf.minify.error or
                                   inf.concat?.inProgress or
                                   inf.compile?.inProgress or inf.source.inProgress)

    if @deployer?
      inf.deploy ?= {}

      if @deployer.deployed
        inf.deploy.done = 1
      else if @deployer.error
        inf.deploy.done  = 0
        inf.deploy.error = 1

      inf.deploy.inProgress = not (inf.deploy.done or inf.deploy.error or
                                   inf.minify?.inProgress or inf.concat?.inProgress or
                                   inf.compile?.inProgress or inf.source.inProgress)

    inf

module.exports = RepoStats
