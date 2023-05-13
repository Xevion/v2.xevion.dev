<div align="center">

[<h1>v2.xevion.dev</h1>][website-url]

[![License][license-badge]][license-url]
[![Website][website-badge]][website-url]
![GitHub deployments][build-badge]

A Jekyll-based static blog for my personal usage. Styling originally by [Delan Azabani][azabani-repo-url].
</div>

## Usage

Note: `Gemfile.lock` generated on Ruby 3.2.2 - delete `Gemfile.lock` for Ruby 2.x support.

```bash
bundle install
bundle exec jekyll serve --config _config.yml,_config_dev.yml -l -t  # Live reload & debug trace
bundle exec jekyll build --config _config.yml -t  
```

Additionally, `./Launch.ps1` can be used to launch the site
with `--drafts --unpublished --incremental --open-url --live-reload --trace` enabled.

## Development Notes

This site uses a special HTML compression layout. This can cause production-only issues as the compression is not used
in development. Know the [restrictions][compression-layout-restrictions] of this layout. The primary issue to remember
is below.

- Inline javascript (`<script>`) tags with single-line comments (`// Single-line comment`) can break, essentially cause
  all of the javascript to lay upon one line.

[user-url]: https://github.com/Xevion/

[repo-url]: https://github.com/Xevion/v2.xevion.dev

[azabani-repo-url]: https://github.com/delan/www.azabani.com

[compression-layout-restrictions]: https://jch.penibelst.de/#restrictions

[website-url]: https://v2.xevion.dev

[banner-url]: ./assets/img/index-cover.png

[license-url]: https://github.com/Xevion/v2.xevion.dev/blob/master/LICENSE

[latest-url]: https://github.com/Xevion/v2.xevion.dev/commit/master

[license-badge]: https://img.shields.io/github/license/Xevion/v2.xevion.dev

[website-badge]: https://img.shields.io/badge/builtwith-jekyll-blue

[build-badge]: https://img.shields.io/github/deployments/Xevion/v2.xevion.dev/production?label=vercel