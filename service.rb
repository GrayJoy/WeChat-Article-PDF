# 目标是，根据微信公众号历史消息页面，爬出所有历史文章并生成pdf
require_relative 'service/article'
require_relative 'service/generator'

module Service
	def self.perform history_url
		urls = Service::Article.new(history_url).get_all_urls
		Service::Generator.generate_pdf(urls)
	end
end
