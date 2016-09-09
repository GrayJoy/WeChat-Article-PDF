require "nokogiri"
require "open-uri"
require 'rest-client'
require 'uri'
require 'cgi'
require 'json'

module Service
  class Article

    # 历史消息URL（最简版本，只能在微信内打开）
    # 'https://mp.weixin.qq.com/mp/getmasssendmsg?__biz=MzI0MjA1Mjg2Ng==#wechat_webview_type=1&wechat_redirect'
    #
    # result['general_msg_list']['list'][0]['app_msg_ext_info']['content_url']
    #
    # 最初HTML中的last_msgid，可以通过nokogiri拿到
    # 后续的请求，last_msgid = result['general_msg_list']['list'][9]['comm_msg_info']['id']

    def initialize url
      params = parameterize(url)
      @__biz = params["__biz"][0]
      @uin = params["uin"][0]
      @key = params["key"][0]
      @pass_ticket = params["pass_ticket"][0]
      @history_url = url
    end

    def get_all_urls
      puts '========= fetch urls ========='
      urls = get_first_10_urls + get_next_urls
      # 文章顺序从前到后
      urls.reverse
    end

    # 首先根据URL，拿到最初10个文章的URL
    def get_first_10_urls
      # url = 'https://mp.weixin.qq.com/mp/getmasssendmsg?__biz=MzI0MjA1Mjg2Ng==&uin=MzMwNTQ4MjU1&key=18e81ac7415f67c475e0d7081758c96fdfe7c19e936c676815d85a2424eb57b670f9e5eaf11e610f4890dba86b9c3942&devicetype=iMac+MacBookPro12%2C1+OSX+OSX+10.10.5+build(14F1808)&version=11020201&lang=zh_CN&pass_ticket=xm7%2FNvvPV6xCkFxqZVH0kMPE2nZKbzbhVlht8sy%2BMiwZvz6%2FA%2FXUjrXPU%2BdA6RiP#wechat_webview_type=1'
      # 这个URL越发难拿到了，现在的做法是，从微信号历史消息页分享给传输助手，到网页版微信查看消息，打开chrome网页调试工具，查看消息内存的URL。
      # （注意，如果直接从传输助手，转发给传输助手，URL里面参数是会过期的）也就是分享之后URL已经固定了，只是客户端里打开又都删减了URL
      # ** 只有关注公众号的用户，才能获取更多消息，否则只能看前十条
      url_array = []
      html_data = open(@history_url, "Accept-Encoding" => "plain")	# ruby版本高于1.9之后，就要说明encoding

      # 直接打开网页时，nokogiri没有拿到所有文件，为什么？
      # 原来此网页是js动态渲染HTML。type：1（纯文字），3（图片），34（音频），49（图文/多图文），62（视频）

      # html_data = File.open("his.html")
      nokogiri_obj = Nokogiri::HTML(html_data)
      data_str = nokogiri_obj.to_s
      # elements = nokogiri_obj.xpath("//div[@class='msg_inner_wrapper default_box news_box']/a")
      raw_url_array = data_str.gsub(/&quot/, '"').scan(/(mp.weixin.qq.com[\S]{1,}?wechat_redirect)/)
      raw_url_array.each do |raw_url|
      	url = "http://#{raw_url[0].gsub(/\\\\/, '').gsub(/amp;amp;/, '')}"
      	puts url
      	url_array << url
      end
      @last_msgid = data_str.scan(/comm_msg_info(.*?)type/).last.first.match(/[\d]{1,}/).to_s
      url_array
    rescue NoMethodError => exception
      puts 'session outdated, try another history_url'
    end



    # 通过请求，获取json，拿到剩余所有文章的URL
    # 当返回的json里面的list内容，少于10的时候，就是停止的时候 ※❤️※
    def get_next_urls
    	url_array = []
    	msg_num = 10

    	# 当返回的消息里面有10条，就继续发送请求获取更多信息
    	# 当返回的消息里面不足10条，说明没有更多信息了
    	while msg_num == 10
        result = send_next_msgs_request @last_msgid
        update_last_msgid result
        msg_num = result['general_msg_list']['list'].length
        (0..(msg_num - 1)).each do |index|
          # 有个问题，如果是纯图片消息，就是result['general_msg_list']['list'][index]['image_msg_ext_info'] ——当然，json里没有关于图片的有效消息
          # 实际上，纯图片消息里面的图片URL，也是用现有参数是可以拼出来的
          msg_list = get_msg_list(result)
          url_array << msg_list[index]['app_msg_ext_info']['content_url'].gsub('amp;', '') if msg_list[index]['app_msg_ext_info']
        end
    	end
    	url_array
    end

    private

    # 从URL获取，想要的参数
    def parameterize url
      params = CGI.parse(URI.parse(url).query)
    end

    # 使用last_msgid，发起更多消息的请求，并获得返回参数
    def send_next_msgs_request last_msgid
      url = "https://mp.weixin.qq.com/mp/getmasssendmsg?__biz=#{@__biz}&uin=#{@uin}&key=#{@key}&f=json&frommsgid=#{last_msgid}&count=10&uin=#{@uin}&key=#{@key}&pass_ticket=#{@pass_ticket}&wxtoken=&x5=0"
      response = RestClient.get url
      result = JSON.parse response.body
    end

		# 根据request的返回hash，更新last_msgid
    def update_last_msgid result
      msg_list = get_msg_list(result)
      @last_msgid = msg_list[9]['comm_msg_info']['id']
    end

    # 返回的json解析一次之后获得result，result['general_msg_list'] 出来还是个string，所以要再解析一次
    def get_msg_list result
      msg_list = JSON.parse(result['general_msg_list'])
      msg_list['list']
    end

  end
end
