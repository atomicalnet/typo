require_dependency 'spam_protection'

class Trackback < Content
  include TypoGuid
  belongs_to :article, :counter_cache => true

  content_fields :excerpt

  validates_age_of :article_id
  validates_presence_of :title, :excerpt, :url
  validate_on_create :article_is_pingable

  def self.default_order
    'created_at ASC'
  end

  def initialize(*args, &block)
    super(*args, &block)
    self.title ||= self.url
    self.blog_name ||= ""
  end

  def location(anchor=:ignored, only_path=true)
    blog.url_for(article, "trackback-#{id}", only_path)
  end

  protected
  before_create :make_nofollow, :process_trackback, :create_guid

  def make_nofollow
    self.blog_name = blog_name.strip_html
    self.title     = title.strip_html
    self.excerpt   = excerpt.strip_html
  end

  def process_trackback
    if excerpt.length >= 251
      # this limits excerpt to 250 chars, including the trailing "..."
      self.excerpt = excerpt[0..246] << "..."
    end
  end

  def article_is_pingable
    return if article.nil?
    if blog.global_pings_disable
      errors.add(:article, "Pings are disabled")
    end
    unless article.allow_pings?
      errors.add(:article, "Article is not pingable")
    end
  end

  def akismet_options
    {:user_ip => ip, :comment_type => 'trackback', :comment_author => blog_name, :comment_author_email => nil,
      :comment_author_url => url, :comment_content => excerpt}
  end
  
  def spam_fields
    [:title, :excerpt, :ip, :url]
  end
end

