class Admin
  class BooksController < AdminController
    before_action :find_book, only: [:show, :edit, :update, :destroy]
    before_action :load_support, only: [:index, :show, :new, :edit, :destroy]

    def index
    end

    def show
      @book_item = BookItem.new
    end

    def new
      @book = Book.new
      @book.build_series
      @book.build_publisher
      @images = @book.images.build
      @book.author_books.build.build_author
    end

    def create
      @book = Book.new book_params
      if @book.save
        save_images if params[:images]
        flash[:success] = t "flash.book.create_success"
        redirect_to admin_book_path @book
      else
        render :new
      end
    end

    def edit
      @images = @book.images.build
    end

    def update
      update_images if params[:images]
      if @book.update_attributes book_params
        flash[:success] = t "flash.book.update_success"
        redirect_to admin_book_path @book
      else
        render :edit
      end
    end

    def destroy
      author = @supports.find_author
      author_book = author.books
      if author
        if (author_book.include? @book) && (author_book.delete @book)
          flash[:success] = t "flash.book.delete_success"
        else
          flash[:danger] = t "flash.book.destroy_fail"
        end
        redirect_back fallback_location: admin_books_path
      end
    end

    private
    def book_params
      params.require(:book).permit :title, :pages, :weight, :dimension, :isbn,
        :description, :publisher_id, :language_id, :series_id, category_ids: [],
        images_attributes: [:id, :url, :url_cache, :_destroy], author_ids: [],
        publisher_attributes: [:id, :name], series_attributes: [:id, :title],
        language_attributes: [:id, :full_name],
        author_books_attributes: [:id, :author_id, :_destroy,
        author_attributes: [:id, :name]], tag_ids: []
    end

    def save_images
      params[:images]["url"].each do |image|
        @images = @book.images.create!(url: image)
      end
    end

    def update_images
      book_images = @book.images
      book_images.each(&:destroy) if book_images.present?
      params[:images]["url"].each do |image|
        @images = book_images.create!(url: image)
      end
    end

    def find_book
      @book = Book.find_by id: params[:id]

      return if @book
      flash[:danger] = t "flash.book.find_fail"
      redirect_to admin_books_path
    end

    def load_support
      @supports = Supports::AdminBook.new book: Book.all, param: params
    end
  end
end
