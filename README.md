# Building Lightning Apps

Created with [mdBook](https://rust-lang.github.io/mdBook/)

## Editing

To build and view content while editing:

1. Ensure rust is installed
1. Install mdBook

```
cargo install mdbook
```

1. Open the book

```
mdbook serve --open
```

1. Enjoy!

## Deploying a New Version

1. Checkout the gh-pages branch
1. git rm docs
1. mdbook build
1. mv book docs
1. commit and push to gh-pages
