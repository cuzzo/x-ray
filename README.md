# x-ray

A declarative way to scrape the web, with Ruby.

## Example

```ruby
xray('https://blog.ycombinator.com/', '.post', [{
  title: 'h1 a',
  link: '.article-title@href'
}])
```

## Installation

```bash
bundle install x-ray
```

## Documentation

This is a ruby implementation of [X-ray](https://github.com/matthewmueller/x-ray). It uses the same selector API.

## Selector API

### xray(url, selector)

Scrape the `url` for the following `selector`, returning an object.

### Scrape a Single Tag

```ruby
xray('https://blog.ycombinator.com', 'title')
```

### Scrape a Single CSS Class
```ruby
xray('https://blog.ycombinator.com', '.article-title')
```

### Scrape a Single Attribute
```ruby
xray('https://blog.ycombinator.com', 'a.article-title@href')
```

### Scrape innerHTML
```ruby
xray('https://blog.ycombinator.com', '.content-section')
```

### xray(url, scope, selector)
You can also supply a `scope` to each `selector`.

```ruby
# example.com = "<body><h2>Pear</h2></body>"
xray('https://example.com', 'body', 'h2')
# returns "Pear"
```

## Pipes
```ruby
xray('https://example.com', 'body', 'h2 | downcase')
# returns "pear"
```

You can pipe functions using the `|` character. If the returned value is a string, you can pipe string functions like `downcase` on the value. Alternatively, you can define your own functions and pipe the value to them.

```ruby
def concat_test(val)
  val + "test"
end

xray('https://example.com', 'body', 'h2 | downcase | concat_test')
# returns "peartest"
```

As the above example demonstartes, you can also pipe multiple functions.

## Filters
def external?(val)
  URI(val).host != 'ycombinator.com'
end

```ruby
xray('https://blog.ycombinator.com', ['img@alt > external? | downcase'])
```

To select exteranl images on ycombinator's blog, you can use the `>` character.

* N.B.: pipe and filter functions are executed in the order they are written.

## Selecting Multiple Values
To select all `.article-title`s on the page, put the selector in an array.

```ruby
xray('https://blog.ycombinator.com', ['.article-title@href'])
# returns ["http://blog.ycombinator.com/post1", "http://blog.ycombinator.com/post2", ...]
```

## Selecting several attributes
```ruby
xray('https://blog.ycombinator.com/', '.post', [{
  title: 'h1 a',
  link: '.article-title@href'
}])
# returns [{title: "post title 1", link: "http://blog.ycombinator.com/post1"}, {title: "post title 2", link: "http://blog.ycombinator.com/post2"}, ...]
```

## Limitations

Currently, sub-selection, pagination, concurrency, and rate-limiting is not implemented.

## Acknowledgements

[Matthew Mueller](https://github.com/matthewmueller) - Created the original [X-ray](https://github.com/matthewmueller/x-ray) for Node.

## License

X-ray is free--as in BSD. Hack your heart out, hackers.
