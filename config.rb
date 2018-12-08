

###
# Compass
###

compass_config do |config|
  config.output_style = :nested
  config.line_comments = false
end

###
# Bower
###
activate :bower

# Make sure that all partials are rendered without a layout
page "/partials/*", :layout => false

###
# Page options, layouts, aliases and proxies
###
set :css_dir, 'assets/css'
set :js_dir, 'assets/js'
set :images_dir, 'assets/img'

set :haml, :attr_wrapper => "\""

###
# Helpers
###
activate :livereload
activate :directory_indexes
activate :automatic_image_sizes

# Build-specific configuration
configure :build do

  # ignore dev stuff
  ignore 'dev/*'
  ignore 'assets/css/dev/*'
  ignore 'assets/js/dev/*'

  # ignore local data
  ignore 'data/*'

  # all js is bundled into application.js
  ignore 'assets/bower/*'
  ignore 'assets/js/libs/*'
  ignore 'assets/js/app/*'

  # partials and layouts not needed in build
  ignore 'layouts/*'
  ignore 'partials/*'

  activate :minify_css
  activate :minify_javascript

  # Use relative URLs
  activate :relative_assets

  activate :imageoptim do |options|
    # Use a build manifest to prevent re-compressing images between builds
    options.manifest = true

    # Silence problematic image_optim workers
    options.skip_missing_workers = true

    # Cause image_optim to be in shouty-mode
    options.verbose = false

    # Setting these to true or nil will let options determine them (recommended)
    options.nice = true
    options.threads = true

    # Image extensions to attempt to compress
    options.image_extensions = %w(.png .jpg .gif .svg)

    # Compressor worker options, individual optimisers can be disabled by passing
    # false instead of a hash
    options.advpng    = { :level => 2 }
    options.gifsicle  = { :interlace => false }
    options.jpegoptim = { :strip => ['all'], :max_quality => 100 }
    options.jpegtran  = { :copy_chunks => false, :progressive => true, :jpegrescan => true }
    options.optipng   = { :level => 3, :interlace => false }
    options.pngcrush  = { :chunks => ['alla'], :fix => false, :brute => false }
    options.pngout    = false
    options.svgo      = {}
  end

  # activate :asset_host
  # set :asset_host, "//interfacecampaigns.blob.core.windows.net"

end
