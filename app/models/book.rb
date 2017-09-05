class Book < ApplicationRecord
  belongs_to :publisher, optional: true
  belongs_to :series, optional: true
  belongs_to :language, optional: true

  has_many :images, as: :target
  has_many :suggest_books
  has_many :rates
  has_many :borrows
  has_many :book_items, dependent: :destroy
  has_many :author_books, inverse_of: :book
  has_many :authors, through: :author_books, dependent: :destroy
  has_many :book_tags
  has_many :tags, through: :book_tags
  has_many :ebooks, dependent: :destroy
  has_many :book_categories
  has_many :categories, through: :book_categories, dependent: :destroy
  has_many :comments, as: :target
  has_many :blog_books
  has_many :blogs, through: :blog_books
  has_many :book_marks
  has_and_belongs_to_many :tags, join_table: :book_tags

  accepts_nested_attributes_for :publisher, reject_if: :all_blank
  accepts_nested_attributes_for :series, reject_if: :all_blank
  accepts_nested_attributes_for :images, allow_destroy: true
  accepts_nested_attributes_for :authors
  accepts_nested_attributes_for :author_books
  accepts_nested_attributes_for :tags
  accepts_nested_attributes_for :book_tags

  validates :title, presence: true

  today = Date.today
  week_ago = today - 1.week
  month_ago = today - 1.month

  scope :new_book, ->limit{Book.where("created_at > ?", week_ago).limit limit}
  scope :top_rated_book, ->limit{Book.order(rate: :desc).limit limit}
  scope :popular_book, ->limit{Book.where(id: rate_in_month).limit limit}
  scope :rate_in_month,
    ->{Rate.where("created_at > ?", month_ago).group(:book_id).pluck :book_id}
  scope :last_15_book, ->{Book.order(created_at: :desc).limit 15}

  def related_books
    id = self.id
    today = Date.today
    month_ago = today - 1.month
    relate = Book.joins(:author_books).where("author_books.author_id":
      AuthorBook.where(book_id: id).pluck(:author_id)).distinct(:id)
      .where.not(id: id)
    return relate if relate.present?
    Book.where("created_at > ?", month_ago).limit Settings.user.home.new_book
  end

  def new_book?
    today = Date.today
    month_ago = today - 1.month
    return true if self.created_at > month_ago
    false
  end

  def parent_comments
    comments.where(parent_id: 0).order id: :desc
  end

  def pdf_ebooks
    self.ebooks.where format: "pdf"
  end

  def available_book_item
    BookItem.ready.where book_id: self.id
  end

  def requesting_book user
    Borrow.where(user_id: user.id, book_id: self.id, status: [0, 1])
  end
end
