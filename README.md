# LazyNames

LazyNames helps programmer to type faster very-long classes names, constants by defining them on a shorter version.   
If you are lazy like me typing many times a day in console long constant then this gem will ease your development process.

## Why

Consider this example from pry terminal session.  
![Lazy names in action](https://media.giphy.com/media/7CtRJfp2yocsOu9zEA/source.gif)

## Installation

1. Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'lazy_names'
end
```
2. Setup your console to automatically load lazy names

- If you are using pry, add this line to `~/.pryrc` or per project `myproject/.pryrc`

```ruby
if defined?(LazyNames)
  Pry.config.hooks.add_hook(:when_started, :lazy_names) do
    LazyNames.load_definitions!
  end
end
```

- If you are using irb, add this line to `~/.irbrc` or per project `myproject/.irbrc`

```ruby
if defined?(LazyNames)
  LazyNames.load_definitions!
end
```

3. And then execute:
```bash
bundle
```

4. Create your own lazy_names config where you define constants
```bash
cp .lazy_names.tt.yml ~/.lazy_names.yml
```

5. Login into your rails or non-rails console
```bash
$ bundle exec rails c # or bin/console
# your shorter version of constants are available now, enjoy!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zhisme/lazy_names.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
