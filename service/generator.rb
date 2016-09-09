require 'pdfkit'
require 'combine_pdf'

class Service::Generator
  def self.generate_pdf(urls=[])
    time = Time.now
    puts "========= start generate pdf ========="
    pdf = CombinePDF.new
    urls.each do |url|
      if url
        article_pdf = PDFKit.new(url).to_pdf
        pdf << CombinePDF.parse(article_pdf)
      end
    end
    pdf.save "combined.pdf"
    duration = Time.now - time
    puts "took #{duration} seconds to generate pdf"
  end
end
