<div align="center">

[<h1>v2.xevion.dev</h1>][website-url]


[![License][license-badge]][license-url]
[![Website][website-badge]][website-url]
[![Build Status][build-badge]][latest-url]

A jekyll-based static blog for my personal usage. Styling originally by [Delan Azabani][azabani-repo-url].
</div>

## Usage

```
bundle install
bundle exec jekyll serve --config _config.yml,_config_dev.yml
bundle exec jekyll build
```

## Development Notes

This site uses a special HTML compression layout. This can cause production-only issues as the compression is not used in development. Know the [restrictions][compression-layout-restrictions] of this layout. The primary issue to remember is below.

- Inline javascript (`<script>`) tags with single-line comments (`// Single-line comment`) can break, essentially cause all of the javascript to lay upon one line.

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
[build-badge]: https://github.com/Xevion/v2.xevion.dev/actions/workflows/pages/pages-build-deployment/badge.svg