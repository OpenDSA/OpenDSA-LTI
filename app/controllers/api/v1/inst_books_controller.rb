class Api::V1::InstBooksController < Api::V1::BaseController

  private

    def inst_book_params
      params.require(:user).permit(:title, :book_code)
    end

    def query_params
      params.permit(:title, :book_code)
    end

end

