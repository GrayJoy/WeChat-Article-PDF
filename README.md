# WeChat Article PDF
Generate PDF of WeChat public account's all history articles
- [x] support single article type
- [ ] to use Gemfile properly
- [ ] speed up pdf generating (almost 1min generating 10 articles)
- [ ] memory problem should be considered when articles are excessive
- [ ] test
- [ ] pdf's images display problem (WeChat original webpage's images display only when being scrolled to)
- [ ] support other types of history (type：1 text，3 image，34 audio，49 single/multiple articles，62 video)

# use
first, set up dependencies
```bash
bundle install
```
next, get your WeChat public account's history articles URL, which should be opened properly in your browser.
Well, this can be a little tricky, because WeChat doesn't seem wanna expose those URLs to public.
As far as I know, there are 2 ways to get the history articles URL, I recommend the first one, which is easier.
- Use `https://wx.qq.com/`
  Share your WeChat public account's history articles URL through File Transfer with your phone, and receive message in web WeChat. However, don't click the message directly.
  With some help of tools like Chrome DevTools, you can get your URL in a `p` element with `class="desc ng-binding"`
- Use old version of desktop WeChat client, version 1.* Mac client can be helpful.
  Share the URL through File Transfer with your phone, and receive message in desktop WeChat client. open it directly in your browser, and if it works, copy that URL.

finally, use this in irb/pry, you'll get `combined.pdf`
```ruby
require_relative 'service'
Service.perform YOUR_HISTORY_ARTICLES_URL
```
